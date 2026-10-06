# <img src="https://raw.githubusercontent.com/alaz-gtn/CraftCheck/main/assets/CraftCheck_icon_40.png" width="40" align="absmiddle"> CraftCheck

**Which of your alts can craft it, whisper the requester in one click, know if the craft is worth it, and work through crafting orders faster.**

## What it does

**Tooltip** – hover or click any item and see which of your characters can craft it (same connected-realm group only), with profession and remaining Concentration.

**One-click whisper** – click a character in the tooltip: a whisper opens to the player who linked the item, message and max-quality link already typed. Just press Enter.

**Profession browser** – `/cc` or the minimap button: all your characters, professions and recipes by realm group. Search, epic-gear filter, click to paste your message, Shift-click to link.

**Crafting value** – on patterns, recipes and craftable items: difficulty, reagent cost, Auction House price and profit after the 5% cut. Gear at your target item level; potions, flasks and enchants at gold quality, with silver-reagent and gold-reagent costs per unit.

**Top ranking** – a **CraftCheck** button in the profession window ranks your recipes by profit. Hover a row for details, click to open the recipe.

**Crafting orders, faster**
- **Previous / Next** buttons in the order view to move through the list without going back.
- After completing an order, the **next one opens automatically**.
- **Your mats / Net**: the cost of the reagents *you* have to provide (customer-supplied ones excluded) and what you actually make on the order.
- Materials the order gives back to you are announced with their Auction House value.
- The "you are using some of your own reagents" confirmation is skipped.

**Farming sessions** – `/cc farm` (or Shift-click the minimap button): start, pause, resume and finish a gathering session. Everything from Herbalism and Mining nodes (Fishing optional) is counted with its Auction House value: total gold, gold per hour, per-profession breakdown, node counts and an item list. Auto-pauses when you stop gathering, survives a reload, and keeps a history of past sessions.

**Order earnings** – tips from personal, public, guild and NPC orders counted per character, plus a realm-group total and the value of returned materials.

Prices from Auctionator's Full Scan (recommended) or CraftCheck's own scan. English and Spanish.

## Setup

Open each profession once on each character. That's it.

## Commands

- `/cc` panel · `/cc tooltip` · `/cc minimap` · `/cc list` · `/cc delete Name-Realm` · `/cc scan`
- `/cc message <text>` and `/cc selfmessage <text>` – whisper messages (`{character}`, `{item}`)
- `/cc orders` – order earnings (`reset` clears the current character)
- `/cc autonext` – open the next order after completing one (on by default)
- `/cc confirm` – show or skip the own-reagents confirmation (skipped by default)
- `/cc farm` – gathering session window
- `/cv top [n]` · `/cv ilvl N` (gear item level, default 232) · `/cv span N`
- `/cv full` / `/cv all` / `/cv scan` / `/cv reset` – own AH scanning (without Auctionator)

Free, no ads. If it saves you time: [buy me a coffee](https://ko-fi.com/gotenzlive). Bugs and ideas: [GitHub Issues](https://github.com/alaz-gtn/CraftCheck/issues).
