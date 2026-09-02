-------------------------------------------------------------------------------
-- CraftCheck - panel de profesiones por grupo de reinos y botón de minimapa
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local L = ns.L

local ROW_HEIGHT = 20
local NUM_ROWS   = 24
local FRAME_W    = 640
local INDENT     = 18
local MSG_BTN_W  = 56

local frame, rows, slider, listFrame, searchBox, searchHint, onlyGroupCheck, gearOnlyCheck, msgBox
local lines      = {}     -- filas visibles calculadas
local expanded   = {}     -- clave -> true/false (estado de despliegue en esta sesión)
local offset     = 0
local searchText = ""

-------------------------------------------------------------------------------
-- Utilidades
-------------------------------------------------------------------------------
local function IconText(icon, size)
    size = size or 14
    if type(icon) == "number" then
        return string.format("|T%d:%d:%d|t", icon, size, size)
    elseif type(icon) == "string" and icon ~= "" then
        return string.format("|T%s:%d:%d|t", icon, size, size)
    end
    return ""
end

local function IsExpanded(key, default)
    local v = expanded[key]
    if v == nil then return default end
    return v
end

local function PassesFilter(r)
    if not ns.db.settings.gearOnly then return true end
    return ns.IsEpicGear(r)
end

local function CountRecipes(p)
    local n = 0
    for _, r in pairs(p.recipes or {}) do
        if PassesFilter(r) then n = n + 1 end
    end
    return n
end

local function GetItemLink(recipe)
    local link = recipe.maxLink or recipe.link
    if link and link:find("|H", 1, true) then return link end
    local itemID = recipe.items and recipe.items[1]
    if itemID and C_Item and C_Item.GetItemInfo then
        local _, l = C_Item.GetItemInfo(itemID)
        if l then return l end
    end
    return link
end

