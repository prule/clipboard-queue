# Design — drop paste interception and re-word the UI

## Context

The app was built from a Claude Design handoff whose premise is automatic ⌘V interception. That premise was never implemented: `AppStore` owns the clipboard and the user advances the cursor by hand, while the UI keeps the design's original wording (`Simulate ⌘V`, `Watching for ⌘V system-wide`, a counter captioned `pasted`). The decision now is that interception is not coming, so the wording is a defect rather than a placeholder.

Current state of the relevant code:

- `AppStore.primaryButtonLabel` is the single source of the primary control's text; both `MainWindowView` and `MenuBarView` read it, so one edit covers both surfaces.
- `AppStore.endBehaviourNote` already demonstrates the pattern for a derived, state-dependent string on the store.
- The main-window status bar is a hard-coded `HStack` of two `Text` views in `MainPaneView.statusBar`.
- `App.swift` builds the `Queue` menu with literal titles.

## Goals / Non-Goals

**Goals:**

- Every string the user can read matches what the app actually does.
- The `⌃⌥→` hot key, now the primary way to advance, is discoverable without opening Settings.
- Zero change to behaviour, geometry, persistence or permissions.

**Non-Goals:**

- Any form of `CGEventTap` / Accessibility-based paste detection.
- Restructuring the views, or introducing a localisation layer for these strings.
- Editing the handoff design files — they stay as the historical record of the original intent.

## Decisions

**Derived strings live on `AppStore`, not in views.**
`primaryButtonLabel` already sits there; the new status-line text becomes a sibling `statusNote` computed property returning `"Queue holds the clipboard"` or `"Parked — you copied something else"`. Alternative considered: computing the string inline in `MainPaneView`. Rejected — the popover and any future surface would each re-derive it, and the store is where every other piece of presented queue state is derived.

**The shortcut hint goes inside the primary button, as a trailing token.**
`Next item  ⌃⌥→` in one filled control, the hint at ~85% opacity so the control still reads as a single label. Alternatives considered: (a) a `.help()` tooltip only — invisible until hovered, which defeats the purpose for the one interaction the app now depends on; (b) a new line of helper text under the button row — adds vertical space and would push the item list, breaking the 640px layout. In the 330px popover the primary control is tight, so there the hint is a `.help()` tooltip on the `→` button instead of inline text.

**Label choice: `Next item`, not `Paste & advance` or `Copy next`.**
The button does exactly one thing — move the cursor forward, which puts the next item on the clipboard. `Paste` in any form would re-introduce the same false promise this change exists to remove.

**The status bar becomes state-dependent; the shortcut legend stays static.**
The legend is reference material and shouldn't flicker. The left side is the only place that reports whether the queue currently owns the clipboard, which is the fact users most need when a paste "doesn't work".

**Keep `Simulate ⌘V`'s `⌘]` key equivalent when renaming the menu item.**
Muscle memory and the hot-key registration are unaffected; only the title changes.

**Documentation records a departure, not a TODO.**
`README.md` currently lists interception under "Deliberate deviations" with language implying it is pending (`not wired`, "where a tap would feed in"). It becomes an explicit non-goal with a pointer to this change, so the next reader doesn't treat it as unfinished work.

## Risks / Trade-offs

- **A user who read the design expects automatic advancing and finds a manual button** → The status bar and the in-button hint now teach the actual loop on first look; Settings states it in a sentence.
- **`Parked — you copied something else` is wrong if the queue parked by hitting the end of a `Stop` list** → Derive the parked text from why it parked, or keep it neutral. Resolution: `statusNote` distinguishes the two, since `AppStore` knows whether the cursor is at the last item.
- **String changes silently diverge from the handoff design, and a later pixel-diff against `Clipboard Queue.dc.html` flags them as regressions** → The spec's "Layout is unchanged" requirement plus the README note make the departure explicit and reviewable.
- **Losing the word "paste" from the primary control makes the app's purpose less obvious to a first-time user** → The `On the clipboard now` heading and the `in queue` counter caption still frame the whole panel around the clipboard.

## Migration Plan

None needed: no persisted data, no settings keys and no shortcuts change. The change is fully reversible by reverting the commit; a rebuild via `./ClipboardQueue/build.sh` picks it up with no user-side migration.

## Open Questions

- Should the parked status line offer a click target to resume, rather than just reporting? Deferred — the primary button already reads `Resume` when parked.
