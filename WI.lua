local frame = CreateFrame("Frame")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("CHAT_MSG_WHISPER")

local function normalize(text)
    if not text then return "" end
    local trimmed = string.gsub(text, "^%s*(.-)%s*$", "%1")
    return string.lower(trimmed)
end

local function ensureDefaults()
    if type(WI_Settings) ~= "table" then WI_Settings = {} end
    if type(WI_Settings.enabled) ~= "boolean" then WI_Settings.enabled = true end
    if type(WI_Settings.keywords) ~= "table" or #WI_Settings.keywords == 0 then
        WI_Settings.keywords = {"+", "sör"}
    end
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
    local cmd, rest = string.match(msg or "", "^(%S+)%s*(.-)$")
    if not cmd or cmd == "" or cmd == "gui" then
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
    else
        DEFAULT_CHAT_FRAME:AddMessage("[WI] Commands: /wi gui | on | off | add <kw> | remove <kw> | list")
    end
end

local function eventHandler(self, event)
    if event == "VARIABLES_LOADED" then
        ensureDefaults()
        createUI()
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