-------------------------------------------------------------------------------
-- Construcción de la lista
-------------------------------------------------------------------------------
local function BuildLines()
    wipe(lines)
    local db = ns.db
    if not db then return end
    local onlyGroup = db.settings.onlyGroup
    local search = searchText:lower()

    -- Mapa reino normalizado -> nombre mostrado
    local realmDisplay = {}
    for _, c in pairs(db.chars) do
        if c.realm and c.realmDisplay then realmDisplay[c.realm] = c.realmDisplay end
    end

    ---------------------------------------------------------------- Búsqueda
    if search ~= "" then
        local results = {}
        for charKey, c in pairs(db.chars) do
            if not onlyGroup or ns.currentGroupSet[c.realm] then
                for profID, p in pairs(c.profs or {}) do
                    for recipeID, r in pairs(p.recipes or {}) do
                        if r.name and r.name:lower():find(search, 1, true) and PassesFilter(r) then
                            results[#results + 1] = {
                                kind = "item", indent = 0,
                                char = c, charKey = charKey, prof = p, recipe = r, recipeID = recipeID,
                                sortKey = r.name:lower(),
                            }
                        end
                    end
                end
            end
        end
        table.sort(results, function(a, b)
            if a.sortKey ~= b.sortKey then return a.sortKey < b.sortKey end
            return a.char.name < b.char.name
        end)
        for _, e in ipairs(results) do
            local c, r, p = e.char, e.recipe, e.prof
            local conc = ns.ConcentrationText(p, r.exp, e.charKey == ns.playerKey)
            e.text = string.format("%s %s  |cff888888-|r  %s %s|cffaaaaaa-%s|r |cffffd100(%s)|r%s",
                IconText(r.icon), ns.QualityName(r),
                ns.FactionIcon(c.faction), ns.ClassColorText(c.class, c.name),
                realmDisplay[c.realm] or c.realm or "?", p.name or "?",
                conc and ("  " .. conc) or "")
            lines[#lines + 1] = e
        end
        if #lines == 0 then
            lines[1] = { kind = "info", indent = 0, text = "|cffaaaaaa" .. L.NO_RESULTS .. "|r" }
        end
        return
    end

    ---------------------------------------------------------------- Árbol
    local groups = {}
    for charKey, c in pairs(db.chars) do
        if not onlyGroup or ns.currentGroupSet[c.realm] then
            local gk = c.groupKey or c.realm or "?"
            local g = groups[gk]
            if not g then
                g = { key = gk, realms = c.groupRealms or { c.realm }, chars = {} }
                groups[gk] = g
            end
            g.chars[#g.chars + 1] = { key = charKey, c = c }
        end
    end
    local glist = {}
    for _, g in pairs(groups) do glist[#glist + 1] = g end
    table.sort(glist, function(a, b) return a.key < b.key end)

    if #glist == 0 then
        lines[1] = { kind = "info", indent = 0, text = "|cffaaaaaa" .. L.NO_DATA .. "|r" }
        return
    end

    for _, g in ipairs(glist) do
        local gkey = "g:" .. g.key
        local gexp = IsExpanded(gkey, true)
        local names = {}
        for _, r in ipairs(g.realms) do names[#names + 1] = realmDisplay[r] or r end
        lines[#lines + 1] = {
            kind = "group", key = gkey, defExp = true, indent = 0,
            text = (gexp and "|cffffd100[-]|r " or "|cffffd100[+]|r ")
                .. "|cffffd100" .. string.format(L.REALM_GROUP, table.concat(names, ", ")) .. "|r"
                .. "  |cffaaaaaa(" .. string.format(L.CHARS, #g.chars) .. ")|r",
        }
        if gexp then
            table.sort(g.chars, function(a, b) return a.c.name < b.c.name end)
            for _, ch in ipairs(g.chars) do
                local c = ch.c
                local ckey = "c:" .. ch.key
                local cexp = IsExpanded(ckey, true)
                local profList = {}
                for profID, p in pairs(c.profs or {}) do
                    local n = CountRecipes(p)
                    if n > 0 or not ns.db.settings.gearOnly then
                        profList[#profList + 1] = { id = profID, p = p, n = n }
                    end
                end
                table.sort(profList, function(a, b) return (a.p.name or "") < (b.p.name or "") end)
                local profNames = {}
                for _, pr in ipairs(profList) do profNames[#profNames + 1] = pr.p.name or "?" end

                lines[#lines + 1] = {
                    kind = "char", key = ckey, defExp = true, indent = 1, charKey = ch.key,
                    text = (cexp and "[-] " or "[+] ")
                        .. ns.FactionIcon(c.faction) .. " " .. ns.ClassColorText(c.class, c.name)
                        .. "|cffaaaaaa-" .. (realmDisplay[c.realm] or c.realm or "?") .. "|r"
                        .. (ch.key == ns.playerKey and (" |cff00ff00" .. L.YOU .. "|r") or "")
                        .. "  |cffaaaaaa" .. table.concat(profNames, ", ") .. "|r",
                }
                if cexp then
                    for _, pr in ipairs(profList) do
                        local pkey = "p:" .. ch.key .. ":" .. tostring(pr.id)
                        local pexp = IsExpanded(pkey, false)
                        local profConc = ns.ConcentrationText(pr.p, nil, ch.key == ns.playerKey)
                        lines[#lines + 1] = {
                            kind = "prof", key = pkey, defExp = false, indent = 2,
                            text = (pexp and "[-] " or "[+] ") .. IconText(pr.p.icon)
                                .. " |cffffd100" .. (pr.p.name or "?") .. "|r"
                                .. "  |cffaaaaaa(" .. string.format(L.RECIPES, pr.n) .. ")|r"
                                .. (profConc and ("   " .. profConc) or ""),
                        }
                        if pexp then
                            local rl = {}
                            for recipeID, r in pairs(pr.p.recipes or {}) do
                                if PassesFilter(r) then rl[#rl + 1] = { id = recipeID, r = r } end
                            end
                            table.sort(rl, function(a, b) return (a.r.name or "") < (b.r.name or "") end)
                            for _, e in ipairs(rl) do
                                lines[#lines + 1] = {
                                    kind = "item", indent = 3,
                                    char = c, charKey = ch.key, prof = pr.p, recipe = e.r, recipeID = e.id,
                                    text = IconText(e.r.icon) .. " " .. ns.QualityName(e.r),
                                }
                            end
                        end
                    end
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Pintado de filas
-------------------------------------------------------------------------------
local function UpdateList()
    if not frame then return end
    local total = #lines
    local maxOffset = math.max(0, total - NUM_ROWS)
    if offset > maxOffset then offset = maxOffset end
    if offset < 0 then offset = 0 end
    slider:SetMinMaxValues(0, maxOffset)
    slider:SetValue(offset)
    if maxOffset > 0 then slider:Show() else slider:Hide() end

    for i = 1, NUM_ROWS do
        local row = rows[i]
        local line = lines[offset + i]
        if line then
            row.line = line
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", row, "LEFT", 4 + (line.indent or 0) * INDENT, 0)
            row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            row.text:SetText(line.text or "")
            row:Show()
        else
            row.line = nil
            row:Hide()
        end
    end
end

local function Rebuild()
    BuildLines()
    UpdateList()
end

-------------------------------------------------------------------------------
-- Eventos de fila
-------------------------------------------------------------------------------
local function Row_OnClick(self, button)
    local line = self.line
    if not line then return end
    if line.kind == "item" then
        local link = GetItemLink(line.recipe)
        if IsModifiedClick("CHATLINK") then
            if link then ns.InsertLink(link) end
        elseif line.charKey then
            local itemID = line.recipe.items and line.recipe.items[1]
            ns.WhisperMessage(line.charKey, itemID, link)
        end
    elseif line.key then
        expanded[line.key] = not IsExpanded(line.key, line.defExp)
        Rebuild()
    end
end

local function Row_OnEnter(self)
    local line = self.line
    if not line or line.kind ~= "item" then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local r = line.recipe
    local shown = false
    if r.maxLink and r.maxLink:find("|H", 1, true) then
        GameTooltip:SetHyperlink(r.maxLink)
        shown = true
    elseif r.items and r.items[1] then
        GameTooltip:SetItemByID(r.items[1])
        shown = true
    elseif r.link and r.link:find("|H", 1, true) then
        GameTooltip:SetHyperlink(r.link)
        shown = true
    end
    if not shown then
        GameTooltip:SetText(r.name or "?")
    end
    if not ns.db.settings.tooltip then
        -- El tooltip global está desactivado: añadimos aquí el fabricante igualmente
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(ns.FormatCrafterLine({ char = line.char, prof = line.prof, isMe = (line.charKey == ns.playerKey) }), 1, 1, 1)
    end
    GameTooltip:Show()
end

local function Row_OnLeave(self)
    GameTooltip:Hide()
end


-------------------------------------------------------------------------------
-- Creación del panel
-------------------------------------------------------------------------------
local function CreatePanel()
    frame = CreateFrame("Frame", "CraftCheckFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_W, 70 + NUM_ROWS * ROW_HEIGHT + 84)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnShow", function()
        if ns.RefreshCurrentGroup then ns.RefreshCurrentGroup() end
        Rebuild()
    end)
    frame:Hide()
    tinsert(UISpecialFrames, "CraftCheckFrame")

    -- Título
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -18)
    title:SetText(L.PANEL_TITLE)

    -- Botón cerrar
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

    -- Caja de búsqueda
    searchBox = CreateFrame("EditBox", "CraftCheckSearchBox", frame, "InputBoxTemplate")
    searchBox:SetSize(200, 22)
    searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 26, -48)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(60)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    searchBox:SetScript("OnTextChanged", function(self, userInput)
        local t = strtrim(self:GetText() or "")
        if t ~= searchText then
            searchText = t
            offset = 0
            Rebuild()
        end
        if searchHint then searchHint:SetShown(t == "") end
    end)
    searchHint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchHint:SetPoint("LEFT", searchBox, "LEFT", 4, 0)
    searchHint:SetText(L.SEARCH)

    -- Casilla "Solo mi grupo de reinos"
    onlyGroupCheck = CreateFrame("CheckButton", "CraftCheckOnlyGroupCheck", frame, "UICheckButtonTemplate")
    onlyGroupCheck:SetSize(26, 26)
    onlyGroupCheck:SetPoint("LEFT", searchBox, "RIGHT", 16, 0)
    onlyGroupCheck:SetChecked(ns.db.settings.onlyGroup)
    onlyGroupCheck:SetScript("OnClick", function(self)
        ns.db.settings.onlyGroup = self:GetChecked() and true or false
        offset = 0
        Rebuild()
    end)
    local checkLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    checkLabel:SetPoint("LEFT", onlyGroupCheck, "RIGHT", 2, 0)
    checkLabel:SetText(L.ONLY_GROUP)

    -- Casilla "Solo equipo épico"
    gearOnlyCheck = CreateFrame("CheckButton", "CraftCheckGearOnlyCheck", frame, "UICheckButtonTemplate")
    gearOnlyCheck:SetSize(26, 26)
    gearOnlyCheck:SetPoint("LEFT", checkLabel, "RIGHT", 12, 0)
    gearOnlyCheck:SetChecked(ns.db.settings.gearOnly)
    gearOnlyCheck:SetScript("OnClick", function(self)
        ns.db.settings.gearOnly = self:GetChecked() and true or false
        offset = 0
        Rebuild()
    end)
    local gearLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    gearLabel:SetPoint("LEFT", gearOnlyCheck, "RIGHT", 2, 0)
    gearLabel:SetText(L.GEAR_ONLY)

    -- Contenedor de lista
    listFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    listFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -80)
    listFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -40, 66)
    listFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    listFrame:SetBackdropColor(0, 0, 0, 0.5)
    listFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    listFrame:EnableMouseWheel(true)
    listFrame:SetScript("OnMouseWheel", function(self, delta)
        offset = offset - delta * 3
        UpdateList()
    end)

    -- Filas
    rows = {}
    for i = 1, NUM_ROWS do
        local row = CreateFrame("Button", nil, listFrame)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 6, -6 - (i - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", listFrame, "RIGHT", -6, 0)
        row:RegisterForClicks("LeftButtonUp")
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)
        row.text:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row:SetScript("OnClick", Row_OnClick)
        row:SetScript("OnEnter", Row_OnEnter)
        row:SetScript("OnLeave", Row_OnLeave)

        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(self, delta)
            offset = offset - delta * 3
            UpdateList()
        end)
        rows[i] = row
    end

    -- Barra de desplazamiento
    slider = CreateFrame("Slider", nil, frame, "BackdropTemplate")
    slider:SetOrientation("VERTICAL")
    slider:SetWidth(16)
    slider:SetPoint("TOPLEFT", listFrame, "TOPRIGHT", 4, -8)
    slider:SetPoint("BOTTOMLEFT", listFrame, "BOTTOMRIGHT", 4, 8)
    slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 },
    })
    slider:SetMinMaxValues(0, 0)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(0)
    slider:SetScript("OnValueChanged", function(self, value)
        local v = math.floor(value + 0.5)
        if v ~= offset then
            offset = v
            UpdateList()
        end
    end)

    -- Editor del mensaje de susurro
    local msgLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    msgLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 40)
    msgLabel:SetText(L.MSG_LABEL)

    msgBox = CreateFrame("EditBox", "CraftCheckMsgBox", frame, "InputBoxTemplate")
    msgBox:SetHeight(22)
    msgBox:SetPoint("LEFT", msgLabel, "RIGHT", 10, 0)
    msgBox:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
    msgBox:SetAutoFocus(false)
    msgBox:SetMaxLetters(240)
    msgBox:SetText(ns.db.settings.msgTemplate or L.MSG_DEFAULT)
    local function SaveMsg(self)
        local t = strtrim(self:GetText() or "")
        if t == "" then
            ns.db.settings.msgTemplate = nil
            self:SetText(L.MSG_DEFAULT)
        else
            ns.db.settings.msgTemplate = t
        end
        self:ClearFocus()
    end
    msgBox:SetScript("OnEnterPressed", SaveMsg)
    msgBox:SetScript("OnEditFocusLost", SaveMsg)
    msgBox:SetScript("OnEscapePressed", function(self)
        self:SetText(ns.db.settings.msgTemplate or L.MSG_DEFAULT)
        self:ClearFocus()
    end)

    msgBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L.MSG_LABEL, 1, 0.82, 0)
        GameTooltip:AddLine(L.MSG_HELP, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    msgBox:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Ayuda
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOM", frame, "BOTTOM", 0, 16)
    hint:SetText(L.HINT)
end

-------------------------------------------------------------------------------
-- Botón de minimapa
-------------------------------------------------------------------------------
local minimapButton

local function UpdateMinimapPosition()
    if not minimapButton then return end
    local angle = math.rad(ns.db.settings.minimap.angle or 220)
    local radius = (Minimap:GetWidth() / 2) + 5
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateMinimapButton()
    minimapButton = CreateFrame("Button", "CraftCheckMinimapButton", Minimap)
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:SetMovable(true)

    local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local background = minimapButton:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = minimapButton:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetTexture("Interface\\AddOns\\CraftCheck\\icon")
    icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
    icon:SetPoint("TOPLEFT", 7, -6)

    minimapButton:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ns.db.settings.tooltip = not ns.db.settings.tooltip
            print(ns.db.settings.tooltip and L.TOOLTIP_ON or L.TOOLTIP_OFF)
        else
            ns.UI_Toggle()
        end
    end)
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L.MINIMAP_TIP1)
        GameTooltip:AddLine(L.MINIMAP_TIP2, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    minimapButton:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            ns.db.settings.minimap.angle = math.deg(math.atan2(cy - my, cx - mx))
            UpdateMinimapPosition()
        end)
    end)
    minimapButton:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    UpdateMinimapPosition()
end

function ns.UI_UpdateMinimap()
    if not minimapButton then return end
    if ns.db.settings.minimap.hide then
        minimapButton:Hide()
    else
        minimapButton:Show()
        UpdateMinimapPosition()
    end
end

-------------------------------------------------------------------------------
-- API pública del módulo
-------------------------------------------------------------------------------
function ns.UI_Init()
    if not frame then CreatePanel() end
    if not minimapButton then CreateMinimapButton() end
    ns.UI_UpdateMinimap()
end

function ns.UI_Toggle()
    if not frame then CreatePanel() end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

function ns.UI_Refresh()
    if frame and frame:IsShown() then
        Rebuild()
    end
end
