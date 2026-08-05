# queue-advance

## ADDED Requirements

### Requirement: The queue owns the clipboard while running

The app SHALL place the current item of the active list on the system clipboard whenever the cursor moves, the active list changes, or the queue resumes. The app SHALL NOT write to the clipboard while parked.

#### Scenario: Cursor moves

- **WHEN** the cursor moves to a new item by any means (next, back, reset, row click, list switch)
- **THEN** the text of that item is on the system clipboard
- **AND** an ordinary paste in any other application inserts that text

#### Scenario: Parked queue leaves the clipboard alone

- **WHEN** the queue is parked
- **THEN** the app performs no clipboard writes
- **AND** whatever the user last copied remains on the clipboard

### Requirement: The user advances the queue explicitly

The app SHALL advance the queue only in response to an explicit user action: the primary button, the `Skip` / `Back` controls, the popover `→` / `←` controls, a row click, the `Queue` menu items, or the global hot keys `⌃⌥→` and `⌃⌥←`. The app SHALL NOT observe, intercept, or infer paste events.

#### Scenario: Paste alone does not advance

- **WHEN** the user pastes the current item into another application and takes no further action
- **THEN** the cursor stays where it is
- **AND** the same item remains on the clipboard, so pasting again inserts the same text

#### Scenario: Hot key advances without any permission prompt

- **WHEN** the user presses `⌃⌥→` while any application is frontmost
- **THEN** the queue advances one item and the new item is on the clipboard
- **AND** the app has requested no Accessibility or Input Monitoring permission

#### Scenario: Advancing from a parked queue resumes it

- **WHEN** the queue is parked and the user triggers any advance action
- **THEN** the queue resumes and writes the current item to the clipboard

### Requirement: An outside copy parks the queue

When the clipboard changes to content the app did not write, the app SHALL park the queue, retaining the cursor position.

#### Scenario: User copies their own text

- **WHEN** the user copies text in another application
- **THEN** the queue parks
- **AND** the cursor is unchanged, so resuming continues from the same item

#### Scenario: Capture on copy

- **WHEN** `Capture on copy` is enabled and the user copies text in another application
- **THEN** that text is appended to the active list as a new item
- **AND** the queue still parks

### Requirement: End of list behaviour

At the last item, the app SHALL either stop or loop to the first item, according to the end-of-list setting.

#### Scenario: Stop at the end

- **WHEN** the setting is `Stop` and the user advances past the last item
- **THEN** the cursor stays on the last item and the queue parks

#### Scenario: Loop at the end

- **WHEN** the setting is `Loop` and the user advances past the last item
- **THEN** the cursor returns to the first item and that item is on the clipboard

### Requirement: Empty lists are inert

The app SHALL tolerate a list with no items without crashing or writing to the clipboard.

#### Scenario: Advancing an empty list

- **WHEN** the active list has no items and the user triggers any advance action
- **THEN** nothing is written to the clipboard and the app remains responsive
