-------------------------------------------------------------------------------
-- CraftCheck - núcleo: base de datos, escaneo de profesiones y tooltip
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Localización (español por defecto, inglés como alternativa)
-------------------------------------------------------------------------------
local locale = GetLocale()
local isES = (locale == "esES" or locale == "esMX")
local L
if isES then
    L = {
        SCANNED        = "|cff33ff99CraftCheck|r: %d recetas nuevas (%d en total) de |cffffd100%s|r guardadas para %s.",
        CAN_CRAFT      = "Pueden fabricarlo:",
        YOU            = "(tú)",
        PANEL_TITLE    = "CraftCheck - Profesiones por grupo de reinos",
        SEARCH         = "Buscar objeto...",
        ONLY_GROUP     = "Solo mi grupo de reinos",
        REALM_GROUP    = "Grupo de reinos: %s",
        CHARS          = "%d personajes",
        RECIPES        = "%d recetas",
        NO_DATA        = "Sin datos. Abre cada profesión (y cada pestaña de expansión) en cada personaje para que CraftCheck las registre.",
        NO_RESULTS     = "Ningún objeto coincide con la búsqueda.",
        HINT           = "Click en un objeto: pega el mensaje en el chat. Shift+click: enlaza solo el objeto.",
        MINIMAP_TIP1   = "|cff33ff99CraftCheck|r",
        MINIMAP_TIP2   = "Click izquierdo: abrir/cerrar panel\nClick derecho: activar/desactivar tooltip\nArrastrar: mover el botón",
        TOOLTIP_ON     = "|cff33ff99CraftCheck|r: información en tooltip |cff00ff00activada|r.",
        TOOLTIP_OFF    = "|cff33ff99CraftCheck|r: información en tooltip |cffff0000desactivada|r.",
        DELETED        = "|cff33ff99CraftCheck|r: personaje %s eliminado.",
        NOT_FOUND      = "|cff33ff99CraftCheck|r: no se encontró el personaje %s.",
        HELP           = "|cff33ff99CraftCheck|r comandos:\n  /cc - abrir/cerrar panel\n  /cc tooltip - activar/desactivar tooltip\n  /cc minimapa - mostrar/ocultar botón de minimapa\n  /cc borrar Nombre-Reino - eliminar un personaje\n  /cc lista - listar personajes guardados\n  /cc escanear - forzar escaneo de la profesión abierta\n  /cc mensaje <texto> - cambiar el mensaje del susurro ({personaje}, {objeto})\n  /cc mensaje reset - restablecer el mensaje\n  /cc mensajeyo <texto> - mensaje cuando el fabricante eres tú",
        LIST_HEADER    = "|cff33ff99CraftCheck|r personajes guardados:",
        UNKNOWN_REALM  = "Reino desconocido",
        CONC           = "Concentración",
        GEAR_ONLY      = "Solo equipo épico",
        MSG_BTN        = "Chat",
        MSG_TIP        = "Pega este mensaje en el chat activo:",
        TIP_CLICK_HINT = "Click en un personaje para susurrar el mensaje",
        TIP_WHISPER_TO = "Susurro a: %s",
        MSG_LABEL      = "Mensaje del susurro:",
        MSG_SELF_LABEL = "Si soy yo:",
        MSG_SELF_DEFAULT = "Yo lo crafteo, envíamela por la voluntad :) {objeto}",
        MSG_SELF_HELP  = "Se usa cuando el fabricante es el personaje con el que estás jugando. Mismos marcadores. Intro para guardar.",
        MSG_SELF_CURRENT = "|cff33ff99CraftCheck|r mensaje (si soy yo) actual: %s",
        CHAT_LOCKDOWN  = "|cff33ff99CraftCheck|r: el chat está bloqueado ahora mismo, no se puede escribir el mensaje.",
        INSERT_FAIL    = "|cff33ff99CraftCheck|r: no se pudo abrir el cuadro de chat. Mensaje: %s",
        MSG_HELP       = "{personaje} o {character} = Nombre-Reino del fabricante, {objeto} o {item} = enlace del objeto a calidad máxima (si falta, se añade al final). Intro para guardar.",
        MSG_DEFAULT    = "Yo lo crafteo, puedes enviárselo a \"{personaje}\" por la voluntad :) {objeto}",
        MSG_CURRENT    = "|cff33ff99CraftCheck|r mensaje actual: %s",
        MSG_SET        = "|cff33ff99CraftCheck|r mensaje guardado. Marcadores: {personaje} = Nombre-Reino, {objeto} = enlace del objeto.",
        MSG_RESET      = "|cff33ff99CraftCheck|r mensaje restablecido al valor por defecto.",
    }
else
    L = {
        SCANNED        = "|cff33ff99CraftCheck|r: %d new recipes (%d total) of |cffffd100%s|r saved for %s.",
        CAN_CRAFT      = "Can be crafted by:",
        YOU            = "(you)",
        PANEL_TITLE    = "CraftCheck - Professions by realm group",
        SEARCH         = "Search item...",
        ONLY_GROUP     = "Only my realm group",
        REALM_GROUP    = "Realm group: %s",
        CHARS          = "%d characters",
        RECIPES        = "%d recipes",
        NO_DATA        = "No data. Open each profession (and each expansion tab) on each character so CraftCheck can record them.",
        NO_RESULTS     = "No item matches the search.",
        HINT           = "Click an item: paste the message into chat. Shift+click: link the item only.",
        MINIMAP_TIP1   = "|cff33ff99CraftCheck|r",
        MINIMAP_TIP2   = "Left click: toggle panel\nRight click: toggle tooltip info\nDrag: move button",
        TOOLTIP_ON     = "|cff33ff99CraftCheck|r: tooltip info |cff00ff00enabled|r.",
        TOOLTIP_OFF    = "|cff33ff99CraftCheck|r: tooltip info |cffff0000disabled|r.",
        DELETED        = "|cff33ff99CraftCheck|r: character %s removed.",
        NOT_FOUND      = "|cff33ff99CraftCheck|r: character %s not found.",
        HELP           = "|cff33ff99CraftCheck|r commands:\n  /cc - toggle panel\n  /cc tooltip - toggle tooltip info\n  /cc minimap - show/hide minimap button\n  /cc delete Name-Realm - remove a character\n  /cc list - list saved characters\n  /cc scan - force a scan of the open profession\n  /cc message <text> - change the whisper message ({character}, {item})\n  /cc message reset - reset the message\n  /cc selfmessage <text> - message when the crafter is you",
        LIST_HEADER    = "|cff33ff99CraftCheck|r saved characters:",
        UNKNOWN_REALM  = "Unknown realm",
        CONC           = "Concentration",
        GEAR_ONLY      = "Epic gear only",
        MSG_BTN        = "Chat",
        MSG_TIP        = "Paste this message into the active chat:",
        TIP_CLICK_HINT = "Click a character to whisper the message",
        TIP_WHISPER_TO = "Whisper to: %s",
        MSG_LABEL      = "Whisper message:",
        MSG_SELF_LABEL = "If it's me:",
        MSG_SELF_DEFAULT = "I can craft it, send me the order for a tip :) {item}",
        MSG_SELF_HELP  = "Used when the crafter is the character you are playing. Same placeholders. Enter to save.",
        MSG_SELF_CURRENT = "|cff33ff99CraftCheck|r message (if it's me) current: %s",
        CHAT_LOCKDOWN  = "|cff33ff99CraftCheck|r: chat is locked down right now, the message cannot be typed.",
        INSERT_FAIL    = "|cff33ff99CraftCheck|r: could not open the chat box. Message: %s",
        MSG_HELP       = "{character} or {personaje} = crafter Name-Realm, {item} or {objeto} = max-quality item link (appended at the end if missing). Enter to save.",
        MSG_DEFAULT    = "I can craft it, send the order to \"{character}\" for a tip :) {item}",
        MSG_CURRENT    = "|cff33ff99CraftCheck|r current message: %s",
        MSG_SET        = "|cff33ff99CraftCheck|r message saved. Placeholders: {character} = Name-Realm, {item} = item link.",
        MSG_RESET      = "|cff33ff99CraftCheck|r message reset to default.",
    }
