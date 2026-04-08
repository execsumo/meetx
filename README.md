# Heard

A macOS menu bar app that automatically detects Microsoft Teams meetings, records dual-track audio (app + mic), and produces on-device transcripts with speaker diarization. Also includes real-time dictation with text injection into any app.

No cloud, no LLM, no external APIs — everything runs on-device.

## Features

### Meeting Transcription
- **Auto-detection** — Polls `IOPMCopyAssertionsByProcess()` to detect active Teams meetings, extracts meeting title from window info
- **Dual-track recording** — Captures app audio via `CATapDescription` process tap and microphone via `AVAudioEngine`, both saved as WAV
- **On-device pipeline** — Sequential stages: VAD preprocessing (Silero) → transcription (Parakeet TDT V2) → diarization (LS-EEND + WeSpeaker) → speaker assignment
- **Speaker management** — Persistent speaker profiles with cosine-distance embedding matching, inline rename, merge, delete, and search
- **Roster scraping** — Reads Teams participant names via Accessibility APIs for automatic speaker name assignment
- **Markdown output** — Timestamped transcripts with speaker labels saved to a configurable folder
- **Job queue** — Persistent pipeline queue with retry logic (3x with backoff), survives app restart

### Dictation
- **Real-time speech-to-text** — Uses batch Parakeet TDT V2 with a 0.6s polling loop for low-latency transcription
- **Text injection** — Types transcribed text directly into the focused app via CGEvent unicode insertion
- **Stability-based injection** — Only injects words that are consistent across consecutive transcription cycles, preventing duplicates from model corrections
- **Global hotkey** — Ctrl+Shift+D (configurable) to toggle dictation from any app, registered via Carbon `RegisterEventHotKey` (no Accessibility permission needed for the hotkey itself)
- **Push-to-talk** — Optional mode where dictation is active only while the hotkey is held down
- **Model keep-alive** — ASR models stay loaded for 120s after dictation stops to avoid reload latency

### UI
- **Menu bar** — Status dot (pulsing red during recording), recording timer, job list, dictation state with partial transcript preview
- **Settings window** — Six tabs: General, Transcription, Dictation, Speakers, Permissions, About
- **Model management** — Pre-download cards with progress bars for all three model sets (VAD, Parakeet, Diarizer)
- **Launch at login** via `SMAppService`

## Requirements

- macOS 15.0+
- Apple Silicon (for CoreML/ANE inference)
- [FluidAudio](https://github.com/AugmentedAudioKit/FluidAudio) framework (resolved automatically via SPM)

## Build & Run

```bash
# Development build
swift build
swift run Heard

# App bundle (recommended — proper mic/accessibility permissions)
./scripts/bundle.sh
open build/Heard.app

# Signed build (required for dictation — Accessibility permission persists across rebuilds)
./scripts/bundle.sh --sign "Heard Dev"
open build/Heard.app
```

> **Note:** Running via `swift run` attributes mic permission to the terminal app. Use the `.app` bundle for proper permissions.

## Architecture

Single-process SwiftUI menu bar app (`MenuBarExtra` with `.window` style). All persistence is JSON files in `~/Library/Application Support/Heard/`.

```
Heard/
├── Sources/
│   ├── Heard/
│   │   └── MTApp.swift              # @main entry, MenuBarExtra + Window scenes
│   └── HeardCore/
│       ├── AppModel.swift           # Central state orchestration, dictation wiring
│       ├── CoreModels.swift         # AppPhase, PipelineJob, SpeakerProfile, AppSettings
│       ├── Services.swift           # MeetingDetector, RecordingManager, PipelineProcessor
│       ├── Views.swift              # Menu bar dropdown + settings window (all tabs)
│       ├── Stores.swift             # SettingsStore, SpeakerStore, PipelineQueueStore
│       ├── AudioProcessing.swift    # AudioPreprocessor, VadSegmentMap, resampling
│       ├── SpeakerAssignment.swift  # SpeakerMatcher, SegmentMerger, cosine distance
│       ├── ModelDownloadManager.swift # Pre-download manager for FluidAudio models
│       ├── DictationManager.swift   # Real-time dictation engine (batch ASR + polling)
│       ├── TextInjector.swift       # CGEvent unicode insertion into focused apps
│       ├── HotkeyManager.swift      # Global hotkey via Carbon RegisterEventHotKey
│       └── RosterReader.swift       # Teams participant names via AX APIs
├── scripts/
│   └── bundle.sh                    # Build + bundle + sign script
├── Info.plist                       # LSUIElement, mic usage description
├── Heard.entitlements               # Audio input (no sandbox)
├── spec.md                          # Full product specification
└── handoff.md                       # Implementation status and next steps
```

### Key Design Decisions

- **Batch ASR for dictation** — Streaming ASR (FluidAudio's `StreamingEouAsrManager`) was abandoned due to CoreML shape mismatches. Batch `AsrManager` with 0.6s polling provides better accuracy with acceptable latency.
- **Carbon hotkeys** — `RegisterEventHotKey` doesn't require Accessibility permission, unlike `CGEvent.tapCreate`. Works with ad-hoc signed builds.
- **Stability-based text injection** — Words are only injected after appearing in the same position across two consecutive transcription cycles, preventing duplicates from the model correcting earlier words as more audio accumulates.
- **No sandbox** — Required for `CATapDescription` app audio tapping and `CGEvent` text injection.

## Permissions

| Permission | Purpose | When Required |
|-----------|---------|---------------|
| Microphone | Record local audio | Always |
| Screen Recording | Tap app audio via process tap | For meeting recording |
| Accessibility | Text injection for dictation, roster scraping | For dictation and speaker names |

## Testing

```bash
swift run HeardTests    # 30+ unit tests
```

Manual testing: build the `.app` bundle and use "Simulate Meeting Start" (visible in Developer Mode under Settings → General) to exercise the full pipeline without a real Teams call.

## References

- `spec.md` — Full product and architecture specification
- `handoff.md` — Implementation status and next steps
