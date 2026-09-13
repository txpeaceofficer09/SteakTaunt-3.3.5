local f = CreateFrame("Frame")

local TAUNTS = {
	[355] = "Taunt", -- Warrior
	[694] = "Mocking Blow", -- Warrior
	[62124] = "Hand of Reckoning", -- Paladin
	[31789] = "Righteous Defense", -- Paladin
	[56222] = "Dark Command", -- DK
	[6795] = "Growl", -- Druid
	[2649] = "Growl (Pet)", -- Pet
}

local function IsTaunt(spellId)
	return TAUNTS[spellId] ~= nil
end

local function Announce(msg)
	local channel

	if GetNumRaidMembers() > 0 then
		channel = "RAID"
	elseif GetNumPartyMembers() > 0 then
		channel = "PARTY"
	else
		channel = "SAY"
	end

	SendChatMessage(msg, nil, nil, channel)
end

f:SetScript("OnEvent", function(self, event, ...)
	local timestamp, subevent, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType = ...

	if not srcName then return end
	if not spellId or not IsTaunt(spellId) then return end

	local msg

	if subevent == "SPELL_CAST_SUCCESS" then
		msg = string.format("Taunt landed on %s (%s)", dstName or "?", spellName)
	elseif subevent == "SPELL_MISSED" then
		msg = string.format("Taunt FAILED on %s (%s: %s)", dstName or "?", spellName, missType or "unknown")
	end

	if msg ~= nil then
		if srcName == UnitName("player") then
			Announce(msg)
		else
			print("|cffff8800[SteakTaunt]:|r "..msg)
		end
	end
end)

f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
