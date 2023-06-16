--------------------------------------------------------------------------------------
--	Backport and modifications by Sattva
--	Credit to simon_hirsig & tablegrapes
--	Credit to Macumba for checking all rares in list and then adding frFR database!
--	Code from unitscan & unitscan-rares
--------------------------------------------------------------------------------------
	
	-- Create global table
	_G.unitscanDB = _G.unitscanDB or {}

	-- Get locale table
	local void, unitscan = ...
	local L = unitscan.L



	-- Create locals
	local unitscan = CreateFrame'Frame'
	local forbidden
	local is_resting
	local deadscan = false
	local unitscanLC, unitscanCB, usDropList, usConfigList, usLockList = {}, {}, {}, {}, {}
	local void

	-- Version
	unitscanLC["AddonVer"] = "3.3.5"	

	--===== Check the current locale of the WoW client =====--
	local currentLocale = GetLocale()

	--===== Check for game version =====--
	local isTBC = select(4, GetBuildInfo()) == 20400 -- true if TBC 2.4.3
	local isWOTLK = select(4, GetBuildInfo()) == 30300 -- true if WOTLK 3.3.5

----------------------------------------------------------------------
--	L00: unitscan
----------------------------------------------------------------------
	-- inititialize vairables
	unitscanLC["NumberOfPages"] = 9

	-- Create event frame
	local usEvt = CreateFrame("FRAME")
	usEvt:RegisterEvent("ADDON_LOADED")
	usEvt:RegisterEvent("PLAYER_LOGIN")
	usEvt:RegisterEvent("PLAYER_ENTERING_WORLD")


--------------------------------------------------------------------------------
-- More Events
--------------------------------------------------------------------------------

	unitscan:RegisterEvent'ADDON_LOADED'
	unitscan:RegisterEvent'ADDON_ACTION_FORBIDDEN'
	unitscan:RegisterEvent'PLAYER_TARGET_CHANGED'
	unitscan:RegisterEvent'ZONE_CHANGED_NEW_AREA'
	unitscan:RegisterEvent'PLAYER_LOGIN'
	unitscan:RegisterEvent'PLAYER_UPDATE_RESTING'


--------------------------------------------------------------------------------
-- Colors
--------------------------------------------------------------------------------

	--===== Some Colors for borders of button =====--
	local BROWN = {.7, .15, .05}
	local YELLOW = {1, 1, .15}


--------------------------------------------------------------------------------
-- Creating SavedVariables DB tables here. 
--------------------------------------------------------------------------------

	--===== DB Table for user-added targets via /unitscan "name" or /unitscan target =====--
	unitscan_targets = {}

	--===== DB Table for user-added rare spawns to ignore from scanning =====--
	unitscan_ignored = {}

	--===== DB Table for Default Settings =====--
	unitscan_defaults = {
		CHECK_INTERVAL = .3,
	}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

	--===== Local table to prevent spamming the alert. =====--
	local found = {}

	rare_spawns = {}
----------------------------------------------------------------------
--	L01: Functions
----------------------------------------------------------------------

	-- Print text
	function unitscanLC:Print(text)
		DEFAULT_CHAT_FRAME:AddMessage(L[text], 1.0, 0.85, 0.0)
	end

	-- Lock and unlock an item
	function unitscanLC:LockItem(item, lock)
		if lock then
			item:Disable()
			item:SetAlpha(0.3)
		else
			item:Enable()
			item:SetAlpha(1.0)
		end
	end

	-- Hide configuration panels
	function unitscanLC:HideConfigPanels()
		for k, v in pairs(usConfigList) do
			v:Hide()
		end
	end

	-- Show a single line prefilled editbox with copy functionality
	function unitscanLC:ShowSystemEditBox(word, focuschat)
		if not unitscanLC.FactoryEditBox then
			-- Create frame for first time
			local eFrame = CreateFrame("FRAME", nil, UIParent)
			unitscanLC.FactoryEditBox = eFrame
			eFrame:SetSize(700, 110)
			eFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
			eFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			-- eFrame:SetFrameLevel(5000)
			eFrame:EnableMouse(true)
			eFrame:EnableKeyboard()
			eFrame:SetScript("OnMouseDown", function(self, btn)
				if btn == "RightButton" then
					eFrame:Hide()
				end
			end)
			-- Add background color
			eFrame.t = eFrame:CreateTexture(nil, "BACKGROUND")
			eFrame.t:SetAllPoints()
			eFrame.t:SetTexture(0.05, 0.05, 0.05, 0.9)
			-- Add copy title
			eFrame.f = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.f:SetPoint("TOPLEFT", x, y)
			eFrame.f:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -52)
			eFrame.f:SetWidth(676)
			eFrame.f:SetJustifyH("LEFT")
			eFrame.f:SetWordWrap(false)
			-- Add copy label
			eFrame.c = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.c:SetPoint("TOPLEFT", x, y)
			eFrame.c:SetText(L["Press CTRL/C to copy"])
			eFrame.c:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -82)
			-- Add feedback label
			eFrame.x = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.x:SetPoint("TOPRIGHT", x, y)
			eFrame.x:SetText("|cff00ff00Feedback Discord:|r |cffadd8e6Sattva#7238|r")

			eFrame.x:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -52)
			hooksecurefunc(eFrame.f, "SetText", function()
				eFrame.f:SetWidth(676 - eFrame.x:GetStringWidth() - 26)
			end)
			-- Add cancel label
			eFrame.x = eFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
			eFrame.x:SetPoint("TOPRIGHT", x, y)
			eFrame.x:SetText(L["Right-click to close"])
			eFrame.x:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -82)
			-- Create editbox
			eFrame.b = CreateFrame("EditBox", nil, eFrame, "InputBoxTemplate")
			eFrame.b:ClearAllPoints()
			eFrame.b:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 16, -12)
			eFrame.b:SetSize(672, 24)
			eFrame.b:SetFontObject("GameFontNormalLarge")
			eFrame.b:SetTextColor(1.0, 1.0, 1.0, 1)
			eFrame.b:DisableDrawLayer("BACKGROUND")
			-- eFrame.b:SetBlinkSpeed(0)
			eFrame.b:SetHitRectInsets(99, 99, 99, 99)
			eFrame.b:SetAutoFocus(true)
			eFrame.b:SetAltArrowKeyMode(true)
			eFrame.b:EnableMouse(true)
			eFrame.b:EnableKeyboard(true)
			-- Editbox texture
			eFrame.t = CreateFrame("FRAME", nil, eFrame.b)
			eFrame.t:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
			eFrame.t:SetPoint("LEFT", -6, 0)
			eFrame.t:SetWidth(eFrame.b:GetWidth() + 6)
			eFrame.t:SetHeight(eFrame.b:GetHeight())
			eFrame.t:SetBackdropColor(1.0, 1.0, 1.0, 0.3)
			-- Handler
			-- it doesnt work in 3.3.5
			eFrame.b:SetScript("OnKeyDown", function(void, key)
				if key == "c" and IsControlKeyDown() then
					LibCompat.After(0.1, function()
						eFrame:Hide()
						ActionStatus_DisplayMessage(L["Copied to clipboard."], true)
						if unitscanLC.FactoryEditBoxFocusChat then
							local eBox = ChatEdit_ChooseBoxForSend()
							ChatEdit_ActivateChat(eBox)
						end
					end)
				end
			end)
			-- Prevent changes
			-- eFrame.b:SetScript("OnEscapePressed", function() eFrame:Hide() end)
			-- eFrame.b:SetScript("OnEnterPressed", eFrame.b.HighlightText)
			-- eFrame.b:SetScript("OnMouseDown", eFrame.b.ClearFocus)
			-- eFrame.b:SetScript("OnMouseUp", eFrame.b.HighlightText)
			eFrame.b:SetScript("OnChar", function() eFrame.b:SetText(word); eFrame.b:HighlightText(); end);
			eFrame.b:SetScript("OnMouseUp", function() eFrame.b:HighlightText(); end);
			eFrame.b:SetScript("OnEscapePressed", function() eFrame:Hide() end)
			eFrame.b:SetFocus(true)
			eFrame.b:HighlightText()
			eFrame:Show()
		end
		if focuschat then unitscanLC.FactoryEditBoxFocusChat = true else unitscanLC.FactoryEditBoxFocusChat = nil end
		unitscanLC.FactoryEditBox:Show()
		unitscanLC.FactoryEditBox.b:SetText(word)
		unitscanLC.FactoryEditBox.b:HighlightText()
		unitscanLC.FactoryEditBox.b:SetScript("OnChar", function() unitscanLC.FactoryEditBox.b:SetFocus(true) unitscanLC.FactoryEditBox.b:SetText(word) unitscanLC.FactoryEditBox.b:HighlightText() end)
		unitscanLC.FactoryEditBox.b:SetScript("OnKeyUp", function() unitscanLC.FactoryEditBox.b:SetFocus(true) unitscanLC.FactoryEditBox.b:SetText(word) unitscanLC.FactoryEditBox.b:HighlightText() end)
	end

	-- Load a string variable or set it to default if it's not set to "On" or "Off"
	function unitscanLC:LoadVarChk(var, def)
		if unitscanDB[var] and type(unitscanDB[var]) == "string" and unitscanDB[var] == "On" or unitscanDB[var] == "Off" then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Load a numeric variable and set it to default if it's not within a given range
	function unitscanLC:LoadVarNum(var, def, valmin, valmax)
		if unitscanDB[var] and type(unitscanDB[var]) == "number" and unitscanDB[var] >= valmin and unitscanDB[var] <= valmax then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Load an anchor point variable and set it to default if the anchor point is invalid
	function unitscanLC:LoadVarAnc(var, def)
		if unitscanDB[var] and type(unitscanDB[var]) == "string" and unitscanDB[var] == "CENTER" or unitscanDB[var] == "TOP" or unitscanDB[var] == "BOTTOM" or unitscanDB[var] == "LEFT" or unitscanDB[var] == "RIGHT" or unitscanDB[var] == "TOPLEFT" or unitscanDB[var] == "TOPRIGHT" or unitscanDB[var] == "BOTTOMLEFT" or unitscanDB[var] == "BOTTOMRIGHT" then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Load a string variable and set it to default if it is not a string (used with minimap exclude list)
	function unitscanLC:LoadVarStr(var, def)
		if unitscanDB[var] and type(unitscanDB[var]) == "string" then
			unitscanLC[var] = unitscanDB[var]
		else
			unitscanLC[var] = def
			unitscanDB[var] = def
		end
	end

	-- Show tooltips for checkboxes
	function unitscanLC:TipSee()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent()
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for dropdown menu tooltips
	function unitscanLC:ShowDropTip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = self:GetParent():GetParent():GetParent()
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Show tooltips for configuration buttons and dropdown menus
	function unitscanLC:ShowTooltip()
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		local parent = unitscanLC["PageF"]
		local pscale = parent:GetEffectiveScale()
		local gscale = UIParent:GetEffectiveScale()
		local tscale = GameTooltip:GetEffectiveScale()
		local gap = ((UIParent:GetRight() * gscale) - (unitscanLC["PageF"]:GetRight() * pscale))
		if gap < (250 * tscale) then
			GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
		else
			GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
		end
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end

	-- Create configuration button
	function unitscanLC:CfgBtn(name, parent)
		local CfgBtn = CreateFrame("BUTTON", nil, parent)
		unitscanCB[name] = CfgBtn
		CfgBtn:SetWidth(20)
		CfgBtn:SetHeight(20)
		CfgBtn:SetPoint("LEFT", parent.f, "RIGHT", 0, 0)

		CfgBtn.t = CfgBtn:CreateTexture(nil, "BORDER")
		CfgBtn.t:SetAllPoints()
		CfgBtn.t:SetTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn.t:SetTexCoord(0, 0.50, 0, 0.50);
		CfgBtn.t:SetVertexColor(1.0, 0.82, 0, 1.0)

		CfgBtn:SetHighlightTexture("Interface\\WorldMap\\Gear_64.png")
		CfgBtn:GetHighlightTexture():SetTexCoord(0, 0.50, 0, 0.50);

		CfgBtn.tiptext = L["Click to configure the settings for this option."]
		CfgBtn:SetScript("OnEnter", unitscanLC.ShowTooltip)
		CfgBtn:SetScript("OnLeave", GameTooltip_Hide)
	end

	-- Create a help button to the right of a fontstring
	function unitscanLC:CreateHelpButton(frame, panel, parent, tip)
		unitscanLC:CfgBtn(frame, panel)
		unitscanCB[frame]:ClearAllPoints()
		unitscanCB[frame]:SetPoint("LEFT", parent, "RIGHT", -parent:GetWidth() + parent:GetStringWidth(), 0)
		unitscanCB[frame]:SetSize(25, 25)
		unitscanCB[frame].t:SetTexture("Interface\\COMMON\\help-i.blp")
		unitscanCB[frame].t:SetTexCoord(0, 1, 0, 1)
		unitscanCB[frame].t:SetVertexColor(0.9, 0.8, 0.0)
		unitscanCB[frame]:SetHighlightTexture("Interface\\COMMON\\help-i.blp")
		unitscanCB[frame]:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
		unitscanCB[frame].tiptext = L[tip]
		unitscanCB[frame]:SetScript("OnEnter", unitscanLC.TipSee)
	end

	-- Show a footer
	function unitscanLC:MakeFT(frame, text, left, width)
		local footer = unitscanLC:MakeTx(frame, text, left, 96)
		footer:SetWidth(width); footer:SetJustifyH("LEFT"); footer:SetWordWrap(true); footer:ClearAllPoints()
		footer:SetPoint("BOTTOMLEFT", left, 96)
	end

	-- Capitalise first character in a string
	function unitscanLC:CapFirst(str)
		return gsub(string.lower(str), "^%l", strupper)
	end

	-- Show memory usage stat
	function unitscanLC:ShowMemoryUsage(frame, anchor, x, y)

		-- Create frame
		local memframe = CreateFrame("FRAME", nil, frame)
		memframe:ClearAllPoints()
		memframe:SetPoint(anchor, x, y)
		memframe:SetWidth(100)
		memframe:SetHeight(20)

		-- Create labels
		local pretext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		pretext:SetPoint("TOPLEFT", 0, 0)
		pretext:SetText(L["Memory Usage"])

		local memtext = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memtext:SetPoint("TOPLEFT", 0, 0 - 30)

		-- Create stat
		local memstat = memframe:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		memstat:SetPoint("BOTTOMLEFT", memtext, "BOTTOMRIGHT")
		memstat:SetText("(calculating...)")

		-- Create update script
		local memtime = -1
		memframe:SetScript("OnUpdate", function(self, elapsed)
			if memtime > 2 or memtime == -1 then
				UpdateAddOnMemoryUsage();
				memtext = GetAddOnMemoryUsage("unitscan")
				memtext = math.floor(memtext + .5) .. " KB"
				memstat:SetText(memtext);
				memtime = 0;
			end
			memtime = memtime + elapsed;
		end)

		-- Release memory
		unitscanLC.ShowMemoryUsage = nil

	end

	-- Check if player is in LFG queue
	function unitscanLC:IsInLFGQueue()
		if unitscanLC["GameVer"] == "5" then
			if GetLFGQueueStats(LE_LFG_CATEGORY_LFD) or GetLFGQueueStats(LE_LFG_CATEGORY_LFR) or GetLFGQueueStats(LE_LFG_CATEGORY_RF) then
				return true
			end
		else
			if MiniMapLFGFrame:IsShown() then return true end
		end
	end

	-- Check if player is in combat
	function unitscanLC:PlayerInCombat()
		if (UnitAffectingCombat("player")) then
			unitscanLC:Print("You cannot do that in combat.")
			return true
		end
	end

	--  Hide panel and pages
	function unitscanLC:HideFrames()

		-- Hide option pages
		for i = 0, unitscanLC["NumberOfPages"] do
			if unitscanLC["Page"..i] then
				unitscanLC["Page"..i]:Hide();
			end;
		end

		-- Hide options panel
		unitscanLC["PageF"]:Hide();

	end

	-- Find out if Leatrix Plus is showing (main panel or config panel)
	function unitscanLC:IsPlusShowing()
		if unitscanLC["PageF"]:IsShown() then return true end
		for k, v in pairs(usConfigList) do
			if v:IsShown() then
				return true
			end
		end
	end

	-- Check if a name is in your friends list or guild (does not check realm as realm is unknown for some checks)
	function unitscanLC:FriendCheck(name)

		-- Do nothing if name is empty (such as whispering from the Battle.net app)
		if not name then return end

		-- Update friends list
		ShowFriends()

		-- Remove realm if it exists
		if name ~= nil then
			name = strsplit("-", name, 2)
		end

		-- Check character friends
		for i = 1, GetNumFriends() do
			local friendName, _, _, _, friendConnected = GetFriendInfo(i)
			if friendName ~= nil then -- Check if name is not nil
				friendName = strsplit("-", friendName, 2)
			end

			if (name == friendName) and friendConnected then -- Check if name matches and friend is connected
				return true
			end
		end

		-- Check guild members if guild is enabled (new members may need to press J to refresh roster)
		if unitscanLC["FriendlyGuild"] == "On" then
			local gCount = GetNumGuildMembers()
			for i = 1, gCount do
				local gName, void, void, void, void, void, void, void, gOnline = GetGuildRosterInfo(i)
				if gOnline then
					gName = strsplit("-", gName, 2)
					-- Return true if character name matches
					if (name == gName) then
						return true
					end
				end
			end
		end
	end	


---------------------------------------------------------------------------------------------------
-- Functions mainly for restrictions and conditions for unit scanning, RAID mark setup conditions.
---------------------------------------------------------------------------------------------------


	unitscan:SetScript('OnUpdate', function() unitscan.UPDATE() end)
	unitscan:SetScript('OnEvent', function(_, event, arg1)
		if event == 'ADDON_LOADED' and arg1 == 'unitscan' then
			unitscan.LOAD()
		elseif event == 'ADDON_ACTION_FORBIDDEN' and arg1 == 'unitscan' then
			forbidden = true
		elseif event == 'PLAYER_TARGET_CHANGED' then
			if UnitName'target' and strupper(UnitName'target') == unitscan.button:GetText() and not GetRaidTargetIndex'target' and (not UnitInRaid'player' or IsRaidOfficer() or IsRaidLeader()) then
				SetRaidTarget('target', 2)
			end
		elseif event == 'ZONE_CHANGED_NEW_AREA' or 'PLAYER_LOGIN' or 'PLAYER_UPDATE_RESTING' then
			unitscan_LoadRareSpawns()
			local loc = GetRealZoneText()
			local _, instance_type = IsInInstance()
			is_resting = IsResting()
			nearby_targets = {}

			if instance_type == "raid" or instance_type == "pvp" then return end
			if loc == nil then return end

			for name, zone in pairs(rare_spawns) do
				if not unitscan_ignored[name] then
					local reaction = UnitReaction("player", name)
					if not reaction or reaction < 4 then reaction = true else reaction = false end
					if reaction and (loc == zone or string.match(loc, zone) or zone == "A H") then 
						table.insert(nearby_targets, name)
					end
				end
			end
			-- print("nearby_targets:", table.concat(nearby_targets, ", ")) -- Don't delete, it's a useful debug code to print what was added to the rare list scanning.
		end
	end)


-------------------------------------------------------------------------------------
-- Function to refresh current rare mob list, after doing /unitscan ignore #unitname
-------------------------------------------------------------------------------------


	function unitscan.refresh_nearby_targets()
		unitscan_LoadRareSpawns()
		-- print("Refreshed nearby rare list.")
	    local loc = GetRealZoneText()
	    local _, instance_type = IsInInstance()
	    is_resting = IsResting()
	    nearby_targets = {}
	    
	    if instance_type == "raid" or instance_type == "pvp" then return end
	    if loc == nil then return end
	    
	    for name, zone in pairs(rare_spawns) do
	        if not unitscan_ignored[name] then
	            local reaction = UnitReaction("player", name)
	            if not reaction or reaction < 4 then reaction = true else reaction = false end
	            if reaction and (loc == zone or string.match(loc, zone) or zone == "A H") then 
	                table.insert(nearby_targets, name)
	            end
	        end
	    end

	    -- print("nearby_targets:", table.concat(nearby_targets, ", "))
	end



----------------------------------------------------------------------
--	L02: Locks
----------------------------------------------------------------------

	-- Function to set lock state for configuration buttons
	function unitscanLC:LockOption(option, item, reloadreq)
		if reloadreq then
			-- Option change requires UI reload
			if unitscanLC[option] ~= unitscanDB[option] or unitscanLC[option] == "Off" then
				unitscanLC:LockItem(unitscanCB[item], true)
			else
				unitscanLC:LockItem(unitscanCB[item], false)
			end
		else
			-- Option change does not require UI reload
			if unitscanLC[option] == "Off" then
				unitscanLC:LockItem(unitscanCB[item], true)
			else
				unitscanLC:LockItem(unitscanCB[item], false)
			end
		end
	end

