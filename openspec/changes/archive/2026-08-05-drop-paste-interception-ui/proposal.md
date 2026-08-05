# Drop paste interception and make the UI tell the truth

## Why

The handoff design is built on a promise the app does not keep: "Every ⌘V pastes the current item and loads the next one." System-wide ⌘V interception needs a `CGEventTap` and Accessibility permission, and we have decided not to build that. Meanwhile the shipped UI still says `Watching for ⌘V system-wide` and labels its primary button `Simulate ⌘V`, so the app advertises an automatic behaviour that never happens — the worst possible state, because a user pastes twice and gets the same text without understanding why.

This change keeps the app exactly as capable as it is today and re-words the interface around what it actually does: the queue owns the clipboard, and the user advances it explicitly with `⌃⌥→` or a button.

## What Changes

Behaviour the user sees:

- The primary button in the main window and the menu-bar popover reads **`Next item`** instead of `Simulate ⌘V`, and carries a `⌃⌥→` shortcut hint. Its parked state still reads `Resume`. Nothing about what the button *does* changes.
- The main-window status bar no longer claims `Watching for ⌘V system-wide`. It reports the real state of the queue: **`Queue holds the clipboard`** while running, **`Parked — you copied something else`** when parked. The right-hand shortcut legend is unchanged.
- The counter caption changes from `pasted` to **`in queue`**. The number was always a position (`4 of 20`), never a count of pastes.
- The `Queue` menu item `Simulate ⌘V` is renamed to `Next item`; its `⌘]` key equivalent is unchanged.
- Settings gains one line explaining the model in a sentence: the app puts each item on the clipboard, you paste it yourself, then advance.

Documentation:

- `ClipboardQueue/README.md` records that paste interception is dropped rather than pending, and that the UI copy intentionally departs from the design's ⌘V wording.

Not breaking: no behaviour, shortcut, persisted data or API changes — this is copy and one new derived string.

## Capabilities

### New Capabilities

- `queue-advance`: how items reach the system clipboard, how the user moves the cursor forward and back, and what happens when the user copies something of their own.
- `queue-status-display`: what the main window, menu-bar popover and status item tell the user about queue state, including the constraint that no surface may promise automatic paste interception.

### Modified Capabilities

None — `openspec/specs/` is empty; this is the first change in the project.

## Impact

- Code: `AppStore.swift` (button label, new status-line string), `MainWindowView.swift` (status bar, counter caption), `MenuBarView.swift` (shortcut hint), `App.swift` (menu item title), `Sheets.swift` (explanatory line). No change to the queue engine, pasteboard ownership, parking rule, hot keys or persistence.
- `lists.json` schema: unchanged.
- Permissions: unchanged, and that is the point — this change locks in an app that needs **no** Accessibility or Input Monitoring prompt. Re-introducing interception later would need its own proposal.
- Design fidelity: this is a deliberate, documented departure from the `Clipboard Queue.dc.html` copy in frames 1a and 1b. Layout, colour, type and spacing are untouched.

## Non-goals

- Implementing `CGEventTap`-based ⌘V interception, now or as a hidden/experimental flag.
- Changing how the queue advances, what the hot keys are, or how parking works.
- Re-drawing any part of the design — only text inside existing elements changes.
- Removing `HotKeys.swift` or the Carbon path; global shortcuts stay and become the primary way to advance.
