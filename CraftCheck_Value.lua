-------------------------------------------------------------------------------
-- CraftCheck - módulo Value (antes addon independiente "CraftValue")
--  * Ventana de profesión: coste de reagentes a calidad máx. vs precio AH del objeto por ilvl.
--  * Tooltip de patrones/objetos fabricables: precio AH por ilvl, coste de reagentes y beneficio.
--  * Precios: Auctionator si está cargado; si no, escaneo propio con la AH abierta.
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

-- Compatibilidad con clientes donde las funciones globales de objeto ya no existen
local GetItemInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)
local GetItemInfoInstant = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo or (C_Item and C_Item.GetDetailedItemLevelInfo)

local TAG = "|cff33ff99CraftCheck|r Value"
local AH_CUT   = 0.95
local MAX_AGE  = 3600   -- s antes de rebuscar un precio si la AH esta abierta
local INTERVAL = 0.5    -- s entre busquedas en la AH


---------------------------------------------------------------------------
-- Idioma: ingles por defecto, espanol si el cliente es esES/esMX
---------------------------------------------------------------------------
local L = setmetatable({}, { __index = function(_, k) return k end })
local locale = GetLocale and GetLocale() or "enUS"
if locale == "esES" or locale == "esMX" then
  L["Difficulty"] = "Dificultad"
  L["Difficulty: no data (open the profession once)"] = "Dificultad: sin datos (abre la profesion una vez)"
  L["Reagents max quality"] = "Reagentes calidad max"
  L["Reagents"] = "Reagentes"
  L["missing"] = "sin precio"
  L["incomplete"] = "incompleto"
  L["Item"] = "Objeto"
  L["Binds when picked up: crafting orders only, not sold in the AH"] = "Se liga al recogerlo: solo órdenes de fabricación, no se vende en la AH"
  L["in AH"] = "en la AH"
  L["own scan"] = "escaneo propio"
  L["Profit (after 5%)"] = L["Profit (after 5%)"]
  L["no price in Auctionator (run Full Scan, or none listed)"] = "sin precio en Auctionator (haz Full Scan o no hay ninguno listado)"
  L["none listed"] = "ninguno listado"
  L["no data (Auctionator Full Scan or Scan AH)"] = "sin datos (Full Scan de Auctionator o Escanear AH)"
  L["Could not identify the crafted item (/cv debug)"] = L["Could not identify the crafted item (/cv debug)"]
  L["ilvl"] = "ilvl"
  L["Scan AH"] = "Escanear AH"
  L["Top"] = "Top"
  L["Recipe"] = "Receta"
  L["Cost"] = "Coste"
  L["AH"] = "AH"
  L["Profit"] = "Beneficio"
  L["Prices: Auctionator Full Scan. Press Top."] = "Precios: Full Scan de Auctionator. Pulsa Top."
  L["With the AH open: Scan AH. Then: Top."] = "Con la AH abierta: Escanear AH. Luego: Top."
  L["No recipes with ilvl %d in the AH and full cost. "] = "Sin recetas con ilvl %d en la AH y coste completo. "
  L["Run Full Scan in Auctionator."] = "Haz Full Scan en Auctionator."
  L["Scan first."] = "Escanea primero."
  L["%d recipes with ilvl %d listed in the AH."] = "%d recetas con ilvl %d listado en la AH."
  L["total"] = "en total"
  L["Scanning... %d/%d"] = "Escaneando... %d/%d"
  L["Processing AH... %d/%d"] = "Procesando AH... %d/%d"
  L["Full scan: %d items."] = "Escaneo completo: %d objetos."
  L["open the Auction House."] = "abre la Casa de Subastas."
  L["open the profession window."] = "abre la ventana de profesion."
  L["also open the Auction House."] = "abre tambien la Casa de Subastas."
  L["use Auctionator's Full Scan; CraftCheck reads its prices directly."] = "usa el Full Scan de Auctionator; CraftCheck lee sus precios directamente."
  L["Requesting the full AH..."] = "Pidiendo la AH completa..."
  L["No response: full scans are limited to one every ~15 min (Auctionator's counts)."] = "Sin respuesta: el escaneo completo esta limitado a uno cada ~15 min (cuenta el de Auctionator)."
  L["received %d auctions, processing..."] = "recibidas %d subastas, procesando..."
  L["full scan processed, %d items with price."] = "escaneo completo procesado, %d objetos con precio."
  L["scanning %d items/reagents (approx. %d min)..."] = "escaneando %d objetos/reagentes (aprox. %d min)..."
  L["scan finished (%d searches)."] = "escaneo terminado (%d busquedas)."
  L["%d merchant pattern(s) queued; they will be searched when you open the AH (%d pending)."] = "%d patron(es) del vendedor apuntados; se buscaran al abrir la AH (%d pendientes)."
  L["searching %d pending item(s) in the AH..."] = "buscando %d pendiente(s) en la AH..."
  L["cache cleared."] = "cache borrada."
  L["open the AH first."] = "abre la AH primero."
  L["%d pending. Commands: /cv top [n], /cv span N, /cv ilvl, /cv all (scan profession, with AH and profession open), /cv scan (resume), /cv reset"] = "%d pendiente(s). Comandos: /cv top [n], /cv span N, /cv ilvl, /cv all (escanear profesión, con AH y profesión abiertas), /cv scan (reanudar), /cv reset"
  L["loaded. /cv for help."] = "cargado. /cv para ayuda."
  L["could not register event %s (%s)"] = "no se pudo registrar el evento %s (%s)"
  L["could not hook the tooltip: %s"] = "no se pudo enganchar el tooltip: %s"
  L["error"] = "error"
  L["recipes by profit (sale at max ilvl in AH, after 5%, mats at max quality):"] = "recetas por beneficio (venta al ilvl max en AH, tras 5%, mats a calidad max):"
  L["%2d. %s (ilvl %d) sale %s, cost %s -> %s%s|r"] = "%2d. %s (ilvl %d) venta %s, coste %s -> %s%s|r"
  L["  no complete data: use 'Scan' with the AH open."] = "  sin datos completos: usa 'Escanear' con la AH abierta."
end

-- Datos persistentes: CraftCheckDB.value (se inicializa en ADDON_LOADED, cuando ya existen las SavedVariables)
local CraftValueDB = {}
local function InitValueDB()
    CraftCheckDB = CraftCheckDB or {}
    CraftCheckDB.value = CraftCheckDB.value or {}
    CraftValueDB = CraftCheckDB.value
    CraftValueDB.items = CraftValueDB.items or {}     -- [realm][itemID] = { levels = {[ilvl]=minPrice}, when = t }
    CraftValueDB.names = CraftValueDB.names or {}     -- [nombre en minúsculas] = { itemIDs }
    CraftValueDB.recipes = CraftValueDB.recipes or {} -- [char][itemID fabricado] = info de la receta
    CraftValueDB.ilvl = CraftValueDB.ilvl or 232
