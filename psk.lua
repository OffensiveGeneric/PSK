--[[ Ken: This code is untested since I'm at work.  If you feel like running it, let me know what happens ;-)
	The basic breakdown is this:
		- We create a frame (pskFrame) and attach it to the UIParent, using the BasicFrameTemplateWithInset 
			template.
		- Then we attach drag/drop functions with sounds for the frame.
		- Afterwards, we create a slash command so the addon can be opened with /psk.  
			TO DO: Use Ace3 to create a minimap button.
		- We insert PSKMainFrame into the UISpecialFrames collection so it gets nifty UI stuff.
		- We create an event listener frame (everythin is frames, lol) called pskListenerFrame
		- We create our event handler and tell it to do two things: 
			Print the last guild or raid chat message back to us in the console (yellow system text)
		- Finally, we register events to our event handler so that it can actually see them.
]] 


--[[ The database is defined in psk.toc for all characters on an account (instead of just one), 
		so alts can access it also. Without the DB being defined, all data will be lost on 
		reload/relog.  ]]
if not PSKDB then
	PSKDB = { 
		["CharName"] = {
			class = "UNKNOWN",
			seen = os.date("%Y%m%d %H%M")
	}
end

--[[ Create the main frame.  Everything in the WoW UI requires a frame to attach to. 
		"BasicFrameTemplateWithInset provides the title bar, close button, background, 
		and border for the frame.]]
local pskFrame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
pskFrame:SetSize(800, 600)
pskFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
pskFrame.TitleBg:SetHeight(30)
pskFrame.title = pskFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pskFrame.title:SetPoint("TOPLEFT", pskFrame.TitleBg, "TOPLEFT", 5, -3)
pskFrame.title:SetText("Perchance PSK")
pskFrame:Hide()
pskFrame:EnableMouse(true)
pskFrame:SetMovable(true)
pskFrame:RegisterForDrag("LeftButton")

--[[ Mouse functions for the frame ]]
pskFrame:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)

pskFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
end)

pskFrame:SetScript("OnShow", function()
        PlaySound(808)
end)

pskFrame:SetScript("OnHide", function()
        PlaySound(808)
end)

--[[ Create a frame to attach to pskFrame that allows for scrolling ]]
local scrollFrame = CreateFrame("ScrollFrame", nil, pskFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -10)
scrollFrame:SetScrollChild(content)
content:SetSize(260, 400)

--[[ Grab guild member info and save to db ]]
local function SaveOnlineGuildMembers()
	PSKDB.names = PSKDB.names or {}
		
	local total = GetNumGuildMembers()
	
	for i = 1, total do
		local name, _, _, _, _, _, _, _, online, _, _, classFileName = GetGuildRosterInfo(i)
		name = Ambiguate(name, "short")
		classFileName = classFileName or "UNKNOWN"
		
		if online and not PSKDB[name] then
			PSKDB[name] = {
				class = classFileName, 
				seen = date("%Y-%m-%d %H:%M")
			}
		end
	end
end

--[[ Draw the UI ]]
local function UpdateNameList()
	local yOffset = -5
	--[[ local previousFontString ]]
	
	content:setSize(260, math.max(#PSKDB.names * 20, 400))
	
	for name, data in pairs(PSKDB) do
	
		--[[ Class info ]]
		local class = data.class or "UNKNOWN"
		local seen = data.seen or "UNKNOWN"
	
		--[[ Class icon]]
		local icon = content:CreateTexture(nil, "ARTWORK")
		icon.SetSize(16, 16)
		icon:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)
		
		local coords = CLASS_ICON_TCOORDS[class]
		
		--[[ Set class icon ]]
		if coords then
			icon:SetTexture("Interface\GLUES\\CHARACTERCREATE\UI-CHARACTERCREATE-CLASSES")
			icon:SetTextCoord(unpack(coords))
		end
		
		--[[ Name and tooltip ]]
		local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		fs:SetText(name)
		fs:SetPoint("LEFT", icon, "RIGHT", 5, 0)
		
		--[[ Tooltip on hover ]]
		local hoverFrame = CreateFrame("Frame", nil, content)
		hoverFrame:SetPoint("TOPLEFT", icon)
		hoverFrame:SetSize(260, 20)
		hoverFrame:SetScript("OnEnter", function()
			GameToolTip:SetOwner(hoverFrame, "ACHNOR_RIGHT")
			GameToolTip:SetText(name .. "\nFirst Seen: " .. seen, 1, 1, 1)
			GameToolTip:Show()
		end)
		
		hoverFrame:SetScript("OnLeave", GameTooltip_Hide)
		yOffset = yOffset - 20
	end
end


--[[ This is the slash command to open the addon via the console.  We'll also add a minimap button later with Ace3. ]]
SLASH_PSK = "/psk"
SlashCmdList["PSK"] = function()
	if pskFrame:IsShown() then	
		pskFrame:Hide()
	else
		pskFrame.Show()
	end
end 

--[[ Adds "PSKMainFrame" to the "special" frames so that it has access to key controls (ESC to close, etc).
		Other special frames are things like the character frame, social frame, etc. ]]
table.insert(UISpecialFrames, "PSKMainFrame")

--[[ Creates another frame for an event listener, and sets its parent to the UI parent frame ]]
local pskListenerFrame = CreateFrame("Frame", "PSKEventListenerFrame", UIParent)
pskListenerFrame:RegisterEvent("CHAT_MSG_GUILD")
pskListenerFrame:RegisterEvent("CHAT_MSG_RAID")
pskListenerFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
pskListenerFrame:SetScript("OnEvent", function(self, event, ...)

	--[[ If you are in a guild, get the guild roster ]]
	if IsInGuild() then
		C_GuildInfo.GuildRoster()
	end
	
	--[[ If the guild roster was updated, update the name list ]]
	if event == "GUILD_ROSTER_UPDATE" then
		SaveOnlineGuildMembers()
		UpdateNameList()
	end
	
	if pskFrame:IsShown() then
		--[[ TO DO: Display flag for bid next to player's name later ]]
    end
	
	-- [[ If guild chat said anything, print what they said to console ]]
	if event == CHAT_MSG_GUILD
		-- [[ Get the most recent line (0) in Guild (2) chat. ]]
		local msg, sender 
		msg = C_ChatInfo.GetChatLineText(2, 0)
		sender = C_ChatInfo.GetChatLineSenderName(msg)
		Print(sender .. " said " .. chatLine )
	end
	
	--[[ If raid chat said anything, print what they said to console ]]
	if event = CHAT_MSG_RAID
		-- [[ Get the most recent line (0) in Guild (2) chat. ]]
		local msg, sender 
		msg = C_ChatInfo.GetChatLineText(2, 0)
		sender = C_ChatInfo.GetChatLineSenderName(msg)
		Print(sender .. " said " .. chatLine )
    end
end
