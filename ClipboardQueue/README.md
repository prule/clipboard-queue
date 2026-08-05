# Clipboard Queue (macOS)

Native SwiftUI implementation of the `clipboard-queue-app` Claude Design handoff
(`Clipboard Queue.dc.html`, frames 1a and 1b).

## Build & run

```bash
./build.sh            # release; use ./build.sh debug for a debug build
open "build/Clipboard Queue.app"
```

No Xcode required — the script builds with SwiftPM and assembles the `.app`
bundle around the executable, then ad-hoc signs it.

## What's implemented

**Main window (design 1a)** — fixed 1000×640, light appearance.
- 236px sidebar: `LISTS` header, list rows (accent-filled when live, white dot,
  name + meta), `+ New list` and `⌥ Settings` footer actions. The design draws
  its own traffic lights in the 52px header, so the native window buttons are
  hidden and the drawn ones are wired to close/minimise/zoom.
- Pane header: list name, item count, `Edit items`, `Capture on copy`.
- "On the clipboard now" panel: pulsing accent dot (1 → .35 over 1.8s), current
  item in monospace, `Next up ·`, the `n of N` counter, progress bar, and the
  `Simulate ⌘V` / `Back` / `Skip` / `Reset` controls with the end-behaviour note.
- Item list: zero-padded numbers, per-state colours, accent-tinted current row
  with a 3px inset accent bar, `ON CLIPBOARD` / `PASTED` tags. Clicking a row
  jumps the queue to it. Auto-scrolls to keep the current item visible.
- Status bar: `Watching for ⌘V system-wide` · `⌃⌥→ skip · ⌃⌥← back`.

**Menu-bar popover (design 1b)** — 330px, opened from a status item that shows
`▤ 4/20` in the accent colour (grey when parked). List name, counter, progress,
clipboard card with current + next, primary/←/→ controls, and the
`Switch list… ▸` / `Open main window ⌃⌥C` / `Quit ⌘Q` rows. `Switch list…`
swaps the popover body for a list picker.

**Real behaviour**
- Every cursor move writes the current item to `NSPasteboard.general`.
- A pasteboard change the app didn't make = the user copied something of their
  own, so the queue **parks** (keeps its place, primary button becomes
  `Resume`) rather than fighting for the clipboard — the design's "copying
  something outside the app parks the queue" note.
- `Capture on copy` appends externally copied text to the active list.
- Global hot keys via the Carbon API (no Accessibility permission needed):
  `⌃⌥→` skip, `⌃⌥←` back, `⌃⌥C` open the main window. In-app menu equivalents:
  `⌘]`, `⌘[`, `⌘R`, `⌘0`.
- Lists persist to `~/Library/Application Support/ClipboardQueue/lists.json`,
  seeded on first launch with the design's demo data (cursor at item 04, as in
  the mock) plus the four other named lists at their designed item counts.
- The design's three props are real settings (⌘, or the sidebar's Settings):
  accent (the four specified swatches), end-of-list stop/loop, row density
  comfortable/compact.

## Deliberate deviations

- **⌘V interception is not wired.** As agreed, the app owns the clipboard and
  advances on the in-app button and the global hot keys; intercepting every
  system-wide `⌘V` needs a `CGEventTap` plus Accessibility permission. The
  status-bar copy still reads as the design specifies. `ClipboardMonitor`-side
  hooks live in `AppStore.pollPasteboard()`, which is where a tap would feed in.
- **Inconsolata** is used when installed, otherwise SF Mono (`Theme.mono`). The
  design loads it from Google Fonts; the app ships no font file.
- `Edit items` opens a one-item-per-line editor and `New list` creates a list —
  affordances the mock shows but doesn't specify behaviour for.

## Layout

```
Sources/ClipboardQueue/
  App.swift            @main + AppDelegate: window, status item, popover, hot keys, menus
  AppStore.swift       lists, cursor, pasteboard ownership, parking, persistence
  Models.swift         ClipList / QueueItem / Accent / Density + seed data
  Theme.swift          every colour and font from the design, one place
  Components.swift     button styles, pulse dot, progress bar, traffic lights
  MainWindowView.swift design 1a
  MenuBarView.swift    design 1b
  Sheets.swift         settings + item editor
  HotKeys.swift        Carbon hot-key registration
```