end
InitValueDB()

local win                   -- panel lateral de la ventana de profesión (se crea al cargar Blizzard_Professions)
local currentRecipeID
local recipeByOutput = {}   -- [itemID fabricado] = recipeID (profesion abierta)
local queue, queued = {}, {}      -- entradas { itemID = n } o { name = s }
local pending                     -- entrada en curso
local scanTotal = 0
local hooked = false
local ShowTop, UpdateStatusProgress, InvalidateTooltipCache = function() end, function() end, function() end

---------------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------------
local function Money(c) return c and GetMoneyString(math.floor(c), true) or "?" end
-- oro y plata, sin cobre (para la tabla)
local function MoneyGS(c)
  if not c then return "?" end
  local neg = c < 0
  local v = math.floor(math.abs(c) / 100) * 100
  return (neg and "-" or "") .. GetMoneyString(v, true)
end
local function AHOpen() return AuctionHouseFrame and AuctionHouseFrame:IsShown() end
local function RealmItems()
  local realm = GetRealmName() or "?"
  CraftValueDB.items[realm] = CraftValueDB.items[realm] or {}
  return CraftValueDB.items[realm]
end
local function Cache(itemID) return RealmItems()[itemID] end
local function IsStale(c) return not c or (time() - (c.when or 0)) > MAX_AGE end

local function BestLevel(c)
  if not c or not c.levels then return nil end
  local bl, bp
  for ilvl, price in pairs(c.levels) do if not bl or ilvl > bl then bl, bp = ilvl, price end end
  return bl, bp
end

local function MinPrice(c)
  if not c or not c.levels then return nil end
  local m
  for _, price in pairs(c.levels) do if not m or price < m then m = price end end
  return m
end

local function SortedLevels(c)
  local t = {}
  for ilvl, price in pairs(c.levels) do table.insert(t, { ilvl = ilvl, price = price }) end
  table.sort(t, function(a, b) return a.ilvl > b.ilvl end)
  return t
end

local function HasAuctionator()
  return C_AddOns and C_AddOns.IsAddOnLoaded("Auctionator") or (Auctionator ~= nil)
end
local function AuctionatorDB()
  return Auctionator and Auctionator.Database and Auctionator.Database.GetPrice and Auctionator.Database
end

-- Precio de un reagente: Auctionator primero, si no la cache propia
local function ReagentPrice(itemID)
  if Auctionator and Auctionator.API and Auctionator.API.v1 then
    local ok, ap = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, "CraftCheck", itemID)
    if ok and ap then return ap end
  end
  return MinPrice(Cache(itemID))
end

-- Precio del objeto fabricado a un ilvl concreto.
-- Auctionator guarda el equipo (Armor/Weapon/Profession) como "g:itemID:ilvl" en su Full Scan.
-- Devuelve precio, fuente ("auctionator"/"propio"), timestamp (solo propio)
local function ItemLevelPrice(itemID, ilvl)
  local adb = AuctionatorDB()
  if adb then
    local ok, p = pcall(adb.GetPrice, adb, "g:" .. itemID .. ":" .. ilvl)
    if ok and p then return p, "auctionator" end
  end
  local c = Cache(itemID)
  if c and c.levels and c.levels[ilvl] then return c.levels[ilvl], "propio", c.when end
  return nil, HasAuctionator() and "auctionator" or (c and "propio" or nil), c and c.when
end

-- ¿El objeto se liga al recogerlo? (no se puede vender en la AH: solo órdenes de fabricación)
local function IsBoP(itemID)
    if not itemID then return false end
    local bindType = select(14, GetItemInfo(itemID))
    if bindType == nil then return false end
    local onAcquire = (Enum and Enum.ItemBind and Enum.ItemBind.OnAcquire) or 1
    return bindType == onAcquire
end

local function ReagentQuality(itemID)
  local ok, q = pcall(C_TradeSkillUI.GetItemReagentQualityByItemInfo, itemID)
  return ok and q or 0
end

-- De un nombre de reagente, el itemID de mayor calidad conocido
local function BestItemForName(name)
  local ids = CraftValueDB.names[name:lower()]
  if not ids then
    local _, link = GetItemInfo(name)
    return link and GetItemInfoInstant(link)
  end
  local best, bq = nil, -1
  for _, id in ipairs(ids) do
    local q = ReagentQuality(id)
    if q > bq or (q == bq and id > (best or 0)) then best, bq = id, q end
  end
  return best
end

---------------------------------------------------------------------------
-- Cola de busquedas en la AH
---------------------------------------------------------------------------
local function Enqueue(entry)
  if HasAuctionator() then return end   -- con Auctionator los precios salen de su Full Scan
  local key = entry.itemID or ("n:" .. entry.name:lower())
  if queued[key] then return end
  queued[key] = true
  table.insert(queue, entry)
end

local function RunQueue()
  if pending or not AHOpen() then return end
  local e = table.remove(queue, 1)
  if not e then
    if scanTotal > 0 then
      print(TAG .. ": " .. string.format(L["scan finished (%d searches)."], scanTotal))
      scanTotal = 0
      if win and win:IsShown() then ShowTop() end
    end
    return
  end
  queued[e.itemID or ("n:" .. (e.name or ""):lower())] = nil
  local name = e.name or GetItemInfo(e.itemID)
  if not name then
    C_Item.RequestLoadItemDataByID(e.itemID)
    Enqueue(e)
    C_Timer.After(INTERVAL, RunQueue)
    return
  end
  pending = e
  pending.search = name
  C_AuctionHouse.SendBrowseQuery({ searchString = name, sorts = {}, filters = {}, itemClassFilters = {} })
end

local function HarvestBrowse()
  if not pending then return end
  local now = time()
  local seen, byName = {}, {}
  for _, r in ipairs(C_AuctionHouse.GetBrowseResults() or {}) do
    local id = r.itemKey and r.itemKey.itemID
    if id then
      local items = RealmItems()
      local c = items[id]
      if not seen[id] then
        c = { levels = {}, when = now }
        items[id] = c
        seen[id] = true
      end
      local ilvl = r.itemKey.itemLevel or 0
      if not c.levels[ilvl] or r.minPrice < c.levels[ilvl] then c.levels[ilvl] = r.minPrice end
      local n = GetItemInfo(id)
      if n then
        n = n:lower()
        byName[n] = byName[n] or {}
        table.insert(byName[n], id)
      end
    end
  end
  for n, ids in pairs(byName) do CraftValueDB.names[n] = ids end
  -- el item buscado, si no aparecio, queda marcado como "no hay ninguno"
  if pending.itemID and not seen[pending.itemID] then
    RealmItems()[pending.itemID] = { levels = {}, when = now }
  end
  pending = nil
  InvalidateTooltipCache()
  UpdateStatusProgress()
  C_Timer.After(INTERVAL, RunQueue)
end

