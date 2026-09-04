# <img src="https://raw.githubusercontent.com/alaz-gtn/CraftCheck/main/assets/CraftCheck_icon_40.png" width="40" align="absmiddle"> CraftCheck

**Your crafting assistant for alts: see instantly which of your characters can craft an item, whisper the requester in one click, know whether the craft is worth it, and track what your crafting orders earn.**

Do you have several crafters spread across realms? Someone links an item in Trade asking for a crafter, and you have to remember which alt learned that recipe, on which realm, and whether they have Concentration left. CraftCheck answers all of that in the item tooltip, and it also tells you whether a craft makes money before you spend the mats.

## Features

### Who can craft it
Hover or click any item link and the tooltip shows which of your characters can craft it: faction crest, class-colored name, realm, profession and remaining Concentration. Only characters on the same connected-realm group are listed, because that is where personal crafting orders work.

### One-click whisper
Click the item in chat, then click a character in the tooltip. CraftCheck opens a whisper to the player who linked the item with your message already typed, including the max-quality item link. Press Enter and you are done. Two customizable messages: one for when the crafter is another of your characters, one for when it is the character you are playing.

### Profession browser
A panel (minimap button or `/cc`) lists every character grouped by realm group, with their professions and recipes. Filter to epic gear only, search by item name, click an item to paste your message into the whisper you have open (for people who ask without linking), or Shift-click to link the item.

### Concentration tracking
Exact for the logged-in character, estimated with regeneration for your alts, so you know who can actually take the order.

### Crafting value (profit vs Auction House)
Hover any pattern, recipe or craftable item and see the recipe difficulty, the reagent cost and the Auction House price of the crafted item, with the profit after the 5% cut.

- **Gear**: price at your target item level (default 232, `/cv ilvl N`), reagent cost at max quality.
- **Potions, phials, flasks and enchants**: sale price of the gold-quality version, reagent cost with silver reagents (craft it gold with Concentration) and with gold reagents, and the profit with each. Everything per unit. Works when hovering any quality of the item, including in the Auction House.
- Bind-on-pickup crafted gear (crafting-order items) shows difficulty and reagent cost only, since it cannot be sold.

In the profession window, a **CraftCheck** button (Recipes tab) opens a side panel that ranks your known recipes by profit: gear at your target item level and consumables at gold quality, with silver-reagent cost, gold sale price and the resulting profit. Hover a row for the gold-reagent numbers; click it to open the recipe.

Prices come from Auctionator's Full Scan if you have it (recommended). Without Auctionator, CraftCheck can scan the Auction House itself.

### Crafting order earnings
Every fulfilled crafting order is counted per character: personal, public, guild and NPC orders and the gold earned in tips. Shown in the profession side panel (with a total for the whole realm group), in the character list and with `/cc orders`.

### Localized
English and Spanish.

## How it works

Open each profession once on each character (and each expansion tab). CraftCheck records the learned recipes account-wide. Everything else is automatic.

## Commands

- `/cc` – toggle the profession panel
- `/cc tooltip` – enable or disable tooltip info
- `/cc minimap` – show or hide the minimap button
- `/cc list` – list saved characters and recipe counts
- `/cc delete Name-Realm` – remove a character
- `/cc scan` – force a rescan of the open profession
- `/cc message <text>` – whisper message (`{character}` = crafter Name-Realm, `{item}` = item link; Spanish `{personaje}` / `{objeto}` also work)
- `/cc selfmessage <text>` – message used when the crafter is the character you are playing
- `/cc orders` – tips earned from crafting orders per character (`/cc orders reset` clears the current character)
- `/cv top [n]` – rank your known recipes by profit in chat (profession window open)
- `/cv ilvl N` – target item level for gear prices (default 232)
- `/cv span N` – how far below the target ilvl a recipe's base item may be to count (default 30)
- `/cv full` / `/cv all` / `/cv scan` / `/cv reset` – own Auction House scanning (only without Auctionator)

## Support

CraftCheck is free and always will be. If it saves you time, you can [buy me a coffee](https://ko-fi.com/gotenzlive).

## Feedback

Bug reports and suggestions are welcome on the [Issues](https://github.com/alaz-gtn/CraftCheck/issues) page or in the CurseForge comments.

## License

MIT
