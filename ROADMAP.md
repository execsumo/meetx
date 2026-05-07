# Heard — Roadmap

A living list of planned improvements and stretch ideas. Ordered by how close each item is to the current scope of `spec.md`. Anything that would change the product (cloud APIs, LLM integration, non-English transcription, Zoom/Webex support) belongs in [What's explicitly NOT in scope](#whats-explicitly-not-in-scope) unless the spec itself changes.

## Near-term — polish & stability

These land inside the existing v1 scope and mostly tighten things the user already sees.

### Distribution & install
- **DMG packaging.** Add a `scripts/dmg.sh` that builds, signs, notarizes, and stamps out a DMG for GitHub Releases.
- **Homebrew Cask.** Draft a Cask formula so the app is installable via `brew install --cask heard` once the DMG pipeline is live.
- **CI pipeline.** GitHub Actions workflow: `swift build`, run `HeardTests`, build the bundle, (optionally) notarize, publish artifacts on tag pushes.
- **Sparkle (or equivalent) update checker.** Explicitly out of scope per `spec.md`, but worth reconsidering once CI publishes releases.


### Meeting detection & recording
- **Audible meeting-start chime (opt-in).** A short non-intrusive sound confirms recording started. Off by default.

### Pipeline
- **Preprocessing concurrency guard.** Both tracks are currently preprocessed concurrently in a `TaskGroup`. On machines with tight memory, this doubles the peak RAM during VAD. Expose a setting to serialize preprocessing.
- **Progress in the UI.** The menu bar dropdown shows the current stage but no sub-stage progress. Emit sample-count-based progress from `AsrManager.transcribe` through an `AsyncStream`.
- **Per-job log viewer.** When a job fails, the error string is short. Capture a rolling per-job log (stdout/NSLog lines) and show it in a disclosure view.
- **Exclude silent clips from speaker naming.** When extracting audio clips for the speaker naming dialogue, filter out segments with silence/VAD gaps so each playback is continuous speech.
- **Fix speaker naming dialogue auto-close.** The 120-second auto-dismiss is too aggressive when the user is actively filling out speaker names. Change behavior: close only if the window has been open and dormant (no text edits) for the full duration.
- **Improve speaker table sorting.** Replace the sort dropdown with standard column-header sorting: click a column name (Name / Last Seen / Meeting Count) to sort by that field, click again to toggle descending (default) ↔ ascending. Show a subtle indicator (caret) on the active sort column.

### Testing
- **Golden-file tests for `RosterReader` AX traversal.** The parser and filter are covered, but the actual DOM walk (`findRosterPanel`, `findParticipantList`, `extractTextChildren`) is still untested because it's bound to live `AXUIElement`. Introduce a small protocol wrapper around the AX tree that can be fed captured JSON snapshots from real Teams meetings (various states: pre-join lobby, 2-person call, 10-person call, roster panel open vs collapsed). This is the single highest-value remaining roster test — the one most likely to catch breakage when Teams updates its DOM.

### Custom vocabulary
- **Phrase boosting, not just terms.** The CTC path tokenizes whole strings, so multi-word phrases already work — but the UI suggests "terms" and the 3-char minimum blocks short acronyms. Reconsider the minimum and label the field "Terms or short phrases".
- **Import/export vocabulary list.** JSON round-trip via drag-and-drop.

## Mid-term — within-spec enhancements

Features that fit the on-device, single-process philosophy but require more code than a polish pass.

### Speaker management
- **Speaker merge preview.** Before committing a merge, show both speakers' recent meeting counts, first/last-seen dates, and a diff of embeddings count. When merging, keep the name that is not a "Speaker X" placeholder (prefer the real human-given name).
- **Manual speaker split.** Inverse of merge — split a speaker profile if the user realizes two voices were collapsed.
- **Per-speaker colors in the transcript.** Lightweight Markdown footer or HTML export with consistent per-speaker colors.
- **Voice clip gallery.** Store a single 10-second reference clip per known speaker so the user can play it back from Settings → Speakers to verify identity.
- **Bulk-delete / archive old speakers.** Speakers with no meeting activity in N months.

### Pipeline & output
- **Alternative output formats.** Out of scope per spec today, but worth re-evaluating: plain `.txt`, `.srt`, VTT for video workflows, or a lightweight HTML with anchors.
- **Grounded speaker assignment.** Use the WeSpeaker embedding on the mic track to double-check that the "longest-duration speaker on mic = local user" heuristic holds. If it doesn't, fall back to prompting the user.

### Dictation
- **Dictation transcript log.** Optional history of dictated text (with timestamps and target-app name) for recovery if injection drops characters.
- **Per-app enable list.** Disable dictation in banking apps, password managers, or other sensitive fields.
- **Vocab-scoped dictation.** Reuse the custom-vocab boosting (already wired into `SlidingWindowAsrManager`) in a "coding mode" with camelCase / snake_case post-processing.

### Preferences & UI
- **Localize the settings UI.** The spec says English-only for transcription, but the app chrome could be localized.
- **Keyboard shortcuts in the dropdown.** ⌘S (start/stop watching), ⌘N (name speakers), ⌘, (settings), ⌘Q (quit) — mentioned in the spec but currently only partially wired.
- **Re-ordered settings tabs.** "General" is crowded today. Consider splitting out a "Transcription" tab (custom vocabulary + output folder + CTC keep-alive) once we have more to put there.

### Design ideas (from `design_handoff_app_surfaces`)
These surfaces are specified in the design handoff but not yet implemented:
- **First-run onboarding flow.** A 620×480px four-step permission wizard (Microphone → Screen Recording → System Audio → Accessibility) with progress indicator and Grant/Skip buttons. Shows on first launch before the main UI.
- **About as a modal sheet.** The design specifies About as a dimmed overlay sheet (380px wide) over the app, rather than a settings tab. Current tab is functional; this would be a polish upgrade.
- **Empty and error state views.** Dedicated centered states for three cases: no speakers yet (people icon, surfaceAlt well, "Open transcripts" CTA); microphone denied (mic icon, badSoft well, "Open System Settings…" CTA); model download failed (warn icon, badSoft well, "Retry download" CTA).

### Diagnostics
- **In-app diagnostics pane.** Promote `scripts/diagnose.swift` into a hidden developer pane that surfaces Teams process IDs, active power assertions, CoreAudio device tree, and the most recent tap status.
- **One-click bug report bundle.** Zip up recent logs, `pipeline_queue.json`, and (opt-in) the last failed recording's WAVs for manual sharing.

## Long-term — bigger bets

These stretch the architecture and deserve a spec update before landing.

- **Zoom / Webex / Google Meet detection.** Today Heard only recognises Teams power assertions. A pluggable "meeting source" abstraction could add others without touching the pipeline. Out of scope in `spec.md` as of v1.
- **Live captions during the meeting.** The spec explicitly disables this to keep the Mac cool during calls; revisit once Apple Silicon idle cost improves or the user can opt-in per-meeting.
- **Sortformer diarizer.** FluidAudio includes `SortformerDiarizer` (~11% DER vs ~17.7% for current LS-EEND + WeSpeaker). Blocked by an embedding gap: Sortformer's `DiarizerTimeline` carries no per-segment speaker embeddings, which the cross-meeting speaker identity system requires. Unblock by adding a WeSpeaker embedding-extraction pass on Sortformer's segments before converting to `DiarizationResult`. Selectable per-meeting size makes sense (Sortformer has 4 fixed speaker slots).
- **Live speaker identification during the meeting.** Would need a streaming diarizer; today's LS-EEND is offline.
- **Meeting note summaries.** Requires an LLM, which is explicitly out of scope. Revisit only if a local, on-device model ships that meets the quality bar.
- **Batch import of existing recordings.** Drag-and-drop a `.wav` / `.m4a` file into the menu bar dropdown to run the same pipeline on it. Explicitly out of scope in v1.
- **Android / Windows companion.** Heard is macOS-only by design. Not planned.

## Technical debt

- **In-meeting note editing.** Today the user edits notes by opening the rendered `.md` directly. A future polish: a "Notes" disclosure on each completed job in the menu bar dropdown that lists captured notes and lets the user edit/delete before the transcript is finalized (or rewrite the `.md` if it's already been written).
- **Hotkey-collision detection for the note hotkey.** The dictation hotkey recorder validates against a list of system shortcuts; the meeting-note hotkey reuses the same recorder, but neither warns about clashes with the user's other custom hotkeys (Heard's own dictation hotkey, third-party launchers, etc.). Centralize the validator and run both Heard hotkeys through it.
- **`Views.swift` size.** ~1.9 kLOC for all UI after the Paper design system landed. Split by tab once we're past the early iteration phase.
- **`SlidingWindowAsrConfig` doesn't expose `TdtConfig`.** The internal `asrConfig` hardcodes `TdtConfig()` (blankId 8192 = v3 default). `AsrManager` auto-adapts the blankId when it detects a mismatch against the loaded model, so v2 models work correctly today — but if FluidAudio ever removes that adaptation, v2 dictation would silently decode incorrectly. Upstream fix: add a `tdtConfig` parameter to `SlidingWindowAsrConfig`.

## Non-goals (from `spec.md`)

These are intentional exclusions. Don't add them without a spec update.

- LLM integration (no Claude, OpenAI, or local LLM)
- Cloud APIs of any kind
- Non-English transcription / multilingual models
- Zoom / Webex / Google Meet support
- Manual app recording (pick any app)
- System-wide audio capture
- Multiple output formats beyond Markdown
- Configurable VAD threshold or speaker count
- macOS notifications
- Live captions or live speaker ID during meetings
- Batch import of existing recordings
- Pre-release update channels
- Dictation voice commands (`"scratch that"`, `"new paragraph"`) and spoken punctuation
