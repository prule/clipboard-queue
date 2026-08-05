## Why

The saved lists live at `~/Library/Application Support/ClipboardQueue/lists.json`, a path that is awkward to reach from a shell, easy to miss when backing up, and effectively invisible in Finder. The list file is plain, hand-editable JSON that users will reasonably want to inspect, sync, version-control or point a backup tool at, so it belongs in a visible, conventional dot-directory under the home folder.

## What Changes

- Lists are read from and written to `~/.clipboardqueue/lists.json` instead of `~/Library/Application Support/ClipboardQueue/lists.json`. No other behaviour changes: the queue, cursor, parking and settings all work exactly as before.
- **BREAKING for existing installs.** There is no migration. On the first launch after this change the app finds nothing at the new path and seeds its starter list, exactly as on a fresh install. Anyone who wants their old lists back copies the file across by hand:
  ```
  mkdir -p ~/.clipboardqueue
  cp "~/Library/Application Support/ClipboardQueue/lists.json" ~/.clipboardqueue/lists.json
  ```
  The schema is unchanged, so a file copied this way loads as-is. The app is pre-release with no outside users, which is why an automatic copy isn't worth the code it would take.
- The old file is never read, written or deleted. It stays where it is until the user removes it.
- If the new directory cannot be created or written (permissions, read-only home), the app keeps running with whatever it loaded in memory and does not lose the on-disk copy — same silent-failure posture as today's persistence.
- The `lists.json` schema is **unchanged**. This is a location change only, so no schema migration is needed.
- No new permission prompt. `~/.clipboardqueue/` is inside the user's home directory and the app is not sandboxed, so no Accessibility, Input Monitoring or Full Disk Access dialog appears.

## Non-goals

- **No automatic migration from the old path.** Deliberate: the copy is a one-liner the user runs once, and the app carries no legacy-path code, no copy-failure branch and no "already migrated" state as a result.
- Not moving settings. Accent, end-behaviour and density stay in `UserDefaults`; only the list JSON moves.
- Not making the path configurable (no preference, no environment variable). One fixed location.
- Not changing the `lists.json` schema, format or JSON encoding options.
- Not adding UI to reveal, open or import the file. No "Show in Finder" button in this change.
- Not deleting or cleaning up the old Application Support directory.
- Not adding file-watching or reload-on-external-edit. Hand-editing the file while the app runs still gets overwritten by the next save, as today.

## Capabilities

### New Capabilities
- `list-storage-location`: where the app reads and writes the persisted lists file.

### Modified Capabilities

None. No existing spec (`queue-advance`, `queue-status-display`, `starter-content`) states where lists are stored, so their requirements are unaffected.

## Impact

- `ClipboardQueue/Sources/ClipboardQueue/AppStore.swift` — the `Persistence` enum's `url` computed property. One path, nothing else.
- `openspec/config.yaml` — the conventions block names the old path and must be updated to keep the project context truthful.
- `ClipboardQueue/README.md` — documents the storage path at line 50 and tells the user to delete `lists.json` to reset at line 53; both need the new path, and the hand-copy command belongs here too.
- No new dependencies, no build-step change, no `.xcodeproj` involvement. Verification is a build-and-run of the app.
- Existing installs: the app starts over with starter content until the user copies their file across.
