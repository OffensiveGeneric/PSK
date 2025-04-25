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

-- Try to map localize class names to CLASS_ICON_TCOORDS keys since classFileName isn't returned in Classic Era by GetGuildRosterInfo()
local CLASS_TRANSLATIONS = {
    ["Warrior"] = "WARRIOR",
    ["Paladin"] = "PALADIN",
    ["Hunter"] = "HUNTER",
    ["Rogue"] = "ROGUE",
    ["Priest"] = "PRIEST",
    ["Shaman"] = "SHAMAN",
    ["Mage"] = "MAGE",
    ["Warlock"] = "WARLOCK",
    ["Druid"] = "DRUID"
}

-- Main UI Frame
local pskFrame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
pskFrame:SetSize(800, 600)
pskFrame:SetPoint("CENTER")
pskFrame:SetFrameStrata("HIGH")
pskFrame:SetMovable(true)
pskFrame:EnableMouse(true)
pskFrame:RegisterForDrag("LeftButton")

-- Mouse functions for main UI frame
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

-- Refresh Button
local refreshButton = CreateFrame("Button", nil, pskFrame, "UIPanelButtonTemplate")
refreshButton:SetSize(80, 24)
refreshButton.SetPoint("TOPRIGHT", pskFrame, "TOPRIGHT", -30, -30)
refreshButton.SetText("Refresh")

-- Scrollable frame for guild members
local scrollFrame = CreateFrame("ScrollFrame", nil, pskFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 25, -60)
scrollFrame:SetSize(260, 400)

-- Container for player name entries.
local playerFrame = CreateFrame("Frame", nil, scrollFrame)
playerFrame:SetSize(260, 400)
scrollFrame:SetScrollChild(playerFrame)

-- Slash command
SLASH_PSK1 = "/psk"
SlashCmdList["PSK"] = function() pskFrame:Show() end

-- Check if player is in the raid group
local function IsInRaidGroup(name)
    name = name:lower()
    for i = 1, GetNumGroupMembers() do
        local unit = "raid"..i
        if UnitExists(unit) and UnitName(unit):lower == name then
            return true
        end
    end
    return false
end

-- Save all max-level members (online and offline)
local function SaveGuildMembers()

    -- This returns numTotalMembers, numOnlineMaxLevelMembers, numOnlineMembers in the guild
    local totalMembers, totalLevelCapMembers, TotalOnlineMembers = GetNumGuildMembers()

    -- Loop through level-capped guild members
    for i = 1, totalLevelCapMembers do

        -- GetGuildRosterInfo(i) returns the following for the index of the person in the guild (for Classic Era only):
        --     name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile, isSoREligible, standingID
        -- Apparently, classFileName doesn't exist in Classic Era, so we have to work around that to get the textures for class icons...
        -- local name, _, _, level, class, _, _, _, online, _, classFileName, _, _, _, _, _ = GetGuildRosterInfo(i)
        
        local name, _, _, level, class, _, _, _, online, _ = GetGuildRosterInfo(i)
        name = Ambiguate(name or "Unknown", "short")
        
        local token = CLASS_TRANSLATIONS[class or ""] or "UNKNOWN"

        local coords = CLASS_ICON_TCOORDS[token]

        -- Check if level cap, then record class, date, and whether they're online
        if level == 60 then
            PSKDB[name] = {
                class = token,
                seen = date("%Y-%m-%d %H:%M"),
                online = online
            }
        end
    end
end

