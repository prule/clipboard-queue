## 1. Move the storage path

- [x] 1.1 In the `Persistence` enum in `ClipboardQueue/Sources/ClipboardQueue/AppStore.swift`, repoint the `url` accessor at `FileManager.default.homeDirectoryForCurrentUser` + `.clipboardqueue` + `lists.json`, keeping the existing `createDirectory(withIntermediateDirectories: true)` side effect so saving still works when the directory is absent.
- [x] 1.2 Confirm no reference to `applicationSupportDirectory` or the old path remains anywhere in `ClipboardQueue/Sources/` — the app must not read, write or create that directory.

## 2. Update the docs that name the old path

- [x] 2.1 Update `ClipboardQueue/README.md:50` (the persistence note) and `:53` (the reset instructions, which say to delete `lists.json`) to name `~/.clipboardqueue/lists.json`.
- [x] 2.2 Add a short note to the README, next to the reset instructions, giving the one-time hand-copy for anyone carrying data forward from an earlier build: quit the app, then `mkdir -p ~/.clipboardqueue && cp "$HOME/Library/Application Support/ClipboardQueue/lists.json" ~/.clipboardqueue/lists.json`.
- [x] 2.3 Update the `Conventions` block in `openspec/config.yaml` where it states lists persist to `~/Library/Application Support/ClipboardQueue/lists.json`, so future changes get accurate project context.

## 3. Verify against the spec by hand

- [x] 3.1 Fresh-start case: quit the app, remove `~/.clipboardqueue`, then `./ClipboardQueue/build.sh && open "ClipboardQueue/build/Clipboard Queue.app"`. Confirm the starter list seeds, `~/.clipboardqueue/lists.json` is created, and an edit to a list is written back to that file. Confirm `~/Library/Application Support/ClipboardQueue/` is not created or modified.
- [x] 3.2 Hand-copied file case: quit, run the README's copy command (or drop a file with recognisable content at the new path), relaunch, and confirm the lists, their names and item order appear unchanged in both the main window and the menu-bar popover.
- [x] 3.3 Reload case: quit and relaunch with the file already in place, confirming edits made in the previous session persisted.
- [x] 3.4 Queue-behaviour regression pass: walk the queue with the hot keys to confirm advancing, the end-of-list park and the outside-copy park all still behave, and check that a list with no items shows the empty state without advancing.
