# Replace the seeded sample data with one short quotes list

## Why

A first launch currently creates five lists and 135 items of invented business data: personal names, email addresses, a phone number, a street address, signup codes, and eight payment card numbers. None of it is real, but all of it *reads* as real. That is a bad shape for a clipboard tool — the app writes whatever the cursor is on straight to the system clipboard, so a new user's first paste is a plausible-looking email address or card number landing in whatever window they happen to be in. It also makes screenshots, bug reports and demos awkward to share.

Nothing about the app needs data that looks like personal information. A single short list of quotes exercises exactly the same code paths.

## What Changes

Behaviour the user sees on a **fresh install**:

- The sidebar shows **one** list, `Sample quotes`, instead of five.
- That list holds **8 short quotations**, cursor starting at item 01 (today it starts mid-list at item 04 to mirror the design mock).
- No seeded item resembles an email address, phone number, postal address, personal name, account identifier or payment card number.

Removed outright: the `Demo — Q3 signups`, `Test card numbers`, `Support macros`, `Onboarding demo` and `Localisation strings` seed lists, and the `Seed.numbered(_:_:)` filler generator that produced the last two.

Existing installs are **not** touched — `lists.json` is the user's own data by the time it exists, and silently replacing it would destroy anything they had added. Anyone wanting the new starter content deletes `~/Library/Application Support/ClipboardQueue/lists.json` and relaunches; the README will say so.

Not breaking: no schema change, no behaviour change, no API change. Only the content created when no save file exists.

## Capabilities

### New Capabilities

- `starter-content`: what the app creates on a first launch, and the standing constraint that seeded content must never resemble personal or financial data.

### Modified Capabilities

None. `queue-advance` and `queue-status-display` are unaffected — this changes seed content, not queue mechanics or display copy.

## Impact

- Code: `Models.swift` only — the `Seed` enum shrinks to one array and one list. No view, store, persistence or settings code changes.
- `lists.json` schema: **unchanged**. Only the values written on first launch differ, and only when the file is absent.
- Permissions: unchanged.
- Design fidelity: a deliberate departure. The handoff mock (frame 1a) shows five named lists and a 20-item `Demo — Q3 signups` at item 04 of 20; screenshots taken after this change will not match that content. Layout, colour, type and spacing are untouched, and the sidebar's multi-list rendering is unchanged — it simply has one row to draw.
- Anyone who has already run the app keeps the old seed until they delete their save file.

## Non-goals

- Migrating or cleaning up existing `lists.json` files, automatically or on prompt.
- Adding a "restore sample data" or onboarding flow.
- Changing the empty-list experience, list creation, or the item editor.
- Shipping attributions with the quotes — see the design note; the items are quotation text only, which keeps every seeded string free of personal names.
