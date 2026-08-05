## Context

Persistence today is the `Persistence` enum at the bottom of `ClipboardQueue/Sources/ClipboardQueue/AppStore.swift` (~line 265). It is three parts: a computed `url` that builds `~/Library/Application Support/ClipboardQueue/lists.json` and creates the directory as a side effect, `loadLists()` which returns `nil` on any failure, and `saveLists(_:)` which silently drops errors. `AppStore.init()` calls `loadLists()` once and falls back to `Seed.lists()` when it gets `nil`; every mutating intent calls `persistLists()`.

With migration ruled out (see the proposal's non-goals), the change is a single path swap. The design below is short by design — it exists to record why there is no migration machinery and what the existing failure semantics already cover, not to justify an architecture.

## Goals / Non-Goals

**Goals:**
- Lists read and write at `~/.clipboardqueue/lists.json`.
- No legacy-path code anywhere in the app.
- Failure degrades to today's behaviour (silent, non-destructive) rather than to data loss.
- Keep the change inside the `Persistence` enum; `AppStore`'s call sites do not change.

**Non-Goals:**
- Automatic migration, configurable path, settings migration, file-watching, UI to reveal the file, cleanup of the old directory. All covered in the proposal's non-goals.
- Error surfacing. Persistence is silent today and stays silent; adding user-facing error reporting is a separate change with its own UI decisions.

## Decisions

**No migration code at all — the old path is not referenced by the app.** The alternative considered was a lazy copy inside `loadLists()`: if the new file is absent and the old one is present, copy it across. That is maybe fifteen lines, but it also brings a copy-failure branch, a decision about copy-vs-move, a downgrade story, and a legacy constant that has to stay correct forever for a directory the app otherwise has nothing to do with. The app is pre-release with no outside users, so the entire benefit is saving one `cp` for the developer running it. Documenting the command in the README is the better trade. Consequence: existing installs see starter content on first launch after this ships, which the proposal calls out as breaking.

**Home directory via `FileManager.default.homeDirectoryForCurrentUser`, not `NSHomeDirectory()` or `~` expansion.** It returns a `URL` directly, which is what the rest of `Persistence` works in, and it is correct for a non-sandboxed app. The app is not sandboxed (no entitlements file, ad-hoc signed by `build.sh`), so this is the real home directory and not a container. *Alternative:* `NSString(string: "~/.clipboardqueue").expandingTildeInPath` — string-typed, needs conversion, no benefit.

**Directory creation stays a side effect of the `url` accessor, matching the current shape.** `url` already does `try? createDirectory(withIntermediateDirectories: true)` on every access. Keeping that means `loadLists` and `saveLists` need no change at all and the "directory does not exist yet" scenario is satisfied by existing code. It is mildly impure for a computed property, but it is the established local idiom and changing it is scope this change does not need.

**Files changed:** `AppStore.swift` — the two lines of `Persistence.url` that build the directory URL, and nothing else. `ClipboardQueue/README.md:50` (persistence note) and `:53` (reset instructions), which also gains the hand-copy command for anyone carrying data over. `openspec/config.yaml`'s conventions block, which names the old path and would otherwise mislead every future change. No new files, no dependency, no build-step change.

## Risks / Trade-offs

- **Existing installs silently start over with starter content.** → Accepted; this is the point of skipping migration. Mitigated by the README documenting the one-line `cp`, and by the old file remaining untouched on disk so nothing is actually lost.
- **Someone copies the file across while the app is running and loses the copy.** The next save overwrites it, since lists are read once at launch. → Pre-existing behaviour for any hand-edit of `lists.json`; the README's reset instructions already tell the user to quit first, and the copy instructions sit next to them.
- **Dotfile directories are hidden in Finder**, so a user who wants to open the file still needs ⇧⌘. or a shell. → Inherent to the requested location, and still an improvement over a path buried in `~/Library`, which Finder hides too *and* which is harder to type. No mitigation.
- **A home directory that is read-only or full means neither the directory nor the file can be created.** → Same failure mode as today at the old path: `try?` swallows it, the app runs on in-memory lists, and nothing on disk is truncated because `saveLists` never gets as far as a write. Covered by the "write fails" scenario.
- **The stale file at the old path is now orphaned**, and a user who later finds it may not realise it is dead. → It is inert and small. Removing it is the user's call; the change does not touch it.

## Migration Plan

None in the app. Deployment is shipping the commit; the first launch after it creates `~/.clipboardqueue/lists.json` from seeded content. Anyone carrying data forward quits the app and runs the `cp` from the README.

Verification is manual, since there is no test target: launch with no `~/.clipboardqueue` and confirm seeding plus file creation, then quit, drop an old-format file at the new path by hand, relaunch and confirm it loads unchanged.

Rollback is reverting the commit — the old build's file is still at the Application Support path, untouched, so it comes back exactly as it was.