end
ns.L = L

-------------------------------------------------------------------------------
-- Constantes / utilidades
-------------------------------------------------------------------------------
ns.FACTION_ICON = {
    Alliance = "|TInterface\\FriendsFrame\\PlusManz-Alliance:16:16|t",
    Horde    = "|TInterface\\FriendsFrame\\PlusManz-Horde:16:16|t",
    Neutral  = "|TInterface\\FriendsFrame\\PlusManz-PlusManz:16:16|t",
}

-- Valores secretos de 12.x: no se pueden leer ni comparar
local function IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v)
end
ns.IsSecret = IsSecret

local function Trim(str)
    if type(str) ~= "string" then return str end
    return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

function ns.FactionIcon(faction)
    return ns.FACTION_ICON[faction or "Neutral"] or ns.FACTION_ICON.Neutral
end

function ns.ClassColorText(classFile, text)
    if classFile and C_ClassColor and C_ClassColor.GetClassColor then
        local color = C_ClassColor.GetClassColor(classFile)
        if color then return color:WrapTextInColorCode(text) end
    end
    local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if c then
        return string.format("|c%s%s|r", c.colorStr or "ffffffff", text)
    end
    return text
end

-- Índices en memoria (se reconstruyen al cargar y tras cada escaneo)
ns.index = {}        -- itemID -> { {char=charKey, prof=profID, recipe=recipeID}, ... }
ns.playerKey = nil
ns.currentGroupSet = {}
ns.currentGroupList = {}
ns.currentGroupKey = nil

-------------------------------------------------------------------------------
-- Base de datos
-------------------------------------------------------------------------------
local function InitDB()
    CraftCheckDB = CraftCheckDB or {}
    CraftCheckDB.chars = CraftCheckDB.chars or {}
    CraftCheckDB.settings = CraftCheckDB.settings or {}
    local s = CraftCheckDB.settings
    if s.tooltip == nil then s.tooltip = true end
    if s.onlyGroup == nil then s.onlyGroup = true end
    if s.gearOnly == nil then s.gearOnly = true end
    s.minimap = s.minimap or {}
    if s.minimap.hide == nil then s.minimap.hide = false end
    if s.minimap.angle == nil then s.minimap.angle = 220 end
    ns.db = CraftCheckDB
end

