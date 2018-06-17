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

--
-- Global variables
--

XenUtils = XenUtils or {}

local function GetBuffName(buffDetail)
	local buffName = ""
	if buffDetail then
		if buffDetail.name == "" then
			buffName = buffDetail.description
		else
			buffName = buffDetail.name
		end
	end
	
	if not buffName then
		buffName = ""
	end
	
	return buffName
end

local function GetCallbackID(self)
	self.callbackID = self.callbackID + 1
	return "#" .. self.callbackID
end

local function AddEvents(self)
	Command.Event.Attach(Event.Buff.Add, self.BuffAdd, "XenUtils." .. "BuffAdd." .. self.name)
	Command.Event.Attach(Event.Buff.Change, self.BuffChange, "XenUtils." .. "BuffChange." .. self.name)
	Command.Event.Attach(Event.Buff.Remove, self.BuffRemove, "XenUtils." .. "BuffRemove." .. self.name)
end

local function RemoveEvents(self)
	Command.Event.Detach(Event.Buff.Add, self.BuffAdd, "XenUtils." .. "BuffAdd." .. self.name)
	Command.Event.Detach(Event.Buff.Change, self.BuffChange, "XenUtils." .. "BuffChange." .. self.name)
	Command.Event.Detach(Event.Buff.Remove, self.BuffRemove, "XenUtils." .. "BuffRemove." .. self.name)
end

local function IsEmpty(self)
	return self.buffCount == 0
end

local function Clear(self)
	self:RemoveEvents()
	
	self.buffCount = 0
	self.buffByID = {}
	self.buffCallbacks = {}
	self.buffCallbackMap = {}
end

local function InternalAddBuffCallback(self, unitSpec, buffName, isPlayer, callback, eventType, stackCheckFunction)
	if not unitSpec and not buffName then
		print("Ignoring buff with no unit speicifer and name")
		return -1
	end
	if not buffName then
		print("Ignoring " .. unitSpec .. " buff with no name")
		return -1
	end
	if not unitSpec then
		print("Ignoring buff " .. buffName .. " with no unit speicifer")
		return -1
	end
	
	local id = GetCallbackID(self)
	self.buffCallbackMap[id] = {}
	self.buffCallbackMap[id].unitSpec = unitSpec
	self.buffCallbackMap[id].buffName = buffName
	
	if not self.buffCallbacks[unitSpec] then
		self.buffCallbacks[unitSpec] = {}
	end
	
	if not self.buffCallbacks[unitSpec][buffName] then
		self.buffCallbacks[unitSpec][buffName] = {}
		self.buffCallbacks[unitSpec][buffName].duration = 0
		self.buffCallbacks[unitSpec][buffName].stack = 0
	end

	if not self.buffCallbacks[unitSpec][buffName].id then
		self.buffCallbacks[unitSpec][buffName].id = {}
	end
	
	self.buffCallbacks[unitSpec][buffName].id[id] = {}
	self.buffCallbacks[unitSpec][buffName].id[id].callback = callback
	self.buffCallbacks[unitSpec][buffName].id[id].eventType = eventType
	self.buffCallbacks[unitSpec][buffName].id[id].stackCheckFunction = stackCheckFunction
	self.buffCallbacks[unitSpec][buffName].id[id].isPlayer = isPlayer

	self.buffCount = self.buffCount + 1
	
	return id
end

local function AddBuffExistsCallback(self, unitSpec, buffName, isPlayer, callback)
	return InternalAddBuffCallback(self, unitSpec, buffName, isPlayer, callback, BuffManager.existsType)
end

local function AddBuffNotExistsCallback(self, unitSpec, buffName, isPlayer, callback)
	return InternalAddBuffCallback(self, unitSpec, buffName, isPlayer, callback, BuffManager.notExistsType)
end

local function AddStacksLessEqualToCallback(self, unitSpec, buffName, isPlayer, stacks, callback)
	return InternalAddBuffCallback(self, unitSpec, buffName, isPlayer, callback, BuffManager.existsType, function(stack) return stack <= stacks end)
end

local function AddStacksGreaterEqualToCallback(self, unitSpec, buffName, isPlayer, stacks, callback)
	return InternalAddBuffCallback(self, unitSpec, buffName, isPlayer, callback, BuffManager.existsType, function(stack) return stack >= stacks end)
end

local function BuffExists(self, inUnitSpec, unitID, buffIDs)
	if self:IsEmpty() == true then
		return
	end
	
	local unitSpec = inUnitSpec
	if not unitSpec then
		local found = false
		local idLookup = {}
		for key, _ in pairs(self.buffCallbacks) do
			idLookup[key] = 1
			found = true
		end
		
		if found == false then
			return
		end
		
		for thisSpec, thisID in pairs(Inspect.Unit.Lookup(idLookup)) do
			if thisID == unitID then
				unitSpec = thisSpec
				break
			end
		end
		
		if not unitSpec then
			return
		end
	end
	
	if self.buffCallbacks[unitSpec] then
		local buffDetails = Inspect.Buff.Detail(unitID, buffIDs)
		for id, buffDetail in pairs(buffDetails) do
			local buffName = GetBuffName(buffDetail)
			if buffName then
				if not self.buffCallbacks[unitSpec][buffName] then
					self.buffCallbacks[unitSpec][buffName] = {}
					self.buffCallbacks[unitSpec][buffName].id = {}
				end
				
				-- ignore non-player cast buffs if this is the player data set
				local isPlayerBuff = false
				if buffDetail.caster ~= self.playerID then
					isPlayerBuff = true
				end
				
				-- ignore the 2nd buff with the same name but a different ability id.
				if not self.buffCallbacks[unitSpec][buffName].ability or buffDetail.ability == self.buffCallbacks[unitSpec][buffName].ability then
					local duration = 0
					if buffDetail.duration then
						duration = math.ceil(buffDetail.duration)
					end

					local stack = 0
					if buffDetail.stack then
						stack = buffDetail.stack
					end

					self.buffCallbacks[unitSpec][buffName].exists = true
					self.buffCallbacks[unitSpec][buffName].duration = duration
					self.buffCallbacks[unitSpec][buffName].stack = stack
					self.buffCallbacks[unitSpec][buffName].ability = buffDetail.ability

					self.buffByID[id] = {}
					self.buffByID[id].unitSpec = unitSpec
					self.buffByID[id].buffName = buffName
					self.buffByID[id].ability = buffDetail.ability

					for cbId, callback in pairs(self.buffCallbacks[unitSpec][buffName].id) do
						if callback.isPlayer ~= true or (callback.isPlayer == true and isPlayerBuff == true) then
							if callback.eventType == BuffManager.existsType then
								if callback.stackCheckFunction then
									callback.callback(unitSpec, buffName, duration, callback.stackCheckFunction(stack))
								else
									callback.callback(unitSpec, buffName, duration, true)
								end
							else
								callback.callback(unitSpec, buffName, duration, false)
							end
						end
					end
				end
			end
		end
	end
