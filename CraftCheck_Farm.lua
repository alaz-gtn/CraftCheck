-------------------------------------------------------------------------------
-- CraftCheck - módulo Farm: registro de sesiones de recolección
--  * Detecta Herboristería / Minería / Pesca por los lanzamientos del jugador
--  * Asigna el botín que llega justo después a esa categoría
--  * Ventana con sesión (empezar, pausar, continuar, finalizar), oro y oro/hora,
--    lista de objetos, historial de sesiones
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

-------------------------------------------------------------------------------
-- Idioma
-------------------------------------------------------------------------------
local L = setmetatable({}, { __index = function(_, k) return k end })
local locale = GetLocale()
if locale == "esES" or locale == "esMX" then
  L["Farm"] = "Farmeo"
  L["Start"] = "Empezar"
  L["Pause"] = "Pausar"
  L["Resume"] = "Continuar"
  L["Finish"] = "Finalizar"
  L["Reset"] = "Reiniciar"
  L["History"] = "Historial"
  L["Session"] = "Sesión"
  L["Back"] = "Volver"
  L["No session. Press Start and go gather."] = "Sin sesión. Pulsa Empezar y sal a recolectar."
  L["Paused"] = "En pausa"
  L["Auto-paused (no gathering)"] = "Pausa automática (sin recolectar)"
  L["Running"] = "En marcha"
  L["Total"] = "Total"
  L["per hour"] = "por hora"
  L["Herbalism"] = "Herboristería"
  L["Mining"] = "Minería"
  L["Fishing"] = "Pesca"
  L["herbs"] = "plantas"
  L["veins"] = "vetas"
  L["casts"] = "lances"
  L["Nothing gathered yet."] = "Todavía no has recogido nada."
  L["no price"] = "sin precio"
  L["Finish this session? It will be saved to the history."] = "¿Finalizar la sesión? Se guardará en el historial."
  L["Reset the current session? Everything gathered so far will be discarded."] = "¿Reiniciar la sesión? Se descartará todo lo recogido hasta ahora."
  L["Delete the whole farming history?"] = "¿Borrar todo el historial de farmeo?"
  L["Delete history"] = "Borrar historial"
  L["No sessions yet."] = "Aún no hay sesiones."
  L["Session finished: %s in %s (%s/h). Herbalism %s, Mining %s%s."] = "Sesión finalizada: %s en %s (%s/h). Herboristería %s, Minería %s%s."
  L[", Fishing %s"] = ", Pesca %s"
  L["Session resumed from your last login (paused)."] = "Sesión recuperada de tu última conexión (en pausa)."
  L["Count fishing"] = "Contar pesca"
  L["Auto-pause after %d min idle"] = "Pausa automática tras %d min sin recolectar"
  L["Prices: Auctionator (last scan)"] = "Precios: Auctionator (último escaneo)"
  L["Prices: own AH scan"] = "Precios: escaneo propio de la AH"
  L["Duration"] = "Duración"
  L["Character"] = "Personaje"
  L["Date"] = "Fecha"
  L["Gold"] = "Oro"
  L["items"] = "objetos"
end

-------------------------------------------------------------------------------
-- Constantes / utilidades
-------------------------------------------------------------------------------
local TAG = "|cff33ff99Farm|r|cffffd100Check|r"
local CATS = { "herb", "mine", "fish" }
local CAT_LABEL = { herb = L["Herbalism"], mine = L["Mining"], fish = L["Fishing"] }
local CAT_NODE = { herb = L["herbs"], mine = L["veins"], fish = L["casts"] }
local CAT_COLOR = { herb = "|cff7cff7c", mine = "|cffffb84d", fish = "|cff6cc9ff" }
local SKILL_HERB, SKILL_MINE, SKILL_FISH = 182, 186, 356
local GATHER_WINDOW = 5      -- s tras un lance para asignar el botín
local AUTO_PAUSE_MIN = 3     -- min sin recolectar

