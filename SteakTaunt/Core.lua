SteakTaunt = {
	taunts = {
		[355] = "Taunt", -- Warrior
		[694] = "Mocking Blow", -- Warrior
		[62124] = "Hand of Reckoning", -- Paladin
		[31789] = "Righteous Defense", -- Paladin
		[56222] = "Dark Command", -- DK
		[6795] = "Growl", -- Druid
		[27047] = "Growl (Pet)", -- Pet
		[49613] = "Taunt" -- DTK Last Boss Phase 2
	},
	alert = {
		[355] = true,
		[694] = true,
		[62124] = false,
		[31789] = true,
		[56222] = true,
		[6795] = true,
		[27047] = true,
		[49613] = false
	},
	events = {
		"COMBAT_LOG_EVENT_UNFILTERED"
	},
	frame = CreateFrame("Frame", nil, UIParent),
	Init = function(self)
		if self.initialized then return end
		self.initialized = true

		for _, event in ipairs(self.events) do
			self.frame:RegisterEvent(event)
		end

		self.frame:SetScript("OnEvent", function(_, event, ...)
			if self[event] then
				self[event](self, ...)
			end
		end)
	end,
	IsTaunt = function(self, spellID)
		return self.taunts[spellID] ~= nil
	end,
	GetUnitByName = function(self, name)
		if UnitName("player") == name then return "player" end

		if GetNumRaidMembers() > 0 then
			for i=1,40 do
				if not UnitName("raid"..i) then break end
				if UnitName("raid"..i) == name then return "raid"..i end
			end
		elseif GetNumPartyMembers() > 0 then
			for i=1,4 do
				if not UnitName("party"..i) then break end
				if UnitName("party"..i) == name then return "party"..i end
			end
		end

		return false
	end,
	IsInBattleground = function(self)
		local _, instanceType = GetInstanceInfo()

		return instanceType == "pvp"
	end,
	IsPet = function(self, guid)
		if UnitGUID("pet") == guid then return true end

		if GetNumRaidMembers() > 0 then
			for i=1,40 do
				if UnitExists("raid"..i.."pet") and UnitGUID("raid"..i.."pet") == guid then return true end
			end
		elseif GetNumPartyMembers() > 0 then
			for i=1,4 do
				if UnitExists("party"..i.."pet") and UnitGUID("party"..i.."pet") == guid then return true end
			end
		end

		return false
	end,
	GetOwner = function(self, guid)
		if UnitGUID("pet") == guid then return UnitName("player") end

		if GetNumRaidMembers() > 0 then
			for i=1,40 do
				if UnitExists("raid"..i.."pet") and UnitGUID("raid"..i.."pet") == guid then return UnitName("raid"..i) end
			end
		elseif GetNumPartyMembers() > 0 then
			for i=1,4 do
				if UnitExists("party"..i.."pet") and UnitGUID("party"..i.."pet") == guid then return UnitName("party"..i) end
			end
		end

		return "none"
	end,
	Announce = function(self, msg)
		local channel

		if self:IsInBattleground() then
			channel = "BATTLEGROUND"
		elseif GetNumRaidMembers() > 0 then
			channel = "RAID"
		elseif GetNumPartyMembers() > 0 then
			channel = "PARTY"
		else
			channel = "SAY"
		end

		SendChatMessage(msg, channel)
	end,
	UnitGroupRoleAssigned = function(self, unit)
		local tank, healer, damager = UnitGroupRolesAssigned(unit)

		return tank and "tank" or healer and "healer" or damager and "damager" or "none"
	end,
	COMBAT_LOG_EVENT_UNFILTERED = function(self, timestamp, subevent, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool, missType)
		if not srcName then return end
		if not spellID or not self:IsTaunt(spellID) or not self.alert[spellID] then return end

		local msg

		if subevent == "SPELL_CAST_SUCCESS" then
			msg = string.format("Taunt landed on %s (%s)", dstName or "?", spellName)
		elseif subevent == "SPELL_MISSED" then
			msg = string.format("Taunt FAILED on %s (%s: %s)", dstName or "?", spellName, missType or "unknown")
		end

		if msg ~= nil then
			if srcName == UnitName("player") then
				self:Announce(msg)
			elseif self:IsPet(srcGUID) then
				local owner = self:GetOwner(srcGUID)

				if owner then
					self:Announce(("%s's pet %s %s"):format(owner, srcName, msg))
				end
			else
				local tank, healer, damager = UnitGroupRolesAssigned(self:GetUnitByName(srcName))

				if not tank and ( healer or damager ) then
					self:Announce("["..srcName.."]: "..msg)
				else
					print(("|cffff8800[SteakTaunt]:|r (%s) %s"):format(srcName, msg))
				end
			end
		end
	end
}

SteakTaunt:Init()
