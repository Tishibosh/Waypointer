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
-- Main functions
--

local function InternalGetID(self)
	self.eventID = self.eventID + 1
	return "#" .. self.eventID
end

local function Clear(self)
	self:RemoveEvent()
	self.eventsByID = {}
	self.eventsByUnit = {}
end

local function AddCallback(self, unitID, callback)
	if next(self.eventsByID) == nil then
		self:AddEvent()
	end
	
	local eventID = InternalGetID(self)
	self.eventsByID[eventID] = callback
	
	local unitTable = self.eventsByUnit[unitID]
	if unitTable == nil then
		unitTable = {}
	end
	
	unitTable[eventID] = true
	
	if self.eventsByUnit[unitID] == nil then
		self.eventsByUnit[unitID] = unitTable
	end
	
	return eventID
end

local function RemoveCallback(self, callbackId)
	self.eventsByID[callbackId] = nil
	
	if next(self.eventsByID) == nil then
		self:Clear()
	end
end

local function Refresh(self, eventTable)
	if next(self.eventsByID) == nil then
		self:Clear()
	elseif eventTable ~= nil then
		for unitID, unitValue in pairs(eventTable) do
			local unitTable = self.eventsByUnit[unitID]
			if unitTable ~= nil then
				local newValue = unitValue
				if newValue == false then
					newValue = 0
				end

				local hasEvents = false
				for eventID, _ in pairs(unitTable) do
					local callback = self.eventsByID[eventID]
					if callback ~= nil then
						hasEvents = true
						callback(newValue)
					end
				end
				
				if hasEvents == false then
					self.eventsByUnit[unitID] = nil
				end
			end
		end
	end
end

local function AddHealth(self)
	Command.Event.Attach(Event.Unit.Detail.Health, self.Refresh, "XenUtils.StatManager.RefreshHealth")
end

local function RemoveHealth(self)
	Command.Event.Detach(Event.Unit.Detail.Health, self.Refresh, "XenUtils.StatManager.RefreshHealth")
end

local function AddMana(self)
	Command.Event.Attach(Event.Unit.Detail.Mana, self.Refresh, "XenUtils.StatManager.RefreshMana")
end

local function RemoveMana(self)
	Command.Event.Detach(Event.Unit.Detail.Mana, self.Refresh, "XenUtils.StatManager.RefreshMana")
end

local function AddCharge(self)
	Command.Event.Attach(Event.Unit.Detail.Charge, self.Refresh, "XenUtils.StatManager.RefreshCharge")
end

local function RemoveCharge(self)
	Command.Event.Detach(Event.Unit.Detail.Charge, self.Refresh, "XenUtils.StatManager.RefreshCharge")
end

local function AddEnergy(self)
	Command.Event.Attach(Event.Unit.Detail.Energy, self.Refresh, "XenUtils.StatManager.RefreshEnergy")
end

local function RemoveEnergy(self)
	Command.Event.Detach(Event.Unit.Detail.Energy, self.Refresh, "XenUtils.StatManager.RefreshEnergy")
end

local function Create(statType)
	if statType ~= "health" and statType ~= "mana" and statType ~= "energy" and statType ~= "charge" then
		return nil
	end
	
	local Stat = {}
	Stat.statType = statType
	Stat.eventsByID = {}
	Stat.eventsByUnit = {}
	Stat.eventID = 0

	Stat.Clear = Clear
	Stat.AddCallback = AddCallback
	Stat.RemoveCallback = RemoveCallback
	if statType == "health" then
		Stat.AddEvent = AddHealth
		Stat.RemoveEvent = RemoveHealth
	elseif statType == "mana" then
		Stat.AddEvent = AddMana
		Stat.RemoveEvent = RemoveMana
	elseif statType == "charge" then
		Stat.AddEvent = AddCharge
		Stat.RemoveEvent = RemoveCharge
	elseif statType == "energy" then
		Stat.AddEvent = AddEnergy
		Stat.RemoveEvent = RemoveEnergy
	end
	
	Stat.Refresh = function(h, a) Refresh(Stat, a) end
	
	return Stat
end

XenUtils = XenUtils or {}
XenUtils.CreateStat = Create