local GetItemInfoInstant = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)
local GetItemInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)

local function Money(c) return GetMoneyString(math.floor(c or 0), true) end
local function MoneyG(c)
  local v = math.floor(math.abs(c or 0) / 10000)
  local txt = BreakUpLargeNumbers and BreakUpLargeNumbers(v) or tostring(v)
  return txt .. "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t"
end
local function Price(itemID)
  if ns.ValueReagentPrice then return ns.ValueReagentPrice(itemID) end
  return nil
end
local function FormatDuration(secs)
  secs = math.floor(secs or 0)
  local h, m, s = math.floor(secs / 3600), math.floor(secs % 3600 / 60), secs % 60
  if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
  return string.format("%02d:%02d", m, s)
end
local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) end

local function DB()
  ns.db.farm = ns.db.farm or {}
  local f = ns.db.farm
  f.history = f.history or {}
  if f.fishing == nil then f.fishing = false end
  if f.autoPause == nil then f.autoPause = true end
  return f
end

-------------------------------------------------------------------------------
-- Sesión
-------------------------------------------------------------------------------
local function Session() return ns.db and ns.db.farm and ns.db.farm.active or nil end

local function Elapsed(s)
  if not s then return 0 end
  local e = s.elapsed or 0
  if not s.paused and s.lastResume then e = e + (time() - s.lastResume) end
  return e
end

local function SessionTotals(s)
  local totals = { herb = 0, mine = 0, fish = 0, total = 0, unpriced = 0 }
  if not s then return totals end
  for _, cat in ipairs(CATS) do
    for itemID, e in pairs(s.items[cat] or {}) do
      local p = Price(itemID)
      if p then
        totals[cat] = totals[cat] + p * e.count
      else
        totals.unpriced = totals.unpriced + 1
      end
    end
    totals.total = totals.total + totals[cat]
  end
  return totals
end

local function PerHour(gold, secs)
  if not secs or secs < 60 then return nil end
  return gold / (secs / 3600)
end

local Refresh -- UI

local function StartSession()
  local f = DB()
  f.active = {
    char = ns.playerKey, start = time(), elapsed = 0, paused = false, lastResume = time(),
    items = { herb = {}, mine = {}, fish = {} }, nodes = { herb = 0, mine = 0, fish = 0 }, lastGather = time(),
  }
  Refresh()
end

local function PauseSession(auto)
  local s = Session()
  if not s or s.paused then return end
  if auto then
    -- No contar el tiempo muerto desde la última recolección
    s.elapsed = (s.elapsed or 0) + math.max(0, (s.lastGather or time()) - (s.lastResume or time()))
  else
    s.elapsed = Elapsed(s)
  end
  s.paused = true
  s.autoPaused = auto and true or nil
  s.lastResume = nil
  Refresh()
end

local function ResumeSession()
  local s = Session()
  if not s or not s.paused then return end
  s.paused = false
  s.autoPaused = nil
  s.lastResume = time()
  s.lastGather = time()
  Refresh()
end

local function FinishSession()
  local s = Session()
  if not s then return end
  local f = DB()
  local dur = Elapsed(s)
  local t = SessionTotals(s)
  local nItems = 0
  local compact = {}
  for _, cat in ipairs(CATS) do
    compact[cat] = {}
    for itemID, e in pairs(s.items[cat] or {}) do
      compact[cat][itemID] = e.count
      nItems = nItems + e.count
    end
  end
  table.insert(f.history, 1, {
    t = time(), char = s.char, dur = dur, gold = t.total, herb = t.herb, mine = t.mine, fish = t.fish,
    nodes = s.nodes, items = compact, nItems = nItems,
  })
  while #f.history > 200 do table.remove(f.history) end
  f.active = nil
  local ph = PerHour(t.total, dur)
  print(TAG .. ": " .. string.format(L["Session finished: %s in %s (%s/h). Herbalism %s, Mining %s%s."],
    Money(t.total), FormatDuration(dur), ph and Money(ph) or "?", Money(t.herb), Money(t.mine),
    (f.fishing or t.fish > 0) and string.format(L[", Fishing %s"], Money(t.fish)) or ""))
  Refresh()