-- Draw the UI with player names and icons in playerFrame.  Sorted by online first, offline second (for now)
local function UpdateNameList()
    for _, child in ipairs({ playerFrame:GetChildren() }) do child:Hide() end

    local yOffset = -5
    local entries = {}
    local count = 0

    -- Build a sortable table
    for name, data in pairs(PSKDB) do
        table.insert(entries, {
            name = name,
            class = data.class,
            seen = data.seen,
            online = data.online
        })
    end

    -- Simple sort (online first, then offline)
    table.sort(entries, function(a, b)
        if a.online == b.online then
            return a.name < b.name 
        else
            return a.online and not b.online
        end
    end)

    for _, entry in ipairs(entries) do
        
        -- Player data points
        local name = entry.name
        local class = entry.class or "UNKNOWN"
        local seen = entry.seen or "UNKNOWN"
        local isOnline = entry.online
        local inRaid = IsInRaidGroup(name)

        -- Icon
        local icon = playerFrame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", 5, yOffset)

        local coords = CLASS_ICON_TCOORDS[class]
        
        if coords then
            icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            icon:SetTexCoord(unpack(coords))
        else
            print("No coords found for", class)
            icon:SetColorTexture(0.2, 0.2, 0.2)
        end

        -- Name text
        local fs = playerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetText(name)
        fs:SetPoint("LEFT", icon, "RIGHT", 5, 0)

        -- Text color
        if isOnline then
            if inRaid then
                fs:SetTextColor(0, 1, 0) -- green
            else
                fs:SetTextColor(1, 1, 0) -- yellow
            end
        else
            fs:SetTextColor(0.5, 0.5, 0.5) -- gray
        end

        -- Tooltip
        fs:EnableMouse(true)
        
        fs:SetScript("OnEnter", function()
            GameTooltip:SetText(name .. "\nLast Seen: "..seen, 1, 1, 1)
            GameTooltip:Show()
        end)

        fs:SetScript("OnLeave", GameTooltip_Hide)
            yOffset = yOffset - 20
        end

        playerFrame:SetSize(260, math.max(count * 20, 400)
    end
end

-- Refresh button
local function RefreshRoster()
    if not IsInGuild() then return end

    -- Play auction window sound because "why not?"
    PlaySound(12867)

    -- Set up flash
    if not refreshButton.flash then
        local flash = refreshButton.CreateAnimationGroup()
        local alphaOut = flash:CreateAnimation("Alpha)
        alphaOut:SetFromAlpha(1)
        alphaOut:SetToAlpha(0.5)
        alphaOut:SetDuration(0.1)
        alphaOut::SetOrder(1)

        local alphaIn = flash.CreateAnimation("Alpha")
        alphaIn:SetFromAlpha(0.5)
        alphaIn:SetToAlpha(1)
        alphaIn:SetDuration(0.2)
        alphaIn:SetOrder(2)

        refreshButton.flash = flash
    end

    -- Flash button
    refreshButton.flash:Play()

    -- Update roster after a slight delay
    C_GuildInfo.GuildRoster()
        
    C_Timer.After(1, function()
        SaveGuildMembers()
        UpdateNameList()
        pskFrame.statusText:SetText("Last updated: " .. date("%Y-%m-%d %H:%M"))
    end)
end

-- Refresh button Listener
refreshButton:SetScript("OnClick", RefreshRoster)

-- Slow down the guild roster request until player is fully loaded into the world.
local hasRequestedRoster = false

-- Event Listener
local listener = CreateFrame("Frame")

listener:SetScript("OnEvent", function(self, event, message, sender, ...)

    -- Refresh the guild roster when player enters
    if event == "PLAYER_ENTERING_WORLD" and not hasRequestedRoster then
        hasRequestedRoster = true
        C_Timer.After(2, function()
            if IsInGuild() then
                print("Requesting guild roster...")
                RefreshRoster()
            end
        end)
    end

    -- Check guild/raid chat for the word "bid", then handle
    if event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_RAID" then
        if message:lower():find("bid") then
            print(sender .. " has listed their bid!")
        end
    end
end)

-- Register Events for the event listener
listener:RegisterEvent("CHAT_MSG_GUILD")
listener:RegisterEvent("CHAT_MSG_RAID")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")
listener:RegisterEvent("GUILD_ROSTER_UPDATE")
listener:RegisterEvent("PLAYER_LOGIN")
-- Unused for now, will add back later.
-- listener:RegisterEvent("CHAT_MSG_WHISPER")
-- listener:RegisterEvent("CHAT_MSG_WHISPER_INFORM")

-- Mark frame as closable with Escape, among other nifty functions that come with special frames
table.insert(UISpecialFrames, "PSKMainFrame")