--	Set lock state for configuration buttons
	function unitscanLC:SetDim()
		--unitscanLC:LockOption("AutomateQuests", "AutomateQuestsBtn", false)			-- Automate quests
		--unitscanLC:LockOption("AutoAcceptRes", "AutoAcceptResBtn", false)			-- Accept resurrection
		--unitscanLC:LockOption("AutoReleasePvP", "AutoReleasePvPBtn", false)			-- Release in PvP
		--unitscanLC:LockOption("AutoSellJunk", "AutoSellJunkBtn", false)				-- Sell junk automatically
		--unitscanLC:LockOption("AutoRepairGear", "AutoRepairBtn", false)				-- Repair automatically
		unitscanLC:LockOption("InviteFromWhisper", "InvWhisperBtn", false)			-- Invite from whispers
		unitscanLC:LockOption("FilterChatMessages", "FilterChatMessagesBtn", true)	-- Filter chat messages
		unitscanLC:LockOption("MailFontChange", "MailTextBtn", true)					-- Resize mail text
		unitscanLC:LockOption("QuestFontChange", "QuestTextBtn", true)				-- Resize quest text
		unitscanLC:LockOption("BookFontChange", "BookTextBtn", true)					-- Resize book text
		unitscanLC:LockOption("MinimapModder", "ModMinimapBtn", true)				-- Enhance minimap
		unitscanLC:LockOption("TipModEnable", "MoveTooltipButton", true)				-- Enhance tooltip
		-- unitscanLC:LockOption("EnhanceDressup", "EnhanceDressupBtn", true)			-- Enhance dressup
		unitscanLC:LockOption("EnhanceQuestLog", "EnhanceQuestLogBtn", true)			-- Enhance quest log
		unitscanLC:LockOption("EnhanceTrainers", "EnhanceTrainersBtn", true)			-- Enhance trainers
		-- unitscanLC:LockOption("ShowCooldowns", "CooldownsButton", true)				-- Show cooldowns
		unitscanLC:LockOption("ShowPlayerChain", "ModPlayerChain", true)				-- Show player chain
		unitscanLC:LockOption("ShowWowheadLinks", "ShowWowheadLinksBtn", true)		-- Show Wowhead links
		unitscanLC:LockOption("ShowFlightTimes", "ShowFlightTimesBtn", true)			-- Show flight times
		unitscanLC:LockOption("FrmEnabled", "MoveFramesButton", true)				-- Manage frames
		unitscanLC:LockOption("ManageBuffs", "ManageBuffsButton", true)				-- Manage buffs
		unitscanLC:LockOption("ManageWidget", "ManageWidgetButton", true)			-- Manage widget
		unitscanLC:LockOption("ManageFocus", "ManageFocusButton", true)				-- Manage focus
		unitscanLC:LockOption("ManageTimer", "ManageTimerButton", true)				-- Manage timer
		unitscanLC:LockOption("ManageDurability", "ManageDurabilityButton", true)	-- Manage durability
		unitscanLC:LockOption("ManageVehicle", "ManageVehicleButton", true)			-- Manage vehicle
		unitscanLC:LockOption("ClassColFrames", "ClassColFramesBtn", true)			-- Class colored frames
		unitscanLC:LockOption("SetWeatherDensity", "SetWeatherDensityBtn", false)	-- Set weather density
		unitscanLC:LockOption("ViewPortEnable", "ModViewportBtn", true)				-- Enable viewport
		unitscanLC:LockOption("MuteGameSounds", "MuteGameSoundsBtn", false)			-- Mute game sounds
		unitscanLC:LockOption("MuteCustomSounds", "MuteCustomSoundsBtn", false)		-- Mute custom sounds
		unitscanLC:LockOption("StandAndDismount", "DismountBtn", true)				-- Dismount me
	end


----------------------------------------------------------------------
--	L03: Restarts
----------------------------------------------------------------------

	-- Set the reload button state
	function unitscanLC:ReloadCheck()

		-- Chat
		if	(unitscanLC["UseEasyChatResizing"]	~= unitscanDB["UseEasyChatResizing"])	-- Use easy resizing
		or	(unitscanLC["NoCombatLogTab"]		~= unitscanDB["NoCombatLogTab"])			-- Hide the combat log
		or	(unitscanLC["NoChatButtons"]			~= unitscanDB["NoChatButtons"])			-- Hide chat buttons
		or	(unitscanLC["UnclampChat"]			~= unitscanDB["UnclampChat"])			-- Unclamp chat frame
		or	(unitscanLC["MoveChatEditBoxToTop"]	~= unitscanDB["MoveChatEditBoxToTop"])	-- Move editbox to top
		or	(unitscanLC["MoreFontSizes"]			~= unitscanDB["MoreFontSizes"])			-- More font sizes
		or	(unitscanLC["NoStickyChat"]			~= unitscanDB["NoStickyChat"])			-- Disable sticky chat
		or	(unitscanLC["UseArrowKeysInChat"]	~= unitscanDB["UseArrowKeysInChat"])		-- Use arrow keys in chat
		or	(unitscanLC["NoChatFade"]			~= unitscanDB["NoChatFade"])				-- Disable chat fade
		or	(unitscanLC["ClassColorsInChat"]		~= unitscanDB["ClassColorsInChat"])		-- Use class colors in chat
		or	(unitscanLC["RecentChatWindow"]		~= unitscanDB["RecentChatWindow"])		-- Recent chat window
		or	(unitscanLC["MaxChatHstory"]			~= unitscanDB["MaxChatHstory"])			-- Increase chat history
		or	(unitscanLC["FilterChatMessages"]	~= unitscanDB["FilterChatMessages"])		-- Filter chat messages
		or	(unitscanLC["RestoreChatMessages"]	~= unitscanDB["RestoreChatMessages"])	-- Restore chat messages

		-- Text
		or	(unitscanLC["HideErrorMessages"]		~= unitscanDB["HideErrorMessages"])		-- Hide error messages
		or	(unitscanLC["NoHitIndicators"]		~= unitscanDB["NoHitIndicators"])		-- Hide portrait text
		or	(unitscanLC["HideZoneText"]			~= unitscanDB["HideZoneText"])			-- Hide zone text
		or	(unitscanLC["HideKeybindText"]		~= unitscanDB["HideKeybindText"])		-- Hide keybind text
		or	(unitscanLC["HideMacroText"]			~= unitscanDB["HideMacroText"])			-- Hide macro text

		or	(unitscanLC["MailFontChange"]		~= unitscanDB["MailFontChange"])			-- Resize mail text
		or	(unitscanLC["QuestFontChange"]		~= unitscanDB["QuestFontChange"])		-- Resize quest text
		or	(unitscanLC["BookFontChange"]		~= unitscanDB["BookFontChange"])			-- Resize book text

		-- Interface
		or	(unitscanLC["MinimapModder"]			~= unitscanDB["MinimapModder"])			-- Enhance minimap
		or	(unitscanLC["HideMiniAddonButtons"]	~= unitscanDB["HideMiniAddonButtons"])	-- Enhance minimap	
		or	(unitscanLC["SquareMinimap"]			~= unitscanDB["SquareMinimap"])			-- Square minimap
		or	(unitscanLC["CombineAddonButtons"]	~= unitscanDB["CombineAddonButtons"])	-- Combine addon buttons
		or	(unitscanLC["HideMiniTracking"]		~= unitscanDB["HideMiniTracking"])		-- Hide tracking button
		or	(unitscanLC["MiniExcludeList"]		~= unitscanDB["MiniExcludeList"])		-- Minimap exclude list
		or	(unitscanLC["TipModEnable"]			~= unitscanDB["TipModEnable"])			-- Enhance tooltip
		or	(unitscanLC["TipNoHealthBar"]		~= unitscanDB["TipNoHealthBar"])			-- Tooltip hide health bar
		or	(unitscanLC["EnhanceDressup"]		~= unitscanDB["EnhanceDressup"])			-- Enhance dressup
		or	(unitscanLC["EnhanceQuestLog"]		~= unitscanDB["EnhanceQuestLog"])		-- Enhance quest log
		or	(unitscanLC["EnhanceProfessions"]	~= unitscanDB["EnhanceProfessions"])		-- Enhance professions
		or	(unitscanLC["EnhanceTrainers"]		~= unitscanDB["EnhanceTrainers"])		-- Enhance trainers
		or	(unitscanLC["ShowVolume"]			~= unitscanDB["ShowVolume"])				-- Show volume slider
		or	(unitscanLC["AhExtras"]				~= unitscanDB["AhExtras"])				-- Show auction controls
		-- or	(unitscanLC["ShowCooldowns"]			~= unitscanDB["ShowCooldowns"])			-- Show cooldowns
		or	(unitscanLC["DurabilityStatus"]		~= unitscanDB["DurabilityStatus"])		-- Show durability status
		or	(unitscanLC["ShowVanityControls"]	~= unitscanDB["ShowVanityControls"])		-- Show vanity controls
		or	(unitscanLC["ShowBagSearchBox"]		~= unitscanDB["ShowBagSearchBox"])		-- Show bag search box
		-- or	(unitscanLC["ShowRaidToggle"]		~= unitscanDB["ShowRaidToggle"])			-- Show raid button
		or	(unitscanLC["ShowPlayerChain"]		~= unitscanDB["ShowPlayerChain"])		-- Show player chain
		or	(unitscanLC["ShowReadyTimer"]		~= unitscanDB["ShowReadyTimer"])			-- Show ready timer
		or	(unitscanLC["ShowWowheadLinks"]		~= unitscanDB["ShowWowheadLinks"])		-- Show Wowhead links
		or	(unitscanLC["ShowFlightTimes"]		~= unitscanDB["ShowFlightTimes"])		-- Show flight times

		-- Frames
		or	(unitscanLC["FrmEnabled"]			~= unitscanDB["FrmEnabled"])				-- Manage frames
		or	(unitscanLC["ManageBuffs"]			~= unitscanDB["ManageBuffs"])			-- Manage buffs
		or	(unitscanLC["ManageWidget"]			~= unitscanDB["ManageWidget"])			-- Manage widget
		or	(unitscanLC["ManageFocus"]			~= unitscanDB["ManageFocus"])			-- Manage focus
		or	(unitscanLC["ManageTimer"]			~= unitscanDB["ManageTimer"])			-- Manage timer
		or	(unitscanLC["ManageDurability"]		~= unitscanDB["ManageDurability"])		-- Manage durability
		or	(unitscanLC["ManageVehicle"]			~= unitscanDB["ManageVehicle"])			-- Manage vehicle
		or	(unitscanLC["ClassColFrames"]		~= unitscanDB["ClassColFrames"])			-- Class colored frames
		or	(unitscanLC["NoAlerts"]				~= unitscanDB["NoAlerts"])				-- Hide alerts
		or	(unitscanLC["NoGryphons"]			~= unitscanDB["NoGryphons"])				-- Hide gryphons
		or	(unitscanLC["NoClassBar"]			~= unitscanDB["NoClassBar"])				-- Hide stance bar

		-- System
		or	(unitscanLC["ViewPortEnable"]		~= unitscanDB["ViewPortEnable"])			-- Enable viewport
		or	(unitscanLC["NoRestedEmotes"]		~= unitscanDB["NoRestedEmotes"])			-- Silence rested emotes
		or	(unitscanLC["NoBagAutomation"]		~= unitscanDB["NoBagAutomation"])		-- Disable bag automation
		or	(unitscanLC["CharAddonList"]			~= unitscanDB["CharAddonList"])			-- Show character addons
		or	(unitscanLC["FasterLooting"]			~= unitscanDB["FasterLooting"])			-- Faster auto loot
		or	(unitscanLC["FasterMovieSkip"]		~= unitscanDB["FasterMovieSkip"])		-- Faster movie skip
		or	(unitscanLC["StandAndDismount"]		~= unitscanDB["StandAndDismount"])		-- Dismount me
		or	(unitscanLC["ShowVendorPrice"]		~= unitscanDB["ShowVendorPrice"])		-- Show vendor price
		or	(unitscanLC["CombatPlates"]			~= unitscanDB["CombatPlates"])			-- Combat plates
		or	(unitscanLC["EasyItemDestroy"]		~= unitscanDB["EasyItemDestroy"])		-- Easy item destroy

		then
			-- Enable the reload button
			unitscanLC:LockItem(unitscanCB["ReloadUIButton"], false)
			unitscanCB["ReloadUIButton"].f:Show()
		else
			-- Disable the reload button
			unitscanLC:LockItem(unitscanCB["ReloadUIButton"], true)
			unitscanCB["ReloadUIButton"].f:Hide()
		end

	end

----------------------------------------------------------------------
--	L40: Player
----------------------------------------------------------------------

	function unitscanLC:Player()

		----------------------------------------------------------------------
		-- Minimap button (no reload required)
		----------------------------------------------------------------------

		do

			-- Minimap button click function
			local function MiniBtnClickFunc(arg1)

				if unitscanLC["LeaPlusFrameMove"] and unitscanLC["LeaPlusFrameMove"]:IsShown() then return end
                if unitscanCB["TooltipDragFrame"] and unitscanCB["TooltipDragFrame"]:IsShown() then return end
                if InterfaceOptionsFrame:IsShown() or VideoOptionsFrame:IsShown() then return end

                if arg1 == "LeftButton" then
					-- No modifier key toggles the options panel
					if unitscanLC:IsPlusShowing() then
						unitscanLC:HideFrames()
						unitscanLC:HideConfigPanels()
					else
						unitscanLC:HideFrames()
						unitscanLC["PageF"]:Show()
					end
					unitscanLC["Page" .. unitscanLC["LeaStartPage"]]:Show()
                end
                if arg1 == "RightButton" then
                        ReloadUI();
                    end

			end

			-- Create minimap button using LibDBIcon
			local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("unitscan", {
				type = "data source",
				text = "unitscan",
			    icon = "Interface\\Icons\\Inv_qirajidol_life",
				OnClick = function(self, btn)
					MiniBtnClickFunc(btn)
				end,
				OnTooltipShow = function(tooltip)
					if not tooltip or not tooltip.AddLine then return end
					tooltip:AddLine("unitscan")	
					tooltip:AddLine("|cffeda55fClick|r |cff99ff00to open unitscan options.|r")
                    tooltip:AddLine("|cffeda55fRight-Click|r |cff99ff00to reload the user interface.|r")
				end,
			})

			local icon = LibStub("LibDBIcon-1.0", true)
			icon:Register("unitscan", miniButton, unitscanDB)
			--icon:Show("unitscan")

			-- Function to toggle LibDBIcon
			local function SetLibDBIconFunc()
				if unitscanLC["ShowMinimapIcon"] == "On" then
					unitscanDB["hide"] = false
					icon:Show("unitscan")
				else
					unitscanDB["hide"] = true
					icon:Hide("unitscan")
				end
			end

			-- Set LibDBIcon when option is clicked and on startup
			unitscanCB["ShowMinimapIcon"]:HookScript("OnClick", SetLibDBIconFunc)
			SetLibDBIconFunc()
		end



		------------------------------------------------------------------------
		----	Move chat editbox to top
		------------------------------------------------------------------------

		--if unitscanLC["MoveChatEditBoxToTop"] == "On" and not LeaLockList["MoveChatEditBoxToTop"] then

		--	-- Set options for normal chat frames
		--	for i = 1, 50 do
		--		if _G["ChatFrame" .. i] then
		--			-- Position the editbox
		--			_G["ChatFrame" .. i .. "EditBox"]:ClearAllPoints();
		--			_G["ChatFrame" .. i .. "EditBox"]:SetPoint("TOPLEFT", _G["ChatFrame" .. i], 0, 0);
		--			_G["ChatFrame" .. i .. "EditBox"]:SetWidth(_G["ChatFrame" .. i]:GetWidth());
		--			-- Ensure editbox width matches chatframe width
		--			_G["ChatFrame" .. i]:HookScript("OnSizeChanged", function()
		--				_G["ChatFrame" .. i .. "EditBox"]:SetWidth(_G["ChatFrame" .. i]:GetWidth())
		--			end)
		--		end
		--	end

		--	-- Do the functions above for other chat frames (pet battles, whispers, etc)
		--	hooksecurefunc("FCF_OpenTemporaryWindow", function()

		--		local cf = FCF_GetCurrentChatFrame():GetName() or nil
		--		if cf then

		--			-- Position the editbox
		--			_G[cf .. "EditBox"]:ClearAllPoints();
		--			_G[cf .. "EditBox"]:SetPoint("TOPLEFT", cf, "TOPLEFT", 0, 0);
		--			_G[cf .. "EditBox"]:SetWidth(_G[cf]:GetWidth());

		--			-- Ensure editbox width matches chatframe width
		--			_G[cf]:HookScript("OnSizeChanged", function()
		--				_G[cf .. "EditBox"]:SetWidth(_G[cf]:GetWidth())
		--			end)

		--		end
		--	end)

		--end


		----------------------------------------------------------------------
		-- Final code for Player
		----------------------------------------------------------------------

		-- Show first run message
		if not unitscanDB["FirstRunMessageSeen"] then
			LibCompat.After(1, function()
				unitscanLC:Print(L["Enter"] .. " |cff00ff00" .. "/run leaplus()" .. "|r " .. L["or click the minimap button to open unitscan."])
				unitscanDB["FirstRunMessageSeen"] = true
			end)
		end

		-- Register logout event to save settings
		usEvt:RegisterEvent("PLAYER_LOGOUT")

		-- Release memory
		unitscanLC.Player = nil

	end


----------------------------------------------------------------------
--	L45: World
----------------------------------------------------------------------

	function unitscanLC:World()

		----------------------------------------------------------------------
		--	Max camera zoom (no reload required)
		----------------------------------------------------------------------

		do

			---- Function to set camera zoom
			--local function SetZoom()
			--	if unitscanLC["MaxCameraZoom"] == "On" then
			--		SetCVar("cameraDistanceMaxZoomFactor", 4.0)
			--	else
			--		SetCVar("cameraDistanceMaxZoomFactor", 1.9)
			--	end
			--end

			---- Set camera zoom when option is clicked and on startup (if enabled)
			--unitscanCB["MaxCameraZoom"]:HookScript("OnClick", SetZoom)
			--if unitscanLC["MaxCameraZoom"] == "On" then SetZoom() end

		end

	end


