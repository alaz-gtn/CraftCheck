# Changelog

## v1.1.0

- New: a separate whisper message for when the crafter is the character you are playing (default: "I can craft it, send me the order for a tip :)"). Editable in the panel ("If it's me") or with `/cc selfmessage`.

## v1.0.9

- Debug output is throttled so it no longer floods the chat on reload.

## v1.0.8

- Fix: whisper detection had been failing silently since v1.0.4 because of a helper defined too late in the file (nil call error). Pasting from the panel into an open whisper now works.
- Also handles a whisper typed by hand (`/w Name` or `/cw Name` still in the chat box): the message is sent to that name.

## v1.0.7

- Fix: pasting from the panel scans every chat window (including temporary whisper windows) for a visible whisper box and pastes there, instead of grabbing the always-visible main chat box (which ended up in /say and closed the whisper).

## v1.0.6

- Whisper detection now uses Blizzard's official chat edit box callbacks, which cover every chat window including temporary whisper windows, and no longer hooks the edit box directly (avoids tainting chat sends).

## v1.0.5

- More robust detection of the whisper you have open (hooks the game's whisper-open function, reads the chat box header, and records whispers you send), so pasting from the panel lands in that whisper.
- `/cc debug` now dumps the chat box state when it gains focus, to diagnose whisper detection.

## v1.0.4

- Fix: pasting from the profession panel now goes to the whisper you have open. The addon remembers the whisper target while the chat box is in whisper mode and reopens that whisper before pasting (Battle.net whispers supported too).

## v1.0.3

- Fix: pasting the message from the profession panel went to /say instead of the whisper you had open. The addon now reactivates the last used chat box, keeping its whisper target.

## v1.0.2

- Fix: clicking a character in the item tooltip opened the whisper but left it empty. The message is now inserted into the focused chat box and re-checked shortly after.
- Added `/cc debug` to print diagnostics when reporting issues.

## v1.0.1

- Profession panel: click an item to paste the whisper message (crafter + item link) into the open chat, for people who ask without linking. Shift-click still links the item only.
- Message placeholders now accept English and Spanish names in any case: {character}/{personaje}, {item}/{objeto}.
- Placeholder help moved into a tooltip on the message box; panel layout compacted and hint line made readable.
- In-game icon switched to TGA so it renders correctly.

## v1.0.0

- Initial release.
- Tooltip shows which of your characters (same connected-realm group) can craft an item, with faction, class, profession and Concentration.
- One-click whisper from the item tooltip to the player who linked the item, with a customizable message and the max-quality item link.
- Profession browser panel grouped by realm group, with epic-gear filter and search.
- Concentration tracking (exact for the current character, estimated for alts).
- English and Spanish localization.