end

-------------------------------------------------------------------------------
-- Detección de recolección y botín
-------------------------------------------------------------------------------
local profNames = {}   -- nombres localizados de las profesiones de recolección del personaje
local function RefreshProfNames()
  wipe(profNames)
  local slots = { GetProfessions() }
  for i = 1, 5 do
    local idx = slots[i]
    if idx then
      local name, _, _, _, _, _, skillLine = GetProfessionInfo(idx)
      if name then
        if skillLine == SKILL_HERB then profNames.herb = name:lower()
        elseif skillLine == SKILL_MINE then profNames.mine = name:lower()
        elseif skillLine == SKILL_FISH then profNames.fish = name:lower() end
      end
    end
  end
end

local KEYWORDS = {
  herb = { "herb", "herbor", "kräuter", "herbes", "erbor", "ervas", "травн", "草药", "약초" },
  mine = { "mining", "miner", "bergbau", "minage", "estrazione", "mineração", "горн", "采矿", "채광" },
  fish = { "fishing", "pesca", "angeln", "pêche", "рыбн", "钓鱼", "낚시" },
}

local function CategoryForSpell(spellID)
  if not spellID or IsSecret(spellID) then return nil end
  local name
  if C_Spell and C_Spell.GetSpellName then
    local ok, n = pcall(C_Spell.GetSpellName, spellID)
    if ok then name = n end
  end
  if not name and C_Spell and C_Spell.GetSpellInfo then
    local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
    if ok and info then name = info.name end
  end
  if type(name) ~= "string" or IsSecret(name) then return nil end
  name = name:lower()
  for _, cat in ipairs(CATS) do
    local pn = profNames[cat]
    if pn and name:find(pn, 1, true) then return cat end
  end
  for _, cat in ipairs(CATS) do
    for _, kw in ipairs(KEYWORDS[cat]) do
      if name:find(kw, 1, true) then return cat end
    end
  end
  return nil
end

local gatherCat, gatherUntil = nil, 0

local function OnGather(cat)
  local s = Session()
  if not s then return end
  if cat == "fish" and not DB().fishing then return end
  if s.paused then
    if s.autoPaused then ResumeSession() else return end
  end
  gatherCat, gatherUntil = cat, GetTime() + GATHER_WINDOW
  s.nodes[cat] = (s.nodes[cat] or 0) + 1
  s.lastGather = time()
  Refresh()
end

local function OnLoot(msg, looterGUID)
  local s = Session()
  if not s or s.paused or not gatherCat or GetTime() > gatherUntil then return end
  if IsSecret(msg) or type(msg) ~= "string" then return end
  if looterGUID and not IsSecret(looterGUID) and looterGUID ~= "" and looterGUID ~= UnitGUID("player") then return end
  local link = msg:match("(|c[^|]-|Hitem:[^|]-|h%[.-%]|h|r)")
  if not link then return end
  local itemID = tonumber(link:match("item:(%d+)"))
  if not itemID then return end
  local count = tonumber(msg:match("|h|r%s*x(%d+)")) or 1
  local bucket = s.items[gatherCat]
  local e = bucket[itemID]
  if e then
    e.count = e.count + count
  else
    bucket[itemID] = { link = link, count = count }
  end
  gatherUntil = GetTime() + 3
  s.lastGather = time()
  Refresh()
end

-------------------------------------------------------------------------------
-- Ventana
-------------------------------------------------------------------------------
local frame, rows, slider
local NUM_ROWS, ROW_H, WIN_W = 12, 18, 440
local offset = 0
local lines = {}
local showHistory = false