----------------------------------------------------------------------
-- 	L50: RunOnce
----------------------------------------------------------------------

	function unitscanLC:RunOnce()

		----------------------------------------------------------------------
		-- Frame alignment grid
		----------------------------------------------------------------------

		do

			-- Create frame alignment grid
			local grid = CreateFrame('FRAME')
			unitscanLC.grid = grid
			grid:Hide()
			grid:SetAllPoints(UIParent)
			local w, h = GetScreenWidth() * UIParent:GetEffectiveScale(), GetScreenHeight() * UIParent:GetEffectiveScale()
			local ratio = w / h
			local sqsize = w / 20
			local wline = floor(sqsize - (sqsize % 2))
			local hline = floor(sqsize / ratio - ((sqsize / ratio) % 2))
			-- Plot vertical lines
			for i = 0, wline do
				local t = unitscanLC.grid:CreateTexture(nil, 'BACKGROUND')
				if i == wline / 2 then t:SetVertexColor(1, 0, 0, 0.5) else t:SetVertexColor(0, 0, 0, 0.5) end
				t:SetPoint('TOPLEFT', grid, 'TOPLEFT', i * w / wline - 1, 0)
				t:SetPoint('BOTTOMRIGHT', grid, 'BOTTOMLEFT', i * w / wline + 1, 0)
			end
			-- Plot horizontal lines
			for i = 0, hline do
				local t = unitscanLC.grid:CreateTexture(nil, 'BACKGROUND')
				if i == hline / 2 then	t:SetVertexColor(1, 0, 0, 0.5) else t:SetVertexColor(0, 0, 0, 0.5) end
				t:SetPoint('TOPLEFT', grid, 'TOPLEFT', 0, -i * h / hline + 1)
				t:SetPoint('BOTTOMRIGHT', grid, 'TOPRIGHT', 0, -i * h / hline - 1)
			end

		end

		----------------------------------------------------------------------
		-- Rare Spawns List
		----------------------------------------------------------------------


		function unitscanLC:rare_spawns_list()

			-- First - Load the Database of Rare Mobs.
			unitscan_LoadRareSpawns()

			local eb = CreateFrame("Frame", nil, unitscanLC["Page1"])
			eb:SetSize(300, 280)
			eb:SetPoint("TOPLEFT", 400, -50)
			eb:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
				edgeSize = 16,
				insets = {left = 8, right = 6, top = 8, bottom = 8},
			})
			eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)
			eb:SetScale(0.8)

			eb.scroll = CreateFrame("ScrollFrame", nil, eb)
			eb.scroll:SetPoint("TOPLEFT", eb, 12, -10)
			eb.scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)

			local buttonHeight = 20
			local maxVisibleButtons = 450

			local contentFrame = CreateFrame("Frame", nil, eb.scroll)
			contentFrame:SetSize(eb:GetWidth() - 30, maxVisibleButtons * buttonHeight)
			contentFrame.Buttons = {}

			-- Sort rare spawns by zone
			local sortedSpawns = {}
			for name, zone in pairs(rare_spawns) do
				sortedSpawns[zone] = sortedSpawns[zone] or {}
				table.insert(sortedSpawns[zone], name)
			end

			-- Create buttons
			local index = 1
			for zone, mobs in pairs(sortedSpawns) do
				for _, name in ipairs(mobs) do
					if index <= maxVisibleButtons then
						local button = CreateFrame("Button", nil, contentFrame)
						button:SetSize(contentFrame:GetWidth(), buttonHeight)
						button:SetPoint("TOPLEFT", 0, -(index - 1) * buttonHeight)

						-- Create a texture region within the button frame
						local texture = button:CreateTexture(nil, "BACKGROUND")
						texture:SetAllPoints(true)
						texture:SetTexture("Interface\\Buttons\\WHITE8X8")
						texture:SetVertexColor(1.0, 0.5, 0.0, 0.8)
						texture:Hide()

						button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
						button.Text:SetPoint("LEFT", 5, 0)

						button:SetScript("OnClick", function(self)
							-- Handle button click event here
							print("Button clicked: " .. self.Text:GetText())
						end)

						button:SetScript("OnEnter", function(self)
							-- Handle button click event here
							texture:Show()
						end)

						button:SetScript("OnLeave", function(self)
							-- Handle button click event here
							texture:Hide()
						end)

						button.Text:SetText(name)
						button:Show()

						contentFrame.Buttons[index] = button
					end
					index = index + 1
				end
			end

			eb.scroll:SetScrollChild(contentFrame)

			-- Scroll functionality
			local scrollbar = CreateFrame("Slider", nil, eb.scroll, "UIPanelScrollBarTemplate")
			scrollbar:SetPoint("TOPRIGHT", eb.scroll, "TOPRIGHT", 20, -14)
			scrollbar:SetPoint("BOTTOMRIGHT", eb.scroll, "BOTTOMRIGHT", 20, 14)

			scrollbar:SetMinMaxValues(1, 8300)
			scrollbar:SetValueStep(1)
			scrollbar:SetValue(1)
			scrollbar:SetWidth(16)
			scrollbar:SetScript("OnValueChanged", function(self, value)
				self:GetParent():SetVerticalScroll(value)
			end)

			eb.scroll.ScrollBar = scrollbar

			-- Mouse wheel scrolling
			eb.scroll:EnableMouseWheel(true)
			eb.scroll:SetScript("OnMouseWheel", function(self, delta)
				scrollbar:SetValue(scrollbar:GetValue() - delta * 250)
			end)

			-- Hide unused buttons
			for i = index, maxVisibleButtons do
				if contentFrame.Buttons[i] then
					contentFrame.Buttons[i]:Hide()
				end
			end

		end

		-- Run on startup
		unitscanLC:rare_spawns_list()

		-- Release memory
		unitscanLC.rare_spawns_list = nil
	



		----------------------------------------------------------------------
		-- Panel alpha
		----------------------------------------------------------------------

		-- Function to set panel alpha
		local function SetPlusAlpha()
			-- Set panel alpha
			unitscanLC["PageF"].t:SetAlpha(1 - unitscanLC["PlusPanelAlpha"])
			-- Show formatted value
			unitscanCB["PlusPanelAlpha"].f:SetFormattedText("%.0f%%", unitscanLC["PlusPanelAlpha"] * 100)
		end

		-- Set alpha on startup
		SetPlusAlpha()

		-- Set alpha after changing slider
		unitscanCB["PlusPanelAlpha"]:HookScript("OnValueChanged", SetPlusAlpha)

		----------------------------------------------------------------------
		-- Panel scale
		----------------------------------------------------------------------

		-- Function to set panel scale
		local function SetPlusScale()
			-- Reset panel position
			unitscanLC["MainPanelA"], unitscanLC["MainPanelR"], unitscanLC["MainPanelX"], unitscanLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
			if unitscanLC["PageF"]:IsShown() then
				unitscanLC["PageF"]:Hide()
				unitscanLC["PageF"]:Show()
			end
			-- Set panel scale
			unitscanLC["PageF"]:SetScale(unitscanLC["PlusPanelScale"])
			-- Update music player highlight bar scale
			--unitscanLC:UpdateList()
		end

		-- Set scale on startup
		unitscanLC["PageF"]:SetScale(unitscanLC["PlusPanelScale"])

		-- Set scale and reset panel position after changing slider
		unitscanCB["PlusPanelScale"]:HookScript("OnMouseUp", SetPlusScale)
		unitscanCB["PlusPanelScale"]:HookScript("OnMouseWheel", SetPlusScale)

		-- Show formatted slider value
		unitscanCB["PlusPanelScale"]:HookScript("OnValueChanged", function()
			unitscanCB["PlusPanelScale"].f:SetFormattedText("%.0f%%", unitscanLC["PlusPanelScale"] * 100)
		end)

		----------------------------------------------------------------------
		-- Options panel
		----------------------------------------------------------------------

		-- Hide Leatrix Plus if game options panel is shown
		InterfaceOptionsFrame:HookScript("OnShow", unitscanLC.HideFrames);
		VideoOptionsFrame:HookScript("OnShow", unitscanLC.HideFrames);




		----------------------------------------------------------------------
		-- Final code for RunOnce
		----------------------------------------------------------------------

		-- Update addon memory usage (speeds up initial value)
		UpdateAddOnMemoryUsage();

		-- Release memory
		unitscanLC.RunOnce = nil

	end