---------------------------------------------------------------------------
-- Recetas conocidas
---------------------------------------------------------------------------
local function BestReagents(recipeID)
  local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
  if not schematic then return nil end
  local out = {}
  for _, slot in ipairs(schematic.reagentSlotSchematics) do
    if slot.reagentType == Enum.CraftingReagentType.Basic and slot.required and slot.reagents and #slot.reagents > 0 then
      table.insert(out, { itemID = slot.reagents[#slot.reagents].itemID, qty = slot.quantityRequired or 1 })
    end
  end
  return out
end

local function MatsCost(recipeID)
  local reagents = BestReagents(recipeID)
  if not reagents then return nil end
  local total, lines, missing = 0, {}, {}
  for _, r in ipairs(reagents) do
    local price = ReagentPrice(r.itemID)
    if price then
      total = total + price * r.qty
      table.insert(lines, { itemID = r.itemID, qty = r.qty, price = price })
    else
      table.insert(missing, r.itemID)
    end
  end
  return total, lines, missing
end

local function OutputItemID(recipeID)
  local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
  if not info then return nil end
  local data = C_TradeSkillUI.GetRecipeOutputItemData(recipeID, nil, nil, info.maxQuality or 1)
  if data and data.itemID then return data.itemID end
  local link = C_TradeSkillUI.GetRecipeItemLink(recipeID)
  if link then return GetItemInfoInstant(link) end
end

local function KnownRecipes()
  local out = {}
  for _, id in ipairs(C_TradeSkillUI.GetAllRecipeIDs() or {}) do
    local info = C_TradeSkillUI.GetRecipeInfo(id)
    if info and info.learned and info.craftable ~= false and not info.isRecraft
       and info.isSalvageRecipe ~= true and info.isEnchantingRecipe ~= true then
      table.insert(out, id)
    end
  end
  return out
end

-- Encola objeto + reagentes de una receta (solo los que falten o esten viejos)
local function EnqueueRecipe(recipeID, force)
  local out = OutputItemID(recipeID)
  if out and (force or IsStale(Cache(out))) then Enqueue({ itemID = out }) end
  for _, r in ipairs(BestReagents(recipeID) or {}) do
    if force or IsStale(Cache(r.itemID)) then Enqueue({ itemID = r.itemID }) end
  end
end

function ns.ValueScanProfession()
  if not (ProfessionsFrame and ProfessionsFrame:IsShown()) then print(TAG .. ": " .. L["open the profession window."]) return end
  if not AHOpen() then print(TAG .. ": " .. L["also open the Auction House."]) return end
  for _, id in ipairs(KnownRecipes()) do EnqueueRecipe(id, true) end
  scanTotal = #queue
  print(TAG .. ": " .. string.format(L["scanning %d items/reagents (approx. %d min)..."], scanTotal, math.ceil(scanTotal * INTERVAL / 60)))
  RunQueue()
end

function ns.ValueTop(limit)
  if not (ProfessionsFrame and ProfessionsFrame:IsShown()) then print(TAG .. ": " .. L["open the profession window."]) return end
  local rows = {}
  for _, id in ipairs(KnownRecipes()) do
    local out = OutputItemID(id)
    local bl, bp = BestLevel(out and Cache(out))
    local cost, _, missing = MatsCost(id)
    if bl and cost and cost > 0 and #missing == 0 then
      table.insert(rows, { name = C_TradeSkillUI.GetRecipeInfo(id).name, ilvl = bl, price = bp, cost = cost, profit = bp * AH_CUT - cost })
    end
  end
  table.sort(rows, function(a, b) return a.profit > b.profit end)
  print(TAG .. ": " .. L["recipes by profit (sale at max ilvl in AH, after 5%, mats at max quality):"])
  for i = 1, math.min(limit or 15, #rows) do
    local r = rows[i]
    local color = r.profit >= 0 and "|cff40ff40" or "|cffff4040"
    print(string.format(L["%2d. %s (ilvl %d) sale %s, cost %s -> %s%s|r"], i, r.name, r.ilvl, Money(r.price), Money(r.cost), color, Money(r.profit)))
  end
  if #rows == 0 then print(L["  no complete data: use 'Scan' with the AH open."]) end
end

---------------------------------------------------------------------------
-- Tooltip de patrones
---------------------------------------------------------------------------
local lastTooltipData   -- para /cv debug
local lastCraftedID     -- para /cv probe

local function ParseRecipeTooltip(data)
  local craftedID, reagentText
  for _, line in ipairs(data.lines or {}) do
    if TooltipUtil and TooltipUtil.SurfaceArgs then pcall(TooltipUtil.SurfaceArgs, line) end
    if line.args then
      for _, a in ipairs(line.args) do
        if a.field and line[a.field] == nil then line[a.field] = a.intVal or a.stringVal or a.boolVal end
      end
    end
    if not craftedID then
      -- bloque anidado con el objeto fabricado: varios nombres de campo posibles
      if line.type == Enum.TooltipDataLineType.NestedBlock then
        local isItem = (line.tooltipType == nil) or (line.tooltipType == Enum.TooltipDataType.Item)
        if isItem then craftedID = line.tooltipID or line.itemID or line.id end
      end
      -- o un enlace de objeto en el texto
      if not craftedID and line.leftText then
        local id = line.leftText:match("|Hitem:(%d+)")
        if id then craftedID = tonumber(id) end
      end
    end
    if line.leftText and not reagentText then
      if line.leftText:find("%(%d+%)") and line.leftText:find(",") and not line.leftText:find("^Requires") then
        reagentText = line.leftText
      end
    end
  end
  return craftedID, reagentText
end

function ns.ValueDebug()
  if not lastTooltipData then print(TAG .. ": pasa el raton por un patron primero.") return end
  print(TAG .. " debug: item " .. tostring(lastTooltipData.id))
  for i, line in ipairs(lastTooltipData.lines or {}) do
    local parts = {}
    for k, v in pairs(line) do
      if type(v) ~= "table" then table.insert(parts, k .. "=" .. tostring(v):gsub("|", "||"):sub(1, 40)) end
    end
    print(i .. ": " .. table.concat(parts, "  "))
  end
end

local function ReagentsFromText(text)
  local list = {}
  for raw in text:gmatch("[^,]+") do
    local chunk = strtrim(raw)
    local name, qty = chunk:match("^(.-)%s*%((%d+)%)$")
    table.insert(list, { name = name or chunk, qty = tonumber(qty) or 1 })
  end
  return list
end


local DIFF_COLOR = { [0] = "ff8040", [1] = "ffff00", [2] = "40ff40", [3] = "808080" }
local function AddSkillLine(tooltip, craftedID)
  local char = UnitName("player") .. "-" .. GetRealmName()
  local r = CraftValueDB.recipes[char] and CraftValueDB.recipes[char][craftedID]
  if not r then
    tooltip:AddLine(L["Difficulty: no data (open the profession once)"], 0.6, 0.6, 0.6)
    return nil
  end
  local col = DIFF_COLOR[r.difficulty] or "ffffff"
  tooltip:AddLine("|cff" .. col .. L["Difficulty"] .. "|r", 1, 1, 1)
  return r
end

-- Seccion de precios del objeto en la AH + beneficio (comun a ambos casos)
-- "ilvl 232" o el icono de calidad de la receta si sabemos que calidad da ese ilvl
local TIER_ILVL = { [206] = 1, [212] = 2, [218] = 3, [225] = 4, [232] = 5 }  -- tier de Midnight

local function IlvlLabel(craftedID, ilvl)
  local q
  -- 1) si la receta registrada dice que calidad da ese ilvl, usarla
  local char = UnitName("player") .. "-" .. GetRealmName()
  local r = CraftValueDB.recipes[char] and CraftValueDB.recipes[char][craftedID]
  if r and r.qlevels then
    for qq, lv in pairs(r.qlevels) do if lv == ilvl then q = qq end end
  end
  -- 2) si no, la tabla fija del tier actual
  q = q or TIER_ILVL[ilvl]
  if q then
    -- varias vias segun version del cliente
    if C_Texture and C_Texture.GetCraftingReagentQualityChatIcon then
      local ok, icon = pcall(C_Texture.GetCraftingReagentQualityChatIcon, q)
      if ok and type(icon) == "string" and icon ~= "" then return icon end
    end
    if Professions and Professions.GetChatIconMarkupForQuality then
      local ok, icon = pcall(Professions.GetChatIconMarkupForQuality, q)
      if ok and type(icon) == "string" and icon ~= "" then return icon end
    end
    local atlas = "Professions-ChatIcon-Quality-Tier" .. q
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) and CreateAtlasMarkup then
      return CreateAtlasMarkup(atlas, 16, 16)
    end
    local atlas2 = "Professions-Icon-Quality-Tier" .. q .. "-Inv"
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas2) and CreateAtlasMarkup then
      return CreateAtlasMarkup(atlas2, 16, 16)
    end
  end
  return L["ilvl"] .. " " .. ilvl
