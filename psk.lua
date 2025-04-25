-- PSK Addon
print("PSK addon loaded!")

-- Persistent database setup
if not PSKDB then
    PSKDB = {}
end

-- Cleanup: remove invalid entries that may have numeric class values
for k, v in pairs(PSKDB) do
    if type(v.class) ~= "string" then
        print("Removing invalid class entry for", k)
        PSKDB[k] = nil
    end
end

-- Main UI Frame
local pskFrame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
pskFrame:SetSize(800, 600)
pskFrame:SetPoint("CENTER")
pskFrame:SetFrameStrata("HIGH")
pskFrame:SetMovable(true)
pskFrame:EnableMouse(true)
pskFrame:RegisterForDrag("LeftButton")

pskFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
pskFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
pskFrame:SetScript("OnShow", function() PlaySound(808) end)
pskFrame:SetScript("OnHide", function() PlaySound(808) end)

-- Title and status
pskFrame.TitleBg:SetHeight(30)
pskFrame.title = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pskFrame.title:SetPoint("TOPLEFT", pskFrame.TitleBg, "TOPLEFT", 5, -3)
pskFrame.title:SetText("Perchance PSK - Perchance you want some loot?")

pskFrame.statusText = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pskFrame.statusText:SetPoint("TOPLEFT", pskFrame.title, "BOTTOMLEFT", 25, -10)
pskFrame.statusText:SetText("Last updated: never")
pskFrame.statusText:SetTextColor(0.7, 0.7, 0.7)

-- Slash command
SLASH_PSK1 = "/psk"
SlashCmdList["PSK"] = function() pskFrame:Show() end

-- Scrollable Content
local scrollFrame = CreateFrame("ScrollFrame", nil, pskFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 25, -60)
scrollFrame:SetSize(260, 400)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(260, 400)
scrollFrame:SetScrollChild(content)

-- Save online guild members to DB
local function SaveOnlineGuildMembers()
    local total = GetNumGuildMembers()
    for i = 1, total do
        -- Classic-safe version of classFileName extraction
        local name, _, _, _, _, _, _, _, online, _, class, classFileName = GetGuildRosterInfo(i)
        if online and classFileName then
            classFileName = string.upper(strtrim(classFileName))
            name = Ambiguate(name, "short")
            PSKDB[name] = {
                class = classFileName,
                seen = date("%Y-%m-%d %H:%M")
            }
        end
    end
end

-- Draw the UI with player names and icons
local function UpdateNameList()
    for _, child in ipairs({ content:GetChildren() }) do child:Hide() end

    local yOffset = -5
    local count = 0
    for _ in pairs(PSKDB) do count = count + 1 end
    content:SetSize(260, math.max(count * 20, 400))

    for name, data in pairs(PSKDB) do
        local class = string.upper(strtrim(tostring(data.class or "UNKNOWN")))
        local seen = data.seen or "UNKNOWN"

        local icon = content:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)

        print("Drawing:", name, "Class:", class)

        local coords = CLASS_ICON_TCOORDS[class]
        if coords then
            print("Icon coords:", unpack(coords))
            icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            icon:SetTexCoord(unpack(coords))
        else
            print("No coords found for", class)
            icon:SetColorTexture(0.2, 0.2, 0.2)
        end

        local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetText(name .. (coords and "" or " (?)"))
        fs:SetPoint("LEFT", icon, "RIGHT", 5, 0)

        local color = RAID_CLASS_COLORS[class]
        if color then
            fs:SetTextColor(color.r, color.g, color.b)
        end

        local hoverFrame = CreateFrame("Frame", nil, content)
        hoverFrame:SetPoint("TOPLEFT", icon)
        hoverFrame:SetSize(260, 20)
        hoverFrame:SetScript("OnEnter", function()
            GameTooltip:SetOwner(hoverFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(name .. "\nLast Seen: " .. seen, 1, 1, 1)
            GameTooltip:Show()
        end)
        hoverFrame:SetScript("OnLeave", GameTooltip_Hide)

        yOffset = yOffset - 20
    end
end

-- Event Listener
local listener = CreateFrame("Frame")
local hasRequestedRoster = false

listener:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" and not hasRequestedRoster then
        hasRequestedRoster = true
        C_Timer.After(2, function()
            if IsInGuild() then
                print("Requesting guild roster...")
                C_GuildInfo.GuildRoster()
            end
        end)
    elseif event == "GUILD_ROSTER_UPDATE" then
        C_Timer.After(1, function()
            SaveOnlineGuildMembers()
            UpdateNameList()
            pskFrame.statusText:SetText("Last updated: " .. date("%Y-%m-%d %H:%M"))
        end)
    elseif event == "PLAYER_LOGIN" then
        pskFrame:Show()
    end
end)

-- Register Events
listener:RegisterEvent("CHAT_MSG_GUILD")
listener:RegisterEvent("CHAT_MSG_RAID")
listener:RegisterEvent("CHAT_MSG_WHISPER")
listener:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")
listener:RegisterEvent("GUILD_ROSTER_UPDATE")
listener:RegisterEvent("PLAYER_LOGIN")

-- Mark frame as closable with Escape
table.insert(UISpecialFrames, "PSKMainFrame")