----------------------------------------------------------------------
-- 	L60: Default events
----------------------------------------------------------------------

	local function eventHandler(self, event, arg1, arg2, ...)

		----------------------------------------------------------------------
		-- L62: Profile events
		----------------------------------------------------------------------

		if event == "ADDON_LOADED" then
			if arg1 == "unitscan" then

				-- Replace old var names with new ones
				local function UpdateVars(oldvar, newvar)
					if unitscanDB[oldvar] and not unitscanDB[newvar] then unitscanDB[newvar] = unitscanDB[oldvar]; unitscanDB[oldvar] = nil end
				end

				UpdateVars("MuteStriders", "MuteMechSteps")					-- 2.5.108 (1st June 2022)
				UpdateVars("MinimapMod", "MinimapModder")					-- 2.5.120 (24th August 2022)

				---- Automation
				--unitscanLC:LoadVarChk("AutomateQuests", "Off")				-- Automate quests
				--unitscanLC:LoadVarChk("AutoQuestShift", "Off")				-- Automate quests requires shift
				--unitscanLC:LoadVarChk("AutoQuestAvailable", "On")			-- Accept available quests
				--unitscanLC:LoadVarChk("AutoQuestCompleted", "On")			-- Turn-in completed quests
				--unitscanLC:LoadVarNum("AutoQuestKeyMenu", 1, 1, 4)			-- Automate quests override key
				--unitscanLC:LoadVarChk("AutomateGossip", "Off")				-- Automate gossip
				--unitscanLC:LoadVarChk("AutoAcceptSummon", "Off")				-- Accept summon
				--unitscanLC:LoadVarChk("AutoAcceptRes", "Off")				-- Accept resurrection
				--unitscanLC:LoadVarChk("AutoResNoCombat", "On")				-- Accept resurrection exclude combat
				--unitscanLC:LoadVarChk("AutoReleasePvP", "Off")				-- Release in PvP
				--unitscanLC:LoadVarChk("AutoReleaseNoAlterac", "Off")			-- Release in PvP Exclude Alterac Valley
				--unitscanLC:LoadVarNum("AutoReleaseDelay", 200, 200, 3000)	-- Release in PvP Delay

				--unitscanLC:LoadVarChk("AutoSellJunk", "Off")					-- Sell junk automatically
				--unitscanLC:LoadVarChk("AutoSellShowSummary", "On")			-- Sell junk summary in chat
				--unitscanLC:LoadVarStr("AutoSellExcludeList", "")				-- Sell junk exclude list
				--unitscanLC:LoadVarChk("AutoRepairGear", "Off")				-- Repair automatically
				--unitscanLC:LoadVarChk("AutoRepairGuildFunds", "On")			-- Repair using guild funds
				--unitscanLC:LoadVarChk("AutoRepairShowSummary", "On")			-- Repair show summary in chat

				-- Social
				unitscanLC:LoadVarChk("NoDuelRequests", "Off")				-- Block duels
				unitscanLC:LoadVarChk("NoPartyInvites", "Off")				-- Block party invites
				-- unitscanLC:LoadVarChk("NoFriendRequests", "Off")				-- Block friend requests
				unitscanLC:LoadVarChk("NoSharedQuests", "Off")				-- Block shared quests

				unitscanLC:LoadVarChk("AcceptPartyFriends", "Off")			-- Party from friends
				unitscanLC:LoadVarChk("InviteFromWhisper", "Off")			-- Invite from whispers
				unitscanLC:LoadVarChk("InviteFriendsOnly", "Off")			-- Restrict invites to friends
				unitscanLC["InvKey"]	= unitscanDB["InvKey"] or "inv"			-- Invite from whisper keyword
				unitscanLC:LoadVarChk("FriendlyGuild", "On")					-- Friendly guild

				-- Chat
				unitscanLC:LoadVarChk("UseEasyChatResizing", "Off")			-- Use easy resizing
				unitscanLC:LoadVarChk("NoCombatLogTab", "Off")				-- Hide the combat log
				unitscanLC:LoadVarChk("NoChatButtons", "Off")				-- Hide chat buttons
				unitscanLC:LoadVarChk("UnclampChat", "Off")					-- Unclamp chat frame
				unitscanLC:LoadVarChk("MoveChatEditBoxToTop", "Off")			-- Move editbox to top
				unitscanLC:LoadVarChk("MoreFontSizes", "Off")				-- More font sizes

				unitscanLC:LoadVarChk("NoStickyChat", "Off")					-- Disable sticky chat
				unitscanLC:LoadVarChk("UseArrowKeysInChat", "Off")			-- Use arrow keys in chat
				unitscanLC:LoadVarChk("NoChatFade", "Off")					-- Disable chat fade
				unitscanLC:LoadVarChk("UnivGroupColor", "Off")				-- Universal group color
				unitscanLC:LoadVarChk("ClassColorsInChat", "Off")			-- Use class colors in chat
				unitscanLC:LoadVarChk("RecentChatWindow", "Off")				-- Recent chat window
				unitscanLC:LoadVarNum("RecentChatSize", 170, 170, 600)		-- Recent chat size
				unitscanLC:LoadVarChk("MaxChatHstory", "Off")				-- Increase chat history
				unitscanLC:LoadVarChk("FilterChatMessages", "Off")			-- Filter chat messages
				unitscanLC:LoadVarChk("BlockSpellLinks", "Off")				-- Block spell links
				unitscanLC:LoadVarChk("BlockDrunkenSpam", "Off")				-- Block drunken spam
				unitscanLC:LoadVarChk("BlockDuelSpam", "Off")				-- Block duel spam
				unitscanLC:LoadVarChk("RestoreChatMessages", "Off")			-- Restore chat messages

				-- Text
				unitscanLC:LoadVarChk("HideErrorMessages", "Off")			-- Hide error messages
				unitscanLC:LoadVarChk("NoHitIndicators", "Off")				-- Hide portrait text
				unitscanLC:LoadVarChk("HideZoneText", "Off")					-- Hide zone text
				unitscanLC:LoadVarChk("HideKeybindText", "Off")				-- Hide keybind text
				unitscanLC:LoadVarChk("HideMacroText", "Off")				-- Hide macro text

				unitscanLC:LoadVarChk("MailFontChange", "Off")				-- Resize mail text
				unitscanLC:LoadVarNum("LeaPlusMailFontSize", 15, 10, 36)		-- Mail text slider

				unitscanLC:LoadVarChk("QuestFontChange", "Off")				-- Resize quest text
				unitscanLC:LoadVarNum("LeaPlusQuestFontSize", 12, 10, 36)	-- Quest text slider

				unitscanLC:LoadVarChk("BookFontChange", "Off")				-- Resize book text
				unitscanLC:LoadVarNum("LeaPlusBookFontSize", 15, 10, 36)		-- Book text slider

				-- Interface
				unitscanLC:LoadVarChk("MinimapModder", "Off")				-- Enhance minimap
				unitscanLC:LoadVarChk("SquareMinimap", "Off")				-- Square minimap
				unitscanLC:LoadVarChk("ShowWhoPinged", "On")					-- Show who pinged
				unitscanLC:LoadVarChk("CombineAddonButtons", "Off")			-- Combine addon buttons
				unitscanLC:LoadVarStr("MiniExcludeList", "")					-- Minimap exclude list
				unitscanLC:LoadVarChk("HideMiniZoomBtns", "Off")				-- Hide zoom buttons
				unitscanLC:LoadVarChk("HideMiniZoneText", "Off")				-- Hide the zone text bar
				unitscanLC:LoadVarChk("HideMiniAddonButtons", "On")			-- Hide addon buttons
				unitscanLC:LoadVarChk("HideMiniMapButton", "On")				-- Hide the world map button
				unitscanLC:LoadVarChk("HideMiniTracking", "Off")				-- Hide the tracking button
				unitscanLC:LoadVarNum("MinimapScale", 1, 1, 4)				-- Minimap scale slider
				unitscanLC:LoadVarNum("MinimapSize", 140, 140, 560)			-- Minimap size slider
				unitscanLC:LoadVarNum("MiniClusterScale", 1, 1, 2)			-- Minimap cluster scale
				unitscanLC:LoadVarChk("MinimapNoScale", "Off")				-- Minimap not minimap
				unitscanLC:LoadVarAnc("MinimapA", "TOPRIGHT")				-- Minimap anchor
				unitscanLC:LoadVarAnc("MinimapR", "TOPRIGHT")				-- Minimap relative
				unitscanLC:LoadVarNum("MinimapX", -17, -5000, 5000)			-- Minimap X
				unitscanLC:LoadVarNum("MinimapY", -22, -5000, 5000)			-- Minimap Y
				unitscanLC:LoadVarChk("TipModEnable", "Off")					-- Enhance tooltip
				unitscanLC:LoadVarChk("TipShowRank", "On")					-- Show rank
				unitscanLC:LoadVarChk("TipShowOtherRank", "Off")				-- Show rank for other guilds
				unitscanLC:LoadVarChk("TipShowTarget", "On")					-- Show target
				unitscanLC:LoadVarChk("TipHideInCombat", "Off")				-- Hide tooltips during combat
				unitscanLC:LoadVarChk("TipHideShiftOverride", "On")			-- Hide tooltips shift override
				unitscanLC:LoadVarChk("TipNoHealthBar", "Off")				-- Hide health bar
				unitscanLC:LoadVarNum("LeaPlusTipSize", 1.00, 0.50, 2.00)	-- Tooltip scale slider
				unitscanLC:LoadVarNum("TipOffsetX", -13, -5000, 5000)		-- Tooltip X offset
				unitscanLC:LoadVarNum("TipOffsetY", 94, -5000, 5000)			-- Tooltip Y offset
				unitscanLC:LoadVarNum("TooltipAnchorMenu", 1, 1, 5)			-- Tooltip anchor menu
				unitscanLC:LoadVarNum("TipCursorX", 0, -128, 128)			-- Tooltip cursor X offset
				unitscanLC:LoadVarNum("TipCursorY", 0, -128, 128)			-- Tooltip cursor Y offset

				unitscanLC:LoadVarChk("EnhanceDressup", "Off")				-- Enhance dressup
				unitscanLC:LoadVarChk("DressupItemButtons", "On")			-- Dressup item buttons
				unitscanLC:LoadVarChk("DressupAnimControl", "On")			-- Dressup animation control
				unitscanLC:LoadVarChk("HideDressupStats", "Off")				-- Hide dressup stats
				unitscanLC:LoadVarChk("EnhanceQuestLog", "Off")				-- Enhance quest log
				unitscanLC:LoadVarChk("EnhanceQuestHeaders", "On")			-- Enhance quest log toggle headers
				unitscanLC:LoadVarChk("EnhanceQuestLevels", "On")			-- Enhance quest log quest levels
				unitscanLC:LoadVarChk("EnhanceQuestDifficulty", "On")		-- Enhance quest log quest difficulty
				unitscanLC:LoadVarChk("EnhanceProfessions", "Off")			-- Enhance professions
				unitscanLC:LoadVarChk("EnhanceTrainers", "Off")				-- Enhance trainers
				unitscanLC:LoadVarChk("ShowTrainAllBtn", "On")				-- Enhance trainers train all button

				unitscanLC:LoadVarChk("ShowVolume", "Off")					-- Show volume slider
				unitscanLC:LoadVarChk("AhExtras", "Off")						-- Show auction controls
				unitscanLC:LoadVarChk("AhBuyoutOnly", "Off")					-- Auction buyout only
				unitscanLC:LoadVarChk("AhGoldOnly", "Off")					-- Auction gold only
				unitscanLC:LoadVarChk("AhTabConfirm", "Off")					-- Auction confirm on TAB pressed

				-- unitscanLC:LoadVarChk("ShowCooldowns", "Off")				-- Show cooldowns
				-- unitscanLC:LoadVarChk("ShowCooldownID", "On")				-- Show cooldown ID in tips
				-- unitscanLC:LoadVarChk("NoCooldownDuration", "On")			-- Hide cooldown duration
				-- unitscanLC:LoadVarChk("CooldownsOnPlayer", "Off")			-- Anchor to player
				unitscanLC:LoadVarChk("DurabilityStatus", "Off")				-- Show durability status
				unitscanLC:LoadVarChk("ShowVanityControls", "Off")			-- Show vanity controls
				unitscanLC:LoadVarChk("VanityAltLayout", "Off")				-- Vanity alternative layout
				unitscanLC:LoadVarChk("ShowBagSearchBox", "Off")				-- Show bag search box
				-- unitscanLC:LoadVarChk("ShowRaidToggle", "Off")				-- Show raid button
				unitscanLC:LoadVarChk("ShowPlayerChain", "Off")				-- Show player chain
				unitscanLC:LoadVarNum("PlayerChainMenu", 2, 1, 3)			-- Player chain dropdown value
				unitscanLC:LoadVarChk("ShowReadyTimer", "Off")				-- Show ready timer
				unitscanLC:LoadVarChk("ShowWowheadLinks", "Off")				-- Show Wowhead links
				unitscanLC:LoadVarChk("WowheadLinkComments", "Off")			-- Show Wowhead links to comments

				unitscanLC:LoadVarChk("ShowFlightTimes", "Off")				-- Show flight times
				unitscanLC:LoadVarChk("FlightBarBackground", "On")			-- Show flight times bar background
				unitscanLC:LoadVarChk("FlightBarDestination", "On")			-- Show flight times bar destination
				unitscanLC:LoadVarChk("FlightBarFillBar", "Off")				-- Show flight times bar fill mode
				unitscanLC:LoadVarChk("FlightBarSpeech", "Off")				-- Show flight times bar speech

				unitscanLC:LoadVarChk("FlightBarContribute", "On")			-- Show flight times contribute
				unitscanLC:LoadVarAnc("FlightBarA", "TOP")					-- Show flight times anchor
				unitscanLC:LoadVarAnc("FlightBarR", "TOP")					-- Show flight times relative
				unitscanLC:LoadVarNum("FlightBarX", 0, -5000, 5000)			-- Show flight position X
				unitscanLC:LoadVarNum("FlightBarY", -66, -5000, 5000)		-- Show flight position Y
				unitscanLC:LoadVarNum("FlightBarScale", 2, 1, 5)				-- Show flight times bar scale
				unitscanLC:LoadVarNum("FlightBarWidth", 230, 40, 460)		-- Show flight times bar width

				-- Frames
				unitscanLC:LoadVarChk("FrmEnabled", "Off")					-- Manage frames

				unitscanLC:LoadVarChk("ManageBuffs", "Off")					-- Manage buffs
				unitscanLC:LoadVarAnc("BuffFrameA", "TOPRIGHT")				-- Manage buffs anchor
				unitscanLC:LoadVarAnc("BuffFrameR", "TOPRIGHT")				-- Manage buffs relative
				unitscanLC:LoadVarNum("BuffFrameX", -205, -5000, 5000)		-- Manage buffs position X
				unitscanLC:LoadVarNum("BuffFrameY", -13, -5000, 5000)		-- Manage buffs position Y
				unitscanLC:LoadVarNum("BuffFrameScale", 1, 0.5, 2)			-- Manage buffs scale

				unitscanLC:LoadVarChk("ManageWidget", "Off")					-- Manage widget
				unitscanLC:LoadVarAnc("WidgetA", "TOP")						-- Manage widget anchor
				unitscanLC:LoadVarAnc("WidgetR", "TOP")						-- Manage widget relative
				unitscanLC:LoadVarNum("WidgetX", 0, -5000, 5000)				-- Manage widget position X
				unitscanLC:LoadVarNum("WidgetY", -15, -5000, 5000)			-- Manage widget position Y
				unitscanLC:LoadVarNum("WidgetScale", 1, 0.5, 2)				-- Manage widget scale

				unitscanLC:LoadVarChk("ManageFocus", "Off")					-- Manage focus
				unitscanLC:LoadVarAnc("FocusA", "CENTER")					-- Manage focus anchor
				unitscanLC:LoadVarAnc("FocusR", "CENTER")					-- Manage focus relative
				unitscanLC:LoadVarNum("FocusX", 0, -5000, 5000)				-- Manage focus position X
				unitscanLC:LoadVarNum("FocusY", 0, -5000, 5000)				-- Manage focus position Y
				unitscanLC:LoadVarNum("FocusScale", 1, 0.5, 2)				-- Manage focus scale

				unitscanLC:LoadVarChk("ManageTimer", "Off")					-- Manage timer
				unitscanLC:LoadVarAnc("TimerA", "TOP")						-- Manage timer anchor
				unitscanLC:LoadVarAnc("TimerR", "TOP")						-- Manage timer relative
				unitscanLC:LoadVarNum("TimerX", -5, -5000, 5000)				-- Manage timer position X
				unitscanLC:LoadVarNum("TimerY", -96, -5000, 5000)			-- Manage timer position Y
				unitscanLC:LoadVarNum("TimerScale", 1, 0.5, 2)				-- Manage timer scale

				unitscanLC:LoadVarChk("ManageDurability", "Off")				-- Manage durability
				unitscanLC:LoadVarAnc("DurabilityA", "TOPRIGHT")				-- Manage durability anchor
				unitscanLC:LoadVarAnc("DurabilityR", "TOPRIGHT")				-- Manage durability relative
				unitscanLC:LoadVarNum("DurabilityX", 0, -5000, 5000)			-- Manage durability position X
				unitscanLC:LoadVarNum("DurabilityY", -192, -5000, 5000)		-- Manage durability position Y
				unitscanLC:LoadVarNum("DurabilityScale", 1, 0.5, 2)			-- Manage durability scale

				unitscanLC:LoadVarChk("ManageVehicle", "Off")				-- Manage vehicle
				unitscanLC:LoadVarAnc("VehicleA", "TOPRIGHT")				-- Manage vehicle anchor
				unitscanLC:LoadVarAnc("VehicleR", "TOPRIGHT")				-- Manage vehicle relative
				unitscanLC:LoadVarNum("VehicleX", -100, -5000, 5000)			-- Manage vehicle position X
				unitscanLC:LoadVarNum("VehicleY", -192, -5000, 5000)			-- Manage vehicle position Y
				unitscanLC:LoadVarNum("VehicleScale", 1, 0.5, 2)				-- Manage vehicle scale

				unitscanLC:LoadVarChk("ClassColFrames", "Off")				-- Class colored frames
				unitscanLC:LoadVarChk("ClassColPlayer", "On")				-- Class colored player frame
				unitscanLC:LoadVarChk("ClassColTarget", "On")				-- Class colored target frame

				unitscanLC:LoadVarChk("NoAlerts", "Off")						-- Hide alerts
				unitscanLC:LoadVarChk("NoGryphons", "Off")					-- Hide gryphons
				unitscanLC:LoadVarChk("NoClassBar", "Off")					-- Hide stance bar

				-- System
				unitscanLC:LoadVarChk("NoScreenGlow", "Off")					-- Disable screen glow
				unitscanLC:LoadVarChk("NoScreenEffects", "Off")				-- Disable screen effects
				unitscanLC:LoadVarChk("SetWeatherDensity", "Off")			-- Set weather density
				unitscanLC:LoadVarNum("WeatherLevel", 3, 0, 3)				-- Weather density level
				unitscanLC:LoadVarChk("MaxCameraZoom", "Off")				-- Max camera zoom
				unitscanLC:LoadVarChk("ViewPortEnable", "Off")				-- Enable viewport
				unitscanLC:LoadVarNum("ViewPortTop", 0, 0, 300)				-- Top border
				unitscanLC:LoadVarNum("ViewPortBottom", 0, 0, 300)			-- Bottom border
				unitscanLC:LoadVarNum("ViewPortLeft", 0, 0, 300)				-- Left border
				unitscanLC:LoadVarNum("ViewPortRight", 0, 0, 300)			-- Right border
				unitscanLC:LoadVarNum("ViewPortResizeTop", 0, 0, 300)		-- Resize top border
				unitscanLC:LoadVarNum("ViewPortResizeBottom", 0, 0, 300)		-- Resize bottom border
				unitscanLC:LoadVarNum("ViewPortAlpha", 0, 0, 0.9)			-- Border alpha

				unitscanLC:LoadVarChk("NoRestedEmotes", "Off")				-- Silence rested emotes
				unitscanLC:LoadVarChk("MuteGameSounds", "Off")				-- Mute game sounds
				unitscanLC:LoadVarChk("MuteCustomSounds", "Off")				-- Mute custom sounds
				unitscanLC:LoadVarStr("MuteCustomList", "")					-- Mute custom sounds list

				unitscanLC:LoadVarChk("NoBagAutomation", "Off")				-- Disable bag automation
				unitscanLC:LoadVarChk("CharAddonList", "Off")				-- Show character addons
				unitscanLC:LoadVarChk("NoConfirmLoot", "Off")				-- Disable loot warnings
				unitscanLC:LoadVarChk("FasterLooting", "Off")				-- Faster auto loot
				unitscanLC:LoadVarChk("FasterMovieSkip", "Off")				-- Faster movie skip
				unitscanLC:LoadVarChk("StandAndDismount", "Off")				-- Dismount me
				unitscanLC:LoadVarChk("DismountNoResource", "On")			-- Dismount on resource error
				unitscanLC:LoadVarChk("DismountNoMoving", "On")				-- Dismount on moving
				unitscanLC:LoadVarChk("DismountNoTaxi", "On")				-- Dismount on flight map open
				unitscanLC:LoadVarChk("DismountShowFormBtn", "On")			-- Dismount cancel form button
				unitscanLC:LoadVarChk("ShowVendorPrice", "Off")				-- Show vendor price
				unitscanLC:LoadVarChk("CombatPlates", "Off")					-- Combat plates
				unitscanLC:LoadVarChk("EasyItemDestroy", "Off")				-- Easy item destroy

				-- Settings
				unitscanLC:LoadVarChk("ShowMinimapIcon", "On")				-- Show minimap button
				unitscanLC:LoadVarNum("PlusPanelScale", 1, 1, 2)				-- Panel scale
				unitscanLC:LoadVarNum("PlusPanelAlpha", 0, 0, 1)				-- Panel alpha

				-- Panel position
				unitscanLC:LoadVarAnc("MainPanelA", "CENTER")				-- Panel anchor
				unitscanLC:LoadVarAnc("MainPanelR", "CENTER")				-- Panel relative
				unitscanLC:LoadVarNum("MainPanelX", 0, -5000, 5000)			-- Panel X axis
				unitscanLC:LoadVarNum("MainPanelY", 0, -5000, 5000)			-- Panel Y axis

				-- Start page
				unitscanLC:LoadVarNum("LeaStartPage", 0, 0, unitscanLC["NumberOfPages"])

				-- Lock conflicting options
				do

					-- Function to disable and lock an option and add a note to the tooltip
					local function Lock(option, reason, optmodule)
						usLockList[option] = unitscanLC[option]
						unitscanLC:LockItem(unitscanCB[option], true)
						unitscanCB[option].tiptext = unitscanCB[option].tiptext .. "|n|n|cff00AAFF" .. reason
						if optmodule then
							unitscanCB[option].tiptext = unitscanCB[option].tiptext .. " " .. optmodule .. " " .. L["module"]
						end
						unitscanCB[option].tiptext = unitscanCB[option].tiptext .. "."
						-- Remove hover from configuration button if there is one
						local temp = {unitscanCB[option]:GetChildren()}
						if temp and temp[1] and temp[1].t and temp[1].t:GetTexture() == "Interface\\WorldMap\\Gear_64.png" then
							temp[1]:SetHighlightTexture(0)
							temp[1]:SetScript("OnEnter", nil)
						end
					end

					-- Disable items that conflict with Glass
					if unitscanLC.Glass then
						local reason = L["Cannot be used with Glass"]
						Lock("UseEasyChatResizing", reason) -- Use easy resizing
						Lock("NoCombatLogTab", reason) -- Hide the combat log
						Lock("NoChatButtons", reason) -- Hide chat buttons
						Lock("UnclampChat", reason) -- Unclamp chat frame
						Lock("MoveChatEditBoxToTop", reason) -- Move editbox to top
						Lock("MoreFontSizes", reason) --  More font sizes
						Lock("NoChatFade", reason) --  Disable chat fade
						Lock("ClassColorsInChat", reason) -- Use class colors in chat
						Lock("RecentChatWindow", reason) -- Recent chat window
					end

					-- Disable items that conflict with ElvUI
					if unitscanLC.ElvUI then
						local E = unitscanLC.ElvUI
						if E and E.private then

							local reason = L["Cannot be used with ElvUI"]

							-- Chat
							if E.private.chat.enable then
								Lock("UseEasyChatResizing", reason, "Chat") -- Use easy resizing
								Lock("NoCombatLogTab", reason, "Chat") -- Hide the combat log
								Lock("NoChatButtons", reason, "Chat") -- Hide chat buttons
								Lock("UnclampChat", reason, "Chat") -- Unclamp chat frame
								Lock("MoreFontSizes", reason, "Chat") --  More font sizes
								Lock("NoStickyChat", reason, "Chat") -- Disable sticky chat
								Lock("UseArrowKeysInChat", reason, "Chat") -- Use arrow keys in chat
								Lock("NoChatFade", reason, "Chat") -- Disable chat fade
								Lock("MaxChatHstory", reason, "Chat") -- Increase chat history
								Lock("RestoreChatMessages", reason, "Chat") -- Restore chat messages
							end

							-- Minimap
							if E.private.general.minimap.enable then
								Lock("MinimapModder", reason, "Minimap") -- Enhance minimap
							end

							-- -- UnitFrames
							-- if E.private.unitframe.enable then
							-- 	Lock("ShowRaidToggle", reason, "UnitFrames") -- Show raid button
							-- end

							-- ActionBars
							if E.private.actionbar.enable then
								Lock("NoGryphons", reason, "ActionBars") -- Hide gryphons
								Lock("NoClassBar", reason, "ActionBars") -- Hide stance bar
								Lock("HideKeybindText", reason, "ActionBars") -- Hide keybind text
								Lock("HideMacroText", reason, "ActionBars") -- Hide macro text
							end

							-- Bags
							if E.private.bags.enable then
								Lock("NoBagAutomation", reason, "Bags") -- Disable bag automation
								Lock("ShowBagSearchBox", reason, "Bags") -- Show bag search box
							end

							-- Tooltip
							if E.private.tooltip.enable then
								Lock("TipModEnable", reason, "Tooltip") -- Enhance tooltip
							end

							-- Buffs: Disable Blizzard
							if E.private.auras.disableBlizzard then
								Lock("ManageBuffs", reason, "Buffs and Debuffs (Disable Blizzard)") -- Manage buffs
							end

							-- UnitFrames: Disabled Blizzard: Focus
							if E.private.unitframe.disabledBlizzardFrames.focus then
								Lock("ManageFocus", reason, "UnitFrames (Disabled Blizzard Frames Focus)") -- Manage focus
							end

							-- UnitFrames: Disabled Blizzard: Player
							if E.private.unitframe.disabledBlizzardFrames.player then
								Lock("ShowPlayerChain", reason, "UnitFrames (Disabled Blizzard Frames Player)") -- Show player chain
								Lock("NoHitIndicators", reason, "UnitFrames (Disabled Blizzard Frames Player)") -- Hide portrait numbers
							end

							-- UnitFrames: Disabled Blizzard: Player and Target
							if E.private.unitframe.disabledBlizzardFrames.player or E.private.unitframe.disabledBlizzardFrames.target then
								Lock("FrmEnabled", reason, "UnitFrames (Disabled Blizzard Frames Player and Target)") -- Manage frames
							end

							-- UnitFrames: Disabled Blizzard: Player, Target and Focus
							if E.private.unitframe.disabledBlizzardFrames.player or E.private.unitframe.disabledBlizzardFrames.target or E.private.unitframe.disabledBlizzardFrames.focus then
								Lock("ClassColFrames", reason, "UnitFrames (Disabled Blizzard Frames Player, Target and Focus)") -- Class-colored frames
							end

							-- Skins: Blizzard Gossip Frame
							if E.private.skins.blizzard.enable and E.private.skins.blizzard.gossip then
								Lock("QuestFontChange", reason, "Skins (Blizzard Gossip Frame)") -- Resize quest font
							end

							-- Base
							do
								Lock("ManageWidget", reason) -- Manage widget
								Lock("ManageTimer", reason) -- Manage timer
								Lock("ManageDurability", reason) -- Manage durability
								Lock("ManageVehicle", reason) -- Manage vehicle
							end

						end

						EnableAddOn("unitscan")
					end

				end

				-- Run other startup items
				--unitscanLC:Live()
				--unitscanLC:Isolated()
				unitscanLC:RunOnce()
				unitscanLC:SetDim()

			end
			return
		end


		if event == "PLAYER_LOGIN" then
			unitscanLC:Player()
			collectgarbage()
			return
		end

		if event == "PLAYER_ENTERING_WORLD" then
			unitscanLC:World()
			usEvt:UnregisterEvent("PLAYER_ENTERING_WORLD")
			return
		end

		-- Save locals back to globals on logout
		if event == "PLAYER_LOGOUT" then

			-- Run the logout function without wipe flag
			unitscanLC:PlayerLogout(false)

			---- Automation
			--unitscanDB["AutomateQuests"]			= unitscanLC["AutomateQuests"]
			--unitscanDB["AutoQuestShift"]			= unitscanLC["AutoQuestShift"]
			--unitscanDB["AutoQuestAvailable"]		= unitscanLC["AutoQuestAvailable"]
			--unitscanDB["AutoQuestCompleted"]		= unitscanLC["AutoQuestCompleted"]
			--unitscanDB["AutoQuestKeyMenu"]		= unitscanLC["AutoQuestKeyMenu"]
			--unitscanDB["AutomateGossip"]			= unitscanLC["AutomateGossip"]
			--unitscanDB["AutoAcceptSummon"] 		= unitscanLC["AutoAcceptSummon"]
			--unitscanDB["AutoAcceptRes"] 			= unitscanLC["AutoAcceptRes"]
			--unitscanDB["AutoResNoCombat"] 		= unitscanLC["AutoResNoCombat"]
			--unitscanDB["AutoReleasePvP"] 		= unitscanLC["AutoReleasePvP"]
			--unitscanDB["AutoReleaseNoAlterac"] 	= unitscanLC["AutoReleaseNoAlterac"]
			--unitscanDB["AutoReleaseDelay"] 		= unitscanLC["AutoReleaseDelay"]

			--unitscanDB["AutoSellJunk"] 			= unitscanLC["AutoSellJunk"]
			--unitscanDB["AutoSellShowSummary"] 	= unitscanLC["AutoSellShowSummary"]
			--unitscanDB["AutoSellExcludeList"] 	= unitscanLC["AutoSellExcludeList"]
			--unitscanDB["AutoRepairGear"] 		= unitscanLC["AutoRepairGear"]
			--unitscanDB["AutoRepairGuildFunds"] 	= unitscanLC["AutoRepairGuildFunds"]
			--unitscanDB["AutoRepairShowSummary"] 	= unitscanLC["AutoRepairShowSummary"]

			-- Social
			unitscanDB["NoDuelRequests"] 		= unitscanLC["NoDuelRequests"]
			unitscanDB["NoPartyInvites"]			= unitscanLC["NoPartyInvites"]
			-- unitscanDB["NoFriendRequests"]		= unitscanLC["NoFriendRequests"]
			unitscanDB["NoSharedQuests"]			= unitscanLC["NoSharedQuests"]

			unitscanDB["AcceptPartyFriends"]		= unitscanLC["AcceptPartyFriends"]
			unitscanDB["InviteFromWhisper"]		= unitscanLC["InviteFromWhisper"]
			unitscanDB["InviteFriendsOnly"]		= unitscanLC["InviteFriendsOnly"]
			unitscanDB["InvKey"]					= unitscanLC["InvKey"]
			unitscanDB["FriendlyGuild"]			= unitscanLC["FriendlyGuild"]

			-- Chat
			unitscanDB["UseEasyChatResizing"]	= unitscanLC["UseEasyChatResizing"]
			unitscanDB["NoCombatLogTab"]			= unitscanLC["NoCombatLogTab"]
			unitscanDB["NoChatButtons"]			= unitscanLC["NoChatButtons"]
			unitscanDB["UnclampChat"]			= unitscanLC["UnclampChat"]
			unitscanDB["MoveChatEditBoxToTop"]	= unitscanLC["MoveChatEditBoxToTop"]
			unitscanDB["MoreFontSizes"]			= unitscanLC["MoreFontSizes"]

			unitscanDB["NoStickyChat"] 			= unitscanLC["NoStickyChat"]
			unitscanDB["UseArrowKeysInChat"]		= unitscanLC["UseArrowKeysInChat"]
			unitscanDB["NoChatFade"]				= unitscanLC["NoChatFade"]
			unitscanDB["UnivGroupColor"]			= unitscanLC["UnivGroupColor"]
			unitscanDB["ClassColorsInChat"]		= unitscanLC["ClassColorsInChat"]
			unitscanDB["RecentChatWindow"]		= unitscanLC["RecentChatWindow"]
			unitscanDB["RecentChatSize"]			= unitscanLC["RecentChatSize"]
			unitscanDB["MaxChatHstory"]			= unitscanLC["MaxChatHstory"]
			unitscanDB["FilterChatMessages"]		= unitscanLC["FilterChatMessages"]
			unitscanDB["BlockSpellLinks"]		= unitscanLC["BlockSpellLinks"]
			unitscanDB["BlockDrunkenSpam"]		= unitscanLC["BlockDrunkenSpam"]
			unitscanDB["BlockDuelSpam"]			= unitscanLC["BlockDuelSpam"]
			unitscanDB["RestoreChatMessages"]	= unitscanLC["RestoreChatMessages"]

			-- Text
			unitscanDB["HideErrorMessages"]		= unitscanLC["HideErrorMessages"]
			unitscanDB["NoHitIndicators"]		= unitscanLC["NoHitIndicators"]
			unitscanDB["HideZoneText"] 			= unitscanLC["HideZoneText"]
			unitscanDB["HideKeybindText"] 		= unitscanLC["HideKeybindText"]
			unitscanDB["HideMacroText"] 			= unitscanLC["HideMacroText"]

			unitscanDB["MailFontChange"] 		= unitscanLC["MailFontChange"]
			unitscanDB["LeaPlusMailFontSize"] 	= unitscanLC["LeaPlusMailFontSize"]

			unitscanDB["QuestFontChange"] 		= unitscanLC["QuestFontChange"]
			unitscanDB["LeaPlusQuestFontSize"]	= unitscanLC["LeaPlusQuestFontSize"]

			unitscanDB["BookFontChange"] 		= unitscanLC["BookFontChange"]
			unitscanDB["LeaPlusBookFontSize"]	= unitscanLC["LeaPlusBookFontSize"]

			-- Interface
			unitscanDB["MinimapModder"]			= unitscanLC["MinimapModder"]
			unitscanDB["SquareMinimap"]			= unitscanLC["SquareMinimap"]
			unitscanDB["ShowWhoPinged"]			= unitscanLC["ShowWhoPinged"]
			unitscanDB["CombineAddonButtons"]	= unitscanLC["CombineAddonButtons"]
			unitscanDB["MiniExcludeList"] 		= unitscanLC["MiniExcludeList"]
			unitscanDB["HideMiniZoomBtns"]		= unitscanLC["HideMiniZoomBtns"]
			unitscanDB["HideMiniZoneText"]		= unitscanLC["HideMiniZoneText"]
			unitscanDB["HideMiniAddonButtons"]	= unitscanLC["HideMiniAddonButtons"]
			unitscanDB["HideMiniMapButton"]		= unitscanLC["HideMiniMapButton"]
			unitscanDB["HideMiniTracking"]		= unitscanLC["HideMiniTracking"]
			unitscanDB["MinimapScale"]			= unitscanLC["MinimapScale"]
			unitscanDB["MinimapSize"]			= unitscanLC["MinimapSize"]
			unitscanDB["MiniClusterScale"]		= unitscanLC["MiniClusterScale"]
			unitscanDB["MinimapNoScale"]			= unitscanLC["MinimapNoScale"]
			unitscanDB["MinimapA"]				= unitscanLC["MinimapA"]
			unitscanDB["MinimapR"]				= unitscanLC["MinimapR"]
			unitscanDB["MinimapX"]				= unitscanLC["MinimapX"]
			unitscanDB["MinimapY"]				= unitscanLC["MinimapY"]

			unitscanDB["TipModEnable"]			= unitscanLC["TipModEnable"]
			unitscanDB["TipShowRank"]			= unitscanLC["TipShowRank"]
			unitscanDB["TipShowOtherRank"]		= unitscanLC["TipShowOtherRank"]
			unitscanDB["TipShowTarget"]			= unitscanLC["TipShowTarget"]
			unitscanDB["TipHideInCombat"]		= unitscanLC["TipHideInCombat"]
			unitscanDB["TipHideShiftOverride"]	= unitscanLC["TipHideShiftOverride"]
			unitscanDB["TipNoHealthBar"]			= unitscanLC["TipNoHealthBar"]
			unitscanDB["LeaPlusTipSize"]			= unitscanLC["LeaPlusTipSize"]
			unitscanDB["TipOffsetX"]				= unitscanLC["TipOffsetX"]
			unitscanDB["TipOffsetY"]				= unitscanLC["TipOffsetY"]
			unitscanDB["TooltipAnchorMenu"]		= unitscanLC["TooltipAnchorMenu"]
			unitscanDB["TipCursorX"]				= unitscanLC["TipCursorX"]
			unitscanDB["TipCursorY"]				= unitscanLC["TipCursorY"]

			unitscanDB["EnhanceDressup"]			= unitscanLC["EnhanceDressup"]
			unitscanDB["DressupItemButtons"]		= unitscanLC["DressupItemButtons"]
			unitscanDB["DressupAnimControl"]		= unitscanLC["DressupAnimControl"]
			unitscanDB["HideDressupStats"]		= unitscanLC["HideDressupStats"]
			unitscanDB["EnhanceQuestLog"]		= unitscanLC["EnhanceQuestLog"]
			unitscanDB["EnhanceQuestHeaders"]	= unitscanLC["EnhanceQuestHeaders"]
			unitscanDB["EnhanceQuestLevels"]		= unitscanLC["EnhanceQuestLevels"]
			unitscanDB["EnhanceQuestDifficulty"]	= unitscanLC["EnhanceQuestDifficulty"]

			unitscanDB["EnhanceProfessions"]		= unitscanLC["EnhanceProfessions"]
			unitscanDB["EnhanceTrainers"]		= unitscanLC["EnhanceTrainers"]
			unitscanDB["ShowTrainAllBtn"]		= unitscanLC["ShowTrainAllBtn"]

			unitscanDB["ShowVolume"] 			= unitscanLC["ShowVolume"]
			unitscanDB["AhExtras"]				= unitscanLC["AhExtras"]
			unitscanDB["AhBuyoutOnly"]			= unitscanLC["AhBuyoutOnly"]
			unitscanDB["AhGoldOnly"]				= unitscanLC["AhGoldOnly"]
			unitscanDB["AhTabConfirm"]			= unitscanLC["AhTabConfirm"]		

			-- unitscanDB["ShowCooldowns"]			= unitscanLC["ShowCooldowns"]
			-- unitscanDB["ShowCooldownID"]			= unitscanLC["ShowCooldownID"]
			-- unitscanDB["NoCooldownDuration"]		= unitscanLC["NoCooldownDuration"]
			-- unitscanDB["CooldownsOnPlayer"]		= unitscanLC["CooldownsOnPlayer"]
			unitscanDB["DurabilityStatus"]		= unitscanLC["DurabilityStatus"]
			unitscanDB["ShowVanityControls"]		= unitscanLC["ShowVanityControls"]
			unitscanDB["VanityAltLayout"]		= unitscanLC["VanityAltLayout"]
			unitscanDB["ShowBagSearchBox"]		= unitscanLC["ShowBagSearchBox"]
			-- unitscanDB["ShowRaidToggle"]			= unitscanLC["ShowRaidToggle"]
			unitscanDB["ShowPlayerChain"]		= unitscanLC["ShowPlayerChain"]
			unitscanDB["PlayerChainMenu"]		= unitscanLC["PlayerChainMenu"]
			unitscanDB["ShowReadyTimer"]			= unitscanLC["ShowReadyTimer"]
			unitscanDB["ShowWowheadLinks"]		= unitscanLC["ShowWowheadLinks"]
			unitscanDB["WowheadLinkComments"]	= unitscanLC["WowheadLinkComments"]

			unitscanDB["ShowFlightTimes"]		= unitscanLC["ShowFlightTimes"]
			unitscanDB["FlightBarBackground"]	= unitscanLC["FlightBarBackground"]
			unitscanDB["FlightBarDestination"]	= unitscanLC["FlightBarDestination"]
			unitscanDB["FlightBarFillBar"]		= unitscanLC["FlightBarFillBar"]
			unitscanDB["FlightBarSpeech"]		= unitscanLC["FlightBarSpeech"]

			unitscanDB["FlightBarContribute"]	= unitscanLC["FlightBarContribute"]
			unitscanDB["FlightBarA"]				= unitscanLC["FlightBarA"]
			unitscanDB["FlightBarR"]				= unitscanLC["FlightBarR"]
			unitscanDB["FlightBarX"]				= unitscanLC["FlightBarX"]
			unitscanDB["FlightBarY"]				= unitscanLC["FlightBarY"]
			unitscanDB["FlightBarScale"]			= unitscanLC["FlightBarScale"]
			unitscanDB["FlightBarWidth"]			= unitscanLC["FlightBarWidth"]

			-- Frames
			unitscanDB["FrmEnabled"]				= unitscanLC["FrmEnabled"]

			unitscanDB["ManageBuffs"]			= unitscanLC["ManageBuffs"]
			unitscanDB["BuffFrameA"]				= unitscanLC["BuffFrameA"]
			unitscanDB["BuffFrameR"]				= unitscanLC["BuffFrameR"]
			unitscanDB["BuffFrameX"]				= unitscanLC["BuffFrameX"]
			unitscanDB["BuffFrameY"]				= unitscanLC["BuffFrameY"]
			unitscanDB["BuffFrameScale"]			= unitscanLC["BuffFrameScale"]

			unitscanDB["ManageWidget"]			= unitscanLC["ManageWidget"]
			unitscanDB["WidgetA"]				= unitscanLC["WidgetA"]
			unitscanDB["WidgetR"]				= unitscanLC["WidgetR"]
			unitscanDB["WidgetX"]				= unitscanLC["WidgetX"]
			unitscanDB["WidgetY"]				= unitscanLC["WidgetY"]
			unitscanDB["WidgetScale"]			= unitscanLC["WidgetScale"]

			unitscanDB["ManageFocus"]			= unitscanLC["ManageFocus"]
			unitscanDB["FocusA"]					= unitscanLC["FocusA"]
			unitscanDB["FocusR"]					= unitscanLC["FocusR"]
			unitscanDB["FocusX"]					= unitscanLC["FocusX"]
			unitscanDB["FocusY"]					= unitscanLC["FocusY"]
			unitscanDB["FocusScale"]				= unitscanLC["FocusScale"]

			unitscanDB["ManageTimer"]			= unitscanLC["ManageTimer"]
			unitscanDB["TimerA"]					= unitscanLC["TimerA"]
			unitscanDB["TimerR"]					= unitscanLC["TimerR"]
			unitscanDB["TimerX"]					= unitscanLC["TimerX"]
			unitscanDB["TimerY"]					= unitscanLC["TimerY"]
			unitscanDB["TimerScale"]				= unitscanLC["TimerScale"]

			unitscanDB["ManageDurability"]		= unitscanLC["ManageDurability"]
			unitscanDB["DurabilityA"]			= unitscanLC["DurabilityA"]
			unitscanDB["DurabilityR"]			= unitscanLC["DurabilityR"]
			unitscanDB["DurabilityX"]			= unitscanLC["DurabilityX"]
			unitscanDB["DurabilityY"]			= unitscanLC["DurabilityY"]
			unitscanDB["DurabilityScale"]		= unitscanLC["DurabilityScale"]

			unitscanDB["ManageVehicle"]			= unitscanLC["ManageVehicle"]
			unitscanDB["VehicleA"]				= unitscanLC["VehicleA"]
			unitscanDB["VehicleR"]				= unitscanLC["VehicleR"]
			unitscanDB["VehicleX"]				= unitscanLC["VehicleX"]
			unitscanDB["VehicleY"]				= unitscanLC["VehicleY"]
			unitscanDB["VehicleScale"]			= unitscanLC["VehicleScale"]

			unitscanDB["ClassColFrames"]			= unitscanLC["ClassColFrames"]
			unitscanDB["ClassColPlayer"]			= unitscanLC["ClassColPlayer"]
			unitscanDB["ClassColTarget"]			= unitscanLC["ClassColTarget"]

			unitscanDB["NoAlerts"]				= unitscanLC["NoAlerts"]
			unitscanDB["NoGryphons"]				= unitscanLC["NoGryphons"]
			unitscanDB["NoClassBar"]				= unitscanLC["NoClassBar"]

			-- System
			unitscanDB["NoScreenGlow"] 			= unitscanLC["NoScreenGlow"]
			unitscanDB["NoScreenEffects"] 		= unitscanLC["NoScreenEffects"]
			unitscanDB["SetWeatherDensity"] 		= unitscanLC["SetWeatherDensity"]
			unitscanDB["WeatherLevel"] 			= unitscanLC["WeatherLevel"]
			unitscanDB["MaxCameraZoom"] 			= unitscanLC["MaxCameraZoom"]
			unitscanDB["ViewPortEnable"]			= unitscanLC["ViewPortEnable"]
			unitscanDB["ViewPortTop"]			= unitscanLC["ViewPortTop"]
			unitscanDB["ViewPortBottom"]			= unitscanLC["ViewPortBottom"]
			unitscanDB["ViewPortLeft"]			= unitscanLC["ViewPortLeft"]
			unitscanDB["ViewPortRight"]			= unitscanLC["ViewPortRight"]
			unitscanDB["ViewPortResizeTop"]		= unitscanLC["ViewPortResizeTop"]
			unitscanDB["ViewPortResizeBottom"]	= unitscanLC["ViewPortResizeBottom"]
			unitscanDB["ViewPortAlpha"]			= unitscanLC["ViewPortAlpha"]

			unitscanDB["NoRestedEmotes"]			= unitscanLC["NoRestedEmotes"]
			unitscanDB["MuteGameSounds"]			= unitscanLC["MuteGameSounds"]
			unitscanDB["MuteCustomSounds"]		= unitscanLC["MuteCustomSounds"]
			unitscanDB["MuteCustomList"]			= unitscanLC["MuteCustomList"]

			unitscanDB["NoBagAutomation"]		= unitscanLC["NoBagAutomation"]
			unitscanDB["CharAddonList"]			= unitscanLC["CharAddonList"]
			unitscanDB["NoConfirmLoot"] 			= unitscanLC["NoConfirmLoot"]
			unitscanDB["FasterLooting"] 			= unitscanLC["FasterLooting"]
			unitscanDB["FasterMovieSkip"] 		= unitscanLC["FasterMovieSkip"]
			unitscanDB["StandAndDismount"] 		= unitscanLC["StandAndDismount"]
			unitscanDB["DismountNoResource"] 	= unitscanLC["DismountNoResource"]
			unitscanDB["DismountNoMoving"] 		= unitscanLC["DismountNoMoving"]
			unitscanDB["DismountNoTaxi"] 		= unitscanLC["DismountNoTaxi"]
			unitscanDB["DismountShowFormBtn"] 	= unitscanLC["DismountShowFormBtn"]
			unitscanDB["ShowVendorPrice"] 		= unitscanLC["ShowVendorPrice"]
			unitscanDB["CombatPlates"]			= unitscanLC["CombatPlates"]
			unitscanDB["EasyItemDestroy"]		= unitscanLC["EasyItemDestroy"]

			-- Settings
			unitscanDB["ShowMinimapIcon"] 		= unitscanLC["ShowMinimapIcon"]
			unitscanDB["PlusPanelScale"] 		= unitscanLC["PlusPanelScale"]
			unitscanDB["PlusPanelAlpha"] 		= unitscanLC["PlusPanelAlpha"]

			-- Panel position
			unitscanDB["MainPanelA"]				= unitscanLC["MainPanelA"]
			unitscanDB["MainPanelR"]				= unitscanLC["MainPanelR"]
			unitscanDB["MainPanelX"]				= unitscanLC["MainPanelX"]
			unitscanDB["MainPanelY"]				= unitscanLC["MainPanelY"]

			-- Start page
			unitscanDB["LeaStartPage"]			= unitscanLC["LeaStartPage"]

			---- Mute game sounds (unitscanLC["MuteGameSounds"])
			--for k, v in pairs(unitscanLC["muteTable"]) do
			--	unitscanDB[k] = unitscanLC[k]
			--end

		end

	end