end

local function AddAHSection(tooltip, craftedID, cost, complete)
  if IsBoP(craftedID) then
    tooltip:AddLine(L["Binds when picked up: crafting orders only, not sold in the AH"], 0.6, 0.6, 0.6)
    return
  end
  local ilvl = CraftValueDB.ilvl or 232
  local label = IlvlLabel(craftedID, ilvl)
  local price, src, when = ItemLevelPrice(craftedID, ilvl)
  if price then
    local tag = src == "propio" and (" (" .. L["own scan"] .. " " .. date("%d/%m %H:%M", when) .. ")") or ""
    tooltip:AddDoubleLine(L["Item"] .. " " .. label .. " " .. L["in AH"] .. tag, Money(price), 1, 0.82, 0, 1, 1, 1)
    if cost and complete then
      local profit = price * AH_CUT - cost
      tooltip:AddDoubleLine(L["Profit (after 5%)"], Money(profit), 1, 0.82, 0, profit >= 0 and 0.25 or 1, profit >= 0 and 1 or 0.25, 0.25)
    end
  elseif src == "auctionator" then
    tooltip:AddLine(L["Item"] .. " " .. label .. ": " .. L["no price in Auctionator (run Full Scan, or none listed)"], 1, 0.5, 0.5)
  elseif src == "propio" then
    tooltip:AddLine(L["Item"] .. " " .. label .. ": " .. L["none listed"] .. " (" .. date("%d/%m %H:%M", when) .. ")", 1, 0.5, 0.5)
  else
    tooltip:AddLine(L["Item"] .. " " .. label .. ": " .. L["no data (Auctionator Full Scan or Scan AH)"], 1, 0.5, 0.5)
  end
  -- sin Auctionator, apuntar para la busqueda propia
  if not HasAuctionator() then
    if IsStale(Cache(craftedID)) then Enqueue({ itemID = craftedID }) end
    if AHOpen() then RunQueue() end
  end
end