function ns.RebuildIndex()
    wipe(ns.index)
    for charKey, c in pairs(ns.db.chars) do
        for profID, p in pairs(c.profs or {}) do
            for recipeID, r in pairs(p.recipes or {}) do
                for _, itemID in ipairs(r.items or {}) do
                    local t = ns.index[itemID]
                    if not t then t = {}; ns.index[itemID] = t end
                    t[#t + 1] = { char = charKey, prof = profID, recipe = recipeID }
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Grupo de reinos conectados
-------------------------------------------------------------------------------
function ns.GetRealmGroup()
    local set, list = {}, {}
    local me = GetNormalizedRealmName()
    local ok, realms = pcall(GetAutoCompleteRealms)
    if ok and type(realms) == "table" then
        for _, r in ipairs(realms) do set[r] = true end
    end
    if me then set[me] = true end
    for r in pairs(set) do list[#list + 1] = r end
    table.sort(list)
    return set, list, table.concat(list, "|")
end

function ns.RefreshCurrentGroup()
    local set, list, key = ns.GetRealmGroup()
    ns.currentGroupSet = set
    ns.currentGroupList = list
    ns.currentGroupKey = key
end

-------------------------------------------------------------------------------
-- Registro del personaje actual
-------------------------------------------------------------------------------
local function GetProfessionIconBySkillLine()
    local map = {}
    local slots = { GetProfessions() }
    for i = 1, 5 do
        local idx = slots[i]
        if idx then
            local name, icon, _, _, _, _, skillLine = GetProfessionInfo(idx)
            if skillLine then map[skillLine] = { name = name, icon = icon } end
        end
    end
    return map
end

function ns.GetCharEntry()
    local name = UnitName("player")
    local realm = GetNormalizedRealmName()
    if not name or not realm then return nil end
    local key = name .. "-" .. realm
    local c = ns.db.chars[key]
    if not c then
        c = { profs = {} }
        ns.db.chars[key] = c
    end
    c.name = name
    c.realm = realm
    c.realmDisplay = GetRealmName() or realm
    c.faction = UnitFactionGroup("player") or "Neutral"
    c.class = select(2, UnitClass("player"))
    ns.RefreshCurrentGroup()
    c.groupKey = ns.currentGroupKey
    c.groupRealms = ns.currentGroupList
    c.lastSeen = time()
    c.profs = c.profs or {}
    ns.playerKey = key
    return c, key
end

-- Elimina profesiones que el personaje ya no tiene y actualiza nombre/icono
local function PruneProfessions(c)
    local current = GetProfessionIconBySkillLine()
    if not next(current) then return end
    for profID, p in pairs(c.profs) do
        if current[profID] then
            p.name = current[profID].name or p.name
            p.icon = current[profID].icon or p.icon
        else
            c.profs[profID] = nil
        end
    end
end

-------------------------------------------------------------------------------
-- Concentración
-------------------------------------------------------------------------------
-- Lee la concentración actual de una entrada {currencyID=...} y guarda la fecha
function ns.ReadConcentration(entry)
    if not entry or not entry.currencyID or not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return end
    local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, entry.currencyID)
    if ok and info then
        entry.qty = info.quantity or 0
        entry.max = (info.maxQuantity and info.maxQuantity > 0) and info.maxQuantity or 1000
        entry.t = time()
    end
end

-- Refresca la concentración de todas las profesiones del personaje actual
function ns.UpdateOwnConcentration()
    local c = ns.db and ns.playerKey and ns.db.chars[ns.playerKey]
    if not c then return end
    for _, p in pairs(c.profs or {}) do
        for _, entry in pairs(p.conc or {}) do
            ns.ReadConcentration(entry)
        end
    end
end

-- Estimación para personajes desconectados: se regenera un 25% del máximo al día
function ns.EstimateConcentration(entry)
    if not entry or not entry.qty or not entry.t then return nil end
    local max = entry.max or 1000
    local rate = max * 0.25 / 86400
    local est = entry.qty + (time() - entry.t) * rate
    if est > max then est = max end
    return math.floor(est), max
end

-- Texto de concentración para una profesión (opcionalmente solo una expansión)
function ns.ConcentrationText(prof, childID, isMe)
    if not prof or not prof.conc then return nil end
    if isMe then ns.UpdateOwnConcentration() end
    local ids = {}
    for id in pairs(prof.conc) do
        if not childID or id == childID then ids[#ids + 1] = id end
    end
    if #ids == 0 then return nil end
    table.sort(ids, function(a, b) return (prof.conc[a].exp or "") < (prof.conc[b].exp or "") end)
    local parts = {}
    for _, id in ipairs(ids) do
        local e = prof.conc[id]
        local est, max = ns.EstimateConcentration(e)
        if est then
            local color = est >= max * 0.5 and "|cff00ff00" or (est >= max * 0.2 and "|cffffff00" or "|cffff4040")
            local label = (not childID and e.exp) and (e.exp .. " ") or ""
            parts[#parts + 1] = string.format("%s%s%s%d/%d|r", label, isMe and "" or "~", color, est, max)
        end
    end
    if #parts == 0 then return nil end
    return "|cff9999ff" .. L.CONC .. ":|r " .. table.concat(parts, ", ")
end

-------------------------------------------------------------------------------
-- Metadatos del objeto resultante (equipable, rareza)
-------------------------------------------------------------------------------
local QUALITY_BY_COLOR = {
    ["ff9d9d9d"] = 0, ["ffffffff"] = 1, ["ff1eff00"] = 2, ["ff0070dd"] = 3,
    ["ffa335ee"] = 4, ["ffff8000"] = 5, ["ffe6cc80"] = 6, ["ff00ccff"] = 7,
}

-- Rellena r.equip (slot) y r.quality (rareza) si faltan. Devuelve true si cambió algo.
function ns.FillItemMeta(r)
    if not r or (r.equip ~= nil and r.quality ~= nil) then return false end
    local itemID = r.items and r.items[1]
    local changed = false
    if itemID and C_Item and C_Item.GetItemInfoInstant then
        local ok, _, _, _, equipLoc, _, classID = pcall(C_Item.GetItemInfoInstant, itemID)
        if ok then
            if r.equip == nil then
                if equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" then
                    r.equip = equipLoc
                else
                    r.equip = false
                end
                changed = true
            end
            if classID and r.classID == nil then r.classID = classID end
        end
        if r.quality == nil then
            local q
            if C_Item.GetItemQualityByID then
                local okQ, v = pcall(C_Item.GetItemQualityByID, itemID)
                if okQ and type(v) == "number" then q = v end
            end
            if not q and C_Item.GetItemInfo then
                local okG, _, _, v = pcall(C_Item.GetItemInfo, itemID)
                if okG and type(v) == "number" then q = v end
            end
            if not q then
                local link = r.maxLink or r.link
                local color = link and link:match("|c(%x%x%x%x%x%x%x%x)")
                if color then q = QUALITY_BY_COLOR[color:lower()] end
            end
            if q then r.quality = q; changed = true end
        end
    end
    return changed
end

-- ¿Es un objeto de equipo/herramienta épico (o mejor)?
function ns.IsEpicGear(r)
    ns.FillItemMeta(r)
    return r.equip and r.equip ~= false and (r.quality or 0) >= 4
end

-- Nombre coloreado por rareza
function ns.QualityName(r)
    local name = r.name or "?"
    local q = r.quality
    if q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q] and ITEM_QUALITY_COLORS[q].hex then
        return ITEM_QUALITY_COLORS[q].hex .. name .. "|r"
    end
    return name
end

-------------------------------------------------------------------------------
-- Escaneo de la profesión abierta
-------------------------------------------------------------------------------
local function GetRecipeIDs()
    if C_TradeSkillUI.GetAllRecipeIDs then
        local ok, ids = pcall(C_TradeSkillUI.GetAllRecipeIDs)
        if ok and type(ids) == "table" then return ids end
    end
    -- Alternativa: lista filtrada (asegurando que se muestran las aprendidas)
    if C_TradeSkillUI.SetShowLearned then pcall(C_TradeSkillUI.SetShowLearned, true) end
    local ok, ids = pcall(C_TradeSkillUI.GetFilteredRecipeIDs)
    if ok and type(ids) == "table" then return ids end
    return {}
end

local SKIP_TYPES = {}
if Enum and Enum.TradeskillRecipeType then
    SKIP_TYPES[Enum.TradeskillRecipeType.Salvage or -1] = true
    SKIP_TYPES[Enum.TradeskillRecipeType.Gathering or -1] = true
    SKIP_TYPES[Enum.TradeskillRecipeType.Recraft or -1] = true
end

function ns.ScanCurrentTradeSkill(silent)
    if not C_TradeSkillUI or not C_TradeSkillUI.IsTradeSkillReady then return end
    if not C_TradeSkillUI.IsTradeSkillReady() then return end
    if C_TradeSkillUI.IsDataSourceChanging and C_TradeSkillUI.IsDataSourceChanging() then return end
    if (C_TradeSkillUI.IsTradeSkillLinked and C_TradeSkillUI.IsTradeSkillLinked())
        or (C_TradeSkillUI.IsTradeSkillGuild and C_TradeSkillUI.IsTradeSkillGuild())
        or (C_TradeSkillUI.IsNPCCrafting and C_TradeSkillUI.IsNPCCrafting()) then
        return
    end

    local base = C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo()
    if not base or not base.professionID then return end

    local c = ns.GetCharEntry()
    if not c then return end

    local profID = base.professionID
    local prof = c.profs[profID]
    if not prof then
        prof = { recipes = {} }
        c.profs[profID] = prof
    end
    prof.recipes = prof.recipes or {}
    prof.name = base.parentProfessionName or base.professionName or prof.name or ("#" .. profID)
    local icons = GetProfessionIconBySkillLine()
    if icons[profID] then prof.icon = icons[profID].icon end

    -- Profesión de expansión (hija) y su concentración
    local childID, expName
    if C_TradeSkillUI.GetChildProfessionInfo then
        local okC, child = pcall(C_TradeSkillUI.GetChildProfessionInfo)
        if okC and child then
            childID = child.professionID
            expName = child.expansionName
        end
    end
    if childID then
        prof.conc = prof.conc or {}
        local entry = prof.conc[childID] or {}
        entry.exp = expName or entry.exp
        if C_TradeSkillUI.GetConcentrationCurrencyID then
            local okI, currencyID = pcall(C_TradeSkillUI.GetConcentrationCurrencyID, childID)
            if okI and currencyID and currencyID > 0 then
                entry.currencyID = currencyID
                ns.ReadConcentration(entry)
            end
        end
        if entry.currencyID then prof.conc[childID] = entry end
    end

    local ids = GetRecipeIDs()
    local count, added, removed = 0, 0, 0
    for _, recipeID in ipairs(ids) do
        local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
        if info then
            if info.learned then
                local skip = false
                local okS, schem = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
                if okS and schem and schem.recipeType and SKIP_TYPES[schem.recipeType] then
                    skip = true
                end
                if not skip then
                    local items = {}
                    local okQ, qIDs = pcall(C_TradeSkillUI.GetRecipeQualityItemIDs, recipeID)
                    if okQ and type(qIDs) == "table" then
                        for _, id in ipairs(qIDs) do
                            if type(id) == "number" and not tContains(items, id) then items[#items + 1] = id end
                        end
                    end
                    local outID = okS and schem and schem.outputItemID
                    if outID and not tContains(items, outID) then table.insert(items, 1, outID) end

                    local link
                    if C_TradeSkillUI.GetRecipeItemLink then
                        local okL, l = pcall(C_TradeSkillUI.GetRecipeItemLink, recipeID)
                        if okL and type(l) == "string" then link = l end
                    end
                    if #items == 0 and link then
                        local id = tonumber(link:match("item:(%d+)"))
                        if id then items[1] = id end
                    end

                    -- Enlace del objeto a calidad máxima de fabricación
                    local maxLink
                    local qualityIDs = info.qualityIDs
                    if type(qualityIDs) == "table" and #qualityIDs > 0 and C_TradeSkillUI.GetRecipeOutputItemData then
                        local okM, out = pcall(C_TradeSkillUI.GetRecipeOutputItemData, recipeID, {}, nil, qualityIDs[#qualityIDs])
                        if okM and type(out) == "table" then
                            if type(out.hyperlink) == "string" then maxLink = out.hyperlink end
                            if out.itemID and not tContains(items, out.itemID) then items[#items + 1] = out.itemID end
                        end
                    end

                    if not prof.recipes[recipeID] then added = added + 1 end
                    local rec = {
                        name    = info.name,
                        icon    = info.icon,
                        items   = items,
                        link    = link,
                        maxLink = maxLink,
                        enchant = info.isEnchantingRecipe or nil,
                        exp     = childID,
                    }
                    ns.FillItemMeta(rec)
                    prof.recipes[recipeID] = rec
                    count = count + 1
                end
            elseif prof.recipes[recipeID] then
                -- Antes aprendida y ahora no (rango cambiado, etc.)
                prof.recipes[recipeID] = nil
                removed = removed + 1
            end
        end
    end
    prof.lastScan = time()

    ns.RebuildIndex()
    if ns.UI_Refresh then ns.UI_Refresh() end
    if not silent and (added > 0 or removed > 0) then
        local suffix = expName and (" [" .. expName .. "]") or ""
        print(string.format(L.SCANNED, added, count, prof.name .. suffix, ns.ClassColorText(c.class, c.name)))
    end
end

-- Escaneo con retardo para agrupar ráfagas de eventos
local scanPending = false
local function QueueScan()
    if scanPending then return end
    scanPending = true
    C_Timer.After(0.8, function()
        scanPending = false
        ns.ScanCurrentTradeSkill(false)
    end)
end

-------------------------------------------------------------------------------
-- Consulta: quién puede fabricar un objeto
-------------------------------------------------------------------------------
function ns.GetCraftersForItem(itemID, onlyCurrentGroup)
    local entries = ns.index[itemID]
    if not entries then return nil end
    local seen, result = {}, {}
    for _, e in ipairs(entries) do
        local c = ns.db.chars[e.char]
        local p = c and c.profs[e.prof]
        if c and p and (not onlyCurrentGroup or ns.currentGroupSet[c.realm]) then
            local k = e.char .. ":" .. tostring(e.prof)
            if not seen[k] then
                seen[k] = true
                result[#result + 1] = { key = e.char, char = c, prof = p, recipeID = e.recipe, isMe = (e.char == ns.playerKey) }
            end
        end
    end
    table.sort(result, function(a, b)
        if a.isMe ~= b.isMe then return a.isMe end
        if a.char.name ~= b.char.name then return a.char.name < b.char.name end
        return (a.prof.name or "") < (b.prof.name or "")
    end)
    return result
end

function ns.FormatCrafterLine(entry)
    local c = entry.char
    local realm = c.realmDisplay or c.realm or L.UNKNOWN_REALM
    local s = ns.FactionIcon(c.faction) .. " " .. ns.ClassColorText(c.class, c.name)
    s = s .. "|cffaaaaaa-" .. realm .. "|r"
    if entry.isMe then s = s .. " |cff00ff00" .. L.YOU .. "|r" end
    s = s .. "  |cffffd100" .. (entry.prof.name or "?") .. "|r"
    local recipe = entry.recipeID and entry.prof.recipes and entry.prof.recipes[entry.recipeID]
    local conc = ns.ConcentrationText(entry.prof, recipe and recipe.exp or nil, entry.isMe)
    if conc then s = s .. "  " .. conc end
    return s
end

-------------------------------------------------------------------------------
-- Mensaje de chat ("Yo lo crafteo...")
-------------------------------------------------------------------------------
-- Marcadores admitidos (sin distinguir mayúsculas): {personaje} {character} {char} {pj} y {objeto} {item} {link}
local PLACEHOLDERS = {
    personaje = "char", character = "char", char = "char", pj = "char",
    objeto = "item", item = "item", link = "item",
}

function ns.BuildChatMessage(charKey, itemLink)
    local template
    if charKey and charKey == ns.playerKey then
        template = ns.db.settings.msgTemplateSelf or L.MSG_SELF_DEFAULT
    else
        template = ns.db.settings.msgTemplate or L.MSG_DEFAULT
    end
    local values = { char = charKey or "?", item = itemLink or "" }
    local hasItem = false
    for key in template:gmatch("{(%a+)}") do
        if PLACEHOLDERS[key:lower()] == "item" then hasItem = true end
    end
    local msg = template
    if values.item ~= "" and not hasItem then
        msg = msg .. " {objeto}"
    end
    msg = msg:gsub("{(%a+)}", function(key)
        local kind = PLACEHOLDERS[key:lower()]
        if kind then return values[kind] end
        return nil
    end)
    return (msg:gsub("%s+$", ""))
end

-- Compatibilidad 12.x (ChatFrameUtil.*) con nombres antiguos (ChatEdit_* / ChatFrame_*)
local function ChatFn(name, legacy)
    if ChatFrameUtil and type(ChatFrameUtil[name]) == "function" then return ChatFrameUtil[name] end
    local f = _G[legacy]
    if type(f) == "function" then return f end
    return nil
end

local function GetActiveEditBox()
    local f = ChatFn("GetActiveWindow", "ChatEdit_GetActiveWindow")
    if f then
        local ok, eb = pcall(f)
        if ok and eb then return eb end
    end
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local cf = _G["ChatFrame" .. i]
        local eb = cf and cf.editBox
        if eb and eb:IsShown() and eb.HasFocus and eb:HasFocus() then return eb end
    end
    return nil
end

-- Último cuadro de chat que estuvo activo (p. ej. un susurro abierto que perdió el foco al pulsar en el panel)
ns.lastFocusedEditBox = nil

local function GetLastActiveEditBox()
    local last = ns.lastFocusedEditBox
    if last and last.IsShown and last:IsShown() then return last end
    local f = ChatFn("GetLastActiveWindow", "ChatEdit_GetLastActiveWindow")
    if f then
        local ok, eb = pcall(f)
        if ok and eb then return eb end
    end
    for i = 1, 20 do
        local cf = _G["ChatFrame" .. i]
        local eb = cf and cf.editBox
        if eb and eb:IsShown() then return eb end
    end
    return last
end

-- Cuadro de edición con el foco del teclado (la forma más fiable de saber dónde escribir)
local function FocusedEditBox()
    local f = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
    if f and f.Insert and f.GetText and f.IsShown and f:IsShown() then return f end
    return GetActiveEditBox()
end

local function Debug(...)
    if ns.db and ns.db.settings.debug then
        print("|cffff8800CraftCheck debug|r:", ...)
    end
end

-- Recordar a quién está abierto el susurro (el juego lo pierde al reactivar el cuadro)
ns.lastWhisper = nil   -- { target=, bn=, t= }

local function SetLastWhisper(target, bn, source)
    if IsSecret(target) or type(target) ~= "string" or target == "" then return end
    ns.lastWhisper = { target = target, bn = bn and true or false, t = GetTime() }
    Debug("whisper target captured: " .. target .. " (" .. tostring(source) .. ")")
end

-- Convierte una cadena global como "Tell %s:" en un patrón de captura
local function HeaderPattern(fmt)
    if type(fmt) ~= "string" then return nil end
    local pat = fmt:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"):gsub("%%%%s", "(.+)")
    return "^" .. pat .. "$"
end
local WHISPER_HEADER_PAT = HeaderPattern(CHAT_WHISPER_SEND)
local BN_HEADER_PAT = HeaderPattern(CHAT_BN_WHISPER_SEND)

local function RecordWhisperBox(eb)
    if not eb then return end
    -- 1) Atributos del cuadro
    if eb.GetAttribute then
        local ok, ctype = pcall(eb.GetAttribute, eb, "chatType")
        if ok and (ctype == "WHISPER" or ctype == "BN_WHISPER") then
            local ok2, target = pcall(eb.GetAttribute, eb, "tellTarget")
            if ok2 then SetLastWhisper(target, ctype == "BN_WHISPER", "attribute") return end
        end
    end
    -- 1b) Métodos del mixin de 12.x
    if type(eb.GetChatType) == "function" then
        local ok, ctype = pcall(eb.GetChatType, eb)
        if ok and (ctype == "WHISPER" or ctype == "BN_WHISPER") then
            local target
            if type(eb.GetTellTarget) == "function" then
                local ok2, t = pcall(eb.GetTellTarget, eb)
                if ok2 then target = t end
            end
            if not target and eb.GetAttribute then
                local ok3, t = pcall(eb.GetAttribute, eb, "tellTarget")
                if ok3 then target = t end
            end
            if target then SetLastWhisper(target, ctype == "BN_WHISPER", "method") return end
        end
    end
    -- 2) Campos directos
    if (eb.chatType == "WHISPER" or eb.chatType == "BN_WHISPER") and eb.tellTarget then
        SetLastWhisper(eb.tellTarget, eb.chatType == "BN_WHISPER", "field")
        return
    end
    -- 3) Rótulo "Susurrar a Nombre:"
    local header = eb.header and eb.header.GetText and eb.header:GetText()
    if type(header) == "string" and not IsSecret(header) and header ~= "" then
        local name = WHISPER_HEADER_PAT and header:match(WHISPER_HEADER_PAT)
        if name then SetLastWhisper(Trim(name), false, "header") return end
        name = BN_HEADER_PAT and header:match(BN_HEADER_PAT)
        if name then SetLastWhisper(Trim(name), true, "header") return end
    end
end

local lastDump = 0
local function DumpEditBox(eb)
    if not ns.db or not ns.db.settings.debug or not eb then return end
    local okA, ctype = pcall(eb.GetAttribute, eb, "chatType")
    -- Solo interesa cuando no es el chat normal; y como mucho una vez por segundo
    if (not okA or ctype == "SAY" or ctype == nil) and (GetTime() - lastDump) < 1 then return end
    lastDump = GetTime()
    local okB, tt = pcall(eb.GetAttribute, eb, "tellTarget")
    local header = eb.header and eb.header.GetText and eb.header:GetText()
    local mtype
    if type(eb.GetChatType) == "function" then local okM, v = pcall(eb.GetChatType, eb); mtype = okM and v end
    Debug("editbox " .. tostring(eb:GetName()),
        "GetChatType=" .. tostring(mtype),
        "attr chatType=" .. tostring(okA and ctype),
        "attr tellTarget=" .. tostring(okB and (IsSecret(tt) and "<secret>" or tt)),
        "field chatType=" .. tostring(eb.chatType),
        "header=" .. tostring(IsSecret(header) and "<secret>" or header))
end

-- Tipo de chat y destinatario de un cuadro, por cualquiera de las vías disponibles
local function EditBoxChatInfo(eb)
    if not eb then return nil end
    local ctype, target
    if type(eb.GetChatType) == "function" then
        local ok, v = pcall(eb.GetChatType, eb)
        if ok and type(v) == "string" then ctype = v end
    end
    if not ctype and eb.GetAttribute then
        local ok, v = pcall(eb.GetAttribute, eb, "chatType")
        if ok and type(v) == "string" then ctype = v end
    end
    if not ctype and type(eb.chatType) == "string" then ctype = eb.chatType end
    if ctype == "WHISPER" or ctype == "BN_WHISPER" then
        if type(eb.GetTellTarget) == "function" then
            local ok, v = pcall(eb.GetTellTarget, eb)
            if ok then target = v end
        end
        if target == nil and eb.GetAttribute then
            local ok, v = pcall(eb.GetAttribute, eb, "tellTarget")
            if ok then target = v end
        end
        if target == nil then target = eb.tellTarget end
    else
        local header = eb.header and eb.header.GetText and eb.header:GetText()
        if type(header) == "string" and not IsSecret(header) and header ~= "" then
            local name = WHISPER_HEADER_PAT and header:match(WHISPER_HEADER_PAT)
            if name then ctype, target = "WHISPER", Trim(name) end
            if not name then
                name = BN_HEADER_PAT and header:match(BN_HEADER_PAT)
                if name then ctype, target = "BN_WHISPER", Trim(name) end
            end
        end
    end
    if IsSecret(target) then target = "<secret>" end
    return ctype, target
end

-- "/w Nombre " (o "/cw Nombre ") escrito en un cuadro de chat que el juego aún no ha convertido a susurro
function ns.GetTypedWhisperTarget()
    for i = 1, 30 do
        local cf = _G["ChatFrame" .. i]
        local eb = cf and cf.editBox
        if eb and eb.IsShown and eb:IsShown() then
            local text = eb:GetText()
            if type(text) == "string" and not IsSecret(text) then
                local cmd, name = text:match("^/(%a+)%s+(%S+)%s*$")
                if cmd and name and name:match("^[%a\128-\255'][%a\128-\255'%-]*$") then
                    Debug("typed whisper in " .. tostring(eb:GetName()) .. ": /" .. cmd .. " " .. name)
                    return name, eb
                end
            end
        end
    end
    return nil
end

-- Busca entre todos los cuadros de chat (fijos y temporales) uno visible en modo susurro
function ns.FindWhisperEditBox()
    local candidate
    for i = 1, 30 do
        local cf = _G["ChatFrame" .. i]
        local eb = cf and cf.editBox
        if eb and eb.IsShown and eb:IsShown() then
            local ctype, target = EditBoxChatInfo(eb)
            Debug("scan " .. tostring(eb:GetName()), "type=" .. tostring(ctype), "target=" .. tostring(target),
                "focus=" .. tostring(eb.HasFocus and eb:HasFocus()))
            if ctype == "WHISPER" or ctype == "BN_WHISPER" then
                if eb.HasFocus and eb:HasFocus() then return eb, ctype, target end
                candidate = candidate or eb
                if not candidate.craftCheckType then candidate.craftCheckType = ctype end
            end
        end
    end
    if candidate then
        local ctype, target = EditBoxChatInfo(candidate)
        return candidate, ctype, target
    end
    return nil
end

local function PasteIntoBox(eb, msg)
    local activate = ChatFn("ActivateChat", "ChatEdit_ActivateChat")
    if not (eb.HasFocus and eb:HasFocus()) and activate then pcall(activate, eb) end
    local current = eb:GetText() or ""
    if not current:find(msg, 1, true) then eb:Insert(msg) end
    C_Timer.After(0.1, function()
        local now = eb:GetText() or ""
        if not now:find(msg, 1, true) then eb:Insert(msg) end
        Debug("pasted into " .. tostring(eb:GetName()) .. " -> [" .. tostring(eb:GetText()) .. "]")
    end)
end
ns.PasteIntoBox = PasteIntoBox

function ns.HookChatEditBoxes()
    -- Callbacks oficiales (no HookScript sobre el cuadro: contaminaría el envío de mensajes)
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("ChatFrame.OnEditBoxFocusGained", function(_, eb)
            ns.lastFocusedEditBox = eb
            DumpEditBox(eb)
            RecordWhisperBox(eb)
        end, "CraftCheckFocusGained")
        EventRegistry:RegisterCallback("ChatFrame.OnEditBoxFocusLost", function(_, eb)
            RecordWhisperBox(eb)
        end, "CraftCheckFocusLost")
        EventRegistry:RegisterCallback("ChatFrame.OnEditBoxShow", function(_, eb)
            RecordWhisperBox(eb)
        end, "CraftCheckShow")
        EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", function(_, eb)
            RecordWhisperBox(eb)
        end, "CraftCheckPreSend")
        Debug("EventRegistry chat callbacks registered")
    else
        Debug("EventRegistry not available")
    end
    -- Funciones del juego que abren un susurro (click en un nombre, /w, respuesta)
    if ChatFrameUtil then
        if type(ChatFrameUtil.SendTell) == "function" then
            hooksecurefunc(ChatFrameUtil, "SendTell", function(name) SetLastWhisper(name, false, "SendTell") end)
        end
        if type(ChatFrameUtil.SendBNetTell) == "function" then
            hooksecurefunc(ChatFrameUtil, "SendBNetTell", function(name) SetLastWhisper(name, true, "SendBNetTell") end)
        end
    end
    if type(ChatFrame_SendTell) == "function" then
        hooksecurefunc("ChatFrame_SendTell", function(name) SetLastWhisper(name, false, "ChatFrame_SendTell") end)
    end
end

-- Destinatario del susurro que el usuario tiene abierto ahora mismo (o acaba de tener)
function ns.GetOpenWhisperTarget()
    local eb = GetLastActiveEditBox()
    if eb then RecordWhisperBox(eb) end
    local lw = ns.lastWhisper
    if not lw then return nil end
    local age = GetTime() - lw.t
    local shown = eb and eb:IsShown()
    if age <= 600 and (shown or age <= 120) then
        return lw.target, lw.bn
    end
    return nil
end

local function ChatLocked()
    return C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
end

function ns.InsertLink(link)
    if not link then return end
    if ChatLocked() then print(L.CHAT_LOCKDOWN) return end
    local f = ChatFn("InsertLink", "ChatEdit_InsertLink")
    if f then pcall(f, link) end
end

-- Quién ha enlazado cada objeto en el chat recientemente (itemID -> {sender, t})
ns.recentLinkers = {}
local LINKER_TTL = 15 * 60

local function OnChatMessage(msg, sender)
    if IsSecret(msg) or IsSecret(sender) then return end
    if type(msg) ~= "string" or type(sender) ~= "string" or sender == "" then return end
    local me = ns.playerKey
    if me and (sender == me or sender == UnitName("player")) then return end
    for id in msg:gmatch("|Hitem:(%d+)") do
        ns.recentLinkers[tonumber(id)] = { sender = sender, t = time() }
    end
end
ns.OnChatMessage = OnChatMessage

function ns.GetRecentLinker(itemID)
    local e = itemID and ns.recentLinkers[itemID]
    if e and (time() - e.t) <= LINKER_TTL then return e.sender end
    return nil
end

-- Abre un susurro al que pidió el objeto (si se sabe) con el mensaje ya escrito;
-- si no se sabe, pega el mensaje en el chat activo.
function ns.WhisperMessage(charKey, itemID, itemLink, target)
    local msg = ns.BuildChatMessage(charKey, itemLink)
    local bn = false
    if not target then
        if ChatLocked() then print(L.CHAT_LOCKDOWN) return end
        local box = ns.FindWhisperEditBox()
        if box then
            Debug("whisper box found: " .. tostring(box:GetName()))
            PasteIntoBox(box, msg)
            return
        end
        local typedName, typedBox = ns.GetTypedWhisperTarget()
        if typedName then
            target = typedName
            if typedBox then pcall(typedBox.SetText, typedBox, "") end
        end
        if not target then
            target, bn = ns.GetOpenWhisperTarget()
        end
        Debug("open whisper target=" .. tostring(target), "bn=" .. tostring(bn))
    end
    target = target or ns.GetRecentLinker(itemID)
    if ChatLocked() then print(L.CHAT_LOCKDOWN) return end
    if target then
        local sendTell
        if bn then
            sendTell = ChatFn("SendBNetTell", "ChatFrame_SendBNetTell")
        else
            sendTell = ChatFn("SendTell", "ChatFrame_SendTell")
        end
        local openChat = ChatFn("OpenChat", "ChatFrame_OpenChat")
        Debug("target=" .. tostring(target), "SendTell=" .. tostring(sendTell ~= nil), "OpenChat=" .. tostring(openChat ~= nil))
        local opened = false
        if sendTell then
            local ok, err = pcall(sendTell, target)
            opened = ok
            if not ok then Debug("SendTell error: " .. tostring(err)) end
        end
        if not opened and openChat and not bn then
            local ok, err = pcall(openChat, "/w " .. target .. " ")
            opened = ok
            if not ok then Debug("OpenChat error: " .. tostring(err)) end
        end
        if opened then
            local function PutText(label)
                local eb = FocusedEditBox()
                Debug(label, "box=" .. tostring(eb and eb:GetName() or eb), "text=[" .. tostring(eb and eb:GetText() or "") .. "]")
                if not eb then return false end
                local current = eb:GetText() or ""
                if not current:find(msg, 1, true) then
                    eb:Insert(msg)
                    Debug(label, "inserted -> [" .. tostring(eb:GetText()) .. "]")
                end
                return true
            end
            if not PutText("t0") then
                C_Timer.After(0.1, function() PutText("t0.1") end)
            end
            C_Timer.After(0.3, function() PutText("t0.3") end)
            return
        end
    end
    ns.InsertChatText(msg)
end

function ns.InsertChatText(text)
    if not text or text == "" then return end
    if ChatLocked() then print(L.CHAT_LOCKDOWN) return end
    local eb = FocusedEditBox()
    if not eb then
        eb = ns.FindWhisperEditBox()
        if eb then PasteIntoBox(eb, text) return end
        -- Un susurro abierto que perdió el foco al pulsar en el panel: lo reactivamos y conserva su destinatario
        eb = GetLastActiveEditBox()
        Debug("InsertChatText: last active box=" .. tostring(eb and eb:GetName() or eb))
        if not eb then
            local choose = ChatFn("ChooseBoxForSend", "ChatEdit_ChooseBoxForSend")
            if choose then
                local ok, box = pcall(choose)
                if ok then eb = box end
            end
            eb = eb or (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox)
        end
        local activate = ChatFn("ActivateChat", "ChatEdit_ActivateChat")
        if eb and activate then pcall(activate, eb) end
    end
    if not eb or not eb.Insert then
        print(string.format(L.INSERT_FAIL, text))
        return
    end
    eb:Insert(text)
    -- Si el cuadro se acaba de activar, algunas interfaces lo reescriben: reinsertamos si hace falta
    C_Timer.After(0.1, function()
        local box = FocusedEditBox() or eb
        local current = box:GetText() or ""
        if not current:find(text, 1, true) then
            box:Insert(text)
        end
    end)
end

-------------------------------------------------------------------------------
-- Detección de la línea de chat clicada (para saber a quién susurrar)
-------------------------------------------------------------------------------
ns.lastClicked = nil   -- { itemID=, sender=, t= } del último enlace de objeto clicado en el chat

local function RegionUnderCursor(region)
    if not region or not region.GetRect then return false end
    if region.IsShown and not region:IsShown() then return false end
    if region.IsMouseOver then
        local ok, over = pcall(region.IsMouseOver, region)
        if ok then return over end
    end
    local left, bottom, width, height = region:GetRect()
    if not left then return false end
    local scale = region:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    return cx >= left and cx <= left + width and cy >= bottom and cy <= bottom + height
end

-- Extrae el remitente de la información de una línea del chat
local function SenderFromMessageInfo(cf, info)
    if type(info) ~= "table" then return nil end
    -- 1) Argumentos del evento guardados en la línea
    local extra = info.extraData
    if type(extra) == "table" then
        for _, v in pairs(extra) do
            if type(v) == "table" and not IsSecret(v[2]) and type(v[2]) == "string" and v[2] ~= "" then
                return v[2]
            end
        end
    end
    -- 2) Vía GetMessageInfo (evento + args) localizando la entrada en el historial
    local hb = cf and cf.historyBuffer
    if hb and hb.GetNumElements and hb.GetEntryAtIndex and cf.GetMessageInfo then
        local n = hb:GetNumElements()
        for j = 1, n do
            if hb:GetEntryAtIndex(j) == info then
                local ok, _, _, _, _, _, _, _, _, args = pcall(cf.GetMessageInfo, cf, n - j + 1)
                if ok and type(args) == "table" and not IsSecret(args[2]) and type(args[2]) == "string" and args[2] ~= "" then
                    return args[2]
                end
                break
            end
        end
    end
    -- 3) Enlace de jugador dentro del texto
    local msg = info.message
    if not IsSecret(msg) and type(msg) == "string" then
        local name = msg:match("|Hplayer:([^:|]+)")
        if name then return name end
    end
    return nil