--	Register event handler
	usEvt:SetScript("OnEvent", eventHandler);





----------------------------------------------------------------------
--	L70: Player logout
----------------------------------------------------------------------

	-- Player Logout
	function unitscanLC:PlayerLogout(wipe)

		----------------------------------------------------------------------
		-- Restore default values for options that do not require reloads
		----------------------------------------------------------------------

		if wipe then

			-- Max camera zoom (unitscanLC["MaxCameraZoom"])
			SetCVar("cameraDistanceMaxZoomFactor", 1.9)


		end



		----------------------------------------------------------------------
		-- Restore default values for options that require reloads
		----------------------------------------------------------------------

		---- More font sizes
		--if unitscanDB["MoreFontSizes"] == "On" and not LeaLockList["MoreFontSizes"] then
		--	if wipe or (not wipe and unitscanLC["MoreFontSizes"] == "Off") then
		--		RunScript('for i = 1, 50 do if _G["ChatFrame" .. i] then local void, fontSize = FCF_GetChatWindowInfo(i); if fontSize and fontSize ~= 12 and fontSize ~= 14 and fontSize ~= 16 and fontSize ~= 18 then FCF_SetChatWindowFontSize(self, _G["ChatFrame" .. i], CHAT_FRAME_DEFAULT_FONT_SIZE) end end end')
		--	end
		--end

	end

