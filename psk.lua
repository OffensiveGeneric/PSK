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

--[[ This is the slash command to open the addon via the console.  We'll also add a minimap button later. ]]
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

local function eventHandler(self, event, ...)

	if event == CHAT_MSG_GUILD
		-- [[ Get the most recent line (0) in Guild (2) chat. ]]
		local msg, sender 
		msg = C_ChatInfo.GetChatLineText(2, 0)
		sender = C_ChatInfo.GetChatLineSenderName(msg)
		Print(sender .. " said " .. chatLine )
	elseif event = CHAT_MSG_RAID
		-- [[ Get the most recent line (0) in Guild (2) chat. ]]
		local msg, sender 
		msg = C_ChatInfo.GetChatLineText(2, 0)
		sender = C_ChatInfo.GetChatLineSenderName(msg)
		Print(sender .. " said " .. chatLine )
    end
	
	if pskFrame:IsShown() then
		--[[ Display flag for bid next to player's name later ]]
    end
end

pskListenerFrame:SetScript("OnEvent", eventHandler)
pskListenerFrame:RegisterEvent("CHAT_MSG_GUILD")
pskListenerFrame:RegisterEvent("CHAT_MSG_RAID")
