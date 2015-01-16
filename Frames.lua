--[[-----------------------------------------------------------
	oUF_Kygo
	PvE oriented oUF layout.
	See LICENSE for more info.
	
---------------------------------------------------------------]]
	local addonName, ns = ...
	local cfg = ns.cfg 
	local tags = ns.tags
	local Colors = ns.Colors
	local color = PowerBarColor[powerType]
	local powerType = UnitPowerType("player")
	local color = oUF.colors.power[powerType]
	local _, playerClass = UnitClass("player")

ns.headers = {}
------------------------------------------------------------------------

-- Configurable stuff starts here
local BUFF_HEIGHT = 17
local BUFF_SPACING = 0.2
local MAX_NUM_BUFFS = 10

local auraElement = {
	player = "Buffs",
	target = "Debuffs",
}

local auraFilter = {
	player = function(element, unit, icon, name, rank, texture, count, debuffType, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
		local ok = duration and duration > 0 and duration < 330
		--print(unit, ok and "|cff7fff7fPASS|r" or "|cffff7f7fFAIL|r", name, duration)
		return ok
	end,
	target = function(element, unit, icon, name, rank, texture, count, debuffType, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
		local ok = duration and duration > 0 and duration < 330 and caster
		--print(unit, ok and "|cff7fff7fPASS|r" or "|cffff7f7fFAIL|r", name, canApplyAura, caster)
		return ok
	end
}

-- End of configurable stuff
------------------------------------------------------------------------

local function auras_PostCreateIcon(element, icon)
	local frame = element.__owner
	--print("PostCreateIcon", frame.unit)
	local BAR_TEXTURE = frame.Health and frame.Health:GetStatusBarTexture():GetTexture() or "Interface\\TargetingFrame\\UI-StatusBar"

	-- Create the status bar:
	local bar = CreateFrame("StatusBar", nil, icon)
	bar:SetPoint("LEFT", icon, "RIGHT")
	bar:SetWidth(frame:GetWidth() - BUFF_HEIGHT)
	bar:SetHeight(BUFF_HEIGHT)
	bar:SetStatusBarTexture(cfg.texture)
	bar:SetStatusBarColor(79/255, 79/255, 79/255)
	-- Add a background texture:
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(true)
	bg:SetTexture(cfg.texture)
	bg:SetAlpha(1)
	bar.bg = bg

	-- Add a fonstring to display the remaining time:
	local time = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall", "MONOCHROMEOUTLINE")
	time:SetPoint("RIGHT", -4, 0)
	time:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	bar.time = time

	-- Move the count fontstring from the icon to the bar:
	icon.count:ClearAllPoints()
	icon.count:SetParent(bar)
	icon.count:SetPoint("LEFT", 4, 0)
	icon.count:SetWidth(15)
	icon.count:SetFontObject(GameFontHighlightSmall)
	icon.count:SetJustifyH("RIGHT")

	-- Add a fontstring to display the name:
	local name = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall", "MONOCHROMEOUTLINE")
	name:SetPoint("LEFT", 4 + 15 + 8, 0)
	-- ^ This can't be anchored to RIGHT of icon.count because oUF sets the
	-- count text to nil, resulting in 0 width, and anchoring something to a
	-- 0-width object results in it being hidden since WoW 6.0
	name:SetPoint("RIGHT", time, "LEFT", -4, 0)
	name:SetJustifyH("LEFT")
	name:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	bar.name = name

	-- Trim the icon borders:
	icon.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	-- Attach the bar to the icon for future access:
	icon.bar = bar
end

local function aurabar_OnUpdate(bar, elapsed)
	local t = bar.timeLeft - elapsed
	bar:SetValue(t > 0 and t or 0)
	bar.time:SetFormattedText(SecondsToTimeAbbrev(t))
	bar.timeLeft = t
end

local function auras_PostUpdateIcon(element, unit, icon, index, offset)
	local bar = icon.bar
	local name, _, _, count, debuffType, duration, expirationTime = UnitAura(unit, index, icon.filter)
	--print("PostUpdateIcon", name, duration)
	bar.name:SetText(name)
	bar.bg:SetVertexColor(26/255, 26/255, 26/255)
	bar.bg:SetAlpha(0.9)
	--[[
	if icon.filter == "HARMFUL" then
		-- Color debuffs by type:
		local color = DebuffTypeColor[debuffType or "none"]
		bar:SetStatusBarColor(color.r * 0.6, color.g * 0.6, color.b * 0.6)
		bar.bg:SetVertexColor(color.r * 0.2, color.g * 0.2, color.b * 0.2)
	elseif UnitIsPlayer(unit) then
		-- Color buffs on players by class:
		local _, class = UnitClass(unit)
		local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
		bar:SetStatusBarColor(color.r * 0.6, color.g * 0.6, color.b * 0.6)
		bar.bg:SetVertexColor(color.r * 0.2, color.g * 0.2, color.b * 0.2)
	else
		-- Color buffs on NPCs green:
		bar:SetStatusBarColor(0, 0.6, 0)
	end
	--]]
	if duration > 0 then
		bar.timeLeft = expirationTime - GetTime()
		bar:SetMinMaxValues(0, duration)
		bar:SetScript("OnUpdate", aurabar_OnUpdate)
	else
		bar:SetScript("OnUpdate", nil)
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(1)
		bar.time:SetText("") -- Set to "" instead of nil to avoid issues with anchoring to 0-width objects
	end
end

local function AddAuraElement(frame, unit, isSingle)
	local auraElementForUnit = auraElement[unit]
	if auraElementForUnit then
		-- Create the element:
		local Auras = CreateFrame("Frame", nil, frame)
		Auras:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 20)
		Auras:SetWidth(BUFF_HEIGHT + BUFF_SPACING)
		Auras:SetHeight(1)

		-- Layout options:
		Auras["initialAnchor"] = "BOTTOMLEFT"
		Auras["growth-y"] = "UP"
		Auras["spacing-y"] = BUFF_SPACING
		Auras["num"] = MAX_NUM_BUFFS
		Auras["size"] = BUFF_HEIGHT

		-- Other options:
		Auras.disableCooldown = true

		-- Callbacks:
		Auras.PostCreateIcon = auras_PostCreateIcon
		Auras.PostUpdateIcon = auras_PostUpdateIcon
		Auras.CustomFilter = auraFilter[unit]

		-- Register it for oUF:
		frame[auraElementForUnit] = Auras
	end
end




local function Portrait_PostUpdate(portrait, unit)
	portrait:SetCamera(0)
end




local function Style(frame, unit, isSingle)

	frame:SetSize(305, 54)
	
	frame:RegisterForClicks("AnyUp")

	frame:SetScript("OnEnter", UnitFrame_OnEnter)
	frame:SetScript("OnLeave", UnitFrame_OnLeave)


	-----------------------------------
	--  Frame background and border  --
	-----------------------------------
	
	frame:SetBackdrop({
			bgFile = cfg.bgFile, tile = false,
            edgeFile = cfg.edgeFile, edgeSize = 10,
            insets = { left = 2, right = 2 , top = 2, bottom = 2 }
    })
	frame:SetBackdropColor(26/255, 26/255, 26/255, 0.6)
    frame:SetBackdropBorderColor(26/255, 26/255, 26/255, 0.6)
    
		
	-----------------------------------
	-- 			 Health bar	    	 --
	-----------------------------------
	local health = CreateFrame("StatusBar", nil, frame)
	health:SetPoint("TOPLEFT", frame, 5, -5)
	health:SetPoint("TOPRIGHT", frame, -5, 5)
	health:SetHeight(40)
	

	
	-- Health bar background
	local healthBG = health:CreateTexture(nil, "BACKGROUND")
	healthBG:SetAllPoints()
	healthBG:SetTexture(cfg.texture)	
	health.bg = healthBG	
	
	
	-- Health bar colors
	health:SetStatusBarTexture(cfg.texture)
	health:SetStatusBarColor(79/255, 79/255, 79/255) -- R G B Foreground color
	healthBG:SetVertexColor(0.5, 0.2, 0.2) -- R G B Background color
--	health.colorTapping = true
	health.frequentUpdates = true
	
	
	--Health bar text
	local healthText = health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if unit == "player" then
	healthText:SetPoint("LEFT", health, "LEFT", 5, 0)
	elseif unit == "targettarget" then
	else
	healthText:SetPoint("RIGHT", health, "RIGHT", -5, 0)
	
	end
	healthText:SetTextColor(1, 1, 1, 1)
	healthText:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	frame:Tag(healthText, "[status][raidcolor][shorthp]/[perhp]")
	

	frame.Health = health
	
	-----------------------------------
	-- 			 Power bar	    	 --
	-----------------------------------
	local power = CreateFrame("StatusBar", nil, frame)
	power:SetPoint("TOPLEFT", health, "BOTTOMLEFT")
	power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT")
	power:SetPoint("BOTTOM", frame, 0, 2)
	
	
	--Power background
	local powerBG = power:CreateTexture(nil, "BACKGROUND")
	powerBG:SetAllPoints()
	powerBG:SetTexture(cfg.texture)
	power:SetStatusBarTexture(cfg.texture)
	powerBG.multiplier = 0.3
	power.bg = powerBG
	
	
	--Power Text
	local powerText = health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if unit == "player" then
	powerText:SetPoint("RIGHT", health, "RIGHT", -5, 0)
	elseif unit == "target" then
	powerText:SetPoint("LEFT", health, "LEFT", 5, 0)	
	end

	powerText:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	powerText:SetTextColor(powerType)
	
	frame:Tag(powerText, "[shortpp]")
	power.colorPower = true	
	frame.Power = power
	

	---------------------------------
	--		      Name text    	   --
	---------------------------------
	if unit == "player" or unit == "pet"  then
	
	else 
	local name = health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	name:SetPoint("CENTER", frame, 0, 0)
	if unit == "targettarget" then
	name:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	else
	name:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	end
	name:SetTextColor(1, 1, 1, 1)
	frame:Tag(name, "[raidcolor][shortname]")
	end
	
	---------------------------------
	--Level and classification text--
	---------------------------------
	if unit == "target" then
	local level = health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	level:SetPoint("LEFT", frame, 70, 0)
	level:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	level:SetTextColor(1, 1, 1, 1)
	frame:Tag(level, "[smartlevel][shortclassification]")
	end
	--------------------------------
	--			   Misc           --
	--------------------------------
	local resting = health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	resting:SetPoint("TOPLEFT", frame)
	resting:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	frame:Tag(resting, "[rsicon]")
	
	local master = health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	master:SetPoint("TOPLEFT", frame, "TOPRIGHT", -15, 0)
	master:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	frame:Tag(master, "[mastericon]")
--[[	
	local combaticon = health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	combaticon:SetPoint("TOPLEFT", frame)
	combaticon:SetFont(TFONT, 10)
	frame:Tag(combaticon, "[combaticon]")
--]]	
	local readycheckicon = health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	readycheckicon:SetPoint("CENTER", frame)
	readycheckicon:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	frame:Tag(readycheckicon, "[readycheckicon]")
	
	local leadericon = health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	leadericon:SetPoint("TOPLEFT", frame)
	leadericon:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	frame:Tag(leadericon, "[leadericon]")
	
	local LFDRole = health:CreateTexture(nil, "OVERLAY")
	LFDRole:SetSize(16, 16)
	LFDRole:SetPoint("BOTTOMLEFT", health)
    LFDRole:SetTexture[[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]]
	frame.LFDRole = LFDRole

	local ReadyCheck = health:CreateTexture(nil, 'OVERLAY')
	ReadyCheck:SetSize(24, 24)
	ReadyCheck:SetPoint("TOP", health)
	ReadyCheck.finishedTime = 7
	ReadyCheck.fadeTime = 3
	frame.ReadyCheck = ReadyCheck

	local RaidIcon = health:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(16, 16)
	RaidIcon:SetPoint("CENTER", health)
	frame.RaidIcon = RaidIcon
	
	--------------------------------
	--			Portrait		  --
	--------------------------------
	if unit == "player" or unit == "target" then
		local portrait = CreateFrame("PlayerModel", nil, frame)
		portrait:SetWidth(50)
		portrait:SetAlpha(1)
		if unit == "player" then
			portrait:SetPoint("TOPRIGHT", frame, "TOPLEFT")
			portrait:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT")
		else
			portrait:SetPoint("TOPLEFT", frame, "TOPRIGHT")
			portrait:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT")
		end
	
	frame.Portrait = portrait
	end
	
	if unit == "player" or unit == "target" then
		local portraitBG = frame:CreateTexture(nil, "BACKGROUND")
		portraitBG:SetWidth(50)
		portraitBG:SetTexture(.1, .1, .1)
		portraitBG:SetAlpha(1)
		if unit == "player" then
			portraitBG:SetPoint("TOPRIGHT", frame, "TOPLEFT")
			portraitBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT")
		else
			portraitBG:SetPoint("TOPLEFT", frame, "TOPRIGHT")
			portraitBG:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT")
	end
	frame.portraitBG = portraitBG
	end
	
	------------------
	--	Aurabars	--
	------------------
	AddAuraElement(frame, unit, isSingle)

	---------------------------------	
	--		  Combo Points		   --
	---------------------------------
    if unit == "target" and playerClass == "ROGUE"  then
			local CPoints = {}
 
            for index = 1, MAX_COMBO_POINTS do
					local CPoint = health:CreateTexture(nil, "OVERLAY")
					-- Position and size of the combo point.
					CPoint:SetSize(10, 10)
					CPoint:SetPoint("LEFT", health, "LEFT", index * CPoint:GetWidth(), 0, 20)
					CPoint:SetTexture("Interface\\AddOns\\oUF_Kygo\\Media\\OrbFG")
					CPoint:SetVertexColor(1, 0, 0)
					CPoints[index] = CPoint
			end
 
			frame.CPoints = CPoints
					
    end
	----------------------------------------------
	--	Shards, Holy Power, Chi, Shadow Orbs	--
	----------------------------------------------

	
	local CIf = CreateFrame("Frame", nil, frame)
	CIf:SetSize(210, 32)
	
		local ClassIcons = {}
		for index = 1, 5 do
			local Icon = health:CreateTexture(nil, "OVERLAY")
			--Icon:SetSize(16, 16)  --Just here so I can see the default values
			--Icon:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", index * Icon:GetWidth(), 0, 20) --Just here so I can see the default values
					
			Icon:SetTexture("Interface\\AddOns\\oUF_Kygo\\Media\\Neal_border")
			ClassIcons[index] = Icon
				if unit == "player" and playerClass == "WARLOCK" then
				CIf:SetPoint("TOPLEFT", frame, -0, -0)
				Icon:SetSize(53, 15)
				Icon:SetPoint("TOPLEFT", frame, "TOPLEFT", index * Icon:GetWidth(), 10, 0)
				
				elseif unit == "player" and playerClass == "MONK" then
				CIf:SetPoint("TOPLEFT", frame, -0, -0)
				Icon:SetSize(53, 15)
				Icon:SetPoint("TOPLEFT", frame, "TOPLEFT", index * Icon:GetWidth(), 0, 20)
				
				elseif unit == "player" and playerClass == "PALADIN" then
				CIf:SetPoint("TOPLEFT", frame, -0, -0)
				Icon:SetSize(53, 15)
				Icon:SetPoint("TOPLEFT", frame, "TOPLEFT", index * Icon:GetWidth(), 0, 20)
				
				elseif unit == "player" and playerClass == "PRIEST" then
				CIf:SetPoint("TOPLEFT", frame, -0, -0)
				Icon:SetSize(53, 15)
				Icon:SetPoint("TOPLEFT", frame, "TOPLEFT", index * Icon:GetWidth(), 0, 20)
				end
		end


		frame.ClassIcons = ClassIcons
	

	-------------------------------
	-- 		Burning Embers		 --
	-------------------------------
	if unit == "player" and playerClass == "WARLOCK" then
	local BEf = CreateFrame("Frame", nil, frame)
	BEf:SetPoint("BOTTOM", health, -0, -8)
	BEf:SetSize(210, 15)
	
		local BurningEmbers = {}
			for index = 1, 4 do
		
			local BurningEmber = CreateFrame("StatusBar", nil, BEf)
			BurningEmber:SetSize(210 / 6, 15)
			BurningEmber:SetPoint("TOPLEFT", BEf, "BOTTOMLEFT", index * 210 / 6, 1)
			BurningEmber:SetStatusBarTexture("Interface\\AddOns\\oUF_Kygo\\Media\\NCPoint")
			BurningEmber:SetStatusBarColor(0, 1, 1) 
			BurningEmbers[index] = BurningEmber
			end
   
		frame.BurningEmbers = BurningEmbers
	end
	
	-----------------------------
	-- 		Eclipse Bar		   --
	-----------------------------
	
	if unit == "player" and playerClass == "DRUID" then
	
		local EclipseBar = CreateFrame("Frame", nil, frame)
		EclipseBar:SetPoint("BOTTOM", health)
		EclipseBar:SetSize(270, 15)
		
		local SolarBar = CreateFrame("StatusBar", nil, EclipseBar)
		SolarBar:SetPoint("TOP", health, 0, 22)
		SolarBar:SetStatusBarTexture("Interface\\AddOns\\oUF_Kygo\\Media\\Minimalist")
		SolarBar:SetStatusBarColor(0, 191, 255)
		SolarBar:SetReverseFill(1)
		SolarBar:SetSize(260, 22)
		
		local LunarBar = CreateFrame("StatusBar", nil, EclipseBar)
		LunarBar:SetPoint("TOP", health, 0, 22)
		LunarBar:SetSize(260, 22)
		LunarBar:SetStatusBarTexture("Interface\\AddOns\\oUF_Kygo\\Media\\Minimalist")
		LunarBar:SetStatusBarColor(255, 255, 0)
   
		EclipseBar.LunarBar = LunarBar
		EclipseBar.SolarBar = SolarBar
		frame.EclipseBar = EclipseBar
   
		local spark = SolarBar:CreateTexture(nil, "OVERLAY")
		spark:SetSize(5, 10)
		spark:SetPoint("LEFT", SolarBar)
		spark:SetTexture("Interface\\PlayerFrame\\Direction_Eclipse")
		
		frame.spark = spark
		
		local perEclipse = SolarBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		perEclipse:SetPoint("CENTER", EclipseBar, 0, 45)
		perEclipse:SetFont(cfg.font, cfg.fontsize, cfg.fontflag, 20)
		perEclipse:SetTextColor(1, 1, 1)
		frame:Tag(perEclipse, "[pereclipse]")
		
	end

	----------------------
	--		Runebar		--
	----------------------
	if unit == "player" and playerClass == "DEATHKNIGHT" then
	local Rf = CreateFrame("Frame", nil, frame)
	Rf:SetSize(110, 15)
	Rf:SetPoint("BOTTOM", health, -40, -8)
	
		local Runes = {}
		for index = 1, 6 do
		-- Position and size of the rune bar indicators
		local Rune = CreateFrame("StatusBar", nil, Rf)
		Rune:SetSize(100 / 6, 10)
		Rune:SetPoint("TOPLEFT", Rf, "BOTTOMLEFT", index * 100 / 4, 0)
		Rune:SetStatusBarTexture("Interface\\AddOns\\oUF_Kygo\\Media\\Neal")
   
		Runes[index] = Rune
		end
   
		-- Register with oUF
	frame.Runes = Runes
	end
	
	---------------------
	--		Castbar	   --
	---------------------
	-- Temp castbar..
	if unit == "player" then
	local Castbar = CreateFrame("StatusBar", nil, frame)
	Castbar:SetSize(303, 50)
	Castbar:SetPoint("BOTTOM", frame, 0, -50)
	
	local CastbarBG = Castbar:CreateTexture(nil, "BACKGROUND")
	CastbarBG:SetAllPoints(Castbar)
	CastbarBG:SetTexture(cfg.texture)

	local CastbarSpellText = Castbar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	CastbarSpellText:SetPoint("LEFT", Castbar)
	CastbarSpellText:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	
	local CastbarSpark = Castbar:CreateTexture(nil, "OVERLAY")
	CastbarSpark:SetSize(20, 20)
	CastbarSpark:SetBlendMode("ADD")
	
	local CastbarTimer = Castbar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	CastbarTimer:SetPoint("RIGHT", Castbar)
	CastbarTimer:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
	
	local CastbarSafeZone = Castbar:CreateTexture(nil, "OVERLAY")

	
	-- Castbar colors
	Castbar:SetStatusBarTexture(cfg.texture)
	Castbar:SetStatusBarColor(79/255, 79/255, 79/255) -- R G B Foreground color
	CastbarBG:SetVertexColor(150/255, 150/255, 150/255)
	
	frame.Castbar = Castbar
	frame.Castbar.bg = CastbarBG
	frame.Castbar.Text = CastbarSpellText
	frame.Castbar.Spark = CastbarSpark
	frame.Castbar.Time = CastbarTimer
	frame.Castbar.SafeZone = CastbarSafeZone
	end
	
	---------------------
	--   Plug-in's     --
	---------------------
	---------------------
	--  oUF_Smooth     --
	---------------------
	if IsAddOnLoaded("oUF_Smooth") and not strmatch(unit, ".target$") then
		frame.Health.Smooth = true
		if frame.Power then
			frame.Power.Smooth = true
		end	
	end
	
	--------------------
	-- oUF_SpellRange --
	--------------------
	if IsAddOnLoaded("oUF_SpellRange") then
		frame.SpellRange = {
			insideAlpha = 1,
			outsideAlpha = 0.7,
		}

	elseif unit == "pet" or unit == "party"  then
		frame.Range = {
			insideAlpha = 1,
			outsideAlpha = 0.7,
		}
	end

	
	--------------------
	--   oUF_AuraBars --
	--------------------
	--[[
	if IsAddOnLoaded("oUF_AuraBars") then
		if unit == "player" or unit == "target" then
			frame.AuraBars = CreateFrame("Frame", nil, frame)
			frame.AuraBars:SetHeight(1)
			frame.AuraBars:SetWidth(142)
			frame.AuraBars:SetPoint("TOP", 0, -3)
			frame.AuraBars:SetPoint("RIGHT", -4, 0)
			frame.AuraBars.auraBarHeight = 10
			frame.AuraBars.spellNameSize = 5
			frame.AuraBars.spellTimeSize = 5
			frame.AuraBars.sort = 1
			frame.AuraBars.auraBarTexture = "Interface\\AddOns\\oUF_Kygo\\Media\\Neal"
			frame.AuraBars.filter =
				function(name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, canApplyAura, isBossDebuff)
					if(unitCaster == "player") and duration > 1 and duration < 305 then
					return true
					end
				end

		end
	end
	--]]
end






oUF:RegisterStyle("Kygo", Style)
oUF:SetActiveStyle("Kygo")
--Spawning units!
local player = oUF:Spawn("player")
player:SetPoint("CENTER", UIParent, "CENTER", -213, -191)

local target = oUF:Spawn("target")
target:SetPoint("CENTER", UIParent, "CENTER", 213, -191)

local pet = oUF:Spawn("pet")
pet:SetPoint("LEFT", player, "LEFT", -325, -15)
pet:SetScale(0.7)

local tot = oUF:Spawn("targettarget")
tot:SetPoint("CENTER", UIParent, "CENTER", 0, -325)
tot:SetScale(0.7)
tot:SetWidth(130)

local focus = oUF:Spawn("focus")
focus:SetPoint("TOP", target, "TOP", 120, 120)
focus:SetScale(0.7)

local boss1 = oUF:Spawn("boss1")
boss1:SetPoint("CENTER", player, "CENTER", 0, 70)

--[[
local boss2 = oUF:Spawn("boss2")
boss2:SetPoint("CENTER", player, "CENTER", 0, 110)

local boss3 = oUF:Spawn("boss3")
boss3:SetPoint("CENTER", player, "CENTER", 0, 140)

local boss4 = oUF:Spawn("boss4")
boss4:SetPoint("CENTER", player, "CENTER", 0, 170)

local boss5 = oUF:Spawn("boss5")
boss5:SetPoint("CENTER", player, "CENTER", 0, 210)
--]]

	for  unit, object in pairs(ns.headers) do
		local udata = uconfig[unit]
		local p1, parent, p2, x, y = string.split(" ", udata.point)
		object:ClearAllPoints()
		object:SetPoint(p1, ns.headers[parent] or ns.frames[parent] or _G[parent] or UIParent, p2, tonumber(x) or 0, tonumber(y) or 0)
	end
local party1 = oUF:Spawn("party")
party1:SetPoint("LEFT", UIParent, "LEFT", 54, 0)
party1:SetScale(0.8)

--[[
local party2 = oUF:Spawn("party2")
party2:SetPoint("LEFT", UIParent, "LEFT", 54, 110)
party2:SetScale(0.8)

local party3 = oUF:Spawn("party3")
party3:SetPoint("LEFT", UIParent, "LEFT", 54, 220)
party3:SetScale(0.8)

local party4 = oUF:Spawn("party4")
party4:SetPoint("LEFT", UIParent, "LEFT", 54, 330)
party4:SetScale(0.8)
--]]