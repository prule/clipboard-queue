# Tasks — replace the seeded sample data with one short quotes list

## 1. Replace the seed content

- [x] 1.1 In `Models.swift`, delete the `demo`, `testCards` and `supportMacros` arrays and the `numbered(_:_:)` helper from `Seed`.
- [x] 1.2 In `Models.swift`, add a single `quotes` array holding the 8 quotation strings from the design, and rewrite `Seed.lists()` to return one `ClipList(name: "Sample quotes", items: …)` with the default cursor of 0.
- [x] 1.3 Build (`swift build`) and confirm nothing else referenced the removed arrays or helper.

## 2. Documentation

- [x] 2.1 In `ClipboardQueue/README.md`, replace the description of the seeded demo data (five lists, "the design's demo data (cursor at item 04, as in the mock)") with the single quotes list, and add the reset instruction: delete `~/Library/Application Support/ClipboardQueue/lists.json` and relaunch to get fresh starter content.
- [x] 2.2 In `ClipboardQueue/README.md`, note under the deliberate deviations that the seeded content intentionally no longer matches the mock's `Demo — Q3 signups`, and why.

## 3. Verify

- [x] 3.1 Quit the app, move `~/Library/Application Support/ClipboardQueue/lists.json` aside (rename rather than delete, so the previous data can be restored), then run `./ClipboardQueue/build.sh && open "ClipboardQueue/build/Clipboard Queue.app"`.
- [x] 3.2 Confirm the sidebar shows exactly one list, `Sample quotes · 8 items`, the header reads `8 items`, the cursor is on item 01, and `pbpaste` returns the first quotation.
- [ ] 3.3 Advance through all 8 items; confirm each reaches the clipboard, no row truncates with an ellipsis, and the end-of-list status appears at item 08.
      _(Partly verified: longest item is 51 characters ≈ 400px in 13px mono against ~630px of row width, so truncation is not possible. Advancing needs a human — this shell has no Accessibility permission to synthesise ⌃⌥→.)_
- [x] 3.4 Confirm the regenerated `lists.json` contains no `@`, no card- or phone-shaped digit sequences, and no personal names.
- [x] 3.5 Restore the saved-aside `lists.json`, relaunch, and confirm the previous lists come back untouched — proving the seed never overwrites existing data.