local function BuildLines()
  wipe(lines)
  local s = Session()
  if showHistory then
    local hist = DB().history
    if #hist == 0 then
      lines[1] = { text = "|cffaaaaaa" .. L["No sessions yet."] .. "|r" }
      return
    end
    lines[1] = { text = string.format("|cffffd100%-16s %-14s %10s %12s %10s|r", L["Date"], L["Character"], L["Duration"], L["Gold"], L["per hour"]) }
    for _, h in ipairs(hist) do
      local ph = PerHour(h.gold, h.dur)
      local c = ns.db.chars[h.char or ""]
      local who = c and ns.ClassColorText(c.class, c.name) or (h.char or "?")
      lines[#lines + 1] = {
        entry = h,
        text = string.format("%s  %s  %s  %s  %s", date("%d/%m %H:%M", h.t), who, FormatDuration(h.dur), MoneyG(h.gold), ph and (MoneyG(ph) .. "/h") or "—"),
      }
    end
    return
  end
  if not s then
    lines[1] = { text = "|cffaaaaaa" .. L["No session. Press Start and go gather."] .. "|r" }
    return
  end
  local any = false
  for _, cat in ipairs(CATS) do
    if cat ~= "fish" or DB().fishing or next(s.items.fish or {}) then
      local list = {}
      for itemID, e in pairs(s.items[cat] or {}) do
        local p = Price(itemID)
        list[#list + 1] = { itemID = itemID, e = e, value = p and p * e.count or nil }
      end
      if #list > 0 then
        any = true
        table.sort(list, function(a, b)
          if (a.value ~= nil) ~= (b.value ~= nil) then return a.value ~= nil end
          if a.value and b.value then return a.value > b.value end
          return a.e.count > b.e.count
        end)
        local t = SessionTotals(s)
        lines[#lines + 1] = { text = CAT_COLOR[cat] .. CAT_LABEL[cat] .. "|r  |cffaaaaaa" .. (s.nodes[cat] or 0) .. " " .. CAT_NODE[cat] .. "|r  " .. MoneyG(t[cat]) }
        for _, it in ipairs(list) do
          local icon = GetItemInfoInstant and select(5, GetItemInfoInstant(it.itemID))
          local iconTxt = icon and string.format("|T%s:14:14|t ", icon) or ""
          lines[#lines + 1] = {
            itemID = it.itemID, link = it.e.link,
            text = "   " .. iconTxt .. it.e.link .. " x" .. it.e.count .. "  "
              .. (it.value and ("|cffffffff" .. Money(it.value) .. "|r") or ("|cff808080" .. L["no price"] .. "|r")),
          }
        end
      end
    end
  end
  if not any then lines[1] = { text = "|cffaaaaaa" .. L["Nothing gathered yet."] .. "|r" } end
end

local function UpdateList()
  local total = #lines
  local maxOffset = math.max(0, total - NUM_ROWS)
  if offset > maxOffset then offset = maxOffset end
  if offset < 0 then offset = 0 end
  slider:SetMinMaxValues(0, maxOffset)
  slider:SetValue(offset)
  slider:SetShown(maxOffset > 0)
  for i = 1, NUM_ROWS do
    local row, line = rows[i], lines[offset + i]
    if line then
      row.line = line
      row.text:SetText(line.text or "")
      row:Show()
    else
      row.line = nil
      row:Hide()
    end
  end
end

local function UpdateHeader()
  local s = Session()
  local f = DB()
  if showHistory then
    frame.status:SetText("|cffffd100" .. L["History"] .. "|r")
    frame.big:SetText("")
    frame.cats:SetText("")
    frame.btnStart:Hide(); frame.btnPause:Hide(); frame.btnFinish:Hide(); frame.btnReset:Hide()
    frame.btnHistory:SetText(L["Back"])
    frame.btnDelete:Show()
    return
  end
  frame.btnDelete:Hide()
  frame.btnHistory:SetText(L["History"])
  if not s then
    frame.status:SetText("|cffaaaaaa" .. L["No session. Press Start and go gather."] .. "|r")
    frame.big:SetText("")
    frame.cats:SetText("")
    frame.btnStart:Show(); frame.btnPause:Hide(); frame.btnFinish:Hide(); frame.btnReset:Hide()
    return
  end
  frame.btnStart:Hide(); frame.btnPause:Show(); frame.btnFinish:Show(); frame.btnReset:Show()
  frame.btnPause:SetText(s.paused and L["Resume"] or L["Pause"])
  local dur = Elapsed(s)
  local state = s.paused and (s.autoPaused and ("|cffff8000" .. L["Auto-paused (no gathering)"] .. "|r") or ("|cffffff00" .. L["Paused"] .. "|r")) or ("|cff00ff00" .. L["Running"] .. "|r")
  frame.status:SetText(string.format("|cffffd100%s:|r %s   %s", L["Session"], FormatDuration(dur), state))
  local t = SessionTotals(s)
  local ph = PerHour(t.total, dur)
  frame.big:SetText(string.format("|cffffd100%s:|r %s    |cffffd100%s:|r %s", L["Total"], MoneyG(t.total), L["per hour"], ph and MoneyG(ph) or "—"))
  local parts = {}
  for _, cat in ipairs(CATS) do
    if cat ~= "fish" or f.fishing or t.fish > 0 then
      local cph = PerHour(t[cat], dur)
      parts[#parts + 1] = string.format("%s%s|r %s (%s/h)", CAT_COLOR[cat], CAT_LABEL[cat], MoneyG(t[cat]), cph and MoneyG(cph) or "—")
    end
  end
  frame.cats:SetText(table.concat(parts, "    "))
end

Refresh = function()
  if not frame or not frame:IsShown() then return end
  UpdateHeader()
  BuildLines()
  UpdateList()
end

local function Confirm(text, onAccept)
  StaticPopupDialogs["CRAFTCHECK_FARM_CONFIRM"] = StaticPopupDialogs["CRAFTCHECK_FARM_CONFIRM"] or {
    button1 = YES, button2 = NO, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
  }
  local d = StaticPopupDialogs["CRAFTCHECK_FARM_CONFIRM"]
  d.text = text
  d.OnAccept = onAccept
  StaticPopup_Show("CRAFTCHECK_FARM_CONFIRM")
end

local function CreateWindow()
  frame = CreateFrame("Frame", "CraftCheckFarmFrame", UIParent, "BackdropTemplate")
  frame:SetSize(WIN_W, 150 + NUM_ROWS * ROW_H + 40)
  frame:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
  frame:SetFrameStrata("MEDIUM")
  frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  frame:SetBackdropColor(0.04, 0.04, 0.07, 0.94)
  frame:SetBackdropBorderColor(0.55, 0.45, 0.25, 1)
  frame:SetMovable(true); frame:EnableMouse(true); frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    DB().pos = { p, rp, x, y }
  end)
  frame:SetScript("OnShow", function()
    Refresh()
    if not frame.ticker then frame.ticker = C_Timer.NewTicker(1, function() UpdateHeader() end) end
  end)
  frame:SetScript("OnHide", function()
    if frame.ticker then frame.ticker:Cancel(); frame.ticker = nil end
  end)
  tinsert(UISpecialFrames, "CraftCheckFarmFrame")
  local pos = DB().pos
  if pos then frame:ClearAllPoints(); frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) end

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 14, -12); title:SetText(TAG)
  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -2, -2)

  local function Btn(text, w, x, onClick)
    local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    b:SetSize(w, 22); b:SetPoint("TOPLEFT", x, -40); b:SetText(text); b:SetScript("OnClick", onClick)
    return b
  end
  frame.btnStart = Btn(L["Start"], 90, 14, StartSession)
  frame.btnPause = Btn(L["Pause"], 90, 14, function()
    local s = Session()
    if not s then return end
    if s.paused then ResumeSession() else PauseSession(false) end
  end)
  frame.btnFinish = Btn(L["Finish"], 90, 108, function()
    Confirm(L["Finish this session? It will be saved to the history."], FinishSession)
  end)
  frame.btnReset = Btn(L["Reset"], 80, 202, function()
    Confirm(L["Reset the current session? Everything gathered so far will be discarded."], function() DB().active = nil; StartSession() end)
  end)
  frame.btnHistory = Btn(L["History"], 90, WIN_W - 104, function()
    showHistory = not showHistory
    offset = 0
    Refresh()
  end)
  frame.btnDelete = Btn(L["Delete history"], 120, 14, function()
    Confirm(L["Delete the whole farming history?"], function() wipe(DB().history); Refresh() end)
  end)
  frame.btnDelete:Hide()

  frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.status:SetPoint("TOPLEFT", 14, -70); frame.status:SetPoint("RIGHT", -14, 0); frame.status:SetJustifyH("LEFT")
  frame.big = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.big:SetPoint("TOPLEFT", 14, -90); frame.big:SetPoint("RIGHT", -14, 0); frame.big:SetJustifyH("LEFT")
  frame.cats = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.cats:SetPoint("TOPLEFT", 14, -114); frame.cats:SetPoint("RIGHT", -14, 0); frame.cats:SetJustifyH("LEFT")

  local sep = frame:CreateTexture(nil, "ARTWORK")
  sep:SetColorTexture(0.55, 0.45, 0.25, 0.8); sep:SetHeight(1)
  sep:SetPoint("TOPLEFT", 14, -136); sep:SetPoint("TOPRIGHT", -14, -136)

  local list = CreateFrame("Frame", nil, frame)
  list:SetPoint("TOPLEFT", 14, -142); list:SetPoint("RIGHT", -30, 0); list:SetHeight(NUM_ROWS * ROW_H)
  list:EnableMouseWheel(true)
  list:SetScript("OnMouseWheel", function(_, delta) offset = offset - delta * 3; UpdateList() end)
  rows = {}
  for i = 1, NUM_ROWS do
    local row = CreateFrame("Button", nil, list)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H); row:SetPoint("RIGHT", 0, 0)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.text:SetPoint("LEFT", 2, 0); row.text:SetPoint("RIGHT", -2, 0); row.text:SetJustifyH("LEFT"); row.text:SetWordWrap(false)
    row:EnableMouseWheel(true)
    row:SetScript("OnMouseWheel", function(_, delta) offset = offset - delta * 3; UpdateList() end)
    row:SetScript("OnEnter", function(self)
      local line = self.line
      if not line then return end
      if line.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(line.link); GameTooltip:Show()
      elseif line.entry then
        local h = line.entry
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(date("%d/%m/%Y %H:%M", h.t), 1, 0.82, 0)
        for _, cat in ipairs(CATS) do
          if (h[cat] or 0) > 0 or (h.nodes and (h.nodes[cat] or 0) > 0) then
            GameTooltip:AddDoubleLine(CAT_COLOR[cat] .. CAT_LABEL[cat] .. "|r  " .. ((h.nodes and h.nodes[cat]) or 0) .. " " .. CAT_NODE[cat], Money(h[cat] or 0), 1, 1, 1, 1, 1, 1)
          end
        end
        GameTooltip:AddLine((h.nItems or 0) .. " " .. L["items"], 0.7, 0.7, 0.7)
        GameTooltip:Show()
      end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:SetScript("OnClick", function(self)
      local line = self.line
      if line and line.link and IsModifiedClick("CHATLINK") and ns.InsertLink then ns.InsertLink(line.link) end
    end)
    rows[i] = row
  end

  slider = CreateFrame("Slider", nil, frame, "BackdropTemplate")
  slider:SetOrientation("VERTICAL"); slider:SetWidth(16)
  slider:SetPoint("TOPLEFT", list, "TOPRIGHT", 4, 0); slider:SetPoint("BOTTOMLEFT", list, "BOTTOMRIGHT", 4, 0)
  slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
  slider:SetBackdrop({ bgFile = "Interface\\Buttons\\UI-SliderBar-Background", edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 6, bottom = 6 } })
  slider:SetMinMaxValues(0, 0); slider:SetValueStep(1); slider:SetObeyStepOnDrag(true); slider:SetValue(0)
  slider:SetScript("OnValueChanged", function(_, value)
    local v = math.floor(value + 0.5)
    if v ~= offset then offset = v; UpdateList() end
  end)

  -- Opciones abajo
  local fishCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  fishCheck:SetSize(24, 24); fishCheck:SetPoint("BOTTOMLEFT", 10, 8)
  fishCheck:SetChecked(DB().fishing)
  fishCheck:SetScript("OnClick", function(self) DB().fishing = self:GetChecked() and true or false; Refresh() end)
  local fishLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fishLbl:SetPoint("LEFT", fishCheck, "RIGHT", 0, 0); fishLbl:SetText(L["Count fishing"])

  local apCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  apCheck:SetSize(24, 24); apCheck:SetPoint("LEFT", fishLbl, "RIGHT", 16, 0)
  apCheck:SetChecked(DB().autoPause)
  apCheck:SetScript("OnClick", function(self) DB().autoPause = self:GetChecked() and true or false end)
  local apLbl = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  apLbl:SetPoint("LEFT", apCheck, "RIGHT", 0, 0); apLbl:SetText(string.format(L["Auto-pause after %d min idle"], AUTO_PAUSE_MIN))

  local src = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  src:SetPoint("BOTTOMRIGHT", -14, 12)
  src:SetText((C_AddOns and C_AddOns.IsAddOnLoaded("Auctionator")) and L["Prices: Auctionator (last scan)"] or L["Prices: own AH scan"])

  frame:Hide()
