local addonName, ns = ...

--Some Tags
oUF.Tags.Events["shorthp"] = "UNIT_HEALTH"
oUF.Tags.Methods["shorthp"] = function(unit)
	if not UnitIsDeadOrGhost(unit) then
		local hp = UnitHealth(unit)
		return AbbreviateLargeNumbers(hp)
	end
end

oUF.Tags.Events["shortpp"] = "UNIT_POWER"
oUF.Tags.Methods["shortpp"] = function(unit)
	if not UnitIsDeadOrGhost(unit) then
		local pp = UnitPower(unit)
		return AbbreviateLargeNumbers(pp)
	end
end

oUF.Tags.Events["shortname"] = "UNIT_NAME"
oUF.Tags.Methods["shortname"] = function(unit)
	local name = UnitName(unit)
	return string.sub(UnitName(unit), 1, 20)
end

oUF.Tags.Events["readycheckicon"] = "DoReadyCheck"
oUF.Tags.SharedEvents["IsInGroup"] = true
oUF.Tags.Methods["readycheckicon"] = function(unit)
	if unit == "player" and IsInGroup() then
		return [[|TInterface\RAIDFRAME\ReadyCheck-Ready|t]]
	end
end

oUF.Tags.Events["rsicon"] = "PLAYER_UPDATE_RESTING"
oUF.Tags.SharedEvents["PLAYER_UPDATE_RESTING"] = true
oUF.Tags.Methods["rsicon"] = function(unit)
	if unit == "player" and IsResting() then
		return [[|TInterface\CharacterFrame\UI-StateIcon:0:0:0:-6:64:64:28:6:6:28|t]]
	end
end
oUF.Tags.Events["combaticon"] = "PLAYER_REGEN_DISABLED PLAYER_REGEN_ENABLED"
oUF.Tags.SharedEvents["PLAYER_REGEN_DISABLED"] = true
oUF.Tags.SharedEvents["PLAYER_REGEN_ENABLED"] = true
oUF.Tags.Methods["combaticon"] = function(unit)
	if unit == "player" and UnitAffectingCombat("player") then
		return [[|TInterface\CharacterFrame\UI-StateIcon:0:0:0:0:64:64:37:58:5:26|t]]
	end
end

oUF.Tags.Events["leadericon"] = "GROUP_ROSTER_UPDATE"
oUF.Tags.SharedEvents["GROUP_ROSTER_UPDATE"] = true
oUF.Tags.Methods["leadericon"] = function(unit)
	if UnitIsGroupLeader(unit) then
		return [[|TInterface\GroupFrame\UI-Group-LeaderIcon:0|t]]
	elseif UnitInRaid(unit) and UnitIsGroupAssistant(unit) then
		return [[|TInterface\GroupFrame\UI-Group-AssistantIcon:0|t]]
	end
end

oUF.Tags.Events["mastericon"] = "PARTY_LOOT_METHOD_CHANGED GROUP_ROSTER_UPDATE"
oUF.Tags.SharedEvents["PARTY_LOOT_METHOD_CHANGED"] = true
oUF.Tags.SharedEvents["GROUP_ROSTER_UPDATE"] = true
oUF.Tags.Methods["mastericon"] = function(unit)
	local method, pid, rid = GetLootMethod()
	if method ~= "master" then return end
	local munit
	if pid then
		if pid == 0 then
			munit = "player"
		else
			munit = "party" .. pid
		end
	elseif rid then
		munit = "raid" .. rid
	end
	if munit and UnitIsUnit(munit, unit) then
		return [[|TInterface\GroupFrame\UI-Group-MasterLooter:0:0:0:2|t]]
	end
end


ns.tags = tags