----------------------------------------------------------------------
-- 	Options panel functions
----------------------------------------------------------------------

	-- Function to add textures to panels
	function unitscanLC:CreateBar(name, parent, width, height, anchor, r, g, b, alp, tex)
		local ft = parent:CreateTexture(nil, "BORDER")
		ft:SetTexture(tex)
		ft:SetSize(width, height)
		ft:SetPoint(anchor)
		ft:SetVertexColor(r ,g, b, alp)
		if name == "MainTexture" then
			ft:SetTexCoord(0.09, 1, 0, 1);
		end
	end

	-- Create a configuration panel
	function unitscanLC:CreatePanel(title, globref)

		-- Create the panel
		local Side = CreateFrame("Frame", nil, UIParent)

		-- Make it a system frame
		_G["unitscanGlobalPanel_" .. globref] = Side
		table.insert(UISpecialFrames, "unitscanGlobalPanel_" .. globref)

		-- Store it in the configuration panel table
		tinsert(LeaConfigList, Side)

		-- Set frame parameters
		Side:Hide();
		Side:SetSize(570, 370);
		Side:SetClampedToScreen(true)
		Side:SetClampRectInsets(500, -500, -300, 300)
		Side:SetFrameStrata("FULLSCREEN_DIALOG")

		-- Set the background color
		Side.t = Side:CreateTexture(nil, "BACKGROUND")
		Side.t:SetAllPoints()
		Side.t:SetTexture(0.05, 0.05, 0.05, 0.9)

		-- Add a close Button
		Side.c = CreateFrame("Button", nil, Side, "UIPanelCloseButton")
		Side.c:SetSize(30, 30)
		Side.c:SetPoint("TOPRIGHT", 0, 0)
		Side.c:SetScript("OnClick", function() Side:Hide() end)

		-- Add reset, help and back buttons
		Side.r = unitscanLC:CreateButton("ResetButton", Side, "Reset", "TOPLEFT", 16, -292, 0, 25, true, "Click to reset the settings on this page.")
		Side.h = unitscanLC:CreateButton("HelpButton", Side, "Help", "TOPLEFT", 76, -292, 0, 25, true, "No help is available for this page.")
		Side.b = unitscanLC:CreateButton("BackButton", Side, "Back to Main Menu", "TOPRIGHT", -16, -292, 0, 25, true, "Click to return to the main menu.")

		-- Reposition help button so it doesn't overlap reset button
		Side.h:ClearAllPoints()
		Side.h:SetPoint("LEFT", Side.r, "RIGHT", 10, 0)

		-- Remove the click texture from the help button
		Side.h:SetPushedTextOffset(0, 0)

		-- Add a reload button and syncronise it with the main panel reload button
		local reloadb = unitscanLC:CreateButton("ConfigReload", Side, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, unitscanCB["ReloadUIButton"].tiptext)
		unitscanLC:LockItem(reloadb,true)
		reloadb:SetScript("OnClick", ReloadUI)

		reloadb.f = reloadb:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
		reloadb.f:SetHeight(32);
		reloadb.f:SetPoint('RIGHT', reloadb, 'LEFT', -10, 0)
		reloadb.f:SetText(unitscanCB["ReloadUIButton"].f:GetText())
		reloadb.f:Hide()

		unitscanCB["ReloadUIButton"]:HookScript("OnEnable", function()
			unitscanLC:LockItem(reloadb, false)
			reloadb.f:Show()
		end)

		unitscanCB["ReloadUIButton"]:HookScript("OnDisable", function()
			unitscanLC:LockItem(reloadb, true)
			reloadb.f:Hide()
		end)

		-- Set textures
		unitscanLC:CreateBar("FootTexture", Side, 570, 48, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\addons\\unitscan\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
		unitscanLC:CreateBar("MainTexture", Side, 570, 323, "TOPRIGHT", 0.7, 0.7, 0.7, 0.9,  "Interface\\addons\\unitscan\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")

		-- Allow movement
		Side:EnableMouse(true)
		Side:SetMovable(true)
		Side:RegisterForDrag("LeftButton")
		Side:SetScript("OnDragStart", Side.StartMoving)
		Side:SetScript("OnDragStop", function ()
			Side:StopMovingOrSizing();
			Side:SetUserPlaced(false);
			-- Save panel position
			unitscanLC["MainPanelA"], void, unitscanLC["MainPanelR"], unitscanLC["MainPanelX"], unitscanLC["MainPanelY"] = Side:GetPoint()
		end)

		-- Set panel attributes when shown
		Side:SetScript("OnShow", function()
			Side:ClearAllPoints()
			Side:SetPoint(unitscanLC["MainPanelA"], UIParent, unitscanLC["MainPanelR"], unitscanLC["MainPanelX"], unitscanLC["MainPanelY"])
			Side:SetScale(unitscanLC["PlusPanelScale"])
			Side.t:SetAlpha(1 - unitscanLC["PlusPanelAlpha"])
		end)

		-- Add title
		Side.f = Side:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		Side.f:SetPoint('TOPLEFT', 16, -16);
		Side.f:SetText(L[title])

		-- Add description
		Side.v = Side:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		Side.v:SetHeight(32);
		Side.v:SetPoint('TOPLEFT', Side.f, 'BOTTOMLEFT', 0, -8);
		Side.v:SetPoint('RIGHT', Side, -32, 0)
		Side.v:SetJustifyH('LEFT'); Side.v:SetJustifyV('TOP');
		Side.v:SetText(L["Configuration Panel"])

		-- Prevent options panel from showing while side panel is showing
		unitscanLC["PageF"]:HookScript("OnShow", function()
			if Side:IsShown() then unitscanLC["PageF"]:Hide(); end
		end)

		-- Return the frame
		return Side

	end

	-- Define subheadings
	function unitscanLC:MakeTx(frame, title, x, y)
		local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		text:SetPoint("TOPLEFT", x, y)
		text:SetText(L[title])
		return text
	end

	-- Define text
	function unitscanLC:MakeWD(frame, title, x, y)
		local text = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		text:SetPoint("TOPLEFT", x, y)
		text:SetText(L[title])
		text:SetJustifyH"LEFT";
		return text
	end

	-- Create a slider control (uses standard template)
	function unitscanLC:MakeSL(frame, field, caption, low, high, step, x, y, form)

		-- Create slider control
		local Slider = CreateFrame("Slider", "unitscanGlobalSlider" .. field, frame, "OptionssliderTemplate")
		unitscanCB[field] = Slider;
		Slider:SetMinMaxValues(low, high)
		Slider:SetValueStep(step)
		Slider:EnableMouseWheel(true)
		Slider:SetPoint('TOPLEFT', x,y)
		Slider:SetWidth(100)
		Slider:SetHeight(20)
		Slider:SetHitRectInsets(0, 0, 0, 0);
		Slider.tiptext = L[caption]
		Slider:SetScript("OnEnter", unitscanLC.TipSee)
		Slider:SetScript("OnLeave", GameTooltip_Hide)

		-- Remove slider text
		_G[Slider:GetName().."Low"]:SetText('');
		_G[Slider:GetName().."High"]:SetText('');

		-- Create slider label
		Slider.f = Slider:CreateFontString(nil, 'BACKGROUND')
		Slider.f:SetFontObject('GameFontHighlight')
		Slider.f:SetPoint('LEFT', Slider, 'RIGHT', 12, 0)
		Slider.f:SetFormattedText("%.2f", Slider:GetValue())

		-- Process mousewheel scrolling
		Slider:SetScript("OnMouseWheel", function(self, arg1)
			if Slider:IsEnabled() then
				local step = step * arg1
				local value = self:GetValue()
				if step > 0 then
					self:SetValue(min(value + step, high))
				else
					self:SetValue(max(value + step, low))
				end
			end
		end)

		-- Process value changed
		Slider:SetScript("OnValueChanged", function(self, value)
			local value = floor((value - low) / step + 0.5) * step + low
			Slider.f:SetFormattedText(form, value)
			unitscanLC[field] = value
		end)

		-- Set slider value when shown
		Slider:SetScript("OnShow", function(self)
			self:SetValue(unitscanLC[field])
		end)

	end

	-- Create a checkbox control (uses standard template)
	function unitscanLC:MakeCB(parent, field, caption, x, y, reload, tip, tipstyle)

		-- Create the checkbox
		local Cbox = CreateFrame('CheckButton', nil, parent, "ChatConfigCheckButtonTemplate")
		unitscanCB[field] = Cbox
		Cbox:SetPoint("TOPLEFT",x, y)
		Cbox:SetScript("OnEnter", unitscanLC.TipSee)
		Cbox:SetScript("OnLeave", GameTooltip_Hide)

		-- Add label and tooltip
		Cbox.f = Cbox:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		Cbox.f:SetPoint('LEFT', 20, 0)
		if reload then
			-- Checkbox requires UI reload
			Cbox.f:SetText(L[caption] .. "*")
			Cbox.tiptext = L[tip] .. "|n|n* " .. L["Requires UI reload."]
		else
			-- Checkbox does not require UI reload
			Cbox.f:SetText(L[caption])
			Cbox.tiptext = L[tip]
		end

		-- Set label parameters
		Cbox.f:SetJustifyH("LEFT")
		Cbox.f:SetWordWrap(false)

		-- Set maximum label width
		if parent:GetParent() == unitscanLC["PageF"] then
			-- Main panel checkbox labels
			if Cbox.f:GetWidth() > 152 then
				Cbox.f:SetWidth(152)
				unitscanLC["TruncatedLabelsList"] = unitscanLC["TruncatedLabelsList"] or {}
				unitscanLC["TruncatedLabelsList"][Cbox.f] = L[caption]
			end
			-- Set checkbox click width
			if Cbox.f:GetStringWidth() > 152 then
				Cbox:SetHitRectInsets(0, -142, 0, 0)
			else
				Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
			end
		else
			-- Configuration panel checkbox labels (other checkboxes either have custom functions or blank labels)
			if Cbox.f:GetWidth() > 302 then
				Cbox.f:SetWidth(302)
				unitscanLC["TruncatedLabelsList"] = unitscanLC["TruncatedLabelsList"] or {}
				unitscanLC["TruncatedLabelsList"][Cbox.f] = L[caption]
			end
			-- Set checkbox click width
			if Cbox.f:GetStringWidth() > 302 then
				Cbox:SetHitRectInsets(0, -292, 0, 0)
			else
				Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
			end
		end

		-- Set default checkbox state and click area
		Cbox:SetScript('OnShow', function(self)
			if unitscanLC[field] == "On" then
				self:SetChecked(true)
			else
				self:SetChecked(false)
			end
		end)

		-- Process clicks
		Cbox:SetScript('OnClick', function()
			if Cbox:GetChecked() then
				unitscanLC[field] = "On"
			else
				unitscanLC[field] = "Off"
			end
			unitscanLC:SetDim(); -- Lock invalid options
			unitscanLC:ReloadCheck(); -- Show reload button if needed
			--unitscanLC:Live(); -- Run live code
		end)
	end

	-- Create an editbox (uses standard template)
	function unitscanLC:CreateEditBox(frame, parent, width, maxchars, anchor, x, y, tab, shifttab)

		-- Create editbox
        local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
		unitscanCB[frame] = eb
		eb:SetPoint(anchor, x, y)
		eb:SetWidth(width)
		eb:SetHeight(24)
		eb:SetFontObject("GameFontNormal")
		eb:SetTextColor(1.0, 1.0, 1.0)
		eb:SetAutoFocus(false)
		eb:SetMaxLetters(maxchars)
		eb:SetScript("OnEscapePressed", eb.ClearFocus)
		eb:SetScript("OnEnterPressed", eb.ClearFocus)
		eb:DisableDrawLayer("BACKGROUND")

		-- Add editbox border and backdrop
		eb.f = CreateFrame("FRAME", nil, eb)
		eb.f:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 }})
		eb.f:SetPoint("LEFT", -6, 0)
		eb.f:SetWidth(eb:GetWidth()+6)
		eb.f:SetHeight(eb:GetHeight())
		eb.f:SetBackdropColor(1.0, 1.0, 1.0, 0.3)

		-- Move onto next editbox when tab key is pressed
		eb:SetScript("OnTabPressed", function(self)
			self:ClearFocus()
			if IsShiftKeyDown() then
				unitscanCB[shifttab]:SetFocus()
			else
				unitscanCB[tab]:SetFocus()
			end
		end)

		return eb

	end


	-- Create a standard button (using standard button template)
	function unitscanLC:CreateButton(name, frame, label, anchor, x, y, width, height, reskin, tip, naked)
		local mbtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		unitscanCB[name] = mbtn
		mbtn:SetSize(width, height)
		mbtn:SetPoint(anchor, x, y)
		mbtn:SetHitRectInsets(0, 0, 0, 0)
		mbtn:SetText(L[label])

		-- Create fontstring so the button can be sized correctly
		mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		mbtn.f:SetText(L[label])
		if width > 0 then
			-- Button should have static width
			mbtn:SetWidth(width)
		else
			-- Button should have variable width
			mbtn:SetWidth(mbtn.f:GetStringWidth() + 20)
		end

		-- Tooltip handler
		mbtn.tiptext = L[tip]
		mbtn:SetScript("OnEnter", unitscanLC.TipSee)
		mbtn:SetScript("OnLeave", GameTooltip_Hide)

		-- Texture the button
		if reskin then

			-- Set skinned button textures
			if not naked then
				mbtn:SetNormalTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
				mbtn:GetNormalTexture():SetTexCoord(0.125, 0.25, 0.4375, 0.5)
			end
			mbtn:SetHighlightTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
			mbtn:GetHighlightTexture():SetTexCoord(0, 0.125, 0.4375, 0.5)

			-- Hide the default textures
			-- mbtn:HookScript("OnShow", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			-- mbtn:HookScript("OnEnable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			-- mbtn:HookScript("OnDisable", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)
			-- mbtn:HookScript("OnMouseDown", function() mbtn:GetPushedTexture():Hide() end)
			-- mbtn:HookScript("OnMouseUp", function() mbtn.Left:Hide(); mbtn.Middle:Hide(); mbtn.Right:Hide() end)


			--===== 3.3.5 texture disables =====--

			-- mbtn:GetNormalTexture():SetTexture(nil)
			mbtn:GetPushedTexture():SetTexture(nil)
			-- mbtn:GetDisabledTexture():SetTexture(nil)
			-- mbtn:GetHighlightTexture():SetTexture(nil)

		end

		return mbtn
	end

	-- Create a dropdown menu (using custom function to avoid taint)
	function unitscanLC:CreateDropDown(ddname, label, parent, width, anchor, x, y, items, tip)

		-- Add the dropdown name to a table
		tinsert(LeaDropList, ddname)

		-- Populate variable with item list
		unitscanLC[ddname .. "Table"] = items

		-- Create outer frame
		local frame = CreateFrame("FRAME", nil, parent); frame:SetWidth(width); frame:SetHeight(42); frame:SetPoint("BOTTOMLEFT", parent, anchor, x, y);

		-- Create dropdown inside outer frame
		local dd = CreateFrame("Frame", nil, frame); dd:SetPoint("BOTTOMLEFT", -16, -8); dd:SetPoint("BOTTOMRIGHT", 15, -4); dd:SetHeight(32);

		-- Create dropdown textures
		local lt = dd:CreateTexture(nil, "ARTWORK"); lt:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame"); lt:SetTexCoord(0, 0.1953125, 0, 1); lt:SetPoint("TOPLEFT", dd, 0, 17); lt:SetWidth(25); lt:SetHeight(64);
		local rt = dd:CreateTexture(nil, "BORDER"); rt:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame"); rt:SetTexCoord(0.8046875, 1, 0, 1); rt:SetPoint("TOPRIGHT", dd, 0, 17); rt:SetWidth(25); rt:SetHeight(64);
		local mt = dd:CreateTexture(nil, "BORDER"); mt:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame"); mt:SetTexCoord(0.1953125, 0.8046875, 0, 1); mt:SetPoint("LEFT", lt, "RIGHT"); mt:SetPoint("RIGHT", rt, "LEFT"); mt:SetHeight(64);

		-- Create dropdown label
		local lf = dd:CreateFontString(nil, "OVERLAY", "GameFontNormal"); lf:SetPoint("TOPLEFT", frame, 0, 0); lf:SetPoint("TOPRIGHT", frame, -5, 0); lf:SetJustifyH("LEFT"); lf:SetText(L[label])

		-- Create dropdown placeholder for value (set it using OnShow)
		local value = dd:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		value:SetPoint("LEFT", lt, 26, 2); value:SetPoint("RIGHT", rt, -43, 0); value:SetJustifyH("LEFT"); value:SetWordWrap(false)
		dd:SetScript("OnShow", function() value:SetText(unitscanLC[ddname.."Table"][unitscanLC[ddname]]) end)

		-- Create dropdown button (clicking it opens the dropdown list)
		local dbtn = CreateFrame("Button", nil, dd)
		dbtn:SetPoint("TOPRIGHT", rt, -16, -18); dbtn:SetWidth(24); dbtn:SetHeight(24)
		dbtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up"); dbtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down"); dbtn:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled"); dbtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight"); dbtn:GetHighlightTexture():SetBlendMode("ADD")
		dbtn.tiptext = tip; dbtn:SetScript("OnEnter", unitscanLC.ShowDropTip)
		dbtn:SetScript("OnLeave", GameTooltip_Hide)

		-- Create dropdown list
		local ddlist =  CreateFrame("Frame",nil,frame)
		unitscanCB["ListFrame"..ddname] = ddlist
		ddlist:SetPoint("TOP",0,-42)
		ddlist:SetWidth(frame:GetWidth())
		ddlist:SetHeight((#items * 16) + 16 + 16)
		ddlist:SetFrameStrata("FULLSCREEN_DIALOG")
		ddlist:SetFrameLevel(12)
		ddlist:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = false, tileSize = 0, edgeSize = 32, insets = { left = 4, right = 4, top = 4, bottom = 4 }});
		ddlist:Hide()

		-- Hide list if parent is closed
		parent:HookScript("OnHide", function() ddlist:Hide() end)

		-- Create checkmark (it marks the currently selected item)
		local ddlistchk = CreateFrame("FRAME", nil, ddlist)
		ddlistchk:SetHeight(16); ddlistchk:SetWidth(16)
		ddlistchk.t = ddlistchk:CreateTexture(nil, "ARTWORK"); ddlistchk.t:SetAllPoints(); ddlistchk.t:SetTexture("Interface\\Common\\UI-DropDownRadioChecks"); ddlistchk.t:SetTexCoord(0, 0.5, 0.5, 1.0);

		-- Create dropdown list items
		for k, v in pairs(items) do

			local dditem = CreateFrame("Button", nil, unitscanCB["ListFrame"..ddname])
			unitscanCB["Drop"..ddname..k] = dditem;
			dditem:Show();
			dditem:SetWidth(ddlist:GetWidth() - 22)
			dditem:SetHeight(16)
			dditem:SetPoint("TOPLEFT", 12, -k * 16)

			dditem.f = dditem:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
			dditem.f:SetPoint('LEFT', 16, 0)
			dditem.f:SetText(items[k])

			dditem.f:SetWordWrap(false)
			dditem.f:SetJustifyH("LEFT")
			dditem.f:SetWidth(ddlist:GetWidth()-36)

			dditem.t = dditem:CreateTexture(nil, "BACKGROUND")
			dditem.t:SetAllPoints()
			dditem.t:SetTexture(0.3, 0.3, 0.00, 0.8)
			dditem.t:Hide();

			dditem:SetScript("OnEnter", function() dditem.t:Show() end)
			dditem:SetScript("OnLeave", function() dditem.t:Hide() end)
			dditem:SetScript("OnClick", function()
				unitscanLC[ddname] = k
				value:SetText(unitscanLC[ddname.."Table"][k])
				ddlist:Hide(); -- Must be last in click handler as other functions hook it
			end)

			-- Show list when button is clicked
			dbtn:SetScript("OnClick", function()
				-- Show the dropdown
				if ddlist:IsShown() then ddlist:Hide() else
					ddlist:Show();
					ddlistchk:SetPoint("TOPLEFT",10,select(5,unitscanCB["Drop"..ddname..unitscanLC[ddname]]:GetPoint()))
					ddlistchk:Show();
				end;
				-- Hide all other dropdowns except the one we're dealing with
				for void,v in pairs(LeaDropList) do
					if v ~= ddname then
						unitscanCB["ListFrame"..v]:Hide()
					end
				end
			end)

			-- Expand the clickable area of the button to include the entire menu width
			dbtn:SetHitRectInsets(-width+28, 0, 0, 0)

		end

		return frame

	end

