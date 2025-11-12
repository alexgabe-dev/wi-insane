local frame = CreateFrame("Frame")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_WHISPER")

local function normalize(text)
    if not text then return "" end
    local s = string.gsub(text, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return string.lower(s)
end

local function ensureDefaults()
    if type(WI_Settings) ~= "table" then WI_Settings = {} end
    if type(WI_Settings.enabled) ~= "boolean" then WI_Settings.enabled = true end
    if type(WI_Settings.keywords) ~= "table" or table.getn(WI_Settings.keywords) == 0 then
        WI_Settings.keywords = {"+", "sör"}
    end
    if type(WI_Settings.minimap) ~= "table" then WI_Settings.minimap = {} end
    if type(WI_Settings.minimap.show) ~= "boolean" then WI_Settings.minimap.show = true end
    if type(WI_Settings.minimap.angle) ~= "number" then WI_Settings.minimap.angle = 225 end
    if WI_Settings.debug == nil then WI_Settings.debug = false end
end

local function hasKeyword(msg)
    if type(WI_Settings) ~= "table" or type(WI_Settings.keywords) ~= "table" then return false end
    for i = 1, table.getn(WI_Settings.keywords) do
        local kw = WI_Settings.keywords[i]
        if normalize(kw) == msg then return true end
    end
    return false
end

local uiFrame
local keywordEditBox
local enableCheckbox
local keywordListText
local keywordScroll
local keywordScrollChild
local miniButton
local canInvite -- forward declaration so event handler sees local, not global

local function refreshUI()
    if not uiFrame then return end
    local enabled = (WI_Settings and WI_Settings.enabled) and true or false
    if enableCheckbox then enableCheckbox:SetChecked(enabled) end
    local list = ""
    if WI_Settings and type(WI_Settings.keywords) == "table" then
        local total = table.getn(WI_Settings.keywords)
        for i = 1, total do
            local kw = WI_Settings.keywords[i]
            list = list .. i .. ". " .. tostring(kw or "") .. "\n"
        end
    end
    if list == "" then list = "(no keywords)" end
    if keywordListText then
        keywordListText:SetText(list)
        if keywordScrollChild and keywordScroll then
            local w = keywordScroll:GetWidth() - 24
            if w < 100 then w = 100 end
            keywordScrollChild:SetWidth(w)
            keywordListText:SetWidth(w - 4)
            local h = keywordListText.GetStringHeight and keywordListText:GetStringHeight() or keywordListText:GetHeight()
            if not h or h < 1 then h = keywordScroll:GetHeight() end
            keywordScrollChild:SetHeight(h + 6)
            keywordScroll:SetVerticalScroll(0)
        end
    end
end

local function createUI()
    if uiFrame then return end
    uiFrame = CreateFrame("Frame", "WIConfigFrame", UIParent)
    uiFrame:SetWidth(340); uiFrame:SetHeight(320)
    uiFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    uiFrame:SetFrameStrata("DIALOG")
    uiFrame:EnableMouse(true)
    uiFrame:SetMovable(true)
    uiFrame:RegisterForDrag("LeftButton")
    uiFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    uiFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    uiFrame:Hide()

    if uiFrame.SetBackdrop then
        uiFrame:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        uiFrame:SetBackdropColor(0, 0, 0, 1)
    end

    local header = uiFrame:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(256); header:SetHeight(64)
    header:SetPoint("TOP", uiFrame, "TOP", 0, 12)

    local title = uiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("WI Config")

    enableCheckbox = CreateFrame("CheckButton", "WIEnableCheckbox", uiFrame, "UICheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", uiFrame, "TOPLEFT", 16, -40)
    enableCheckbox.text = getglobal(enableCheckbox:GetName() .. "Text")
    enableCheckbox.text:SetText("Enable auto-invite")
    enableCheckbox:SetScript("OnClick", function()
        WI_Settings.enabled = enableCheckbox:GetChecked() and true or false
        refreshUI()
    end)
    enableCheckbox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Auto-invite", 1, 1, 1)
        GameTooltip:AddLine("Invite on matching whisper", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    enableCheckbox:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local label = uiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -12)
    label:SetText("Keyword")

    keywordEditBox = CreateFrame("EditBox", "WIKeywordEditBox", uiFrame, "InputBoxTemplate")
    keywordEditBox:SetWidth(180); keywordEditBox:SetHeight(20)
    keywordEditBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    if keywordEditBox.SetAutoFocus then keywordEditBox:SetAutoFocus(false) end

    local addButton = CreateFrame("Button", "WIAddButton", uiFrame, "UIPanelButtonTemplate")
    addButton:SetWidth(60); addButton:SetHeight(22)
    addButton:SetPoint("LEFT", keywordEditBox, "RIGHT", 8, 0)
    addButton:SetText("Add")
    addButton:SetScript("OnClick", function()
        local kw = normalize(keywordEditBox:GetText())
        if kw ~= "" then
            local exists = false
            for i = 1, table.getn(WI_Settings.keywords) do
                local v = WI_Settings.keywords[i]
                if normalize(v) == kw then exists = true; break end
            end
            if not exists then table.insert(WI_Settings.keywords, kw) end
            keywordEditBox:SetText("")
            refreshUI()
        end
    end)
    addButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Add keyword", 1, 1, 1)
        GameTooltip:AddLine("Exact match, case-insensitive", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    addButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local removeButton = CreateFrame("Button", "WIRemoveButton", uiFrame, "UIPanelButtonTemplate")
    removeButton:SetWidth(60); removeButton:SetHeight(22)
    removeButton:SetPoint("LEFT", addButton, "RIGHT", 8, 0)
    removeButton:SetText("Remove")
    removeButton:SetScript("OnClick", function()
        local kw = normalize(keywordEditBox:GetText())
        if kw ~= "" then
            for i = table.getn(WI_Settings.keywords), 1, -1 do
                if normalize(WI_Settings.keywords[i]) == kw then table.remove(WI_Settings.keywords, i) end
            end
            keywordEditBox:SetText("")
            refreshUI()
        end
    end)
    removeButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Remove keyword", 1, 1, 1)
        GameTooltip:AddLine("Removes exact matching keyword", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    removeButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local listLabel = uiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listLabel:SetPoint("TOPLEFT", keywordEditBox, "BOTTOMLEFT", 0, -14)
    listLabel:SetText("Keywords:")

    keywordScroll = CreateFrame("ScrollFrame", "WIKeywordScroll", uiFrame, "UIPanelScrollFrameTemplate")
    keywordScroll:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", 0, -8)
    keywordScroll:SetWidth(280)
    keywordScroll:SetHeight(110)

    keywordScrollChild = CreateFrame("Frame", "WIKeywordScrollChild", keywordScroll)
    keywordScrollChild:SetWidth(256)
    keywordScrollChild:SetHeight(1)
    keywordScroll:SetScrollChild(keywordScrollChild)

    keywordListText = keywordScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    keywordListText:SetPoint("TOPLEFT", keywordScrollChild, "TOPLEFT", 0, 0)
    keywordListText:SetJustifyH("LEFT")
    keywordListText:SetWidth(256)

    local listBg = uiFrame:CreateTexture(nil, "BACKGROUND")
    listBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    listBg:SetPoint("TOPLEFT", keywordScroll, "TOPLEFT", -3, 3)
    listBg:SetPoint("BOTTOMRIGHT", keywordScroll, "BOTTOMRIGHT", 3, -3)
    listBg:SetVertexColor(0, 0, 0, 0.4)

    local closeButton = CreateFrame("Button", "WICloseButton", uiFrame, "UIPanelButtonTemplate")
    closeButton:SetWidth(80); closeButton:SetHeight(22)
    closeButton:SetPoint("BOTTOM", uiFrame, "BOTTOM", 0, 4)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() uiFrame:Hide() end)

    local closeX = CreateFrame("Button", "WIConfigCloseX", uiFrame, "UIPanelCloseButton")
    closeX:SetPoint("TOPRIGHT", uiFrame, "TOPRIGHT", -4, -4)
end

local function openConfig()
    createUI()
    refreshUI()
    uiFrame:Show()
end

SlashCmdList = SlashCmdList or {}
SLASH_WI1 = "/wi"
SlashCmdList["WI"] = function(msg)
    ensureDefaults()
    msg = msg or ""
    local space = string.find(msg, " ")
    local cmd, rest
    if space then
        cmd = string.sub(msg, 1, space - 1)
        rest = string.sub(msg, space + 1)
    else
        cmd = msg
        rest = ""
    end
    if not cmd or cmd == "" or string.lower(cmd) == "gui" then
        openConfig()
        return
    end
    cmd = string.lower(cmd)
    if cmd == "on" then
        WI_Settings.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("[WI] Auto-invite enabled")
        refreshUI()
    elseif cmd == "off" then
        WI_Settings.enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("[WI] Auto-invite disabled")
        refreshUI()
    elseif cmd == "toggle" then
        WI_Settings.enabled = not WI_Settings.enabled
        DEFAULT_CHAT_FRAME:AddMessage("[WI] Auto-invite " .. (WI_Settings.enabled and "enabled" or "disabled"))
        refreshUI()
    elseif cmd == "add" and rest and rest ~= "" then
        local kw = normalize(rest)
        if kw ~= "" then
            local exists = false
            for i = 1, table.getn(WI_Settings.keywords) do
                local v = WI_Settings.keywords[i]
                if normalize(v) == kw then exists = true; break end
            end
            if not exists then table.insert(WI_Settings.keywords, kw) end
            DEFAULT_CHAT_FRAME:AddMessage("[WI] Added keyword: " .. kw)
            refreshUI()
        end
    elseif cmd == "remove" and rest and rest ~= "" then
        local kw = normalize(rest)
        local removed = false
        for i = table.getn(WI_Settings.keywords), 1, -1 do
            if normalize(WI_Settings.keywords[i]) == kw then table.remove(WI_Settings.keywords, i) removed = true end
        end
        DEFAULT_CHAT_FRAME:AddMessage("[WI] " .. (removed and "Removed" or "Not found") .. ": " .. kw)
        refreshUI()
    elseif cmd == "list" then
        local list = "[WI] Keywords: "
        for i = 1, table.getn(WI_Settings.keywords) do
            local kw = WI_Settings.keywords[i]
            list = list .. (i > 1 and ", " or "") .. kw
        end
        DEFAULT_CHAT_FRAME:AddMessage(list)
    elseif cmd == "map" then
        WI_Settings.minimap.show = not WI_Settings.minimap.show
        if miniButton then
            if WI_Settings.minimap.show then miniButton:Show() else miniButton:Hide() end
        end
        DEFAULT_CHAT_FRAME:AddMessage("[WI] Minimap icon " .. (WI_Settings.minimap.show and "shown" or "hidden"))
    elseif cmd == "debug" then
        WI_Settings.debug = not WI_Settings.debug
        DEFAULT_CHAT_FRAME:AddMessage("[WI] Debug " .. (WI_Settings.debug and "ON" or "OFF"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("[WI] Commands: /wi gui | on | off | toggle | add <kw> | remove <kw> | list | map | debug")
    end
end

local function eventHandler()
    if event == "VARIABLES_LOADED" then
        ensureDefaults()
        createUI()
        refreshUI()
        DEFAULT_CHAT_FRAME:AddMessage("[WI] Loaded. Use /wi for options.")
        return
    end
    if event == "PLAYER_LOGIN" then
        ensureDefaults()
        if not miniButton and Minimap then
            local btn = CreateFrame("Button", "WI_MinimapButton", Minimap)
            btn:SetWidth(20)
            btn:SetHeight(20)
            btn:SetFrameStrata("MEDIUM")
            btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(btn)
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            btn.icon = icon

            btn:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
                GameTooltip:SetText("WI", 1, 1, 1)
                GameTooltip:AddLine("Left-click: Open GUI", 0.9, 0.9, 0.9)
                GameTooltip:AddLine("Right-click: Toggle auto-invite", 0.9, 0.9, 0.9)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            btn:SetScript("OnClick", function()
                local button = arg1
                if button == "LeftButton" or button == "LeftButtonUp" then
                    openConfig()
                else
                    WI_Settings.enabled = not WI_Settings.enabled
                    DEFAULT_CHAT_FRAME:AddMessage("[WI] Auto-invite " .. (WI_Settings.enabled and "enabled" or "disabled"))
                    refreshUI()
                end
            end)

            btn:RegisterForDrag("LeftButton")
            btn:SetScript("OnDragStart", function() this.isMoving = true end)
            btn:SetScript("OnDragStop", function() this.isMoving = false end)
            btn:SetScript("OnUpdate", function()
                if not this.isMoving then return end
                local mx, my = Minimap:GetCenter()
                local cx, cy = GetCursorPosition()
                local scale = Minimap:GetScale()
                cx = cx / scale; cy = cy / scale
                local dx = cx - mx
                local dy = cy - my
                local angleRad
                if dx == 0 then
                    angleRad = (dy >= 0) and math.pi/2 or -math.pi/2
                else
                    angleRad = math.atan(dy / dx)
                    if dx < 0 then angleRad = angleRad + math.pi end
                end
                local angle = math.deg(angleRad)
                if angle < 0 then angle = angle + 360 end
                WI_Settings.minimap.angle = angle
                local r = (Minimap:GetWidth() / 2) - 10
                local rad = math.rad(angle)
                local x = math.cos(rad) * r
                local y = math.sin(rad) * r
                this:SetPoint("CENTER", Minimap, "CENTER", x, y)
            end)

            local function place()
                local r = (Minimap:GetWidth() / 2) - 10
                local rad = math.rad(WI_Settings.minimap.angle)
                local x = math.cos(rad) * r
                local y = math.sin(rad) * r
                btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
            end

            miniButton = btn
            place()
            if WI_Settings.minimap.show then btn:Show() else btn:Hide() end
        end
        return
    end
    if event == "CHAT_MSG_WHISPER" then
        local message = arg1
        local sender = arg2
        local matched = hasKeyword(normalize(message))
        if WI_Settings.debug then
            DEFAULT_CHAT_FRAME:AddMessage("[WI] Whisper from " .. tostring(sender or "?") .. ": '" .. tostring(message or "") .. "' matched=" .. tostring(matched) .. ", enabled=" .. tostring(WI_Settings.enabled))
        end
        if WI_Settings.enabled and sender and matched then
            if WI_Settings.debug then
                DEFAULT_CHAT_FRAME:AddMessage("[WI] Invite attempt for " .. tostring(sender))
            end
            InviteByName(sender)
            SendChatMessage("Inviting you to the party!", "WHISPER", nil, sender)
        end
    end
end

frame:SetScript("OnEvent", eventHandler)

function canInvite()
    local raidMembers = GetNumRaidMembers and GetNumRaidMembers() or 0
    if raidMembers and raidMembers > 0 then return false, "in raid" end
    local partyMembers = GetNumPartyMembers and GetNumPartyMembers() or 0
    if partyMembers and partyMembers >= 4 then return false, "party full" end
    if partyMembers and partyMembers > 0 then
        local isLeader = IsPartyLeader and IsPartyLeader()
        if not isLeader then return false, "not party leader" end
    end
    return true, nil
end


