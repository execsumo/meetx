import AVFAudio
import Accelerate
import Foundation

// MARK: - VAD Segment Map

/// Maps trimmed-audio timestamps back to original-audio timestamps after VAD silence removal.
/// Uses binary search for O(log n) lookups.
struct VadSegmentMap {
    struct Mapping {
        let trimmedStart: TimeInterval
        let trimmedEnd: TimeInterval
        let originalStart: TimeInterval
        let originalEnd: TimeInterval
    }

    let mappings: [Mapping]

    /// Total duration of trimmed audio (speech only).
    var trimmedDuration: TimeInterval {
        mappings.last?.trimmedEnd ?? 0
    }

    /// Convert a timestamp in trimmed-audio space to original-audio space.
    func toOriginalTime(_ trimmedTime: TimeInterval) -> TimeInterval {
        guard !mappings.isEmpty else { return trimmedTime }

        // Binary search for the mapping containing this trimmed time
        var lo = 0, hi = mappings.count - 1
        while lo <= hi {
            let mid = (lo + hi) / 2
            let m = mappings[mid]
            if trimmedTime < m.trimmedStart {
                hi = mid - 1
            } else if trimmedTime > m.trimmedEnd {
                lo = mid + 1
            } else {
                // Found the segment — linear interpolation within
                let offset = trimmedTime - m.trimmedStart
                return m.originalStart + offset
            }
        }

        // Past the last segment — clamp to end
        if let last = mappings.last {
            return last.originalEnd
        }
        return trimmedTime
    }
}

// MARK: - Preprocessed Track

/// The result of preprocessing one audio track: 16 kHz mono float samples + VAD map.
struct PreprocessedTrack {
    let samples: [Float]
    let sampleRate: Double // always 16000
    let vadMap: VadSegmentMap

    var duration: TimeInterval {
        Double(samples.count) / sampleRate
    }
}

// MARK: - Audio Preprocessor

/// Stage 1 of the pipeline: load WAV, downmix to mono, resample to 16 kHz, run VAD trimming.
enum AudioPreprocessor {

    static let targetSampleRate: Double = 16_000

    /// Preprocess a recorded WAV file into a 16 kHz mono float buffer with VAD trimming.
    static func preprocess(wavURL: URL, isStereo: Bool) async throws -> PreprocessedTrack {
        // Step 1: Load the WAV file
        let sourceFile = try AVAudioFile(forReading: wavURL)
        let sourceFormat = sourceFile.processingFormat
        let frameCount = AVAudioFrameCount(sourceFile.length)

        guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount) else {
            throw PreprocessingError.bufferAllocationFailed
        }
        try sourceFile.read(into: sourceBuffer)

        // Step 2: Downmix to mono if stereo
        let monoBuffer: AVAudioPCMBuffer
        if isStereo && sourceFormat.channelCount > 1 {
            monoBuffer = try downmixToMono(sourceBuffer)
        } else if sourceFormat.channelCount == 1 {
            monoBuffer = sourceBuffer
        } else {
            monoBuffer = try downmixToMono(sourceBuffer)
        }

        // Step 3: Resample to 16 kHz
        let resampledBuffer = try resampleTo16kHz(monoBuffer)

