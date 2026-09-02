# <img src="https://raw.githubusercontent.com/alaz-gtn/CraftCheck/main/assets/CraftCheck_icon_400.png" width="48" align="absmiddle"> CraftCheck

**See instantly which of your characters can craft an item someone links in chat, and whisper them back in one click.**

Do you have several crafters spread across realms? Someone links an item in Trade asking for a crafter, and you have to remember which alt learned that recipe, on which realm, and whether they have Concentration left. CraftCheck answers all of that in the item tooltip.

## Features

**Tooltip info**
Hover or click any item link and see which of your characters can craft it: faction crest, class-colored name, realm, profession and remaining Concentration. Only characters on the same connected-realm group are shown, because that's where personal crafting orders work.

**One-click whisper**
Click the item in chat, then click a character in the tooltip. CraftCheck opens a whisper to the player who linked the item with your message already typed, including the max-quality item link. Press Enter and you're done. The message is fully customizable.

**Profession browser**
A panel (minimap button or `/cc`) lists every character grouped by realm group, with their professions and recipes. Filter to epic gear only, search by item name, click an item to paste your message into chat (for people who ask without linking), or Shift-click to link the item.

**Concentration tracking**
Exact for the logged-in character, estimated with regeneration for your alts, so you know who can actually take the order.

**Localized** in English and Spanish.

## How it works

Open each profession once on each character (and each expansion tab). CraftCheck records the learned recipes account-wide. Everything else is automatic.

## Commands

- `/cc` – toggle the profession panel
- `/cc tooltip` – enable or disable tooltip info
- `/cc minimap` – show or hide the minimap button
- `/cc list` – list saved characters and recipe counts
- `/cc delete Name-Realm` – remove a character
- `/cc scan` – force a rescan of the open profession
- `/cc message <text>` – set the whisper message (`{character}` = crafter Name-Realm, `{item}` = item link; Spanish `{personaje}` / `{objeto}` also work)

## Support

CraftCheck is free and always will be. If it saves you time, you can [buy me a coffee](https://ko-fi.com/gotenzlive).

## Feedback

Bug reports and suggestions are welcome on the [Issues](https://github.com/alaz-gtn/CraftCheck/issues) page or in the CurseForge comments.

## License

MIT
