# Handoff

## Current Status

The app builds cleanly with `swift build` and runs as a menu bar app on macOS 14.2+. Core infrastructure is complete — meeting detection, dual-track audio capture, on-device transcription (Parakeet TDT V2), VAD (Silero), speaker diarization (LS-EEND + WeSpeaker), and speaker assignment are all functional via the FluidAudio framework. An `.app` bundle is available via `./scripts/bundle.sh`.

## What's Working

### Meeting Detection
- Polls `IOPMCopyAssertionsByProcess()` every 3 seconds for Teams power assertions
- Extracts meeting title from Teams window via `CGWindowListCopyWindowInfo`
- Debounce: requires 2 consecutive detections before triggering
- Cooldown: 5-second delay after meeting end before re-detection
- Simulation mode available for testing without a real Teams call (with `isSimulated` flag to prevent polling interference)

### Audio Capture
- **App audio**: `CATapDescription` process tap on the Teams PID, recorded via `AVAudioEngine` to WAV
- **Microphone**: Separate `AVAudioEngine` instance recording to WAV
- Both tracks saved to `~/Library/Application Support/Heard/recordings/`
- Mic delay calibration stored per session for alignment
- 4-hour max recording duration with automatic split and re-start
- Temp file cleanup on app launch (removes stale `.wav` files older than 48 hours)

### Pipeline (Fully Implemented)
- Sequential job queue with stages: queued → preprocessing → transcribing → diarizing → assigning → complete
- **Preprocessing**: Resample to 16kHz mono via `AudioConverter`, Silero VAD silence trimming, `VadSegmentMap` for timestamp remapping
- **Transcription**: Parakeet TDT V2 via `AsrManager` with 16k sample minimum guard
- **Diarization**: `OfflineDiarizerManager` for speaker segments + embeddings
- **Speaker Assignment**: Cosine distance matching against `SpeakerStore`, confidence margin filtering, embedding diversity management
- Non-retryable errors (no audio, too short) fail immediately; transient errors retry 3x with backoff (5s, 30s, 5min)
- Jobs persist to JSON and survive app restart; failed jobs auto-retry on relaunch
- Pipeline fires `onPipelineIdle` callback so app phase returns to dormant
- Markdown transcript output with timestamped speaker-labeled segments

### Model Management
- `ModelDownloadManager` pre-downloads all 3 model sets (VAD, Parakeet, Diarizer) via FluidAudio
- Status detection checks FluidAudio's actual cache paths (`~/Library/Application Support/FluidAudio/Models/`)
- Progress tracking per model during download
- Models auto-download on first meeting if not pre-downloaded

### UI
- Menu bar dropdown with status dot (pulsing red during recording), recording timer, job list with dismiss buttons
- Settings window (opened via `@Environment(\.openWindow)`) with 6 tabs: General, Transcription, Dictation, Speakers, Permissions, About
- Keyboard input works in Settings (activation policy switching)
- Output folder picker via `NSOpenPanel`
- Custom vocabulary management (add/remove terms, 3-char min, 50-term cap, immediate UI update on delete)
- Speaker table with inline rename, merge, delete (context menu), search, and sort (Name / Last Seen / Meeting Count)
- Model download status with progress bars
- Permission status with grant buttons and System Settings deep-links
- Launch at login via `SMAppService`
- Quit button in menu bar dropdown

### App Bundle
- `Info.plist` with `LSUIElement` (menu bar app), `NSMicrophoneUsageDescription`, bundle ID `com.execsumo.heard`
- `Heard.entitlements` with audio-input only (no sandbox per spec)
- `scripts/bundle.sh` builds via SPM, creates `.app` bundle, ad-hoc signs
- Supports `--release` and `--sign IDENTITY` flags for distribution builds

### Testing
- `HeardTests` executable target with 30+ tests covering: VadSegmentMap, cosine distance, SpeakerMatcher, SegmentMerger, AudioPreprocessor, TranscriptWriter, SpeakerStore, PipelineQueueStore
- Custom lightweight test harness (no XCTest/Xcode dependency)
- Run with `swift run HeardTests`

### Persistence
- `SettingsStore`: UserDefaults-backed app settings
- `SpeakerStore`: JSON file at `~/Library/Application Support/Heard/speakers.json`
- `PipelineQueueStore`: JSON file at `~/Library/Application Support/Heard/queue.json`

## Architecture

| Target | Purpose |
|--------|---------|
| `HeardCore` (library) | All models, services, views, stores |
| `Heard` (executable) | App entry point, imports HeardCore |
| `HeardTests` (executable) | Test runner, imports HeardCore |

| File | Purpose |
|------|---------|
| `Package.swift` | SPM config, macOS 14.2+, FluidAudio dependency |
| `Sources/Heard/MTApp.swift` | `@main` entry, MenuBarExtra + Window scenes |
| `Sources/HeardCore/AppModel.swift` | Central state, action handlers, lifecycle |
| `Sources/HeardCore/CoreModels.swift` | AppPhase, PipelineJob, SpeakerProfile, AppSettings, etc. |
| `Sources/HeardCore/Services.swift` | MeetingDetector, RecordingManager, PipelineProcessor, PermissionCenter, TranscriptWriter |
| `Sources/HeardCore/Stores.swift` | SettingsStore, SpeakerStore, PipelineQueueStore, FileManager extensions |
| `Sources/HeardCore/Views.swift` | MenuBarView, SettingsView, all tabs and components |
| `Sources/HeardCore/AudioProcessing.swift` | AudioPreprocessor, VadSegmentMap, PreprocessedTrack |
| `Sources/HeardCore/SpeakerAssignment.swift` | SpeakerMatcher, SegmentMerger, cosineDistance |
| `Sources/HeardCore/ModelDownloadManager.swift` | Pre-download manager for FluidAudio models |
| `Info.plist` | App bundle metadata |
| `Heard.entitlements` | Audio input entitlement |
| `scripts/bundle.sh` | Build + bundle script |

## Next Steps

1. **Accessibility roster scraping** — Read Teams participant list via Accessibility APIs for automatic speaker naming (reduces manual naming after meetings)
2. **End-to-end validation** — Test with a real Teams meeting to verify the full pipeline produces a usable transcript
3. **App icon** — Create and include an app icon for the bundle
4. **CI/CD pipeline** — GitHub Actions workflow for build, sign, notarize, publish
5. **DMG packaging** — Create distributable disk image for direct download
6. **Homebrew Cask formula** — For `brew install heard`

## Known Issues

- Running via `swift run` in a terminal causes macOS to attribute microphone permission to the terminal app (e.g., Ghostty) rather than Heard. Use `./scripts/bundle.sh && open build/Heard.app` instead.
- The `.window` style MenuBarExtra panel has a fixed max height; if many jobs accumulate, the bottom of the panel may clip.
- Simulated meetings produce very short recordings that fail in the pipeline (expected — they exist for UI testing, not audio testing).