end

function ns.FarmToggle()
  if not frame then CreateWindow() end
  if frame:IsShown() then frame:Hide() else showHistory = false; frame:Show() end
end

-------------------------------------------------------------------------------
-- Eventos
-------------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:RegisterEvent("SKILL_LINES_CHANGED")
ev:RegisterEvent("CHAT_MSG_LOOT")
pcall(ev.RegisterUnitEvent, ev, "UNIT_SPELLCAST_SUCCEEDED", "player")

ev:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    RefreshProfNames()
    local f = DB()
    local s = f.active
    if s then
      if not s.paused then
        -- La sesión estaba en marcha al desconectar: queda en pausa
        s.paused = true; s.lastResume = nil
      end
      if s.char and s.char ~= ns.playerKey then
        -- Sesión de otro personaje: se queda guardada en pausa hasta que ese personaje entre
      else
        print(TAG .. ": " .. L["Session resumed from your last login (paused)."])
        if not frame then CreateWindow() end
        frame:Show()
      end
    end
    -- Pausa automática
    C_Timer.NewTicker(10, function()
      local s2 = Session()
      if s2 and not s2.paused and DB().autoPause and s2.char == ns.playerKey
         and (time() - (s2.lastGather or time())) > AUTO_PAUSE_MIN * 60 then
        PauseSession(true)
      end
    end)
  elseif event == "PLAYER_LOGOUT" then
    local s = Session()
    if s and not s.paused then
      s.elapsed = Elapsed(s); s.paused = true; s.lastResume = nil
    end
  elseif event == "SKILL_LINES_CHANGED" then
    RefreshProfNames()
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local unit, _, spellID = ...
    if unit ~= "player" then return end
    local s = Session()
    if not s or s.char ~= ns.playerKey then return end
    local cat = CategoryForSpell(spellID)
    if cat then OnGather(cat) end
  elseif event == "CHAT_MSG_LOOT" then
    local msg = ...
    local guid = select(12, ...)
    OnLoot(msg, guid)
  end
end)
