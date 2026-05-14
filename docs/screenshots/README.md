# Screenshots

This folder holds the screenshots referenced from the top-level `README.md`. Replace any missing PNG with a real capture; keep the filenames exactly as listed so the README links don't break.

All shots should be taken on a Retina display, 2x resolution, with the app's "Paper" light palette. Crop tightly to the surface — no surrounding desktop chrome unless noted.

| File | What to capture | Suggested size |
|---|---|---|
| `hero.png` | Menu bar dropdown in `Recording` state, with the elapsed timer visible. Optional: composite over a soft Paper-palette backdrop. | ~1200 × 800 |
| `menubar-dropdown.png` | Menu bar dropdown in `Watching` state, showing 2–3 Recent Meetings. | 268 × natural |
| `recording.png` | Menu bar dropdown in `Recording` state with the dark `#2E3338` header strip and elapsed time. | 268 × natural |
| `transcript.png` | A finished Markdown transcript open in a Markdown viewer (e.g. Obsidian, Marked 2, or VS Code preview). Speaker labels, timestamps, and at least one `[mm:ss] _**Note from …:**_` line should be visible. | ~1000 × 700 |
| `dictation-hud.png` | The floating "Dictating" pill at the bottom of the screen, with a focused text field above it showing live transcribed text. | ~900 × 500 |
| `settings-general.png` | Settings → General tab. Show the Behavior, Permissions, and Custom vocabulary cards. | 880 × 600 |
| `settings-models.png` | Settings → Models tab with the dark hero card and a couple of model rows. | 880 × 600 |
| `settings-speakers.png` | Settings → Speakers tab with a populated list, search visible. | 880 × 600 |
| `name-speakers.png` | Speaker naming window with two candidate cards (one playing, one idle) and the auto-dismiss countdown. | 560 × 520 |

## How to capture cleanly

1. Launch the bundled app: `./scripts/bundle.sh && open build/Heard.app`.
2. Enable Developer Mode (Settings → General) so the **Simulate Meeting** buttons appear.
3. Resize the Settings window to its default 880 × 600 and snap window screenshots with `⌘⇧4 + space` then click the window.
4. For the menu bar dropdown, use `⌘⇧5` → "Capture Selected Portion" and drag a rectangle around the panel.
5. Save PNGs into this folder with the exact filenames above.

Hi-DPI PNGs render crisply on GitHub; avoid JPEG.
