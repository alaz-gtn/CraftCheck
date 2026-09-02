# Changelog

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