        // Step 4: Extract float samples
        guard let channelData = resampledBuffer.floatChannelData else {
            throw PreprocessingError.noChannelData
        }
        let count = Int(resampledBuffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: count))

        // Step 5: VAD trimming
        let (trimmedSamples, vadMap) = vadTrim(samples: samples, sampleRate: targetSampleRate)

        return PreprocessedTrack(
            samples: trimmedSamples,
            sampleRate: targetSampleRate,
            vadMap: vadMap
        )
    }

    // MARK: - Downmix

    /// Average left and right channels to produce a mono buffer.
    private static func downmixToMono(_ stereoBuffer: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer {
        guard let channelData = stereoBuffer.floatChannelData else {
            throw PreprocessingError.noChannelData
        }
        let frameCount = Int(stereoBuffer.frameLength)
        let channelCount = Int(stereoBuffer.format.channelCount)

        let monoFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: stereoBuffer.format.sampleRate,
            channels: 1,
            interleaved: false
        )!
        guard let monoBuffer = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            throw PreprocessingError.bufferAllocationFailed
        }
        monoBuffer.frameLength = AVAudioFrameCount(frameCount)

        guard let monoData = monoBuffer.floatChannelData else {
            throw PreprocessingError.noChannelData
        }

        // Average all channels using Accelerate
        // Start with channel 0
        memcpy(monoData[0], channelData[0], frameCount * MemoryLayout<Float>.size)

        // Add remaining channels
        for ch in 1..<channelCount {
            vDSP_vadd(monoData[0], 1, channelData[ch], 1, monoData[0], 1, vDSP_Length(frameCount))
        }

        // Divide by channel count
        var divisor = Float(channelCount)
        vDSP_vsdiv(monoData[0], 1, &divisor, monoData[0], 1, vDSP_Length(frameCount))

        return monoBuffer
    }

    // MARK: - Resampling

    /// Resample a mono buffer to 16 kHz using AVAudioConverter.
    private static func resampleTo16kHz(_ sourceBuffer: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer {
        let sourceSampleRate = sourceBuffer.format.sampleRate
        if abs(sourceSampleRate - targetSampleRate) < 1.0 {
            return sourceBuffer // Already at target rate
        }

        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        )!

        guard let converter = AVAudioConverter(from: sourceBuffer.format, to: targetFormat) else {
            throw PreprocessingError.converterCreationFailed
        }

        let ratio = targetSampleRate / sourceSampleRate
        let estimatedFrames = AVAudioFrameCount(Double(sourceBuffer.frameLength) * ratio) + 1024
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: estimatedFrames) else {
            throw PreprocessingError.bufferAllocationFailed
        }

        var error: NSError?
        var isDone = false
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if isDone {
                outStatus.pointee = .noDataNow
                return nil
            }
            isDone = true
            outStatus.pointee = .haveData
            return sourceBuffer
        }

        if let error {
            throw PreprocessingError.conversionFailed(error.localizedDescription)
        }
        guard status != .error else {
            throw PreprocessingError.conversionFailed("AVAudioConverter returned error status")
        }

        return outputBuffer
    }

    // MARK: - VAD Trimming

    /// Simple energy-based VAD until Silero VAD CoreML model is integrated.
    /// Uses RMS energy with a fixed threshold to detect speech frames.
    /// Returns trimmed samples and the segment map for timestamp remapping.
    private static func vadTrim(
        samples: [Float],
        sampleRate: Double,
        frameSize: Int = 512, // ~32ms at 16kHz
        hopSize: Int = 256,   // ~16ms hop
        threshold: Float = 0.01 // RMS energy threshold
    ) -> ([Float], VadSegmentMap) {
        guard !samples.isEmpty else {
            return ([], VadSegmentMap(mappings: []))
        }

        // Detect speech frames using RMS energy
        var speechFrames: [Bool] = []
        var offset = 0
        while offset + frameSize <= samples.count {
            var rms: Float = 0
            vDSP_rmsqv(
                samples.withUnsafeBufferPointer { $0.baseAddress! + offset },
                1,
                &rms,
                vDSP_Length(frameSize)
            )
            speechFrames.append(rms > threshold)
            offset += hopSize
        }

        // Merge consecutive speech frames into segments
        var segments: [(start: Int, end: Int)] = [] // in sample indices
        var inSpeech = false
        var segStart = 0

        for (i, isSpeech) in speechFrames.enumerated() {
            let sampleOffset = i * hopSize
            if isSpeech && !inSpeech {
                segStart = sampleOffset
                inSpeech = true
            } else if !isSpeech && inSpeech {
                segments.append((start: segStart, end: sampleOffset + frameSize))
                inSpeech = false
            }
        }
        if inSpeech {
            segments.append((start: segStart, end: samples.count))
        }

        // If no speech detected, return all samples (don't discard everything)
        if segments.isEmpty {
            let fullMap = VadSegmentMap(mappings: [
                VadSegmentMap.Mapping(
                    trimmedStart: 0,
                    trimmedEnd: Double(samples.count) / sampleRate,
                    originalStart: 0,
                    originalEnd: Double(samples.count) / sampleRate
                ),
            ])
            return (samples, fullMap)
        }

        // Build trimmed samples and mapping
        var trimmedSamples: [Float] = []
        var mappings: [VadSegmentMap.Mapping] = []
        var trimmedOffset: TimeInterval = 0

        for seg in segments {
            let originalStart = Double(seg.start) / sampleRate
            let originalEnd = Double(seg.end) / sampleRate
            let segDuration = originalEnd - originalStart

            mappings.append(VadSegmentMap.Mapping(
                trimmedStart: trimmedOffset,
                trimmedEnd: trimmedOffset + segDuration,
                originalStart: originalStart,
                originalEnd: originalEnd
            ))

            let clampedEnd = min(seg.end, samples.count)
            trimmedSamples.append(contentsOf: samples[seg.start..<clampedEnd])
            trimmedOffset += segDuration
        }

        return (trimmedSamples, VadSegmentMap(mappings: mappings))
    }
}

// MARK: - Errors

enum PreprocessingError: LocalizedError {
    case bufferAllocationFailed
    case noChannelData
    case converterCreationFailed
    case conversionFailed(String)

    var errorDescription: String? {
        switch self {
        case .bufferAllocationFailed: return "Failed to allocate audio buffer"
        case .noChannelData: return "Audio buffer has no channel data"
        case .converterCreationFailed: return "Failed to create audio format converter"
        case .conversionFailed(let detail): return "Audio conversion failed: \(detail)"
        }
    }
}
