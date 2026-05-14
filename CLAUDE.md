# CLAUDE.md

## Project Overview

Heard is a macOS menu bar app that auto-detects Microsoft Teams meetings, records dual-track audio, and produces on-device transcripts with speaker diarization. See `spec.md` for the full product specification.

## Build & Run

```bash
swift build                # compile
swift run Heard            # compile and launch (terminal — mic permission goes to terminal app)
./scripts/bundle.sh        # build Heard.app bundle (ad-hoc signed)
open build/Heard.app       # launch as proper app (mic permission goes to Heard)
swift package clean        # clean build artifacts
```

No Xcode project — this is a Swift Package Manager executable. macOS 15.0+ required.

## Key Files

- `spec.md` — Product spec (source of truth for features and architecture)
- `handoff.md` — Current implementation status and next steps
- `Sources/Heard/MTApp.swift` — App entry point
- `Sources/HeardCore/AppModel.swift` — Central state orchestration
- `Sources/HeardCore/Services.swift` — Detection, recording, pipeline, permissions
- `Sources/HeardCore/Views.swift` — All UI (menu bar dropdown + settings window)
- `Sources/HeardCore/CoreModels.swift` — Data types
- `Sources/HeardCore/Stores.swift` — Persistence layer
- `Info.plist` — App bundle metadata
- `Heard.entitlements` — Entitlements (audio input only, no sandbox)
- `scripts/bundle.sh` — Build script for .app bundle
- `scripts/dmg.sh` — Distribution pipeline: release build → sign → notarize → staple → DMG → SHA256
- `.github/workflows/ci.yml` — CI: build + test on all pushes; release bundle + GitHub Release upload on tag push

## Working Rules

- Treat `spec.md` as the product source of truth unless the user explicitly changes scope.
- Read `handoff.md` before making changes to understand current state.
- Update `handoff.md` after substantial implementation work.
- Prefer the real macOS-native path (IOKit, CoreAudio, CoreML) over cross-platform abstractions.
- Keep the app as a single-process menu bar application.
- Do not introduce cloud APIs, LLM integrations, or non-English transcription.
- Keep v1 focused on post-meeting transcription. Dictation is v2 placeholder scaffolding.
- Avoid broad refactors — make targeted changes that deliver the next integration step.
- The "Simulate Meeting" buttons are intentional for testing without a real Teams call. Keep them.

## Architecture Notes

- `MenuBarExtra` with `.window` style — renders SwiftUI views in a floating panel
- `Window` scene with id "settings" — opened via `@Environment(\.openWindow)`
- Library target `HeardCore` + executable `Heard` + test executable `HeardTests`
- All persistence is JSON files in `~/Library/Application Support/Heard/`
- Pipeline stages run sequentially on a background task, one job at a time
- Meeting detection polls every 3 seconds via `IOPMCopyAssertionsByProcess()`
- Audio capture uses `CATapDescription` (app tap) + `AVAudioEngine` (mic)

## Testing

```bash
swift run HeardTests        # run the test suite
```

Manual testing:
1. `./scripts/bundle.sh && open build/Heard.app`
2. Click menu bar icon → "Simulate Meeting Start" to exercise the full flow
3. Use the Settings button to open preferences

## Gotchas

- Running via `swift run` attributes mic permission to the terminal app, not Heard. Use the .app bundle for proper permissions.
- The `.window` MenuBarExtra panel has a max height — keep the dropdown content compact
- FluidAudio dependency is declared but models aren't available as CoreML yet
- The worktree is at `.claude/worktrees/` — run commands from the worktree dir, not the main repo
