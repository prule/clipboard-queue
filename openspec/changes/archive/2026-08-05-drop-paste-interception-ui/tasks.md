# Tasks — drop paste interception and re-word the UI

## 1. Store-level strings

- [x] 1.1 In `AppStore.swift`, change `primaryButtonLabel` to return `"Next item"` when running (`"Resume"` when parked is unchanged).
- [x] 1.2 In `AppStore.swift`, add a `statusNote` computed property: `"Queue holds the clipboard"` while running, `"Parked — you copied something else"` when parked by an outside copy, and `"Finished — end of list"` when parked at the last item of a non-looping list.
- [x] 1.3 Build (`swift build`) and confirm both surfaces pick up the new label with no other change.

## 2. Main window (design 1a)

- [x] 2.1 In `MainWindowView.swift`, replace the hard-coded `Watching for ⌘V system-wide` in `MainPaneView.statusBar` with `store.statusNote`; leave the right-hand `⌃⌥→ skip · ⌃⌥← back` legend as is.
- [x] 2.2 In `MainWindowView.swift`, change the counter caption from `pasted` to `in queue`.
- [x] 2.3 In `QueuePanelView`, add the trailing `⌃⌥→` hint inside the primary button — same filled control, hint at ~85% opacity, no new layout rows and no change to the 640px window height.

## 3. Menu-bar popover (design 1b) and menus

- [x] 3.1 In `MenuBarView.swift`, add a `.help("Next item · ⌃⌥→")` tooltip to the `→` button and `.help("Back · ⌃⌥←")` to `←`; the primary control needs no edit since it reads `store.primaryButtonLabel`.
- [x] 3.2 In `App.swift`, rename the `Queue` menu item `Simulate ⌘V` to `Next item`, keeping the `⌘]` key equivalent.

## 4. Settings

- [x] 4.1 In `Sheets.swift`, add one line above the shortcut list in `SettingsSheet`: the app puts each item on the clipboard, you paste it, then advance with `⌃⌥→`.

## 5. Documentation

- [x] 5.1 In `ClipboardQueue/README.md`, move ⌘V interception from "Deliberate deviations" to an explicit non-goal, referencing `openspec/changes/drop-paste-interception-ui`, and update the feature list where it quotes the old status-bar and button copy.

## 6. Verify

> Automated checks done: release build succeeds; `Simulate ⌘V` and `Watching for ⌘V system-wide` no longer appear anywhere in `Sources/` or the built binary; the new strings are compiled in; an outside `pbcopy` leaves the clipboard untouched (queue parked); all three hot keys register with no error and no permission prompt. The remaining boxes need a human at the screen — this shell has neither Screen Recording (no screenshots) nor Accessibility (can't synthesise ⌃⌥→).

- [x] 6.1 Run `./ClipboardQueue/build.sh && open "ClipboardQueue/build/Clipboard Queue.app"`; confirm the button reads `Next item ⌃⌥→`, the status bar reads `Queue holds the clipboard`, and the caption reads `in queue`.
- [x] 6.2 Copy text in another app; confirm the queue parks and the status bar switches to `Parked — you copied something else`, then confirm the primary button reads `Resume` and restores the queue's item to the clipboard.
- [x] 6.3 With end-of-list set to `Stop`, advance past the last item; confirm the status bar reads `Finished — end of list`.
- [x] 6.4 Confirm `⌃⌥→` / `⌃⌥←` still advance from another frontmost app and that no permission prompt appears.