end

local function Refresh(self, unitSpec)
	if self:IsEmpty() == true then
		return
	end
	
	if not self.buffCallbacks[unitSpec] then
		return
	end

	local buffIDs = Inspect.Buff.List(unitSpec)
	if not buffIDs then
		-- unitSpec empty so hide everything
		for buffName, buffDetail in pairs(self.buffCallbacks[unitSpec]) do
			buffDetail.exists = false
			for cbId, callback in pairs(buffDetail.id) do
				callback.callback(unitSpec, buffName, buffDetail.duration, false)
			end
		end
		
		return
	end
	
	for buffName, buffDetail in pairs(self.buffCallbacks[unitSpec]) do
		buffDetail.exists = false
	end
	
	local buffIdDeleteList = {}
	for buffId, buff in pairs(self.buffByID) do
		if buff.unitSpec == unitSpec then
			table.insert(buffIdDeleteList, buffId)
		end
	end
	
	for indx, buffId in ipairs(buffIdDeleteList) do
		self.buffByID[buffId] = nil
	end

	local unitID = Inspect.Unit.Lookup(unitSpec)
	if unitID then
		BuffExists(self, unitSpec, unitID, buffIDs)
	end
	
	for buffName, buffDetail in pairs(self.buffCallbacks[unitSpec]) do
		if buffDetail.exists == false then
			for cbId, callback in pairs(buffDetail.id) do
				if callback.eventType == self.existsType then
					if callback.stackCheckFunction then
						callback.callback(unitSpec, buffName, buffDetail.duration, callback.stackCheckFunction(0))
					else
						callback.callback(unitSpec, buffName, buffDetail.duration, false)
					end
				else
					callback.callback(unitSpec, buffName, buffDetail.duration, true)
				end
			end
		end
	end	
end

local function BuffAdd(self, unitID, buffIDs)
	BuffExists(self, nil, unitID, buffIDs)
end

local function BuffChange(self, unitID, buffIDs)
	BuffExists(self, nil, unitID, buffIDs)
end

local function BuffRemove(self, unitID, buffIDs)
	local found = false
	local idLookup = {}
	for key, _ in pairs(self.buffCallbacks) do
		idLookup[key] = 1
		found = true
	end
	
	if found == false then
		return
	end
	
	local unitSpec = ""
	for thisSpec, thisID in pairs(Inspect.Unit.Lookup(idLookup)) do
		if unitID == thisID then
			unitSpec = thisSpec
			break
		end
	end

	if self.buffCallbacks[unitSpec] then
		for id, details in pairs(buffIDs) do
			if self.buffByID[id] then
				local buffName = self.buffByID[id].buffName
				if self.buffCallbacks[unitSpec][buffName] then
					self.buffCallbacks[unitSpec][buffName].exists = false
					
					local duration = self.buffCallbacks[unitSpec][buffName].duration
					for cbID, callback in pairs(self.buffCallbacks[unitSpec][buffName].id) do
						if callback.eventType == BuffManager.notExistsType then
							callback.callback(unitSpec, buffName, duration, true)
						elseif callback.stackCheckFunction then
							callback.callback(unitSpec, buffName, duration, callback.stackCheckFunction(0))
						else
							callback.callback(unitSpec, buffName, duration, false)
						end
					end
				end

				self.buffByID[id] = nil
			end
		end
	end
end

local function Create(name, isPlayer, playerID)
	local self = {}
	self.buffCount = 0
	self.isPlayer = isPlayer
	self.playerID = playerID
	self.buffByID = {}
	self.buffCallbacks = {}
	self.buffCallbackMap = {}
	self.callbackID = 0
	self.existsType = 1
	self.notExistsType = 2
	
	self.Clear = Clear
	self.IsEmpty = IsEmpty
	self.AddAbilityEndCallback = AddAbilityEndCallback
	self.AddAbilityBeginCallback = AddAbilityBeginCallback
	self.Refresh = Refresh
	self.AddEvents = AddEvents
	self.RemoveEvents = RemoveEvents
	
	self.BuffAdd = function(h, unitID, buffIDs) BuffAdd(self, unitID, buffIDs) end
	self.BuffChange = function(h, unitID, buffIDs) BuffChange(self, unitID, buffIDs) end
	self.BuffRemove = function(h, unitID, buffIDs) BuffRemove(self, unitID, buffIDs) end
end

XenUtils.CreateBuffManager = Create
