# queue-status-display

## ADDED Requirements

### Requirement: No surface promises paste interception

No text in the app SHALL state or imply that the app watches for, intercepts, or reacts to system-wide paste events.

#### Scenario: Status bar copy

- **WHEN** the main window (design 1a) is open
- **THEN** the status bar does not contain the phrase `Watching for ⌘V system-wide` or any equivalent claim

#### Scenario: Control labels

- **WHEN** any control that advances the queue is visible, in the window or the popover
- **THEN** its label describes moving to the next item, not simulating or intercepting a paste

### Requirement: The primary control reads as an advance action

The primary control in the main window and in the menu-bar popover SHALL read `Next item` while running and `Resume` while parked, and SHALL surface its `⌃⌥→` hot key.

#### Scenario: Running

- **WHEN** the queue is running
- **THEN** the primary control reads `Next item` and is filled with the accent colour

#### Scenario: Parked

- **WHEN** the queue is parked
- **THEN** the primary control reads `Resume` and is filled with the parked grey

#### Scenario: Hot key discoverability

- **WHEN** the user looks at the primary control or hovers it
- **THEN** the `⌃⌥→` shortcut is visible to them without opening Settings

### Requirement: The status bar reports live queue state

The main-window status bar SHALL describe the current relationship between the queue and the clipboard, and SHALL keep the shortcut legend on the right.

#### Scenario: Running

- **WHEN** the queue is running
- **THEN** the left of the status bar reads `Queue holds the clipboard`

#### Scenario: Parked

- **WHEN** the queue has parked because the user copied something else
- **THEN** the left of the status bar reads `Parked — you copied something else`

#### Scenario: Shortcut legend

- **WHEN** the main window is open in any state
- **THEN** the right of the status bar reads `⌃⌥→ skip · ⌃⌥← back`

### Requirement: The counter is labelled as a position

The large counter SHALL be captioned `in queue`, since it reports the cursor position (`n of N`) and not a number of pastes.

#### Scenario: Caption

- **WHEN** the cursor is on item 4 of a 20-item list
- **THEN** the counter reads `4 of 20` above the caption `in queue`

### Requirement: Settings explains the queue model

Settings SHALL state, in one sentence, that the app puts each item on the clipboard, the user pastes it, and the user then advances the queue.

#### Scenario: Opening settings

- **WHEN** the user opens Settings from the sidebar or `⌘,`
- **THEN** a short line describes the put-on-clipboard / paste / advance loop alongside the shortcut list

### Requirement: Layout is unchanged

This capability changes text only. All colours, type scales, spacing, sizes and control geometry SHALL continue to match the handoff design (frames 1a and 1b).

#### Scenario: Visual diff

- **WHEN** the rebuilt app is compared with the previous build
- **THEN** the only differences are the strings named in this specification
