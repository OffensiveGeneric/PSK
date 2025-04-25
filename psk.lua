
--[[ The database is defined in psk.toc for all characters on an account (instead of just one), 
		so alts can access it also. Without the DB being defined, all data will be lost on 
		reload/relog.  ]]
if not PSKDB then
	PSKDB = {
		
	}
end

--[[ Create the main frame.  Everything in the WoW UI requires a frame to attach to. 
		"BasicFrameTemplateWithInset provides the title bar, close button, background, 
		and border for the frame.]]
local pskFrame = CreateFrame("Frame", "PSKMainFrame", UIParent, "BasicFrameTemplateWithInset")
pskFrame:SetSize(800, 600)
pskFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
pskFrame:SetFrameStrata("HIGH")
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

--[[ This is the slash command to open the addon via the console.  We'll also add a minimap button later. ]]
SLASH_PSK1 = "/psk"
SlashCmdList["PSK"] = function()
	pskFrame:Show()
end 

--[[ Adds "PSKMainFrame" to the "special" frames so that it has access to key controls (ESC to close, etc).
		Other special frames are things like the character frame, social frame, etc. ]]
table.insert(UISpecialFrames, "PSKMainFrame")

--[[ Creates another frame for an event listener, and sets its parent to the UI parent frame ]]
local pskListenerFrame = CreateFrame("Frame", "PSKEventListenerFrame", UIParent)


--[[ Handle the events that are registered below ]]
local function eventHandler(self, event, ...)

	if event == "CHAT_MSG_GUILD" 
		or event == "CHAT_MSG_RAID" 
		or event == "CHAT_MSG_WHISPER_INFORM" then
		
        print(sender .. " said: " .. message)
		
    end

end

pskListenerFrame:SetScript("OnEvent", function(self, event, message, sender, ...)
    if event == "CHAT_MSG_GUILD" 
		or event == "CHAT_MSG_RAID" 
		or event == "CHAT_MSG_WHISPER_INFORM" 
		or event == "CHAT_MSG_WHISPER" then
		
			print(sender .. " said: " .. message)
			
    end
	
	if pskFrame:IsShown() then
		print("PSK is showing")
    end
end)

pskListenerFrame:RegisterEvent("CHAT_MSG_GUILD")
pskListenerFrame:RegisterEvent("CHAT_MSG_RAID")
pskListenerFrame:RegisterEvent("CHAT_MSG_WHISPER")
pskListenerFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")

