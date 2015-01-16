local addonName, ns = ...

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

ns.Aurabars = Aurabars