end

local function FindClickedSender(cf)
    if not cf then return nil end
    local candidates = {}
    if type(cf.visibleLines) == "table" then
        for _, fs in ipairs(cf.visibleLines) do candidates[#candidates + 1] = fs end
    end
    if #candidates == 0 and cf.GetRegions then
        for _, region in ipairs({ cf:GetRegions() }) do
            if region.messageInfo then candidates[#candidates + 1] = region end
        end
    end
    for _, fs in ipairs(candidates) do
        if fs.messageInfo and RegionUnderCursor(fs) then
            local ok, sender = pcall(SenderFromMessageInfo, cf, fs.messageInfo)
            if ok and sender then return sender end
        end
    end
    return nil
end

-- Añade al ItemRefTooltip la línea gris con el destinatario del susurro
function ns.AddWhisperHint(tooltip, itemID, target)
    if target then
        tooltip:AddLine("|cff808080" .. L.TIP_CLICK_HINT .. " (" .. string.format(L.TIP_WHISPER_TO, target) .. ")|r")
    else
        tooltip:AddLine("|cff808080" .. L.TIP_CLICK_HINT .. "|r")
    end
    tooltip.craftCheckHintFor = itemID
end

local function OnChatHyperlinkClick(self, link, text, button)
    if IsSecret(link) or type(link) ~= "string" then return end
    local itemID = tonumber(link:match("^item:(%d+)"))
    if not itemID then return end
    local sender
    local me = UnitName("player")
    local ok, found = pcall(FindClickedSender, self)
    if ok and found and found ~= me and found ~= ns.playerKey then sender = found end
    ns.lastClicked = { itemID = itemID, sender = sender, t = GetTime() }

    -- Si el tooltip del objeto ya está abierto y tiene sección CraftCheck, añadimos el destinatario
    if ItemRefTooltip and ItemRefTooltip:IsShown() and ns.db and ns.db.settings.tooltip
        and ItemRefTooltip.craftCheckHintFor ~= itemID then
        local crafters = ns.GetCraftersForItem(itemID, true)
        if crafters and #crafters > 0 then
            ns.AddWhisperHint(ItemRefTooltip, itemID, sender or ns.GetRecentLinker(itemID))
            ItemRefTooltip:Show()
        end
    end
end

local function HookChatFrames()
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local cf = _G["ChatFrame" .. i]
        if cf and not cf.craftCheckHooked then
            cf.craftCheckHooked = true
            cf:HookScript("OnHyperlinkClick", OnChatHyperlinkClick)
        end
    end
end

-------------------------------------------------------------------------------
-- Tooltip
-------------------------------------------------------------------------------
local function OnItemTooltip(tooltip, data)
    if not ns.db or not ns.db.settings.tooltip then return end
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip
        and tooltip ~= ShoppingTooltip1 and tooltip ~= ShoppingTooltip2 then
        return
    end
    local itemID = data and data.id
    if not itemID and tooltip.GetItem then
        local _, link = tooltip:GetItem()
        if link and C_Item and C_Item.GetItemInfoInstant then
            itemID = C_Item.GetItemInfoInstant(link)
        end
    end
    if not itemID then return end

    local crafters = ns.GetCraftersForItem(itemID, true)
    if not crafters or #crafters == 0 then return end

    local clickable = (tooltip == ItemRefTooltip)
    local function Wrap(charKey, text)
        if not clickable then return text end
        return string.format("|Hcraftcheck:%s:%d|h%s|h", charKey, itemID, text)
    end
    tooltip:AddLine(" ")
    -- La cabecera usa el primer personaje de la lista (el tuyo si está)
    tooltip:AddLine(Wrap(crafters[1].key, "|cff33ff99CraftCheck|r") .. " - " .. L.CAN_CRAFT, 1, 0.82, 0)
    for _, e in ipairs(crafters) do
        tooltip:AddLine(Wrap(e.key, ns.FormatCrafterLine(e)), 1, 1, 1)
    end
    if clickable then
        local lc = ns.lastClicked
        if lc and lc.itemID == itemID and (GetTime() - lc.t) < 2 then
            ns.AddWhisperHint(tooltip, itemID, lc.sender or ns.GetRecentLinker(itemID))
        else
            tooltip.craftCheckHintFor = nil
        end
    end
    tooltip:Show()
end

-- Click en el enlace [Chat] dentro del ItemRefTooltip
local function OnTooltipHyperlinkClick(self, link, text, button)
    if type(link) ~= "string" then return end
    local charKey, itemIDText = link:match("^craftcheck:([^:]+):(%d*)")
    if not charKey then return end
    local itemID = tonumber(itemIDText)
    local itemLink
    if itemID then
        local crafters = ns.GetCraftersForItem(itemID, false)
        for _, e in ipairs(crafters or {}) do
            if e.key == charKey then
                local r = e.prof.recipes and e.prof.recipes[e.recipeID]
                itemLink = r and (r.maxLink or r.link)
                break
            end
        end
        if not itemLink and C_Item and C_Item.GetItemInfo then
            local _, l = C_Item.GetItemInfo(itemID)
            itemLink = l
        end
    end
    local target
    local lc = ns.lastClicked
    if lc and lc.itemID == itemID and lc.sender then target = lc.sender end
    ns.WhisperMessage(charKey, itemID, itemLink, target)
end

local function HookItemRefTooltip()
    if not ItemRefTooltip or ItemRefTooltip.craftCheckHooked then return end
    ItemRefTooltip.craftCheckHooked = true
    if ItemRefTooltip.SetHyperlinksEnabled then ItemRefTooltip:SetHyperlinksEnabled(true) end
    ItemRefTooltip:HookScript("OnHyperlinkClick", OnTooltipHyperlinkClick)
end

-------------------------------------------------------------------------------
-- Comandos
-------------------------------------------------------------------------------
local function SlashHandler(msg)
    msg = strtrim(msg or "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    rest = rest or ""
    if cmd == "" then
        if ns.UI_Toggle then ns.UI_Toggle() end
    elseif cmd == "tooltip" then
        ns.db.settings.tooltip = not ns.db.settings.tooltip
        print(ns.db.settings.tooltip and L.TOOLTIP_ON or L.TOOLTIP_OFF)
    elseif cmd == "minimapa" or cmd == "minimap" then
        ns.db.settings.minimap.hide = not ns.db.settings.minimap.hide
        if ns.UI_UpdateMinimap then ns.UI_UpdateMinimap() end
    elseif cmd == "borrar" or cmd == "delete" then
        local target
        for key in pairs(ns.db.chars) do
            if key:lower() == rest:lower() then target = key; break end
        end
        if target then
            ns.db.chars[target] = nil
            ns.RebuildIndex()
            if ns.UI_Refresh then ns.UI_Refresh() end
            print(string.format(L.DELETED, target))
        else
            print(string.format(L.NOT_FOUND, rest))
        end
    elseif cmd == "lista" or cmd == "list" then
        print(L.LIST_HEADER)
        local keys = {}
        for key in pairs(ns.db.chars) do keys[#keys + 1] = key end
        table.sort(keys)
        for _, key in ipairs(keys) do
            local c = ns.db.chars[key]
            local profs = {}
            for _, p in pairs(c.profs or {}) do
                local n = 0
                for _ in pairs(p.recipes or {}) do n = n + 1 end
                profs[#profs + 1] = string.format("%s (%d)", p.name or "?", n)
            end
            table.sort(profs)
            print("  " .. ns.FactionIcon(c.faction) .. " " .. ns.ClassColorText(c.class, key) .. ": " .. table.concat(profs, ", "))
        end
    elseif cmd == "scan" or cmd == "escanear" then
        ns.ScanCurrentTradeSkill(false)
    elseif cmd == "mensajeyo" or cmd == "selfmessage" or cmd == "selfmsg" then
        if rest == "" then
            print(string.format(L.MSG_SELF_CURRENT, ns.db.settings.msgTemplateSelf or L.MSG_SELF_DEFAULT))
        elseif rest:lower() == "reset" then
            ns.db.settings.msgTemplateSelf = nil
            print(L.MSG_RESET)
        else
            ns.db.settings.msgTemplateSelf = rest
            print(L.MSG_SET)
        end
    elseif cmd == "debug" then
        ns.db.settings.debug = not ns.db.settings.debug
        print("|cff33ff99CraftCheck|r debug: " .. (ns.db.settings.debug and "ON" or "OFF"))
    elseif cmd == "mensaje" or cmd == "message" or cmd == "msg" then
        if rest == "" then
            print(string.format(L.MSG_CURRENT, ns.db.settings.msgTemplate or L.MSG_DEFAULT))
        elseif rest:lower() == "reset" then
            ns.db.settings.msgTemplate = nil
            print(L.MSG_RESET)
        else
            ns.db.settings.msgTemplate = rest
            print(L.MSG_SET)
        end
    else
        print(L.HELP)
    end
end

-------------------------------------------------------------------------------
-- Eventos
-------------------------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("TRADE_SKILL_SHOW")
frame:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
frame:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
frame:RegisterEvent("SKILL_LINES_CHANGED")
frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
local CHAT_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_CHANNEL", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_WHISPER", "CHAT_MSG_EMOTE",
}
for _, ev in ipairs(CHAT_EVENTS) do frame:RegisterEvent(ev) end

frame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "CHAT_MSG_WHISPER_INFORM" then
        SetLastWhisper(arg2, false, "sent whisper")
        return
    end
    if event:sub(1, 9) == "CHAT_MSG_" then
        OnChatMessage(arg1, arg2)
        return
    end
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        InitDB()
        ns.RebuildIndex()
        SLASH_CRAFTCHECK1 = "/cc"
        SLASH_CRAFTCHECK2 = "/craftcheck"
        SlashCmdList["CRAFTCHECK"] = SlashHandler
        if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
        end
        HookItemRefTooltip()
        HookChatFrames()
        ns.HookChatEditBoxes()
    elseif event == "PLAYER_LOGIN" then
        local c = ns.GetCharEntry()
        if c then PruneProfessions(c) end
        ns.RebuildIndex()
        if ns.UI_Init then ns.UI_Init() end
    elseif event == "CURRENCY_DISPLAY_UPDATE" or event == "PLAYER_LOGOUT" then
        ns.UpdateOwnConcentration()
    elseif event == "SKILL_LINES_CHANGED" then
        local c = ns.db and ns.playerKey and ns.db.chars[ns.playerKey]
        if c then PruneProfessions(c); ns.RebuildIndex() end
    elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" then
        QueueScan()
    end
end)
