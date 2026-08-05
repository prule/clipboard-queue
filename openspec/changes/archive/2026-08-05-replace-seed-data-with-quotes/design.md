# Design — replace the seeded sample data with one short quotes list

## Context

`Seed` in `Models.swift` is the only producer of starter content. `AppStore.init()` calls `Seed.lists()` exactly once — when `Persistence.loadLists()` returns nil — then saves the result, so seed content reaches the user only on a genuine first launch.

Today `Seed` carries four literal arrays and a filler generator: `demo` (20 items of invented signups — names, emails, a phone number, a street address, `SIGNUP-nnnn-QX` codes), `testCards` (8 payment card numbers), `supportMacros` (14 canned replies), and `numbered(_:_:)` used to inflate two more lists to 31 and 62 items. The `demo` list is seeded with `cursor: 3` so a first launch reproduces the design mock's "4 of 20" state.

The problem is not that this data is fake; it is that it reads as real, in an app whose whole job is to push the current item onto the system clipboard.

## Goals / Non-Goals

**Goals:**

- A first launch that is safe to paste from, screenshot, and share.
- Starter content that still exercises the queue end to end: multiple items, advancing, end-of-list.
- Less code in `Seed` than before, with no dead helpers left behind.

**Non-Goals:**

- Touching an existing `lists.json`, by migration, prompt or fingerprint-and-replace.
- Any view, store or persistence change — this is data, not behaviour.
- Preserving the mock's list names or item counts.

## Decisions

**One list, not a trimmed set of several.**
The sidebar renders a list of rows; one row exercises the same code path as five, and the design's five-list sidebar was always illustrative rather than functional (four of the five existed only to fill the panel). Alternative considered: keep two or three lists so `Switch list…` has something to switch between. Rejected — inventing content purely to demonstrate a menu is how the current problem started; `New list` is one click away.

**Quotation text only, no attributions.**
The requirement is that nothing in the seed looks like personal data, and an attribution line is a person's name. Dropping attributions removes the whole category rather than relying on "well, that one's a historical figure". It also avoids asserting provenance for lines that are widely paraphrased. Alternative considered: `"quote" — Author`. Rejected on both counts.

Proposed content (8 items, each ≤ 51 characters so they fit the single-line rows without truncation):

```
Well begun is half done.
The obstacle is the way.
Fall seven times, stand up eight.
Simplicity is the ultimate sophistication.
What we do now echoes in eternity.
The best time to plant a tree was twenty years ago.
Begin where you are, with what you have.
Small steps, taken daily, compound.
```

**Cursor starts at item 01, not item 04.**
The mock's mid-list cursor exists so a static image can show a progress bar part-filled. On a real first launch it means the app claims you have already pasted three things. Starting at 01 is both honest and the state a user would reset to.

**Existing save files are left alone, with a documented reset path.**
By the time `lists.json` exists it is the user's data, and the seed lists are indistinguishable from lists they may have renamed or edited. Alternatives considered: (a) fingerprint the old seed and replace it only if untouched — needs the old content kept in the binary forever and still guesses wrong after a single edit; (b) prompt on upgrade — a modal about sample data is worse than the sample data. The README gains the one-line reset instruction instead.

**Delete `Seed.numbered(_:_:)` rather than keeping it for future use.**
It exists only to inflate lists to a count; with nothing calling it, keeping it invites someone to generate filler again.

## Risks / Trade-offs

- **Screenshots, the README and the handoff design no longer agree on what the app contains** → The README's feature list is updated in the same change and the departure is recorded in the proposal; the design bundle stays untouched as the historical record.
- **A developer testing this sees no change, because their `lists.json` already exists** → Verification explicitly starts by deleting the save file; this is the single most likely way to "verify" the change and see nothing.
- **Eight short items make the list panel look sparse where the mock showed twenty** → Acceptable: the panel scrolls and the empty area is the same white as the rows. The alternative is padding the list with filler, which is what we are removing.
- **Losing `Test card numbers` removes a genuinely useful list for anyone testing payment flows** → It is one paste into `Edit items` to recreate, and it is the user's own data at that point rather than something the app ships.

## Migration Plan

None. No schema change, and existing installs are untouched by design. Reverting is a straight revert of the commit; users who already seeded are unaffected either way.

## Open Questions

- None blocking. If attributions turn out to be wanted for flavour, they can be added later as a content-only change against the `starter-content` spec.
