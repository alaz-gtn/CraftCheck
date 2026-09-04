# Changelog

## v1.3.1

- Value info now also appears for recipes you have not learned while the profession window is open (with a "Not learned" note), so you can judge whether a recipe is worth learning. Outside the profession window it still shows only for learned recipes.
- Fix: the tooltip of a recipe's result item in the profession window showed neither the crafter list nor the Value section (that tooltip carries no item id; it is now resolved from the recipe).
- Consumables without quality tiers (for example PvP flasks) are priced by item id instead of by item level.

## v1.3.0

- Value for consumables with quality tiers (potions, phials, flasks) and enchants: the tooltip shows the Auction House price of the gold-quality version, the reagent cost with silver reagents (craft gold with Concentration) and with gold reagents, and the profit with each, all per unit. Works when hovering any quality of the item, including in the Auction House.
- Profession side panel: consumables and enchants join the Top ranking at gold quality. For them, Cost is the silver-reagent cost (silver icon), AH is the gold sale price (gold icon) and Profit is gold sale minus silver cost. Hover a row for the gold-reagent numbers.
- Panel layout: item level box and result count removed (`/cv ilvl N` sets the gear item level), separator between the order counters and the list, scrollbar only when needed, one row per recipe name.
- Quality icons use Midnight's new icon set, taken from the item itself.

## v1.2.1

- Value panel and its button are shown only on the Recipes tab of the profession window; they hide on Specializations and Crafting Orders and come back when you return.
- Value info on item tooltips appears only for recipes the current character has learned.
- Bind-on-pickup crafted items (crafting-order gear) no longer show an Auction House price or profit; they show difficulty and reagent cost plus a note that they cannot be sold.
- Value panel redesigned for readability: solid dark background, larger fonts and rows, wider columns, mouse-wheel scrolling.
- New "Realm group total" line: fulfilled orders and gold across all your characters on the current connected-realm group.

## v1.2.0

- Crafting order earnings counter per character (personal, public, guild, NPC orders and gold from tips). Shown in the Value side panel, in the character list of the /cc panel and with `/cc orders` (`/cc orders reset` clears the current character).
- New Value module (merged from the CraftValue addon): tooltips of patterns, recipes and craftable items show recipe difficulty, reagent cost at max quality, Auction House price of the crafted item at your target item level and the profit after the 5% cut.
- "CraftCheck" button in the profession window opens a side panel ranking your known recipes by profit, with an item level field. Rows open the recipe.
- `/cv` commands: `top [n]`, `span N`, `ilvl`, `debug`, `probe`, and own Auction House scanning (`full`, `all`, `scan`, `reset`) when Auctionator is not installed. Auctionator is optional and preferred as price source.
- Value data lives inside CraftCheckDB (no separate saved variable).

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
