local frame = CreateFrame("Frame")
frame:RegisterEvent("VARIABLES_LOADED")
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
    if type(WI_Settings.keywords) ~= "table" or #WI_Settings.keywords == 0 then
        WI_Settings.keywords = {"+", "sör"}
    end
    if type(WI_Settings.minimap) ~= "table" then WI_Settings.minimap = {} end
    if type(WI_Settings.minimap.show) ~= "boolean" then WI_Settings.minimap.show = true end
    if type(WI_Settings.minimap.angle) ~= "number" then WI_Settings.minimap.angle = 225 end
end

local function hasKeyword(msg)
    if type(WI_Settings) ~= "table" or type(WI_Settings.keywords) ~= "table" then return false end
    for _, kw in ipairs(WI_Settings.keywords) do
        if normalize(kw) == msg then return true end
    end
    return false
end

local uiFrame
local keywordEditBox
local enableCheckbox
local keywordListText
local miniButton

local function refreshUI()
    if not uiFrame then return end
    enableCheckbox:SetChecked(WI_Settings.enabled)
    local list = ""
    for i, kw in ipairs(WI_Settings.keywords) do
        list = list .. i .. ". " .. kw .. "\n"
    end
    if list == "" then list = "(no keywords)" end
    keywordListText:SetText(list)
end

local function createUI()
    if uiFrame then return end
    uiFrame = CreateFrame("Frame", "WIConfigFrame", UIParent)
    uiFrame:SetSize(300, 240)
    uiFrame:SetPoint("CENTER")
    uiFrame:EnableMouse(true)
    uiFrame:SetMovable(true)
    uiFrame:RegisterForDrag("LeftButton")
    uiFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    uiFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    uiFrame:Hide()

    uiFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    uiFrame:SetBackdropColor(0, 0, 0, 1)

    local title = uiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("WI Config")

    enableCheckbox = CreateFrame("CheckButton", "WIEnableCheckbox", uiFrame, "UICheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", 16, -40)
    enableCheckbox.text = _G[enableCheckbox:GetName() .. "Text"]
    enableCheckbox.text:SetText("Enable auto-invite")
    enableCheckbox:SetScript("OnClick", function()
        WI_Settings.enabled = enableCheckbox:GetChecked() and true or false
        refreshUI()
    end)

    local label = uiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -12)
    label:SetText("Keyword")

    keywordEditBox = CreateFrame("EditBox", "WIKeywordEditBox", uiFrame, "InputBoxTemplate")
    keywordEditBox:SetSize(180, 20)
    keywordEditBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    keywordEditBox:SetAutoFocus(false)

    local addButton = CreateFrame("Button", "WIAddButton", uiFrame, "UIPanelButtonTemplate")
    addButton:SetSize(60, 22)
    addButton:SetPoint("LEFT", keywordEditBox, "RIGHT", 8, 0)
    addButton:SetText("Add")
    addButton:SetScript("OnClick", function()
        local kw = normalize(keywordEditBox:GetText())
        if kw ~= "" then
            local exists = false
            for _, v in ipairs(WI_Settings.keywords) do if normalize(v) == kw then exists = true break end end
            if not exists then table.insert(WI_Settings.keywords, kw) end
            keywordEditBox:SetText("")
            refreshUI()
        end
    end)

    local removeButton = CreateFrame("Button", "WIRemoveButton", uiFrame, "UIPanelButtonTemplate")
    removeButton:SetSize(60, 22)
    removeButton:SetPoint("LEFT", addButton, "RIGHT", 8, 0)
    removeButton:SetText("Remove")
    removeButton:SetScript("OnClick", function()
        local kw = normalize(keywordEditBox:GetText())
        if kw ~= "" then
            for i = #WI_Settings.keywords, 1, -1 do
                if normalize(WI_Settings.keywords[i]) == kw then table.remove(WI_Settings.keywords, i) end
            end
            keywordEditBox:SetText("")
            refreshUI()
        end
    end)

    local listLabel = uiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listLabel:SetPoint("TOPLEFT", keywordEditBox, "BOTTOMLEFT", 0, -14)
    listLabel:SetText("Keywords:")

    keywordListText = uiFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    keywordListText:SetPoint("TOPLEFT", listLabel, "BOTTOMLEFT", 0, -8)
    keywordListText:SetJustifyH("LEFT")
    keywordListText:SetWidth(260)
    keywordListText:SetHeight(100)

    local closeButton = CreateFrame("Button", "WICloseButton", uiFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 22)
    closeButton:SetPoint("BOTTOM", 0, 12)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() uiFrame:Hide() end)
