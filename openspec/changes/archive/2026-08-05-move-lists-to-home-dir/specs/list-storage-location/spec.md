## ADDED Requirements

### Requirement: Lists persist under the home directory

The app SHALL read and write its persisted lists file at `~/.clipboardqueue/lists.json`. The app SHALL create the `~/.clipboardqueue` directory if it does not exist. The app SHALL NOT read from or write to `~/Library/Application Support/ClipboardQueue/`.

#### Scenario: Saving a list edit

- **WHEN** the user adds, edits, reorders or deletes an item, or creates, renames or deletes a list
- **THEN** the updated lists are written to `~/.clipboardqueue/lists.json`
- **AND** nothing is written to `~/Library/Application Support/ClipboardQueue/lists.json`

#### Scenario: Relaunching with saved lists

- **WHEN** the app launches and `~/.clipboardqueue/lists.json` exists
- **THEN** the lists, their names and their item order are restored from that file
- **AND** the queue starts parked at the first item of the active list, as it does on any launch

#### Scenario: Directory does not exist yet

- **WHEN** the app needs to save and `~/.clipboardqueue` does not exist
- **THEN** the app creates the directory and writes the file into it
- **AND** no directory is created under `~/Library/Application Support/`

#### Scenario: No file at the new location

- **WHEN** the app launches and `~/.clipboardqueue/lists.json` does not exist
- **THEN** the app seeds its starter list as it does on any first launch and saves it to that path
- **AND** this holds whether or not a file exists at the old Application Support path, which is never consulted

#### Scenario: File placed by hand

- **WHEN** the user copies a lists file saved by an earlier version to `~/.clipboardqueue/lists.json` and launches the app
- **THEN** the lists load from it unchanged, since the file schema is the same as before the move

#### Scenario: Write fails

- **WHEN** the lists file cannot be written (the directory cannot be created, or the path is not writable)
- **THEN** the app continues running with its in-memory lists and stays usable
- **AND** any previously saved file on disk is left intact rather than truncated

#### Scenario: Empty list loaded from disk

- **WHEN** the loaded file contains a list with no items and that list is active
- **THEN** the window and popover show the empty state for that list and the queue does not advance, exactly as for an empty list created in-app
