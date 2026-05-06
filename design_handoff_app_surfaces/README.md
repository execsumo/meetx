# Handoff: Heard — App Surfaces

## Overview
Full UI design for **Heard**, a macOS menu bar app that silently auto-detects Microsoft Teams meetings, records dual-track audio (app + mic), and produces on-device transcripts with speaker diarization and dictation.

This package covers every primary surface:
- Settings window (4 tabs: General, Dictation, Models, Speakers)
- Menu bar dropdown (5 states)
- First-run onboarding flow
- Speaker naming window
- About sheet
- Empty / error states

## About the design files
The files in `reference/` are **HTML design prototypes** — they show intended look, structure, and interactive behavior, but are **not production code**. Open `Heard App.html` in any browser to explore all surfaces interactively. The job in Claude Code is to **recreate these designs natively in the target macOS codebase** (AppKit, SwiftUI, or hybrid) using its established patterns.

To open the reference: unzip, open `reference/Heard App.html` in Chrome or Safari.

## Fidelity
**High-fidelity.** Final colors, typography, spacing, component shapes, and interaction states are all specified. Recreate pixel-for-pixel using the tokens below.

---

## Design tokens

### Colors — "Paper" palette
```
bg:           #F5EFE4   window/pane background
surface:      #FBF7EF   cards, inputs
surfaceAlt:   #EFE7D7   row alternates, icon wells
sidebar:      #EBE2CE   left nav background
border:       #D9CFB9   primary border (0.5px)
borderSoft:   #E5DCC8   subtle dividers (0.5px)
ink:          #1C2024   primary text
ink2:         #3A3F47   secondary text
mute:         #7B7264   labels, captions
muteSoft:     #C9BBA5   placeholder, disabled track
shadow:       rgba(60,45,20,0.06)
shadowDeep:   rgba(60,45,20,0.18)

accent:       #3F5C8C   (default "Dusk"; see accent variants below)
accentInk:    #2F4570
accentSoft:   #E5EAF3

good:         #3D7A4F   green (granted/ready)
goodSoft:     #E1EEDF
warn:         #A66A1F   amber (limited/downloading)
warnSoft:     #F4E6CE
bad:          #A6452B   red (denied/recording)
badSoft:      #F2DCD2

recordingBg:  #2E3338   dark status strip when recording
recordingInk: #F5EFE4
```

**Accent color variants** (user-selectable):
| Name  | accent   | accentInk | accentSoft |
|-------|----------|-----------|------------|
| Dusk  | #3F5C8C  | #2F4570   | #E5EAF3   |
| Olive | #5C6F3E  | #46552F   | #E8ECDC   |
| Brick | #A6452B  | #7E3220   | #F2DCD2   |
| Ink   | #1C2024  | #000000   | #E0DDD4   |

### Typography
```
UI body:    -apple-system / SF Pro Text, system-ui, sans-serif
Display:    -apple-system / SF Pro Display, system-ui, sans-serif
Mono:       ui-monospace / SF Mono / Menlo, monospace
```
| Role             | Size  | Weight |
|------------------|-------|--------|
| Window title     | 13px  | 600    |
| Pane H1          | 19px  | 600    |
| Section label    | 10.5px| 700, uppercase, 0.7 letter-spacing |
| Body / row label | 12px  | 500    |
| Sub / caption    | 11px  | 400    |
| Mono values      | 11px  | 400    |
| Pill             | 10.5px| 600    |

### Radii
```
Window:    11px (+ overflow:hidden)
Card:      10px
Row icon well: 6–7px
Button:    6px
Toggle:    999px (pill)
Input:     6px
Pill:      999px
```

### Spacing
Pane padding: 14px vertical, 18px horizontal. Card internal padding: 12px (rows use 4px + per-row py:7px). Gap between cards/sections: 14px.

### Shadows
```
Window:  0 0 0 0.5px border, 0 24px 56px shadowDeep, 0 6px 16px shadow
Card:    0 0 0 0.5px border, 0 1px 2px shadow
Button:  0 1px 0 shadow (default variant only)
About/Naming windows: 0 0 0 0.5px border, 0 24px 56px shadowDeep
```

---

## Surfaces

### 1. Settings window
**Size:** 880 × 600px. Sidebar (188px) + content pane (flex 1).

