-- There is no copyright on this code

-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
-- associated documentation files (the "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is furnished to do so.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
-- LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
-- NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

XenUtils = XenUtils or {}

local AbilityDetail = Inspect.Ability.New.Detail
local AbilityList = Inspect.Ability.New.List

local function RefreshAbilities(self)
	local abilityList = AbilityList()
	if abilityList ~= nil then
		local abilityDetails = AbilityDetail(abilityList)
		if abilityDetails ~= nil then
			for id, details in pairs(abilityDetails) do
				self.abilityByID[id] = details.name
				self.abilityByName[details.name] = id
			end
		end
	end
end

local function FindID(self, abilityName)
	local ret = self.abilityByName[abilityName]
	if ret == nil then
		RefreshAbilities(self)
		ret = self.abilityByName[abilityName]
	end
	
	return ret
end

local function GetName(self, abilityID)
	return self.abilityByID[abilityID]
end

local function AbilityFired(self, abilities)
	local frameTime = nil
	
	if self.abilityCount == 0 then
		self:Clear()
	else
		for abilityID, count in pairs(abilities) do
			local abilityName = GetName(self, abilityID)
			if abilityName and self.abilityCallbacks[abilityName] then
				local details = AbilityDetail(abilityID)
				local isStarted = false
				local isEnded = false

				local remaining = 0
				if details and details.currentCooldownRemaining then
					remaining = XenUtils.Utils.Round(details.currentCooldownRemaining, 2)
				end
				
				if remaining == 0 then
					isEnded = true
				else
					isStarted = true
				end

				if not frameTime then
					frameTime = Inspect.Time.Frame()
				end
				
				for id, callbackTable in pairs(self.abilityCallbacks[abilityName]) do
					if callbackTable.eventType == self.beginType and isStarted == true then
						callbackTable.callback(abilityName, remaining, frameTime)
					elseif callbackTable.eventType == self.endType and isEnded == true then
						callbackTable.callback(abilityName)
					end
				end
			end
		end
	end
end

local function AbilityBegin(self, abilities)
	AbilityFired(self, abilities)
end

local function AbilityEnd(self, abilities)
	AbilityFired(self, abilities)
end

local function AddEvents(self)
	Command.Event.Attach(Event.Ability.New.Cooldown.Begin, self.AbilityBegin, "XenUtils." .. "AbilityBegin." .. self.name)
	Command.Event.Attach(Event.Ability.New.Cooldown.End, self.AbilityEnd, "XenUtils." .. "AbilityEnd." .. self.name)
end

local function RemoveEvents(self)
	Command.Event.Detach(Event.Ability.New.Cooldown.Begin, self.AbilityBegin, "XenUtils." .. "AbilityBegin." .. self.name)
	Command.Event.Detach(Event.Ability.New.Cooldown.End, self.AbilityEnd, "XenUtils." .. "AbilityEnd." .. self.name)
end

local function Clear(self)
	self:RemoveEvents()
	
	self.abilityCallbacks = {}
	self.abilityCallbackMap = {}
	self.abilityCount = 0
end

local function GetCooldown(self, abilityName)
	if not self.abilityByName[abilityName] then
		return nil
	end
	
	local abilityID = self.abilityByName[abilityName]
	if abilityID then
		local details = AbilityDetail(abilityID)
		if details ~= nil then
			return details.currentCooldownBegin, details.currentCooldownRemaining
		end
	end
	
	return nil
end

local function GetAbilityNames(self)
	if next(self.abilityByName) == nil then
		RefreshAbilities(self)
	end

	local names = {}
	for name, _ in pairs(self.abilityByName) do
		table.insert(names, name)
	end
	
	table.sort(names)
	
	return names
end

function RemoveAbilityCallback(self, id)
	local key = self.abilityCallbackMap[id]
	if key then
		self.abilityCount = self.abilityCount - 1
		if self.abilityCount == 0 then
			self:Clear()
		else
			self.abilityCallbacks[key][id] = nil
			if next(self.abilityCallbacks[key]) == nil then
				self.abilityCallbacks[key] = nil
			end
		end
	end
end

local function GetAbilityList(self)
	local abilityIds = {}
	for abilityName, _ in pairs (self.abilityCallbacks) do
		local abilityId = self.abilityByName[abilityName]
		if abilityId ~= nil then
			abilityIds[abilityId] = true
		end
	end
	
	if next(abilityIds) ~= nil then
		return abilityIds
	else
		return nil
	end
end

local function Refresh(self)
	if self.abilityCount > 0 then
		local abilities = GetAbilityList(self)
		if abilities then
			local details = AbilityDetail(abilities)
			if details then
				local currentTime = Inspect.Time.Frame()
				for abilityID, detail in pairs(detail) do
					local abilityCallbacks = self.abilityCallbacks[detail.name]
					if abilityCallbacks and self.abilityByName[detail.name] then
						local isStarted = false
						local isEnded = false
						local remaining = 0
						if detail.currentCooldownRemaining then
							remaining = XenUtils.Utils.Round(detail.currentCooldownRemaining, 2)
						end
						
						if remaining == 0 then
							isEnded = true
						else
							isStarted = true
						end
						
						for id, callbackTable in pairs(abilityCallbacks) do
							if callbackTable.eventType == AbilityManager.availableType and isEnded == true then
								callbackTable.callback(abilityName)
							elseif callbackTable.eventType == AbilityManager.notAvailableType and isStarted == true then
								callbackTable.callback(abilityName)
							end
						end
					end
				end
			end
		end
	end
end

local function GetCallbackID(self)
	self.callbackID = self.callbackID + 1
	return "#" .. self.callbackID
end

local function InternalAddAbilityCallback(self, abilityName, callback, eventType)
	if not abilityName then
		print("Ignoring ability with no name")
		return -1
	end
	if not abilityName then
		print("Ignoring " .. unitSpec .. " ability with no name")
		return -1
	end
	
	local abilityID = FindID(self, abilityName)
	if not abilityID then
		return -1
	end
	
	local details = AbilityDetail(abilityID)
	
	if not details or not details.cooldown or details.cooldown == 0 then
		return -1
	end
	
	if self.abilityCount == 0 then
		self:AddEvents()
	end
	
	self.abilityCount = self.abilityCount + 1
	
	local id = GetCallbackID(self)
	self.abilityCallbackMap[id] = abilityName
	
	if not self.abilityCallbacks[abilityName] then
		self.abilityCallbacks[abilityName] = {}
	end

	self.abilityCallbacks[abilityName][id] = {}
	self.abilityCallbacks[abilityName][id].callback = callback
	self.abilityCallbacks[abilityName][id].eventType = eventType
	
	self:Refresh(abilityName)
	return id
end

local function AddAbilityEndCallback(self, abilityName, callback)
	return InternalAddAbilityCallback(self, abilityName, callback, self.endType)
end

local function AddAbilityBeginCallback(self, abilityName, callback)
	return InternalAddAbilityCallback(self, abilityName, callback, self.beginType)
end

local function Create(name)
	local self = {}
	self.name = name
	self.abilityByID = {}
	self.abilityByName = {}
	self.abilityCallbacks = {}
	self.abilityCallbackMap = {}
	self.callbackID = 0
	self.abilityCount = 0
	self.beginType = 1
	self.endType = 2
	
	self.Clear = Clear
	self.GetAbilityNames = GetAbilityNames
	self.GetCooldown = GetCooldown
	self.AddAbilityEndCallback = AddAbilityEndCallback
	self.AddAbilityBeginCallback = AddAbilityBeginCallback
	self.RemoveAbilityCallback = RemoveAbilityCallback
	self.Refresh = Refresh
	self.AddEvents = AddEvents
	self.RemoveEvents = RemoveEvents
	
	self.AbilityBegin = function(h, abilityIDs) AbilityBegin(self, abilityIDs) end
	self.AbilityEnd = function(h, abilityIDs) AbilityEnd(self, abilityIDs) end
end

XenUtils.CreateAbilityManager = Create