----------------------------------------------------------------------
-- 	Create main options panel frame
----------------------------------------------------------------------

	function unitscanLC:CreateMainPanel()

		-- Create the panel
		local PageF = CreateFrame("Frame", nil, UIParent);

		-- Make it a system frame
		_G["unitscanGlobalPanel"] = PageF
		table.insert(UISpecialFrames, "unitscanGlobalPanel")

		-- Set frame parameters
		unitscanLC["PageF"] = PageF
		PageF:SetSize(570,370)
		PageF:Hide();
		PageF:SetFrameStrata("FULLSCREEN_DIALOG")
		PageF:SetClampedToScreen(true)
		PageF:SetClampRectInsets(500, -500, -300, 300)
		PageF:EnableMouse(true)
		PageF:SetMovable(true)
		PageF:RegisterForDrag("LeftButton")
		PageF:SetScript("OnDragStart", PageF.StartMoving)
		PageF:SetScript("OnDragStop", function ()
		PageF:StopMovingOrSizing();
		PageF:SetUserPlaced(false);
		-- Save panel position
		unitscanLC["MainPanelA"], void, unitscanLC["MainPanelR"], unitscanLC["MainPanelX"], unitscanLC["MainPanelY"] = PageF:GetPoint()
		end)

		-- Add background color
		PageF.t = PageF:CreateTexture(nil, "BACKGROUND")
		PageF.t:SetAllPoints()
		PageF.t:SetTexture(0.05, 0.05, 0.05, 0.9)

		-- Add textures
		unitscanLC:CreateBar("FootTexture", PageF, 570, 42, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
		unitscanLC:CreateBar("MainTexture", PageF, 440, 348, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
		unitscanLC:CreateBar("MenuTexture", PageF, 130, 348, "TOPLEFT", 0.7, 0.7, 0.7, 0.7, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")

		-- Set panel position when shown
		PageF:SetScript("OnShow", function()
			PageF:ClearAllPoints()
			PageF:SetPoint(unitscanLC["MainPanelA"], UIParent, unitscanLC["MainPanelR"], unitscanLC["MainPanelX"], unitscanLC["MainPanelY"])
		end)

		-- Add main title (shown above menu in the corner)
		PageF.mt = PageF:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		PageF.mt:SetPoint('TOPLEFT', 16, -16)
		PageF.mt:SetText("unitscan")

		-- Add version text (shown underneath main title)
		PageF.v = PageF:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
		PageF.v:SetHeight(32);
		PageF.v:SetPoint('TOPLEFT', PageF.mt, 'BOTTOMLEFT', 0, -8);
		PageF.v:SetPoint('RIGHT', PageF, -32, 0)
		PageF.v:SetJustifyH('LEFT'); PageF.v:SetJustifyV('TOP');
		PageF.v:SetNonSpaceWrap(true); PageF.v:SetText(L["Version"] .. " " .. unitscanLC["AddonVer"])

		-- Add reload UI Button
		local reloadb = unitscanLC:CreateButton("ReloadUIButton", PageF, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, "Your UI needs to be reloaded for some of the changes to take effect.|n|nYou don't have to click the reload button immediately but you do need to click it when you are done making changes and you want the changes to take effect.")
		unitscanLC:LockItem(reloadb,true)
		reloadb:SetScript("OnClick", ReloadUI)

		reloadb.f = reloadb:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
		reloadb.f:SetHeight(32);
		reloadb.f:SetPoint('RIGHT', reloadb, 'LEFT', -10, 0)
		reloadb.f:SetText(L["Your UI needs to be reloaded."])
		reloadb.f:Hide()

		-- Add close Button
		local CloseB = CreateFrame("Button", nil, PageF, "UIPanelCloseButton")
		CloseB:SetSize(30, 30)
		CloseB:SetPoint("TOPRIGHT", 0, 0)
		CloseB:SetScript("OnClick", unitscanLC.HideFrames)

		-- Add web link Button
		local PageFAlertButton = unitscanLC:CreateButton("PageFAlertButton", PageF, "You should keybind web link!", "BOTTOMLEFT", 16, 10, 0, 25, true, "You should set a keybind for the web link feature.  It's very useful.|n|nOpen the key bindings window (accessible from the game menu) and click Leatrix Plus.|n|nSet a keybind for Show web link.|n|nNow when your pointer is over an item, NPC or spell (and more), press your keybind to get a web link.")
		PageFAlertButton:SetPushedTextOffset(0, 0)
		PageF:HookScript("OnShow", function()
			if GetBindingKey("LEATRIX_PLUS_GLOBAL_WEBLINK") then PageFAlertButton:Hide() else PageFAlertButton:Show() end
		end)

		-- Release memory
		unitscanLC.CreateMainPanel = nil

	end

	unitscanLC:CreateMainPanel();



----------------------------------------------------------------------
-- 	L90: Create options panel pages (no content yet)
----------------------------------------------------------------------

	-- Function to add menu button
	function unitscanLC:MakeMN(name, text, parent, anchor, x, y, width, height)

		local mbtn = CreateFrame("Button", nil, parent)
		unitscanLC[name] = mbtn
		mbtn:Show();
		mbtn:SetSize(width, height)
		mbtn:SetAlpha(1.0)
		mbtn:SetPoint(anchor, x, y)

		mbtn.t = mbtn:CreateTexture(nil, "BACKGROUND")
		mbtn.t:SetAllPoints()
		mbtn.t:SetTexture("Interface\\Buttons\\WHITE8X8")
		mbtn.t:SetVertexColor(1.0, 0.5, 0.0, 0.8)
		mbtn.t:SetAlpha(0.7)
		mbtn.t:Hide()

		mbtn.s = mbtn:CreateTexture(nil, "BACKGROUND")
		mbtn.s:SetAllPoints()
		mbtn.s:SetTexture("Interface\\Buttons\\WHITE8X8")
		mbtn.s:SetVertexColor(1.0, 0.5, 0.0, 0.8)
		mbtn.s:Hide()

		mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
		mbtn.f:SetPoint('LEFT', 16, 0)
		mbtn.f:SetText(L[text])

		mbtn:SetScript("OnEnter", function()
			mbtn.t:Show()
		end)

		mbtn:SetScript("OnLeave", function()
			mbtn.t:Hide()
		end)

		return mbtn, mbtn.s

	end

	-- Function to create individual options panel pages
	function unitscanLC:MakePage(name, title, menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)

		-- Create frame
		local oPage = CreateFrame("Frame", nil, unitscanLC["PageF"]);
		unitscanLC[name] = oPage
		oPage:SetAllPoints(unitscanLC["PageF"])
		oPage:Hide();

		-- Add page title
		oPage.s = oPage:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
		oPage.s:SetPoint('TOPLEFT', 146, -16)
		oPage.s:SetText(L[title])

		-- Add menu item if needed
		if menu then
			unitscanLC[menu], unitscanLC[menu .. ".s"] = unitscanLC:MakeMN(menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)
			unitscanLC[name]:SetScript("OnShow", function() unitscanLC[menu .. ".s"]:Show(); end)
			unitscanLC[name]:SetScript("OnHide", function() unitscanLC[menu .. ".s"]:Hide(); end)
		end

		return oPage;

	end

	-- Create options pages
	unitscanLC["Page0"] = unitscanLC:MakePage("Page0", "Home"			, "unitscanNav0", "Home"			, unitscanLC["PageF"], "TOPLEFT", 16, -72, 112, 20)
	unitscanLC["Page1"] = unitscanLC:MakePage("Page1", "Automation"	, "unitscanNav1", "Automation"	, unitscanLC["PageF"], "TOPLEFT", 16, -112, 112, 20)
	unitscanLC["Page2"] = unitscanLC:MakePage("Page2", "Social"		, "unitscanNav2", "Social"		, unitscanLC["PageF"], "TOPLEFT", 16, -132, 112, 20)
	unitscanLC["Page3"] = unitscanLC:MakePage("Page3", "Chat"			, "unitscanNav3", "Chat"			, unitscanLC["PageF"], "TOPLEFT", 16, -152, 112, 20)
	unitscanLC["Page4"] = unitscanLC:MakePage("Page4", "Text"			, "unitscanNav4", "Text"			, unitscanLC["PageF"], "TOPLEFT", 16, -172, 112, 20)
	unitscanLC["Page5"] = unitscanLC:MakePage("Page5", "Interface"	, "unitscanNav5", "Interface"	, unitscanLC["PageF"], "TOPLEFT", 16, -192, 112, 20)
	unitscanLC["Page6"] = unitscanLC:MakePage("Page6", "Frames"		, "unitscanNav6", "Frames"		, unitscanLC["PageF"], "TOPLEFT", 16, -212, 112, 20)
	unitscanLC["Page7"] = unitscanLC:MakePage("Page7", "System"		, "unitscanNav7", "System"		, unitscanLC["PageF"], "TOPLEFT", 16, -232, 112, 20)
	unitscanLC["Page8"] = unitscanLC:MakePage("Page8", "Settings"		, "unitscanNav8", "Settings"		, unitscanLC["PageF"], "TOPLEFT", 16, -272, 112, 20)
	unitscanLC["Page9"] = unitscanLC:MakePage("Page9", "Media"		, "unitscanNav9", "Media"		, unitscanLC["PageF"], "TOPLEFT", 16, -292, 112, 20)

	-- Page navigation mechanism
	for i = 0, unitscanLC["NumberOfPages"] do
		unitscanLC["unitscanNav"..i]:SetScript("OnClick", function()
			unitscanLC:HideFrames()
			unitscanLC["PageF"]:Show();
			unitscanLC["Page"..i]:Show();
			unitscanLC["LeaStartPage"] = i
		end)
	end

	-- Use a variable to contain the page number (makes it easier to move options around)
	local pg;

----------------------------------------------------------------------
-- 	LC0: Welcome
----------------------------------------------------------------------

	pg = "Page0";

	unitscanLC:MakeTx(unitscanLC[pg], "Welcome to unitscan.", 146, -72);
	unitscanLC:MakeWD(unitscanLC[pg], "To begin, choose an options page.", 146, -92);

	unitscanLC:MakeTx(unitscanLC[pg], "Support", 146, -132);
	unitscanLC:MakeWD(unitscanLC[pg], "|cff00ff00Feedback Discord:|r |cffadd8e6Sattva#7238|r", 146, -152);

----------------------------------------------------------------------
-- 	LC1: Automation
----------------------------------------------------------------------

	pg = "Page1";


	--unitscanLC:MakeTx(unitscanLC[pg], "Character"					, 	146, -72);
	--unitscanLC:MakeCB(unitscanLC[pg], "AutomateQuests"			,	"Automate quests"				,	146, -92, 	false,	"If checked, quests will be selected, accepted and turned-in automatically.|n|nQuests which have a gold requirement will not be turned-in automatically.")
	--unitscanLC:MakeCB(unitscanLC[pg], "AutomateGossip"			,	"Automate gossip"				,	146, -112, 	false,	"If checked, you can hold down the alt key while opening a gossip window to automatically select a single gossip item.|n|nIf the gossip item type is banker, taxi, trainer, vendor, battlemaster or stable master, gossip will be skipped without needing to hold the alt key.  You can hold the shift key down to prevent this.")
	--unitscanLC:MakeCB(unitscanLC[pg], "AutoAcceptSummon"			,	"Accept summon"					, 	146, -132, 	false,	"If checked, summon requests will be accepted automatically unless you are in combat.")
	--unitscanLC:MakeCB(unitscanLC[pg], "AutoAcceptRes"				,	"Accept resurrection"			, 	146, -152, 	false,	"If checked, resurrection requests will be accepted automatically.")
	--unitscanLC:MakeCB(unitscanLC[pg], "AutoReleasePvP"			,	"Release in PvP"				, 	146, -172, 	false,	"If checked, you will release automatically after you die in a battleground.|n|nYou will not release automatically if you have the ability to self-resurrect.")

	--unitscanLC:MakeTx(unitscanLC[pg], "Vendors"					, 	340, -72);
	--unitscanLC:MakeCB(unitscanLC[pg], "AutoSellJunk"				,	"Sell junk automatically"		,	340, -92, 	false,	"If checked, all grey items in your bags will be sold automatically when you visit a merchant.|n|nYou can hold the shift key down when you talk to a merchant to override this setting.")
	--unitscanLC:MakeCB(unitscanLC[pg], "AutoRepairGear"			, 	"Repair automatically"			,	340, -112, 	false,	"If checked, your gear will be repaired automatically when you visit a suitable merchant.|n|nYou can hold the shift key down when you talk to a merchant to override this setting.")

	--unitscanLC:CfgBtn("AutomateQuestsBtn", unitscanCB["AutomateQuests"])
	--unitscanLC:CfgBtn("AutoAcceptResBtn", unitscanCB["AutoAcceptRes"])
	--unitscanLC:CfgBtn("AutoReleasePvPBtn", unitscanCB["AutoReleasePvP"])
	--unitscanLC:CfgBtn("AutoSellJunkBtn", unitscanCB["AutoSellJunk"])
	--unitscanLC:CfgBtn("AutoRepairBtn", unitscanCB["AutoRepairGear"])

----------------------------------------------------------------------
-- 	LC2: Social
----------------------------------------------------------------------

	pg = "Page2";

	unitscanLC:MakeTx(unitscanLC[pg], "Blocks"					, 	146, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "NoDuelRequests"			, 	"Block duels"					,	146, -92, 	false,	"If checked, duel requests will be blocked unless the player requesting the duel is a friend.")
	unitscanLC:MakeCB(unitscanLC[pg], "NoPartyInvites"			, 	"Block party invites"			, 	146, -112, 	false,	"If checked, party invitations will be blocked unless the player inviting you is a friend.")
	-- unitscanLC:MakeCB(unitscanLC[pg], "NoFriendRequests"			, 	"Block friend requests"			, 	146, -132, 	false,	"If checked, BattleTag and Real ID friend requests will be automatically declined.|n|nEnabling this option will automatically decline any pending requests.")
	unitscanLC:MakeCB(unitscanLC[pg], "NoSharedQuests"			, 	"Block shared quests"			, 	146, -152, 	false,	"If checked, shared quests will be declined unless the player sharing the quest is a friend.")

	unitscanLC:MakeTx(unitscanLC[pg], "Groups"					, 	340, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "AcceptPartyFriends"		, 	"Party from friends"			, 	340, -92, 	false,	"If checked, party invitations from friends will be automatically accepted unless you are queued for a battleground.")
	unitscanLC:MakeCB(unitscanLC[pg], "InviteFromWhisper"			,   "Invite from whispers"			,	340, -112,	false,	L["If checked, a group invite will be sent to anyone who whispers you with a set keyword as long as you are ungrouped, group leader or raid assistant and not queued for a battleground.|n|nFriends who message the keyword using Battle.net will not be sent a group invite if they are appearing offline.  They need to either change their online status or use character whispers."] .. "|n|n" .. L["Keyword"] .. ": |cffffffff" .. "dummy" .. "|r")

	unitscanLC:MakeFT(unitscanLC[pg], "For all of the social options above, you can treat guild members as friends too.", 146, 380)
	unitscanLC:MakeCB(unitscanLC[pg], "FriendlyGuild"				, 	"Guild"							, 	146, -282, 	false,	"If checked, members of your guild will be treated as friends for all of the options on this page.")

	if unitscanCB["FriendlyGuild"].f:GetStringWidth() > 90 then
		unitscanCB["FriendlyGuild"].f:SetWidth(90)
		unitscanCB["FriendlyGuild"]:SetHitRectInsets(0, -84, 0, 0)
	end

	unitscanLC:CfgBtn("InvWhisperBtn", unitscanCB["InviteFromWhisper"])

----------------------------------------------------------------------
-- 	LC3: Chat
----------------------------------------------------------------------

	pg = "Page3";

	unitscanLC:MakeTx(unitscanLC[pg], "Chat Frame"				, 	146, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "UseEasyChatResizing"		,	"Use easy resizing"				,	146, -92,	true,	"If checked, dragging the General chat tab while the chat frame is locked will expand the chat frame upwards.|n|nIf the chat frame is unlocked, dragging the General chat tab will move the chat frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "NoCombatLogTab" 			, 	"Hide the combat log"			, 	146, -112, 	true,	"If checked, the combat log will be hidden.|n|nThe combat log must be docked in order for this option to work.|n|nIf the combat log is undocked, you can dock it by dragging the tab (and reloading your UI) or by resetting the chat windows (from the chat menu).")
	unitscanLC:MakeCB(unitscanLC[pg], "NoChatButtons"				,	"Hide chat buttons"				,	146, -132,	true,	"If checked, chat frame buttons will be hidden.|n|nClicking chat tabs will automatically show the latest messages.|n|nUse the mouse wheel to scroll through the chat history.  Hold down SHIFT for page jump or CTRL to jump to the top or bottom of the chat history.")
	unitscanLC:MakeCB(unitscanLC[pg], "UnclampChat"				,	"Unclamp chat frame"			,	146, -152,	true,	"If checked, you will be able to drag the chat frame to the edge of the screen.")
	unitscanLC:MakeCB(unitscanLC[pg], "MoveChatEditBoxToTop" 		, 	"Move editbox to top"			,	146, -172, 	true,	"If checked, the editbox will be moved to the top of the chat frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "MoreFontSizes"		 		, 	"More font sizes"				,	146, -192, 	true,	"If checked, additional font sizes will be available in the chat frame font size menu.")

	unitscanLC:MakeTx(unitscanLC[pg], "Mechanics"					, 	340, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "NoStickyChat"				, 	"Disable sticky chat"			,	340, -92,	true,	"If checked, sticky chat will be disabled.|n|nNote that this does not apply to temporary chat windows.")
	unitscanLC:MakeCB(unitscanLC[pg], "UseArrowKeysInChat"		, 	"Use arrow keys in chat"		, 	340, -112, 	true,	"If checked, you can press the arrow keys to move the insertion point left and right in the chat frame.|n|nIf unchecked, the arrow keys will use the default keybind setting.")
	unitscanLC:MakeCB(unitscanLC[pg], "NoChatFade"				, 	"Disable chat fade"				, 	340, -132, 	true,	"If checked, chat text will not fade out after a time period.")
	unitscanLC:MakeCB(unitscanLC[pg], "UnivGroupColor"			,	"Universal group color"			,	340, -152,	false,	"If checked, raid chat will be colored blue (to match the default party chat color).")
	unitscanLC:MakeCB(unitscanLC[pg], "ClassColorsInChat"			,	"Use class colors in chat"		,	340, -172,	true,	"If checked, class colors will be used in the chat frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "RecentChatWindow"			,	"Recent chat window"			, 	340, -192, 	true,	"If checked, you can hold down the control key and click a chat tab to view recent chat in a copy-friendly window.")
	unitscanLC:MakeCB(unitscanLC[pg], "MaxChatHstory"				,	"Increase chat history"			, 	340, -212, 	true,	"If checked, your chat history will increase to 4096 lines.  If unchecked, the default will be used (128 lines).|n|nEnabling this option may prevent some chat text from showing during login.")
	unitscanLC:MakeCB(unitscanLC[pg], "FilterChatMessages"		, 	"Filter chat messages"			,	340, -232, 	true,	"If checked, you can block spell links, drunken spam and duel spam.")
	unitscanLC:MakeCB(unitscanLC[pg], "RestoreChatMessages"		, 	"Restore chat messages"			,	340, -252, 	true,	"If checked, recent chat will be restored when you reload your interface.")

	unitscanLC:CfgBtn("FilterChatMessagesBtn", unitscanCB["FilterChatMessages"])

----------------------------------------------------------------------
-- 	LC4: Text
----------------------------------------------------------------------

	pg = "Page4";

	unitscanLC:MakeTx(unitscanLC[pg], "Visibility"				, 	146, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "HideErrorMessages"			, 	"Hide error messages"			,	146, -92, 	true,	"If checked, most error messages (such as 'Not enough rage') will not be shown.  Some important errors are excluded.|n|nIf you have the minimap button enabled, you can hold down the alt key and click it to toggle error messages without affecting this setting.")
	unitscanLC:MakeCB(unitscanLC[pg], "NoHitIndicators"			, 	"Hide portrait numbers"			,	146, -112, 	true,	"If checked, damage and healing numbers in the player and pet portrait frames will be hidden.")
	unitscanLC:MakeCB(unitscanLC[pg], "HideZoneText"				,	"Hide zone text"				,	146, -132, 	true,	"If checked, zone text will not be shown (eg. 'Ironforge').")
	unitscanLC:MakeCB(unitscanLC[pg], "HideKeybindText"			,	"Hide keybind text"				,	146, -152, 	true,	"If checked, keybind text will not be shown on action buttons.")
	unitscanLC:MakeCB(unitscanLC[pg], "HideMacroText"				,	"Hide macro text"				,	146, -172, 	true,	"If checked, macro text will not be shown on action buttons.")

	unitscanLC:MakeTx(unitscanLC[pg], "Text Size"					, 	340, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "MailFontChange"			,	"Resize mail text"				, 	340, -92, 	true,	"If checked, you will be able to change the font size of standard mail text.|n|nThis does not affect mail created using templates (such as auction house invoices).")
	unitscanLC:MakeCB(unitscanLC[pg], "QuestFontChange"			,	"Resize quest text"				, 	340, -112, 	true,	"If checked, you will be able to change the font size of quest text.")
	unitscanLC:MakeCB(unitscanLC[pg], "BookFontChange"			,	"Resize book text"				, 	340, -132, 	true,	"If checked, you will be able to change the font size of book text.")

	unitscanLC:CfgBtn("MailTextBtn", unitscanCB["MailFontChange"])
	unitscanLC:CfgBtn("QuestTextBtn", unitscanCB["QuestFontChange"])
	unitscanLC:CfgBtn("BookTextBtn", unitscanCB["BookFontChange"])

----------------------------------------------------------------------
-- 	LC5: Interface
----------------------------------------------------------------------

	pg = "Page5";

	unitscanLC:MakeTx(unitscanLC[pg], "Enhancements"				, 	146, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "MinimapModder"				,	"Enhance minimap"				, 	146, -92, 	true,	"If checked, you will be able to customise the minimap.")
	unitscanLC:MakeCB(unitscanLC[pg], "TipModEnable"				,	"Enhance tooltip"				,	146, -112, 	true,	"If checked, the tooltip will be color coded and you will be able to modify the tooltip layout and scale.")
	unitscanLC:MakeCB(unitscanLC[pg], "EnhanceDressup"			, 	"Enhance dressup"				,	146, -132, 	true,	"If checked, you will be able to pan (right-button) and zoom (mousewheel) in the character frame, dressup frame and inspect frame.|n|nA toggle stats button will be shown in the character frame.  You can also middle-click the character model to toggle stats.|n|nModel rotation controls will be hidden.  Buttons to toggle gear will be added to the dressup frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "EnhanceQuestLog"			, 	"Enhance quest log"				,	146, -152, 	true,	"If checked, you will be able to customise the quest log frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "EnhanceProfessions"		, 	"Enhance professions"			,	146, -172, 	true,	"If checked, the professions frame will be larger.")
	unitscanLC:MakeCB(unitscanLC[pg], "EnhanceTrainers"			, 	"Enhance trainers"				,	146, -192, 	true,	"If checked, the skill trainer frame will be larger and feature a train all skills button.")

	unitscanLC:MakeTx(unitscanLC[pg], "Extras"					, 	146, -232);
	unitscanLC:MakeCB(unitscanLC[pg], "ShowVolume"				, 	"Show volume slider"			, 	146, -252, 	true,	"If checked, a master volume slider will be shown in the character frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "AhExtras"					, 	"Show auction controls"			, 	146, -272, 	true,	"If checked, additional functionality will be added to the auction house.|n|nBuyout only - create buyout auctions without filling in the starting price.|n|nGold only - set the copper and silver prices at 99 to speed up new auctions.|n|nFind item - search the auction house for the item you are selling.|n|nIn addition, the auction duration setting will be saved account-wide.")

	unitscanLC:MakeTx(unitscanLC[pg], "Extras"					, 	340, -72);
	-- unitscanLC:MakeCB(unitscanLC[pg], "ShowCooldowns"				, 	"Show cooldowns"				, 	340, -92, 	true,	"If checked, you will be able to place up to five beneficial cooldown icons above the target frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "DurabilityStatus"			, 	"Show durability status"		, 	340, -112, 	true,	"If checked, a button will be added to the character frame which will show your equipped item durability when you hover the pointer over it.|n|nIn addition, an overall percentage will be shown in the chat frame when you die.")
	unitscanLC:MakeCB(unitscanLC[pg], "ShowVanityControls"		, 	"Show vanity controls"			, 	340, -132, 	true,	"If checked, helm and cloak toggle checkboxes will be shown in the character frame.|n|nYou can hold shift and right-click the checkboxes to switch layouts.")
	unitscanLC:MakeCB(unitscanLC[pg], "ShowBagSearchBox"			, 	"Show bag search box"			, 	340, -152, 	true,	"If checked, a bag search box will be shown in the backpack frame and the bank frame.")
	-- unitscanLC:MakeCB(unitscanLC[pg], "ShowRaidToggle"			, 	"Show raid button"				,	340, -172, 	true,	"If checked, the button to toggle the raid container frame will be shown just above the raid management frame (left side of the screen) instead of in the raid management frame itself.|n|nThis allows you to toggle the raid container frame without needing to open the raid management frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "ShowPlayerChain"			, 	"Show player chain"				,	340, -192, 	true,	"If checked, you will be able to show a rare, elite or rare elite chain around the player frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "ShowReadyTimer"			, 	"Show ready timer"				,	340, -212, 	true,	"If checked, a timer will be shown under the PvP encounter ready frame so that you know how long you have left to click the enter button.")
	unitscanLC:MakeCB(unitscanLC[pg], "ShowWowheadLinks"			, 	"Show Wowhead links"			, 	340, -232, 	true,	"If checked, Wowhead links will be shown in the world map frame and the achievements frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "ShowFlightTimes"			, 	"Show flight times"				, 	340, -252, 	true,	"If checked, flight times will be shown in the flight map and when you take a flight.")

	unitscanLC:CfgBtn("ModMinimapBtn", unitscanCB["MinimapModder"])
	unitscanLC:CfgBtn("MoveTooltipButton", unitscanCB["TipModEnable"])
	-- unitscanLC:CfgBtn("EnhanceDressupBtn", unitscanCB["EnhanceDressup"])
	unitscanLC:CfgBtn("EnhanceQuestLogBtn", unitscanCB["EnhanceQuestLog"])
	unitscanLC:CfgBtn("EnhanceTrainersBtn", unitscanCB["EnhanceTrainers"])
	-- unitscanLC:CfgBtn("CooldownsButton", unitscanCB["ShowCooldowns"])
	unitscanLC:CfgBtn("ModPlayerChain", unitscanCB["ShowPlayerChain"])
	unitscanLC:CfgBtn("ShowWowheadLinksBtn", unitscanCB["ShowWowheadLinks"])
	unitscanLC:CfgBtn("ShowFlightTimesBtn", unitscanCB["ShowFlightTimes"])

----------------------------------------------------------------------
-- 	LC6: Frames
----------------------------------------------------------------------

	pg = "Page6";

	unitscanLC:MakeTx(unitscanLC[pg], "Features"					, 	146, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "FrmEnabled"				,	"Manage frames"					, 	146, -92, 	true,	"If checked, you will be able to change the position and scale of the player frame and target frame.|n|nNote that enabling this option will prevent you from using the default UI to move the player and target frames.")
	unitscanLC:MakeCB(unitscanLC[pg], "ManageBuffs"				,	"Manage buffs"					, 	146, -112, 	true,	"If checked, you will be able to change the position and scale of the buffs frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "ManageWidget"				,	"Manage widget"					, 	146, -132, 	true,	"If checked, you will be able to change the position and scale of the widget frame.|n|nThe widget frame is commonly used for showing PvP scores and tracking objectives.")
	unitscanLC:MakeCB(unitscanLC[pg], "ManageFocus"				,	"Manage focus"					, 	146, -152, 	true,	"If checked, you will be able to change the position and scale of the focus frame.|n|nNote that enabling this option will prevent you from using the default UI to move the focus frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "ManageTimer"				,	"Manage timer"					, 	146, -172, 	true,	"If checked, you will be able to change the position and scale of the timer bar.|n|nThe timer bar is used for showing remaining breath when underwater as well as other things.")
	unitscanLC:MakeCB(unitscanLC[pg], "ManageDurability"			,	"Manage durability"				, 	146, -192, 	true,	"If checked, you will be able to change the position and scale of the armored man durability frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "ManageVehicle"				,	"Manage vehicle"				, 	146, -212, 	true,	"If checked, you will be able to change the position and scale of the vehicle seat indicator frame.")
	unitscanLC:MakeCB(unitscanLC[pg], "ClassColFrames"			, 	"Class colored frames"			,	146, -232, 	true,	"If checked, class coloring will be used in the player frame, target frame and focus frame.")

	unitscanLC:MakeTx(unitscanLC[pg], "Visibility"				, 	340, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "NoAlerts"					,	"Hide alerts"					, 	340, -92, 	true,	"If checked, alert frames will not be shown.|n|nWhen you earn an achievement, a message will be shown in chat instead.")
	unitscanLC:MakeCB(unitscanLC[pg], "NoGryphons"				,	"Hide gryphons"					, 	340, -112, 	true,	"If checked, the main bar gryphons will not be shown.")
	unitscanLC:MakeCB(unitscanLC[pg], "NoClassBar"				,	"Hide stance bar"				, 	340, -132, 	true,	"If checked, the stance bar will not be shown.")

	unitscanLC:CfgBtn("MoveFramesButton", unitscanCB["FrmEnabled"])
	unitscanLC:CfgBtn("ManageBuffsButton", unitscanCB["ManageBuffs"])
	unitscanLC:CfgBtn("ManageWidgetButton", unitscanCB["ManageWidget"])
	unitscanLC:CfgBtn("ManageFocusButton", unitscanCB["ManageFocus"])
	unitscanLC:CfgBtn("ManageTimerButton", unitscanCB["ManageTimer"])
	unitscanLC:CfgBtn("ManageDurabilityButton", unitscanCB["ManageDurability"])
	unitscanLC:CfgBtn("ManageVehicleButton", unitscanCB["ManageVehicle"])
	unitscanLC:CfgBtn("ClassColFramesBtn", unitscanCB["ClassColFrames"])

----------------------------------------------------------------------
-- 	LC7: System
----------------------------------------------------------------------

	pg = "Page7";

	unitscanLC:MakeTx(unitscanLC[pg], "Graphics and Sound"		, 	146, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "NoScreenGlow"				, 	"Disable screen glow"			, 	146, -92, 	false,	"If checked, the screen glow will be disabled.|n|nEnabling this option will also disable the drunken haze effect.")
	unitscanLC:MakeCB(unitscanLC[pg], "NoScreenEffects"			, 	"Disable screen effects"		, 	146, -112, 	false,	"If checked, the grey screen of death and the netherworld effect will be disabled.")
	unitscanLC:MakeCB(unitscanLC[pg], "SetWeatherDensity"			, 	"Set weather density"			, 	146, -132, 	false,	"If checked, you will be able to set the density of weather effects.")
	unitscanLC:MakeCB(unitscanLC[pg], "MaxCameraZoom"				, 	"Max camera zoom"				, 	146, -152, 	false,	"If checked, you will be able to zoom out to a greater distance.")
	unitscanLC:MakeCB(unitscanLC[pg], "ViewPortEnable"			,	"Enable viewport"				,	146, -172, 	true,	"If checked, you will be able to create a viewport.  A viewport adds adjustable black borders around the game world.|n|nThe borders are placed on top of the game world but under the UI so you can place UI elements over them.")
	unitscanLC:MakeCB(unitscanLC[pg], "NoRestedEmotes"			, 	"Silence rested emotes"			,	146, -192, 	true,	"If checked, emote sounds will be silenced while your character is resting or at the Grim Guzzler.|n|nEmote sounds will be enabled at all other times.")
	unitscanLC:MakeCB(unitscanLC[pg], "MuteGameSounds"			, 	"Mute game sounds"				,	146, -212, 	false,	"If checked, you will be able to mute a selection of game sounds.")
	unitscanLC:MakeCB(unitscanLC[pg], "MuteCustomSounds"			, 	"Mute custom sounds"			,	146, -232, 	false,	"If checked, you will be able to mute your own choice of sounds.")

	unitscanLC:MakeTx(unitscanLC[pg], "Game Options"				, 	340, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "NoBagAutomation"			, 	"Disable bag automation"		, 	340, -92, 	true,	"If checked, your bags will not be opened or closed automatically when you interact with a merchant, bank or mailbox.")
	unitscanLC:MakeCB(unitscanLC[pg], "CharAddonList"				, 	"Show character addons"			, 	340, -112, 	true,	"If checked, the addon list (accessible from the game menu) will show character based addons by default.")
	unitscanLC:MakeCB(unitscanLC[pg], "NoConfirmLoot"				, 	"Disable loot warnings"			,	340, -132, 	false,	"If checked, confirmations will no longer appear when you choose a loot roll option or attempt to sell or mail a tradable item.")
	unitscanLC:MakeCB(unitscanLC[pg], "FasterLooting"				, 	"Faster auto loot"				,	340, -152, 	true,	"If checked, the amount of time it takes to auto loot creatures will be significantly reduced.")
	unitscanLC:MakeCB(unitscanLC[pg], "FasterMovieSkip"			, 	"Faster movie skip"				,	340, -172, 	true,	"If checked, you will be able to cancel cinematics without being prompted for confirmation.")
	unitscanLC:MakeCB(unitscanLC[pg], "StandAndDismount"			, 	"Dismount me"					,	340, -192, 	true,	"If checked, you will be able to set some additional rules for when your character is automatically dismounted.")
	unitscanLC:MakeCB(unitscanLC[pg], "ShowVendorPrice"			, 	"Show vendor price"				,	340, -212, 	true,	"If checked, the vendor price will be shown in item tooltips.")
	unitscanLC:MakeCB(unitscanLC[pg], "CombatPlates"				, 	"Combat plates"					,	340, -232, 	true,	"If checked, enemy nameplates will be shown during combat and hidden when combat ends.")
	unitscanLC:MakeCB(unitscanLC[pg], "EasyItemDestroy"			, 	"Easy item destroy"				,	340, -252, 	true,	"If checked, you will no longer need to type delete when destroying a superior quality item.|n|nIn addition, item links will be shown in all item destroy confirmation windows.")

	unitscanLC:CfgBtn("SetWeatherDensityBtn", unitscanCB["SetWeatherDensity"])
	unitscanLC:CfgBtn("ModViewportBtn", unitscanCB["ViewPortEnable"])
	unitscanLC:CfgBtn("MuteGameSoundsBtn", unitscanCB["MuteGameSounds"])
	unitscanLC:CfgBtn("MuteCustomSoundsBtn", unitscanCB["MuteCustomSounds"])
	unitscanLC:CfgBtn("DismountBtn", unitscanCB["StandAndDismount"])

----------------------------------------------------------------------
-- 	LC8: Settings
----------------------------------------------------------------------

	pg = "Page8";

	unitscanLC:MakeTx(unitscanLC[pg], "Addon"						, 146, -72);
	unitscanLC:MakeCB(unitscanLC[pg], "ShowMinimapIcon"			, "Show minimap button"				, 146, -92,		false,	"If checked, a minimap button will be available.|n|nClick - Toggle options panel.|n|nSHIFT-click - Toggle music.|n|nALT-click - Toggle errors (if enabled).|n|nCTRL/SHIFT-click - Toggle Zygor (if installed).|n|nCTRL/ALT-click - Toggle windowed mode.")

	unitscanLC:MakeTx(unitscanLC[pg], "Scale", 340, -72);
	unitscanLC:MakeSL(unitscanLC[pg], "PlusPanelScale", "Drag to set the scale of the Leatrix Plus panel.", 1, 2, 0.1, 340, -92, "%.1f")

	unitscanLC:MakeTx(unitscanLC[pg], "Transparency", 340, -132);
	unitscanLC:MakeSL(unitscanLC[pg], "PlusPanelAlpha", "Drag to set the transparency of the Leatrix Plus panel.", 0, 1, 0.1, 340, -152, "%.1f")



--------------------------------------------------------------------------------
-- Play sound if wasn't played recently.
--------------------------------------------------------------------------------


	do
		local last_played
		
		function unitscan.play_sound()
			if not last_played or GetTime() - last_played > 3 then
				PlaySoundFile([[Interface\AddOns\unitscan\assets\Event_wardrum_ogre.ogg]], 'Sound')
				PlaySoundFile([[Sound\Interface\MapPing.wav]], 'Sound')
				last_played = GetTime()
			end
		end
	end


--------------------------------------------------------------------------------
-- Main function to scan for targets.
--------------------------------------------------------------------------------


	function unitscan.target(name)
		forbidden = false
		TargetUnit(name)
		-- unitscan.print(tostring(UnitHealth(name)) .. " " .. name)
		-- if not deadscan and UnitIsCorpse(name) then
		-- 	return
		-- end
		if forbidden then
			if not found[name] then
				found[name] = true
				--FlashClientIcon()
				unitscan.play_sound()
				unitscan.flash.animation:Play()
				unitscan.discovered_unit = name
				if InCombatLockdown() then
					print("|cFF00FF00unitscan found - |r |cffffff00" .. name .. "|r")
				end
			end
		else
			found[name] = false
		end
	end


--------------------------------------------------------------------------------
-- Functions that creates button, and other visuals during alert.
--------------------------------------------------------------------------------


	function unitscan.LOAD()
		UIParent:UnregisterEvent'ADDON_ACTION_FORBIDDEN'
		do
			local flash = CreateFrame'Frame'
			unitscan.flash = flash
			flash:Show()
			flash:SetAllPoints()
			flash:SetAlpha(0)
			flash:SetFrameStrata'LOW'
			SetCVar("Sound_EnableErrorSpeech", 0)
			
			local texture = flash:CreateTexture()
			texture:SetBlendMode'ADD'
			texture:SetAllPoints()
			texture:SetTexture[[Interface\FullScreenTextures\LowHealth]]

			flash.animation = CreateFrame'Frame'
			flash.animation:Hide()
			flash.animation:SetScript('OnUpdate', function(self)
				local t = GetTime() - self.t0
				if t <= .5 then
					flash:SetAlpha(t * 2)
				elseif t <= 1 then
					flash:SetAlpha(1)
				elseif t <= 1.5 then
					flash:SetAlpha(1 - (t - 1) * 2)
				else
					flash:SetAlpha(0)
					self.loops = self.loops - 1
					if self.loops == 0 then
						self.t0 = nil
						self:Hide()
					else
						self.t0 = GetTime()
					end
				end
			end)
			function flash.animation:Play()
				if self.t0 then
					self.loops = 2
				else
					self.t0 = GetTime()
					self.loops = 1
				end
				self:Show()
			end
		end
		
		local button = CreateFrame('Button', 'unitscan_button', UIParent, 'SecureActionButtonTemplate')
		-- first code to set left and right click of button
		button:SetAttribute("type1", "macro")
		button:SetAttribute("type2", "macro")
		-- rest of button code
		button:Hide()
		unitscan.button = button
		button:SetPoint('BOTTOM', UIParent, 0, 128)
		button:SetWidth(150)
		button:SetHeight(42)
		button:SetScale(1.25)
		button:SetMovable(true)
		button:SetUserPlaced(true)
		button:SetClampedToScreen(true)

		-- code to enable ctrl-click to move (it has nothing to do with left and right click function)
		button:SetScript('OnMouseDown', function(self)
		    if IsControlKeyDown() then
		        self:RegisterForClicks("AnyDown", "AnyUp")
		        self:StartMoving()
		    end
		end)
		button:SetScript('OnMouseUp', function(self)
		    self:StopMovingOrSizing()
		    self:RegisterForClicks("AnyDown", "AnyUp")
		end) 

		button:SetFrameStrata'LOW'
		button:SetNormalTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Parchment-Horizontal]]
		
		if isWOTLK or isTBC then
			button:SetBackdrop{
				tile = true,
				edgeSize = 16,
				edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
			}
			button:SetBackdropBorderColor(unpack(BROWN))
			button:SetScript('OnEnter', function(self)
				self:SetBackdropBorderColor(unpack(YELLOW))
			end)
			button:SetScript('OnLeave', function(self)
				self:SetBackdropBorderColor(unpack(BROWN))
			end)
		end

		function button:set_target(name)
			-- string that adds name text to the button
			self:SetText(name)
			-- second code to set left and right click of button macro texts
			self:SetAttribute("macrotext1", "/cleartarget\n/targetexact " .. name)
			self:SetAttribute("macrotext2", "/click unitscan_close") -- this is made to click "close" button code for which is defined below
			-- rest of code
			self:Show()
			self.glow.animation:Play()
			self.shine.animation:Play()
		end
		
		do
			local background = button:GetNormalTexture()
			background:SetDrawLayer'BACKGROUND'
			background:ClearAllPoints()
			background:SetPoint('BOTTOMLEFT', 3, 3)
			background:SetPoint('TOPRIGHT', -3, -3)
			background:SetTexCoord(0, 1, 0, .25)
		end
		
		do
			local title_background = button:CreateTexture(nil, 'BORDER')
			title_background:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Title]]
			title_background:SetPoint('TOPRIGHT', -5, -5)
			title_background:SetPoint('LEFT', 5, 0)
			title_background:SetHeight(18)
			title_background:SetTexCoord(0, .9765625, 0, .3125)
			title_background:SetAlpha(.8)


			--===== Create Title (UNIT name) =====--
			local title = button:CreateFontString(nil, 'OVERLAY')
			title:SetFont(GameFontNormal:GetFont(), 14, 'OUTLINE')
			--title:SetWordWrap(false)

			--===== Fix for UNIT name in Chinese, should i add zhTW? =====--
			-- if currentLocale == "zhCN" and isWOTLK then
			-- 	title:SetFont([[Fonts\ZYHei.ttf]], 14)
			-- else	
			-- 	title:SetFont([[Fonts\FRIZQT__.TTF]], 14)
			-- end

			title:SetShadowOffset(1, -1)
			title:SetPoint('TOPLEFT', title_background, 0, 0)
			title:SetPoint('RIGHT', title_background)
			button:SetFontString(title)

			local subtitle = button:CreateFontString(nil, 'OVERLAY')
			subtitle:SetFont([[Fonts\FRIZQT__.TTF]], 14)
			subtitle:SetTextColor(0, 0, 0)
			subtitle:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -4)
			subtitle:SetPoint('RIGHT', title)
			subtitle:SetText'Unit Found!'
		end
		
		do
			local model = CreateFrame('PlayerModel', nil, button)
			button.model = model
			model:SetPoint('BOTTOMLEFT', button, 'TOPLEFT', 0, -4)
			model:SetPoint('RIGHT', 0, 0)
			model:SetHeight(button:GetWidth() * .6)
		end
		
		do
			local close = CreateFrame('Button', "unitscan_close", button, 'UIPanelCloseButton')
			close:SetPoint('BOTTOMRIGHT', 5, -5)
			close:SetWidth(32)
			close:SetHeight(32)
			close:SetScale(.8)
			close:SetHitRectInsets(8, 8, 8, 8)
		end
		
		do
			local glow = button.model:CreateTexture(nil, 'OVERLAY')
			button.glow = glow
			glow:SetPoint('CENTER', button, 'CENTER')
			glow:SetWidth(400 / 300 * button:GetWidth())
			glow:SetHeight(171 / 70 * button:GetHeight())
			glow:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Alert-Glow]]
			glow:SetBlendMode'ADD'
			glow:SetTexCoord(0, .78125, 0, .66796875)
			glow:SetAlpha(0)

			glow.animation = CreateFrame'Frame'
			glow.animation:Hide()
			glow.animation:SetScript('OnUpdate', function(self)
				local t = GetTime() - self.t0
				if t <= .2 then
					glow:SetAlpha(t * 5)
				elseif t <= .7 then
					glow:SetAlpha(1 - (t - .2) * 2)
				else
					glow:SetAlpha(0)
					self:Hide()
				end
			end)
			function glow.animation:Play()
				self.t0 = GetTime()
				self:Show()
			end
		end

		do
			local shine = button:CreateTexture(nil, 'ARTWORK')
			button.shine = shine
			shine:SetPoint('TOPLEFT', button, 0, 8)
			shine:SetWidth(67 / 300 * button:GetWidth())
			shine:SetHeight(1.28 * button:GetHeight())
			shine:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Alert-Glow]]
			shine:SetBlendMode'ADD'
			shine:SetTexCoord(.78125, .912109375, 0, .28125)
			shine:SetAlpha(0)
			
			shine.animation = CreateFrame'Frame'
			shine.animation:Hide()
			shine.animation:SetScript('OnUpdate', function(self)
				local t = GetTime() - self.t0
				if t <= .3 then
					shine:SetPoint('TOPLEFT', button, 0, 8)
				elseif t <= .7 then
					shine:SetPoint('TOPLEFT', button, (t - .3) * 2.5 * self.distance, 8)
				end
				if t <= .3 then
					shine:SetAlpha(0)
				elseif t <= .5 then
					shine:SetAlpha(1)
				elseif t <= .7 then
					shine:SetAlpha(1 - (t - .5) * 5)
				else
					shine:SetAlpha(0)
					self:Hide()
				end
			end)
			function shine.animation:Play()
				self.t0 = GetTime()
				self.distance = button:GetWidth() - shine:GetWidth() + 8
				self:Show()
				button:SetAlpha(1)
			end
		end
	end


--------------------------------------------------------------------------------
-- Function to scan for units with conditions. 
--------------------------------------------------------------------------------


	do
		unitscan.last_check = GetTime()
		function unitscan.UPDATE()
			if is_resting then return end
			if not InCombatLockdown() and unitscan.discovered_unit then
				unitscan.button:set_target(unitscan.discovered_unit)
				unitscan.discovered_unit = nil
			end
			if GetTime() - unitscan.last_check >= unitscan_defaults.CHECK_INTERVAL then
				unitscan.last_check = GetTime()
				for name in pairs(unitscan_targets) do
					unitscan.target(name)
				end
				for _, name in pairs(nearby_targets) do
					unitscan.target(name)
				end
			end
		end
	end


--------------------------------------------------------------------------------
-- Prints to add prefix to message and color text.
--------------------------------------------------------------------------------


	function unitscan.print(msg)
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00/unitscan|r " .. "|cffffff9a" .. msg .. "|r")
		end
	end


	function unitscan.ignoreprint(msg)
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00/unitscan ignore|r " .. "|cffff0000" .. msg .. "|r")
		end
	end

--------------------------------------------------------------------------------
-- Function for sorting targets alphabetically. For user QOL.
--------------------------------------------------------------------------------


	function unitscan.sorted_targets()
		local sorted_targets = {}
		for key in pairs(unitscan_targets) do
			tinsert(sorted_targets, key)
		end
		sort(sorted_targets, function(key1, key2) return key1 < key2 end)
		return sorted_targets
	end


--------------------------------------------------------------------------------
-- Function to add current target to the scanning list.
--------------------------------------------------------------------------------


	function unitscan.toggle_target(name)
		local key = strupper(name)
		if unitscan_targets[key] then
			unitscan_targets[key] = nil
			found[key] = nil
			unitscan.print('- ' .. key)
		elseif key ~= '' then
			unitscan_targets[key] = true
			unitscan.print('+ ' .. key)
		end
	end


--------------------------------------------------------------------------------
-- Slash Commands /unitscan
--------------------------------------------------------------------------------

	-- Slash command function
	function unitscanLC:SlashFunc(parameter)
		--SlashCmdList["UNITSCAN"] = function(parameter)
		local _, _, command, args = string.find(parameter, '^(%S+)%s*(.*)$')
		
		--===== Slash to put current player target to the unit scanning list. =====--	
		if command == "target" then
			local targetName = UnitName("target")
			if targetName then
				local key = strupper(targetName)
				if not unitscan_targets[key] then
					unitscan_targets[key] = true
					unitscan.print("+ " .. key)
				else
					unitscan_targets[key] = nil
					unitscan.print("- " .. key)
					found[key] = nil
				end
			else
				unitscan.print("No target selected.")
			end

		--===== Slash to change unit scanning interval. Default is 0.3 =====--	
		elseif command == "interval" then
			local newInterval = tonumber(args)
			if newInterval then
				unitscan_defaults.CHECK_INTERVAL = newInterval
				unitscan.print("Check interval set to " .. newInterval)
			else
				unitscan.print("Invalid interval value. Usage: /unitscan interval <number>")
			end

		--===== Slash Ignore Rare =====--	
		elseif command == "ignore" then
			unitscan_LoadRareSpawns()
			if args == "" then
				-- print list of ignored NPCs
				if next(unitscan_ignored) == nil then
					print(" ")
				unitscan.ignoreprint("list is empty.")
				else
				print("|cffff0000" .. " Ignore list " .. "|r"  .. "currently contains:")
				for rare in pairs(unitscan_ignored) do
					unitscan.ignoreprint(rare)
				end
			end

				return
			else

		        local rare = string.upper(args)
		        if rare_spawns[rare] == nil then
		            -- rare does not exist in rare_spawns table
		            unitscan.print("|cffffff00" .. args .. "|r" .. " is not a valid rare spawn.")

		            return
		    end

			if unitscan_ignored[rare] then
				-- remove rare from ignore list
				unitscan_ignored[rare] = nil
				unitscan.ignoreprint("- " .. rare)
				unitscan.refresh_nearby_targets()
				found[rare] = nil
			else
				-- add rare to ignore list
				unitscan_ignored[rare] = true
				unitscan.ignoreprint("+ " .. rare)
				unitscan.refresh_nearby_targets()
			end

			return
			end


		--===== Slash to avoid people confusion if they do /unitscan name =====--	
		elseif command == "name" then
			print(" ")
			unitscan.print("replace |cffffff00'name'|r with npc you want to scan.")
			print(" - for example: |cFF00FF00/unitscan|r |cffffff00Hogger|r")

		--===== Slash to only print currently tracked non-rare targets. =====--	
		elseif command == "targets" then
			if unitscan_targets then
				for k, v in pairs(unitscan_targets) do
					unitscan.print(tostring(k))
				end
			end

		--===== Slash to show rare spawns that are currently being scanned. =====--	
		elseif command == "nearby" then
			print(" ")
			unitscan.print("Is someone missing?")
							print(" - Add it to your list with |cFF00FF00/unitscan|r |cffffff00name|r")
					unitscan.print("|cffff0000ignore|r")
					print(" - Adds/removes the rare mob 'name' from the unit scanner |cffff0000ignore list.|r")
					print(" ")
			for key,val in pairs(nearby_targets) do
				if not (val == "Lumbering Horror" or val == "Spirit of the Damned" or val == "Bone Witch") then
					unitscan.print(val)
				end
			end

		--===== Slash to show all avaliable commands =====--	
		elseif command == 'help' then

			print(" ")
			print("|cfff0d440Available commands:|r")

			unitscan.print("target")
			print(" - Adds/removes the name of your |cffffff00current target|r to the scanner.")
			-- print(" ")
			unitscan.print("name")
			print(" - Adds/removes the |cffffff00mob/player 'name'|r from the unit scanner.")
			-- print(" ")
			unitscan.print("nearby")
			print(" - List of |cffffff00rare mob names|r that are being scanned in your current zone.")
			unitscan.print("|cffff0000ignore|r")
					print(" - Adds/removes the rare mob 'name' from the unit scanner |cffff0000ignore list.|r")


		--===== Slash without any arguments (/untiscan) prints currently tracked user-defined units and some basic available slash commands  =====--
		--===== If an agrugment after /unitscan is given, it will add a unit to the scanning targets. =====--
		elseif not command then
			print(" ")
			unitscan.print("|cffffff00help|r")
			print(" - Displays available unitscan |cffffff00commands|r")
			print(" ")
			if unitscan_targets then
				if next(unitscan_targets) == nil then
					unitscan.print("Unit Scanner is currently empty.")
				else
					print(" |cffffff00Unit Scanner|r currently contains:")
					for k, v in pairs(unitscan_targets) do
						unitscan.print(tostring(k))
					end
				end
			end
		else
			unitscan.toggle_target(parameter)
		end
	end

	-- Slash command for global function
	_G.SLASH_UNITSCAN1 = "/unitscan"
	_G.SLASH_UNITSCAN2 = "/uns"


	SlashCmdList["UNITSCAN"] = function(self)
		-- Run slash command function
		unitscanLC:SlashFunc(self)
		-- Redirect tainted variables
		RunScript('ACTIVE_CHAT_EDIT_BOX = ACTIVE_CHAT_EDIT_BOX')
		RunScript('LAST_ACTIVE_CHAT_EDIT_BOX = LAST_ACTIVE_CHAT_EDIT_BOX')
	end

	--SlashCmdList["UNS"] = function(self)
	--	-- Run slash command function
	--	unitscanLC:SlashFunc(self)
	--	-- Redirect tainted variables
	--	RunScript('ACTIVE_CHAT_EDIT_BOX = ACTIVE_CHAT_EDIT_BOX')
	--	RunScript('LAST_ACTIVE_CHAT_EDIT_BOX = LAST_ACTIVE_CHAT_EDIT_BOX')
	--end




