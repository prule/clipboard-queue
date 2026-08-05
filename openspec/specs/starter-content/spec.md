# starter-content Specification

## Purpose
TBD - created by archiving change replace-seed-data-with-quotes. Update Purpose after archive.
## Requirements
### Requirement: A first launch creates exactly one starter list

When no save file exists, the app SHALL create a single list named `Sample quotes` containing 8 items, select it, and place its first item on the clipboard. The app SHALL persist that list immediately, so a first launch and a second launch present the same state.

#### Scenario: First launch with no save file

- **WHEN** the app starts and `~/Library/Application Support/ClipboardQueue/lists.json` does not exist
- **THEN** the sidebar shows exactly one list, `Sample quotes`, with 8 items
- **AND** the cursor is on item 01 and that item's text is on the system clipboard

#### Scenario: Relaunch after first launch

- **WHEN** the app is quit and reopened after a first launch
- **THEN** the same single list is present with the cursor where the user left it
- **AND** no additional seed lists are created

### Requirement: Seeded content never resembles personal or financial data

No item created by the app's seed SHALL resemble an email address, phone number, postal address, personal name, account or signup identifier, or payment card number. Seeded items SHALL be quotation text only, carrying no attribution.

#### Scenario: Inspecting the starter list

- **WHEN** a user, screenshot or bug report shows the seeded list
- **THEN** every item is a short quotation
- **AND** no item contains an `@`, a digit sequence resembling a card or phone number, or a person's name

#### Scenario: First paste is harmless

- **WHEN** a brand-new user pastes immediately after first launch, before reading anything
- **THEN** the pasted text is a quotation, not something that could be mistaken for real personal or financial data

### Requirement: Existing user data is never replaced by seeding

The app SHALL seed only when no save file exists. An existing `lists.json` SHALL be loaded as-is and never overwritten, merged with, or migrated to the current seed.

#### Scenario: Upgrading over an older install

- **WHEN** a user who has previously run the app installs a build with different seed content
- **THEN** their existing lists, items and cursor positions are preserved exactly
- **AND** no starter list is added

#### Scenario: Deliberate reset

- **WHEN** the user deletes `lists.json` and relaunches
- **THEN** the app seeds fresh, as on a first launch

### Requirement: The starter list is a working queue

The starter list SHALL be usable as a queue without editing: enough items to demonstrate advancing, short enough to read in the single-line item rows.

#### Scenario: Advancing through the starter list

- **WHEN** the user advances repeatedly from item 01
- **THEN** each item in turn reaches the clipboard, and the end-of-list behaviour applies at item 08

#### Scenario: Items fit the row

- **WHEN** the starter list is displayed at the default window width
- **THEN** each item's text fits its row without truncation