**Window chrome:**
- Traffic lights (red #E76A5C, amber #E5A23E, green #5BB45C), 12px circles, 8px gap
- Title bar: 38px, gradient `#F0E7D5 → #E8DEC8`, 0.5px bottom border
- Sidebar bg: `#EBE2CE`, 0.5px right border

**Sidebar nav items:**
- 12.5px SF Pro Text, 500 weight unselected / 600 selected
- Selected: `surface` bg, 0.5px border + 1px shadow, accent-colored icon
- Logo mark: 26px HeardMark (bubble icon, see icon section), version `#7B7264` mono 10px

**Tabs:** General · Dictation · Models · Speakers

#### Tab: General
Sections (top to bottom):
1. **Behavior** — Card with 3 toggle rows: Launch at login, Auto-watch on launch, Developer mode
2. **Permissions** — Card with 4 rows (Mic, Screen Recording, System Audio, Accessibility). Each row has a 28×28 icon well (7px radius), name + why, required/detail pills, status pill (Granted/Limited/Not granted), optional Grant button.
3. **Custom vocabulary** — Card with text input + Add button, chip list (deletable pills). Shows count/50.
4. **Output folder** — Card with path display + Choose / Reset / Open buttons.

#### Tab: Dictation
1. **Enable card** (accent-tinted) — toggle + description
2. **Hotkey** — Shows ⌃⇧D key chips; push-to-talk toggle; Record… button
3. **Model keep-alive** — slider 0–600s, "Stay loaded for X" label, memory note, Unload now button
4. **Info card** — 0.6s polling loop explanation

#### Tab: Models
1. **Hero card** — dark ink gradient bg (`#2E3338 → #1C2024`), shows `N of 4 models ready`, disk usage, RAM, Download missing / Unload all buttons
2. **Transcription model** — radio cards: Parakeet TDT V2 (selected) vs V3 (beta)
3. **Models on disk** — list rows with icon, name, role, size, state (Ready pill / download progress bar / Not downloaded pill)
4. **Pipeline keep-alive** — same slider pattern as Dictation

#### Tab: Speakers
Full-height split layout. Top: sticky header with optional "new speakers detected" accent card, search input, sort segmented control, column headers. Scrollable list below. Each row: play button (26×26), name (+ You/Unnamed pill), meeting count, first seen, last seen.

---

### 2. Menu bar dropdown
**Width:** 268px. Floating panel, 10px radius, deep shadow.

**States:**

| State      | Header bg         | Dot color | Title           |
|------------|-------------------|-----------|-----------------|
| idle       | `surfaceAlt`      | good      | Watching        |
| recording  | `recordingBg`     | bad       | Recording       |
| processing | `surfaceAlt`      | warn      | Processing      |
| dictating  | `recordingBg`     | bad       | Dictating       |
| paused     | `surfaceAlt`      | warn      | Paused          |

Status dot: 7×7px circle. Pulsing states (recording, processing, dictating): ring shadow `color + 33` at 3px.

Recording state shows elapsed timer (mono, tabular-nums) in the header trailing edge.
Processing state shows a thin progress bar (3px, warn color) below the sub-label.

**Menu items:** icon (12px, `ink2`) + label + optional kbd hint or badge pill. Danger items use `bad` color. 5px padding, 5px radius hover.

Dividers at: after state section, before Settings/Quit.

---

### 3. First-run onboarding
**Size:** 620 × 480px.

Header (paper gradient bg): 56px HeardMark, title "Heard works in the background.", description, no close button.
Body: 4 permission step cards stacked. Each card: icon well (granted=goodSoft/active=accentSoft/pending=surfaceAlt), title, description, status pill. Active step has accent border + accentSoft bg.
Footer: step indicator "Step N of 4", Skip / Grant… buttons.

Permission sequence: Microphone → Screen Recording → System Audio → Accessibility.

---

### 4. Speaker naming window
**Size:** 560 × 520px.

Header: 44×44 icon well (people icon), "New Speakers Detected" title, description, amber "Auto-saving in Xm Xs" countdown.
Body (scrollable): One card per candidate. Each card: play/stop button (38×38, 8px radius — bad bg when playing), Speaker N label + maybe-pill, name input, Save button.
Footer: Skip all (ghost) + Save & Close (primary).

---

### 5. About sheet
**Size:** 380px wide, centered overlay.

Dimming backdrop: `rgba(28,32,36,0.32)`.
Sheet: paper gradient header, 72px HeardMark centered, app name 22px/600, version mono 11.5px, description, 3 pills (On-device/No cloud/No LLM), model credits footer, Acknowledgements + Done buttons.

---

### 6. Empty / error states
Centered in window, 56×56 icon well (14px radius).

| Kind            | Icon  | Well color   | CTA                    |
|-----------------|-------|--------------|------------------------|
| No speakers     | people| surfaceAlt   | Open transcripts       |
| Microphone denied | mic | badSoft      | Open System Settings…  |
| Model failed    | warn  | badSoft      | Retry download         |

---

## Interactions & behavior

### Toggle
- Width 30px, height 18px, pill shape
- Track: accent (on) / muteSoft (off)
- Thumb: white 14×14 circle, shadow, translateX 12px transition 140ms

### Button variants
| Kind    | Bg         | Border       | Text     |
|---------|------------|--------------|----------|
| default | surface    | border       | ink      |
| primary | accent     | accentInk    | white    |
| ghost   | transparent| transparent  | ink2     |
| danger  | surface    | border       | bad      |
| dark    | ink        | ink          | bg       |

Sizes: `sm` = 11px / 3px 8px padding; `md` = 12px / 5px 10px padding. Border-radius 6px.

### Input
6px radius, 0.5px border, inner shadow `inset 0 1px 1px shadow`. Focus: no additional spec needed beyond OS default.

### Segmented control
Inner padding 2px, 7px radius container. Selected segment: surface bg, 0.5px border, 1px shadow.

### Pill
10.5px / 600 weight. Optional leading dot (6px circle matching tone color) or icon.

### Status dot with pulse
`box-shadow: 0 0 0 3px <color>33` on pulsing states.

---

## App icon (HeardMark)
Used at 26px in sidebar header and 56/72px in About/Onboarding.

Squircle (rx=14 for 64px canvas):
- Background gradient: `#E8DFD2 → #C9BBA5` (vertical)
- Bubble shape: `#2E3338 → #1C2024` (vertical), same geometry as app icon
- Dots: cx 24/32/40, cy 29; r 2.4/3.2/2.4; fill `#E8DFD2`; outer dots 65% opacity

Full app icon and menu bar template SVGs are in `../design_handoff_app_icons/assets/`.

---

## State management (suggested)
```swift
enum HeardState { case idle, recording, processing, dictating, paused }
struct Speaker { var id, name, meetings, firstSeen, lastSeen, isYou, unnamed }
struct AppPrefs {
  var launchAtLogin, autoWatch, devMode: Bool
  var vocab: [String]
  var dictEnabled, pushToTalk: Bool
  var keepAliveSecs: Int    // dictation model
  var pipelineKeepAliveSecs: Int
  var accentVariant: String
}
```

---

## Files in this package
```
design_handoff_app_surfaces/
├── README.md                      ← you are here
└── reference/
    ├── Heard App.html             ← open in browser; interactive design reference
    ├── heard-tokens.jsx           ← all color/font tokens + Icon component
    ├── heard-ui.jsx               ← HeardWindow, Card, Row, Toggle, Btn, Input, Pill, ...
    ├── heard-panes.jsx            ← PaneGeneral, PaneDictation, PaneModels, PaneSpeakers
    ├── heard-shell.jsx            ← Settings, MenuBarDropdown, SpeakerNamingWindow, Onboarding, AboutSheet, EmptyState
    ├── heard-app.jsx              ← top-level canvas layout
    ├── design-canvas.jsx          ← pan/zoom canvas shell (not app code)
    └── tweaks-panel.jsx           ← tweaks panel shell (not app code)
```

## Implementation checklist
- [ ] Implement `HeardMark` icon in asset catalog (see `../design_handoff_app_icons/`)
- [ ] Implement Settings window with sidebar nav (4 tabs)
- [ ] General tab: behavior toggles, permissions list, vocab chips, output folder picker
- [ ] Dictation tab: enable toggle, hotkey recorder, keep-alive slider
- [ ] Models tab: hero status card, model radio, model list with download progress
- [ ] Speakers tab: new-speakers banner, search/sort, scrollable speaker table
- [ ] Menu bar status item + dropdown (5 states, pulse animation on active dot)
- [ ] First-run onboarding (4-step permission flow)
- [ ] Speaker naming window (voice preview + name input)
- [ ] About sheet (modal, paper gradient header)
- [ ] Empty/error states for all three scenarios
- [ ] Accent color preference (4 variants) stored in UserDefaults