-- Objeto fabricado por una receta que conoces (lista de la profesion, bolsa, AH...)
local function KnownRecipeTooltip(tooltip, itemID, recipeID)
  tooltip:AddLine(" ")
  tooltip:AddLine(TAG)
  AddSkillLine(tooltip, itemID)
  local cost, lines, missing = MatsCost(recipeID)
  if cost then
    for _, id in ipairs(missing) do if IsStale(Cache(id)) then Enqueue({ itemID = id }) end end
    tooltip:AddDoubleLine(L["Reagents max quality"] .. (#missing == 0 and "" or " (|cffff4040" .. #missing .. " " .. L["missing"] .. "|r)"), Money(cost), 1, 0.82, 0, 1, 1, 1)
  end
  AddAHSection(tooltip, itemID, cost, cost and #missing == 0)
end

-- Cache de lo que se pinta en el tooltip: evita recalcular en cada frame
local ttCache = {}          -- [itemID] = { when = t, lines = { {kind,...} } }
local TT_TTL = 3
local capture              -- cuando esta activo, las AddLine se guardan aqui

InvalidateTooltipCache = function() wipe(ttCache) end

local recorder = {}
function recorder:AddLine(text, r, g, b)
  table.insert(capture, { "L", text, r, g, b })
end
function recorder:AddDoubleLine(l, rr, r1, g1, b1, r2, g2, b2)
  table.insert(capture, { "D", l, rr, r1, g1, b1, r2, g2, b2 })
end

local function Replay(tooltip, lines)
  for _, ln in ipairs(lines) do
    if ln[1] == "L" then tooltip:AddLine(ln[2], ln[3], ln[4], ln[5])
    else tooltip:AddDoubleLine(ln[2], ln[3], ln[4], ln[5], ln[6], ln[7], ln[8], ln[9]) end
  end
end

local BuildTooltip -- definida abajo

local function OnItemTooltip(tooltip, data)
  if not data or not data.id then return end
  local c = ttCache[data.id]
  if c and (GetTime() - c.when) < TT_TTL then
    Replay(tooltip, c.lines)
    return
  end
  capture = {}
  local ok, err = pcall(BuildTooltip, recorder, data)
  if not ok then table.insert(capture, { "L", TAG .. " |cffff4040" .. L["error"] .. ":|r " .. tostring(err), 1, 1, 1 }) end
  ttCache[data.id] = { when = GetTime(), lines = capture }
  Replay(tooltip, capture)
  capture = nil
end

BuildTooltip = function(tooltip, data)
  local _, _, _, _, _, classID = GetItemInfoInstant(data.id)
  if classID ~= Enum.ItemClass.Recipe then
    if recipeByOutput[data.id] then KnownRecipeTooltip(tooltip, data.id, recipeByOutput[data.id]) end
    return
  end
  lastTooltipData = data
  local craftedID, reagentText = ParseRecipeTooltip(data)

  tooltip:AddLine(" ")
  tooltip:AddLine(TAG)
  if not craftedID then
    tooltip:AddLine(L["Could not identify the crafted item (/cv debug)"], 1, 0.5, 0.5)
    return
  end
  lastCraftedID = craftedID
  local rec = AddSkillLine(tooltip, craftedID)
  if rec and rec.recipeID and C_TradeSkillUI.GetRecipeSchematic(rec.recipeID, false) then
    -- reagentes exactos (calidad max) desde la receta registrada
    local cost, lines, missing = MatsCost(rec.recipeID)
    if cost then
      for _, id in ipairs(missing) do if IsStale(Cache(id)) then Enqueue({ itemID = id }) end end
      tooltip:AddDoubleLine(L["Reagents max quality"] .. (#missing == 0 and "" or " (|cffff4040" .. #missing .. " " .. L["missing"] .. "|r)"), Money(cost), 1, 0.82, 0, 1, 1, 1)
      AddAHSection(tooltip, craftedID, cost, #missing == 0)
      return
    end
  end

  local cost, complete = 0, true
  if reagentText then
    local rows = ReagentsFromText(reagentText)
    for _, r in ipairs(rows) do
      local id = BestItemForName(r.name)
      local price = id and ReagentPrice(id)
      local missingN = 0
      if price then cost = cost + price * r.qty else complete = false; missingN = missingN + 1 end
      if not HasAuctionator() and (not id or IsStale(Cache(id))) then Enqueue({ name = r.name }) end
    end
    tooltip:AddDoubleLine(L["Reagents"] .. (complete and "" or " (|cffff4040" .. L["incomplete"] .. "|r)"), Money(cost), 1, 0.82, 0, 1, 1, 1)
  end

  AddAHSection(tooltip, craftedID, reagentText and cost or nil, reagentText and complete)
end


---------------------------------------------------------------------------
-- Ventana (visible con la profesion abierta)
---------------------------------------------------------------------------
local ROW_H, BASE_H, MAX_ROWS_VISIBLE, WIN_W = 20, 150, 20, 660
local COL_NAME, COL_MONEY = 250, 110

-- ilvl que produce cada calidad (1..5) de una receta
local function RecipeQualityLevels(recipeID)
  local out = {}
  for q = 1, 5 do
    local ok, d = pcall(C_TradeSkillUI.GetRecipeOutputItemData, recipeID, nil, nil, q)
    if ok and d and d.hyperlink then
      local lv = GetDetailedItemLevelInfo(d.hyperlink)
      if lv and lv > 0 then out[q] = lv end
    end
  end
  return out
end

-- ¿La receta es del tier del ilvl objetivo? (alguna calidad lo da, o el objeto base
-- esta a menos de `span` niveles; la API no devuelve fiablemente las calidades altas)
local function RecipeHasIlvl(recipeID, ilvl)
  local span = CraftValueDB.span or 30
  local levels = RecipeQualityLevels(recipeID)
  local base
  for _, lv in pairs(levels) do
    if lv == ilvl then return true end
    if not base or lv < base then base = lv end
  end
  return base ~= nil and base <= ilvl and (ilvl - base) <= span
end

local function TopRows(ilvl)
  local rows = {}
  for _, id in ipairs(KnownRecipes()) do
    local out = OutputItemID(id)
    local price = out and ItemLevelPrice(out, ilvl)
    local cost, _, missing = MatsCost(id)
    if cost and cost > 0 and #missing == 0 and RecipeHasIlvl(id, ilvl) then
      table.insert(rows, { recipeID = id, name = C_TradeSkillUI.GetRecipeInfo(id).name,
                           price = price, cost = cost, profit = price and (price * AH_CUT - cost) or nil })
    end
  end
  table.sort(rows, function(a, b)
    if (a.profit ~= nil) ~= (b.profit ~= nil) then return a.profit ~= nil end
    if a.profit and b.profit then return a.profit > b.profit end
    return a.cost < b.cost
  end)
  return rows
end

local function SetStatus(txt) if win then win.status:SetText(txt or "") end end

ShowTop = function()
  if ns.OnOrderRecorded then ns.OnOrderRecorded() end
  local ilvl = tonumber(win.ilvlBox:GetText()) or CraftValueDB.ilvl
  CraftValueDB.ilvl = ilvl
  local rows = TopRows(ilvl)
  -- reutilizar/crear filas
  for i, r in ipairs(rows) do
    local row = win.rows[i]
    if not row then
      row = CreateFrame("Button", nil, win.content)
      row:SetHeight(ROW_H)
      row:SetPoint("LEFT", 0, 0); row:SetPoint("RIGHT", 0, 0)
      row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      row.name:SetPoint("LEFT", 2, 0); row.name:SetWidth(COL_NAME); row.name:SetJustifyH("LEFT"); row.name:SetWordWrap(false)
      row.cost = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      row.cost:SetPoint("LEFT", row.name, "RIGHT", 4, 0); row.cost:SetWidth(COL_MONEY); row.cost:SetJustifyH("RIGHT")
      row.price = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      row.price:SetPoint("LEFT", row.cost, "RIGHT", 4, 0); row.price:SetWidth(COL_MONEY); row.price:SetJustifyH("RIGHT")
      row.profit = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      row.profit:SetPoint("LEFT", row.price, "RIGHT", 4, 0); row.profit:SetWidth(COL_MONEY); row.profit:SetJustifyH("RIGHT")
      row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
      row:SetScript("OnClick", function(b) if b.recipeID then C_TradeSkillUI.OpenRecipe(b.recipeID) end end)
      win.rows[i] = row
    end
    row:SetPoint("TOP", 0, -(i - 1) * ROW_H)
    row.recipeID = r.recipeID
    row.name:SetText(i .. ". " .. r.name)
    row.cost:SetText(MoneyGS(r.cost))
    row.price:SetText(r.price and MoneyGS(r.price) or "|cff808080—|r")
    row.profit:SetText(r.profit and ((r.profit >= 0 and "|cff40ff40" or "|cffff4040") .. MoneyGS(r.profit) .. "|r") or "|cff808080—|r")
    row:Show()
  end
  for i = #rows + 1, #win.rows do win.rows[i]:Hide() end

  local n = #rows
  win.content:SetHeight(math.max(n * ROW_H, 1))
  local visible = math.min(n, MAX_ROWS_VISIBLE)
  win.scroll:SetHeight(math.max(visible * ROW_H, 1))
  win:SetHeight(BASE_H + (n > 0 and (visible * ROW_H + 26) or 0))
  win.header:SetShown(n > 0)
  if n == 0 then
    SetStatus(string.format(L["No recipes with ilvl %d in the AH and full cost. "], ilvl) .. (HasAuctionator() and L["Run Full Scan in Auctionator."] or L["Scan first."]))
  else
    local priced = 0
    for _, r in ipairs(rows) do if r.price then priced = priced + 1 end end
    SetStatus(string.format(L["%d recipes with ilvl %d listed in the AH."], priced, ilvl) .. " (" .. n .. " " .. L["total"] .. ")")
  end
end

local function BuildWindow()
  win = CreateFrame("Frame", "CraftCheckValueWindow", ProfessionsFrame, "BackdropTemplate")
  win:SetSize(WIN_W, BASE_H)
  win:SetPoint("TOPLEFT", ProfessionsFrame, "TOPRIGHT", 4, 0)
  win:SetFrameStrata("HIGH")
  win:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  win:SetBackdropColor(0.04, 0.04, 0.07, 0.96)
  win:SetBackdropBorderColor(0.55, 0.45, 0.25, 1)
  win:SetMovable(true); win:EnableMouse(true); win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", win.StartMoving); win:SetScript("OnDragStop", win.StopMovingOrSizing)
  win.rows = {}

  local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 14, -12); title:SetText(TAG)

  local lbl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lbl:SetPoint("TOPLEFT", 14, -44); lbl:SetText(L["ilvl"] .. ":")
  win.ilvlBox = CreateFrame("EditBox", nil, win, "InputBoxTemplate")
  win.ilvlBox:SetSize(52, 22); win.ilvlBox:SetPoint("LEFT", lbl, "RIGHT", 10, 0)
  win.ilvlBox:SetAutoFocus(false); win.ilvlBox:SetNumeric(true); win.ilvlBox:SetMaxLetters(4)
  win.ilvlBox:SetText(tostring(CraftValueDB.ilvl))
  win.ilvlBox:SetScript("OnEnterPressed", function(b) b:ClearFocus(); ShowTop() end)
  win.ilvlBox:SetScript("OnEscapePressed", function(b) b:ClearFocus() end)

  local anchor = win.ilvlBox
  if not HasAuctionator() then
    win.btnScan = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    win.btnScan:SetSize(110, 22); win.btnScan:SetPoint("LEFT", win.ilvlBox, "RIGHT", 12, 0); win.btnScan:SetText(L["Scan AH"])
    win.btnScan:SetScript("OnClick", function() ns.ValueFullScan() end)
    anchor = win.btnScan
  end

  win.btnTop = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
  win.btnTop:SetSize(110, 22); win.btnTop:SetPoint("LEFT", anchor, "RIGHT", anchor == win.ilvlBox and 12 or 6, 0); win.btnTop:SetText(L["Top"])
  win.btnTop:SetScript("OnClick", ShowTop)

  win.status = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  win.status:SetPoint("TOPLEFT", 14, -74); win.status:SetPoint("RIGHT", -14, 0); win.status:SetJustifyH("LEFT")
  win.status:SetText(HasAuctionator() and L["Prices: Auctionator Full Scan. Press Top."] or L["With the AH open: Scan AH. Then: Top."])

  -- Órdenes completadas por este personaje
  win.orders = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  win.orders:SetPoint("TOPLEFT", 14, -94); win.orders:SetPoint("RIGHT", -14, 0); win.orders:SetJustifyH("LEFT")
  win.ordersGroup = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  win.ordersGroup:SetPoint("TOPLEFT", 14, -112); win.ordersGroup:SetPoint("RIGHT", -14, 0); win.ordersGroup:SetJustifyH("LEFT")
  ns.OnOrderRecorded = function()
    if not win then return end
    local CL = ns.L or {}
    local stats = ns.FormatOrderStats(ns.GetOrderStats(ns.playerKey)) or CL.ORDERS_NONE or ""
    win.orders:SetText("|cffffd100" .. (CL.ORDERS_LABEL or "Orders") .. ":|r " .. stats)
    local n, gold = ns.OrderTotalForGroup()
    win.ordersGroup:SetText("|cffffd100" .. (CL.ORDERS_GROUP or "Realm group total") .. ":|r "
      .. n .. " " .. (CL.ORDERS_UNIT or "orders") .. " (" .. ns.MoneyGold(gold) .. ")")
  end
  ns.OnOrderRecorded()

  win.header = CreateFrame("Frame", nil, win)
  win.header:SetPoint("TOPLEFT", 14, -134); win.header:SetPoint("RIGHT", -30, 0); win.header:SetHeight(ROW_H)
  local function H(text, anchorTo, width, justify)
    local fsH = win.header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if anchorTo then fsH:SetPoint("LEFT", anchorTo, "RIGHT", 4, 0) else fsH:SetPoint("LEFT", 2, 0) end
    fsH:SetWidth(width); fsH:SetJustifyH(justify); fsH:SetText(text)
    return fsH
  end
  local h1 = H(L["Recipe"], nil, COL_NAME, "LEFT")
  local h2 = H(L["Cost"], h1, COL_MONEY, "RIGHT")
  local h3 = H(L["AH"], h2, COL_MONEY, "RIGHT")
  H(L["Profit"], h3, COL_MONEY, "RIGHT")
  win.header:Hide()

  win.scroll = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
  win.scroll:SetPoint("TOPLEFT", 14, -156); win.scroll:SetPoint("RIGHT", -30, 0); win.scroll:SetHeight(1)
  win.content = CreateFrame("Frame", nil, win.scroll)
  win.content:SetSize(WIN_W - 50, 1)
  win.scroll:SetScript("OnMouseWheel", function(self, delta)
    local cur = self:GetVerticalScroll()
    local maxV = self:GetVerticalScrollRange()
    local newV = math.max(0, math.min(maxV, cur - delta * ROW_H * 3))
    self:SetVerticalScroll(newV)
  end)
  win.scroll:SetScrollChild(win.content)
  win:Hide()

  -- Boton integrado en la ventana de profesion que despliega/oculta el panel
  local toggle = CreateFrame("Button", "CraftCheckValueToggle", ProfessionsFrame, "UIPanelButtonTemplate")
  toggle:SetSize(90, 22)
  toggle:SetText("CraftCheck")
  if ProfessionsFrame.TabSystem then
    toggle:SetPoint("LEFT", ProfessionsFrame.TabSystem, "RIGHT", 10, 0)
  else
    toggle:SetPoint("TOPRIGHT", ProfessionsFrame, "TOPRIGHT", -40, -28)
  end
  toggle:SetFrameStrata("HIGH")
  toggle:SetScript("OnClick", function()
    win:SetShown(not win:IsShown())
    CraftValueDB.winOpen = win:IsShown()
    if win:IsShown() then ShowTop() end
  end)
  win.toggle = toggle

  -- Solo en la pestaña de Recetas: al pasar a Especializaciones u Órdenes se ocultan panel y botón
  local page = ProfessionsFrame.CraftingPage
  if page then
    page:HookScript("OnHide", function()
      toggle:Hide()
      if win:IsShown() then
        win.hiddenByTab = true
        win:Hide()
      end
    end)
    page:HookScript("OnShow", function()
      toggle:Show()
      if win.hiddenByTab then
        win.hiddenByTab = nil
        win:Show()
        C_Timer.After(0.2, ShowTop)
      end
    end)
    toggle:SetShown(page:IsShown())
  end

  if CraftValueDB.winOpen then win:Show(); C_Timer.After(0.5, ShowTop) end
end

UpdateStatusProgress = function()
  if not win or not win:IsShown() then return end
  if scanTotal > 0 then SetStatus(string.format(L["Scanning... %d/%d"], scanTotal - #queue, scanTotal)) end
end



---------------------------------------------------------------------------
-- Escaneo completo de la AH (ReplicateItems): mismo mecanismo que Auctionator
---------------------------------------------------------------------------
local fs = { running = false, index = 0, total = 0, results = {}, retry = {}, retries = 0 }
local FS_CHUNK = 1500
local fsFrame = CreateFrame("Frame")
fsFrame:Hide()

local function FSRecord(itemID, ilvl, unit)
  local e = fs.results[itemID]
  if not e then e = { levels = {} }; fs.results[itemID] = e end
  if not e.levels[ilvl] or unit < e.levels[ilvl] then e.levels[ilvl] = unit end
end

local function FSProcessIndex(i)
  local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID, hasAllInfo = C_AuctionHouse.GetReplicateItemInfo(i)
  if not itemID or not buyout or buyout <= 0 or not count or count <= 0 then return true end
  local unit = buyout / count
  local link = C_AuctionHouse.GetReplicateItemLink(i)
  if not link then
    if not hasAllInfo then return false end   -- reintentar mas tarde
    FSRecord(itemID, 0, unit)
    return true
  end
  local ilvl = GetDetailedItemLevelInfo(link) or 0
  FSRecord(itemID, ilvl, unit)
  return true
end

local function FSFinish()
  fs.running = false
  fsFrame:Hide()
  local now, n = time(), 0
  local items = RealmItems()
  for itemID, e in pairs(fs.results) do
    items[itemID] = { levels = e.levels, when = now }
    n = n + 1
  end
  -- nombres -> ids (para patrones con reagentes solo por nombre)
  for itemID in pairs(fs.results) do
    local nm = GetItemInfo(itemID)
    if nm then
      nm = nm:lower()
      local ids = CraftValueDB.names[nm]
      if not ids then CraftValueDB.names[nm] = { itemID }
      elseif not tContains(ids, itemID) then table.insert(ids, itemID) end
    end
  end
  wipe(fs.results)
  InvalidateTooltipCache()
  print(TAG .. ": " .. string.format(L["full scan processed, %d items with price."], n))
  SetStatus(string.format(L["Full scan: %d items."], n))
  if win and win:IsShown() then ShowTop() end
end

fsFrame:SetScript("OnUpdate", function()
  if not fs.running then fsFrame:Hide() return end
  if fs.index < fs.total then
    local stop = math.min(fs.index + FS_CHUNK, fs.total)
    for i = fs.index, stop - 1 do
      if not FSProcessIndex(i) then table.insert(fs.retry, i) end
    end
    fs.index = stop
    SetStatus(string.format(L["Processing AH... %d/%d"], fs.index, fs.total))
    return
  end
  -- pendientes por falta de info del objeto
  if #fs.retry > 0 and fs.retries < 4 then
    fs.retries = fs.retries + 1
    local pendingList = fs.retry
    fs.retry = {}
    fs.running = false
    fsFrame:Hide()
    C_Timer.After(1, function()
      fs.running = true
      fs.total = 0; fs.index = 0
      for _, i in ipairs(pendingList) do
        if not FSProcessIndex(i) then table.insert(fs.retry, i) end
      end
      if #fs.retry > 0 and fs.retries < 4 then fsFrame:Show() else FSFinish() end
    end)
    return
  end
  FSFinish()
end)

local function OnReplicateReceived()
  if HasAuctionator() then return end   -- Auctionator ya procesa este mismo escaneo
  fs.total = C_AuctionHouse.GetNumReplicateItems() or 0
  if fs.total == 0 then return end
  fs.index, fs.retries = 0, 0
  wipe(fs.results); wipe(fs.retry)
  fs.running = true
  wipe(queue); wipe(queued)   -- el escaneo completo hace innecesaria la cola
  print(TAG .. ": " .. string.format(L["received %d auctions, processing..."], fs.total))
  fsFrame:Show()
end

function ns.ValueFullScan()
  if not AHOpen() then print(TAG .. ": " .. L["open the Auction House."]) return end
  if HasAuctionator() then print(TAG .. ": " .. L["use Auctionator's Full Scan; CraftCheck reads its prices directly."]) return end
  SetStatus(L["Requesting the full AH..."])
  C_AuctionHouse.ReplicateItems()
  C_Timer.After(20, function()
    if not fs.running and fs.total == 0 then
      SetStatus(L["No response: full scans are limited to one every ~15 min (Auctionator's counts)."])
    end
  end)
end

---------------------------------------------------------------------------
-- Vendedor: al abrirlo, apuntar el objeto fabricado por cada patron
---------------------------------------------------------------------------
local function ScanMerchant()
  if HasAuctionator() then return end
  if not C_TooltipInfo or not C_TooltipInfo.GetMerchantItem then return end
  local n, added = GetMerchantNumItems(), 0
  for i = 1, n do
    local link = GetMerchantItemLink(i)
    local itemID = link and GetItemInfoInstant(link)
    if itemID then
      local _, _, _, _, _, classID = GetItemInfoInstant(itemID)
      if classID == Enum.ItemClass.Recipe then
        local data = C_TooltipInfo.GetMerchantItem(i)
        local craftedID = data and ParseRecipeTooltip(data)
        if craftedID and IsStale(Cache(craftedID)) then
          local before = #queue
          Enqueue({ itemID = craftedID })
          if #queue > before then added = added + 1 end
        end
      end
    end
  end
  if added > 0 then
    print(TAG .. ": " .. string.format(L["%d merchant pattern(s) queued; they will be searched when you open the AH (%d pending)."], added, #queue))
  end
end

---------------------------------------------------------------------------
-- Eventos
---------------------------------------------------------------------------
local okTT, errTT = pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Item, OnItemTooltip)
if not okTT then print(TAG .. " |cffff4040error|r: " .. string.format(L["could not hook the tooltip: %s"], tostring(errTT))) end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",
                     "AUCTION_HOUSE_BROWSE_RESULTS_ADDED", "TRADE_SKILL_LIST_UPDATE", "MERCHANT_SHOW",
                     "REPLICATE_ITEM_LIST_UPDATE" }) do
  local ok, err = pcall(ev.RegisterEvent, ev, e)
  if not ok then print(TAG .. " |cffff4040error|r: " .. string.format(L["could not register event %s (%s)"], e, tostring(err))) end
end
local function OnEvent(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    -- las SavedVariables se cargan después de ejecutar el archivo: enlazar con CraftCheckDB.value
    InitValueDB()
  elseif event == "ADDON_LOADED" and arg1 == "Blizzard_Professions" then
    if hooked then return end
    hooked = true
    BuildWindow()
    hooksecurefunc(ProfessionsFrame.CraftingPage.SchematicForm, "Init", function(_, recipeInfo)
      currentRecipeID = recipeInfo and recipeInfo.recipeID
      if currentRecipeID and AHOpen() then EnqueueRecipe(currentRecipeID, false); RunQueue() end
    end)
  elseif event == "AUCTION_HOUSE_SHOW" then
    if #queue > 0 then
      print(TAG .. ": " .. string.format(L["searching %d pending item(s) in the AH..."], #queue))
      C_Timer.After(1, RunQueue)
    end
  elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
    HarvestBrowse()
  elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
    OnReplicateReceived()
  elseif event == "MERCHANT_SHOW" then
    C_Timer.After(0.5, ScanMerchant)   -- dar tiempo a que carguen los objetos
  elseif event == "TRADE_SKILL_LIST_UPDATE" then
    local prof = C_TradeSkillUI.GetBaseProfessionInfo and C_TradeSkillUI.GetBaseProfessionInfo()
    local profName = prof and prof.professionName or "?"
    local char = UnitName("player") .. "-" .. GetRealmName()
    CraftValueDB.recipes[char] = CraftValueDB.recipes[char] or {}
    local mine = CraftValueDB.recipes[char]
    wipe(recipeByOutput)
    for _, id in ipairs(C_TradeSkillUI.GetAllRecipeIDs() or {}) do
      local info = C_TradeSkillUI.GetRecipeInfo(id)
      if info and not info.isRecraft and info.isSalvageRecipe ~= true then
        local out = OutputItemID(id)
        if out then
          if info.learned then recipeByOutput[out] = id end
          local qlevels = RecipeQualityLevels(id)
          mine[out] = {
            recipeID = id, prof = profName, learned = info.learned and true or false,
            canSkillUp = info.canSkillUp, skillUps = info.skillUps, firstCraft = info.firstCraft,
            difficulty = info.relativeDifficulty, qlevels = qlevels, when = time(),
          }
        end
      end
    end
  end
end
ev:SetScript("OnEvent", function(self, event, arg1)
  local ok, err = pcall(OnEvent, self, event, arg1)
  if not ok then print(TAG .. " |cffff4040" .. L["error"] .. "|r (" .. event .. "): " .. tostring(err)) end
end)



function ns.ValueProbe(arg)
  arg = arg or ""
  local itemID = tonumber(arg) or tonumber(arg:match("|Hitem:(%d+)"))
  if not itemID and arg == "" then itemID = lastCraftedID end
  if not itemID then
    local ids = CraftValueDB.names[arg:lower()]
    if ids then itemID = ids[1] else local _, link = GetItemInfo(arg); itemID = link and GetItemInfoInstant(link) end
  end
  if not itemID then print(TAG .. ": no encuentro ese objeto; usa el itemID (esta en el enlace del objeto).") return end
  print(TAG .. " probe: itemID " .. itemID .. " (" .. tostring(GetItemInfo(itemID)) .. ")")
  if not AUCTIONATOR_PRICE_DATABASE then print("  AUCTIONATOR_PRICE_DATABASE no existe (Auctionator no cargado?)") return end
  local pat = "^" .. itemID
  local found = 0
  for realm, tbl in pairs(AUCTIONATOR_PRICE_DATABASE) do
    if type(tbl) == "table" then
      for k, v in pairs(tbl) do
        local ks = tostring(k)
        if ks == tostring(itemID) or ks:match(pat .. "[^%d]") or ks:match("^g:" .. itemID .. ":") then
          found = found + 1
          local desc = {}
          if type(v) == "table" then
            for f, val in pairs(v) do
              if type(val) == "table" then
                local n = 0; for _ in pairs(val) do n = n + 1 end
                table.insert(desc, f .. "=tabla(" .. n .. ")")
              else
                table.insert(desc, f .. "=" .. tostring(val))
              end
            end
          else
            table.insert(desc, tostring(v))
          end
          print("  [" .. tostring(realm) .. "] clave '" .. ks .. "': " .. table.concat(desc, " "))
        end
      end
    end
  end
  if found == 0 then print("  ninguna entrada para ese itemID en la base de datos de Auctionator") end
  if Auctionator and Auctionator.API and Auctionator.API.v1 then
    local ok, p = pcall(Auctionator.API.v1.GetAuctionPriceByItemID, "CraftCheck", itemID)
    print("  API GetAuctionPriceByItemID: " .. tostring(ok and p))
  end
end

SLASH_CRAFTCHECKVALUE1 = "/cv"
SlashCmdList.CRAFTCHECKVALUE = function(msg)
  msg = strtrim(msg or "")
  if msg == "reset" then
    CraftValueDB.items[GetRealmName() or "?"] = {}
    print(TAG .. ": " .. L["cache cleared."])
  elseif msg == "scan" then
    if AHOpen() then RunQueue() else print(TAG .. ": " .. L["open the AH first."]) end
  elseif msg == "full" then
    ns.ValueFullScan()
  elseif msg == "all" then
    ns.ValueScanProfession()
  elseif msg == "debug" then
    ns.ValueDebug()
  elseif msg:match("^span") then
    local n = tonumber(msg:match("%d+"))
    if n then CraftValueDB.span = n end
    print(TAG .. ": span = " .. tostring(CraftValueDB.span or 30))
  elseif msg == "ilvl" then
    if not currentRecipeID then print(TAG .. ": selecciona una receta.") return end
    local info = C_TradeSkillUI.GetRecipeInfo(currentRecipeID)
    print(TAG .. " " .. tostring(info and info.name) .. " maxQuality=" .. tostring(info and info.maxQuality))
    for q = 1, 5 do
      local ok, d = pcall(C_TradeSkillUI.GetRecipeOutputItemData, currentRecipeID, nil, nil, q)
      print("  q" .. q .. ": " .. (ok and d and d.hyperlink and (tostring(GetDetailedItemLevelInfo(d.hyperlink)) .. " " .. d.hyperlink) or ("sin datos " .. tostring(ok and d))))
    end
  elseif msg:match("^probe") then
    ns.ValueProbe(strtrim(msg:sub(6)))
  elseif msg:match("^top") then
    ns.ValueTop(tonumber(msg:match("%d+")) or 15)
  else
    print(TAG .. ": " .. string.format(L["%d pending. Commands: /cv top [n], /cv span N, /cv ilvl, /cv all (scan profession, with AH and profession open), /cv scan (resume), /cv reset"], #queue))
  end
end

if C_AddOns.IsAddOnLoaded("Blizzard_Professions") and not hooked then
  ev:GetScript("OnEvent")(ev, "ADDON_LOADED", "Blizzard_Professions")
end