end

local function openConfig()
    createUI()
    refreshUI()
    uiFrame:Show()
end

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
            for _, v in ipairs(WI_Settings.keywords) do if normalize(v) == kw then exists = true break end end
            if not exists then table.insert(WI_Settings.keywords, kw) end
            DEFAULT_CHAT_FRAME:AddMessage("[WI] Added keyword: " .. kw)
            refreshUI()
        end
    elseif cmd == "remove" and rest and rest ~= "" then
        local kw = normalize(rest)
        local removed = false
        for i = #WI_Settings.keywords, 1, -1 do
            if normalize(WI_Settings.keywords[i]) == kw then table.remove(WI_Settings.keywords, i) removed = true end
        end
        DEFAULT_CHAT_FRAME:AddMessage("[WI] " .. (removed and "Removed" or "Not found") .. ": " .. kw)
        refreshUI()
    elseif cmd == "list" then
        local list = "[WI] Keywords: "
        for i, kw in ipairs(WI_Settings.keywords) do
            list = list .. (i > 1 and ", " or "") .. kw
        end
        DEFAULT_CHAT_FRAME:AddMessage(list)
    elseif cmd == "map" then
        WI_Settings.minimap.show = not WI_Settings.minimap.show
        if miniButton then
            if WI_Settings.minimap.show then miniButton:Show() else miniButton:Hide() end
        end
        DEFAULT_CHAT_FRAME:AddMessage("[WI] Minimap icon " .. (WI_Settings.minimap.show and "shown" or "hidden"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("[WI] Commands: /wi gui | on | off | toggle | add <kw> | remove <kw> | list | map")
    end
end

local function eventHandler(self, event)
    if event == "VARIABLES_LOADED" then
        ensureDefaults()
        createUI()
        if not miniButton then
            local btn = CreateFrame("Button", "WI_MinimapButton", Minimap)
            btn:SetWidth(20)
            btn:SetHeight(20)
            btn:SetFrameStrata("LOW")
            btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(btn)
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            btn.icon = icon

            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
                GameTooltip:SetText("WI", 1, 1, 1)
                GameTooltip:AddLine("Left-click: Open GUI", 0.9, 0.9, 0.9)
                GameTooltip:AddLine("Right-click: Toggle auto-invite", 0.9, 0.9, 0.9)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            btn:SetScript("OnClick", function(self, button)
                if button == "LeftButton" then
                    openConfig()
                else
                    WI_Settings.enabled = not WI_Settings.enabled
                    DEFAULT_CHAT_FRAME:AddMessage("[WI] Auto-invite " .. (WI_Settings.enabled and "enabled" or "disabled"))
                    refreshUI()
                end
            end)

            btn:RegisterForDrag("LeftButton")
            btn:SetScript("OnDragStart", function(self) self.isMoving = true end)
            btn:SetScript("OnDragStop", function(self) self.isMoving = false end)
            btn:SetScript("OnUpdate", function(self)
                if not self.isMoving then return end
                local mx, my = Minimap:GetCenter()
                local cx, cy = GetCursorPosition()
                local scale = Minimap:GetEffectiveScale() or Minimap:GetScale()
                cx = cx / scale; cy = cy / scale
                local dx = cx - mx
                local dy = cy - my
                local angle = math.deg(math.atan2(dy, dx))
                WI_Settings.minimap.angle = angle
                local r = (Minimap:GetWidth() / 2) - 10
                local rad = math.rad(angle)
                local x = math.cos(rad) * r
                local y = math.sin(rad) * r
                self:SetPoint("CENTER", Minimap, "CENTER", x, y)
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
        refreshUI()
        return
    end
    if event == "CHAT_MSG_WHISPER" then
        local message = arg1
        local sender = arg2
        if WI_Settings.enabled and sender and hasKeyword(normalize(message)) then
            InviteByName(sender)
            SendChatMessage("Inviting you to the party!", "WHISPER", nil, sender)
        end
    end
end

frame:SetScript("OnEvent", eventHandler)


