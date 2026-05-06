import Foundation

/// Removes mic-track segments that duplicate app-track segments — the speaker-bleed
/// case where remote audio plays through the laptop speakers and is picked up by
/// the laptop mic. The app track is treated as the canonical source for remote
/// speech; any mic segment whose text is mostly contained in a temporally
/// overlapping app segment is dropped.
public enum SegmentDeduplicator {

    /// Minimum fraction of mic-segment words that must appear in the app-segment
    /// word set for the pair to count as duplicates. Directional (mic ⊆ app),
    /// not symmetric — bleed often produces fewer words than the clean copy.
    static let containmentThreshold: Double = 0.7

    /// Minimum absolute number of overlapping words required in addition to the
    /// containment ratio. Guards short user backchannels — "yeah" / "right" /
    /// "okay" — from being dropped just because the same word happens to appear
    /// in a long overlapping app segment. A genuine bleed of any meaningful
    /// utterance will share at least this many words with the clean app copy.
    static let minIntersectionWords: Int = 3

    /// Edge tolerance applied to time-overlap checks (seconds). Loosely matches
    /// ASR timing slop and any imprecision in `micDelaySeconds`.
    static let edgeTolerance: TimeInterval = 1.5

    /// Drop mic segments that duplicate app segments via speaker bleed.
    ///
    /// `appSegments` and `micSegments` carry their own original-time timestamps.
    /// `micDelaySeconds` is `mic.start − app.start`; mic-track time T maps to
    /// app-track time T + micDelaySeconds.
    public static func dropMicBleed(
        appSegments: [TranscriptSegment],
        micSegments: [TranscriptSegment],
        micDelaySeconds: TimeInterval
    ) -> [TranscriptSegment] {
        guard !appSegments.isEmpty, !micSegments.isEmpty else { return micSegments }

        let appWordSets: [(start: TimeInterval, end: TimeInterval, words: Set<String>)] =
            appSegments.map {
                (start: $0.startTime, end: $0.endTime, words: tokenize($0.text))
            }

        return micSegments.filter { micSeg in
            let micWords = tokenize(micSeg.text)
            guard !micWords.isEmpty else { return true }

            let micStartShared = micSeg.startTime + micDelaySeconds
            let micEndShared = micSeg.endTime + micDelaySeconds

            for app in appWordSets {
                let overlapStart = max(micStartShared, app.start) - edgeTolerance
                let overlapEnd = min(micEndShared, app.end) + edgeTolerance
                guard overlapEnd > overlapStart else { continue }

                let intersection = micWords.intersection(app.words).count
                let containment = Double(intersection) / Double(micWords.count)
                if intersection >= minIntersectionWords && containment >= containmentThreshold {
                    NSLog("Heard: dedup dropped mic segment '\(prefix(micSeg.text))' (containment=\(String(format: "%.2f", containment)))")
                    return false
                }
            }
            return true
        }
    }

    /// Lowercase, strip punctuation, split on whitespace.
    static func tokenize(_ text: String) -> Set<String> {
        let lowered = text.lowercased()
        let scalars = lowered.unicodeScalars.map { scalar -> Character in
            CharacterSet.letters.union(.decimalDigits).union(.whitespaces).contains(scalar)
                ? Character(scalar) : " "
        }
        return Set(String(scalars).split(whereSeparator: \.isWhitespace).map(String.init))
    }

    private static func prefix(_ text: String, length: Int = 40) -> String {
        if text.count <= length { return text }
        return String(text.prefix(length)) + "…"
    }
}
