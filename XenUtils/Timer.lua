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

local function InternalGetTime()
	return math.floor(Inspect.Time.Frame() * 10)
end

local function GetTime(currentTime)
	return currentTime / 10
end

local function GetCurrentTime(self)
	if self.currentTime == 0 then
		return GetTime(InternalGetTime())
	else
		return GetTime(self.currentTime)
	end
end

local function InternalGetID(self)
	self.eventID = self.eventID + 1
	return "#" .. self.eventID
end

local function GetTimeKey(thisTime)
	return "@" .. thisTime
end

local function GetMinimumDelay()
	return 0.1
end

local function InternalAdd(self, id, name, duration, callback, repeatIt)
	local dueTime = self.currentTime + (duration * 10)
	
	local thisXenUtilsTimer = {}
	thisXenUtilsTimer.id = id
	thisXenUtilsTimer.name = name
	thisXenUtilsTimer.duration = duration
	thisXenUtilsTimer.callback = callback
	thisXenUtilsTimer.dueTime = dueTime
	if (repeatIt == true) then
		thisXenUtilsTimer.repeatXenUtilsTimer = true
	else
		thisXenUtilsTimer.repeatXenUtilsTimer = false
	end
	
	local dueTimeKey = GetTimeKey(dueTime)
	if not self.eventsByTime[dueTimeKey] then
		self.eventsByTime[dueTimeKey] = {}
	end

	self.eventsByTime[dueTimeKey][id] = thisXenUtilsTimer
	self.eventsByID[id] = thisXenUtilsTimer
end

local function Clear(self)
	self:RemoveEvent()
	self.eventsByTime = {}
	self.eventsByID = {}
	self.currentTime = 0
end

local function AddCallback(self, name, duration, callback, repeatIt)
	if self.currentTime == 0 then
		self.currentTime = InternalGetTime()
	end
	
	local eventID = InternalGetID(self)
	local roundedDuration = XenUtils.Utils.Round(duration, 1)
	if roundedDuration < 0.1 then
		return nil
	end
	
	if next(self.eventsByID) == nil then
		self:AddEvent()
	end
	
	InternalAdd(self, eventID, name, roundedDuration, callback, repeatIt)
	
	return eventID
end

local function RemoveCallback(self, timerId)
	local thisXenUtilsTimer = self.eventsByID[timerId]
	if thisXenUtilsTimer then
		local dueTimeKey = GetTimeKey(thisXenUtilsTimer.dueTime)
		self.eventsByID[timerId] = nil
		self.eventsByTime[dueTimeKey][timerId] = nil

		local deleteTable = true
		for i, j in pairs(self.eventsByTime[dueTimeKey]) do
			deleteTable = false
		end

		if deleteTable == true then
			self.eventsByTime[dueTimeKey] = nil
		end
	end
	
	if next(self.eventsByID) == nil then
		self:Clear()
	end
end

local function Refresh(self)
	local newTime = InternalGetTime()
	
	if next(self.eventsByID) == nil then
		self:Clear()
	elseif newTime ~= self.currentTime then
		local nextXenUtilsTimerTime = self.currentTime + 1
		for currentTime = nextXenUtilsTimerTime, newTime do
			self.currentTime = currentTime
			local timeKey = GetTimeKey(self.currentTime)
			if self.eventsByTime[timeKey] then
				for id, thisXenUtilsTimer in pairs(self.eventsByTime[timeKey]) do
					if thisXenUtilsTimer.repeatXenUtilsTimer == true then
						InternalAdd(self, thisXenUtilsTimer.id, thisXenUtilsTimer.name, thisXenUtilsTimer.duration, thisXenUtilsTimer.callback, thisXenUtilsTimer.repeatXenUtilsTimer)
					else
						self.eventsByID[thisXenUtilsTimer.id] = nil
					end

					thisXenUtilsTimer.callback(GetTime(currentTime))
				end

				self.eventsByTime[timeKey] = nil
				
				if next(self.eventsByID) == nil then
					self:Clear()
				end
			end
		end
	end
end

local function AddEvent(self)
	Command.Event.Attach(Event.System.Update.Begin, self.Refresh, "XenUtils.Timer.Refresh")
end

local function RemoveEvent(self)
	Command.Event.Detach(Event.System.Update.Begin, self.Refresh, "XenUtils.Timer.Refresh")
end

local function Create()
	local Timer = {}
	Timer.eventsByTime = {}
	Timer.eventsByID = {}
	Timer.eventID = 0
	Timer.currentTime = 0

	Timer.Clear = Clear
	Timer.AddCallback = AddCallback
	Timer.RemoveCallback = RemoveCallback
	Timer.GetCurrentTime = GetCurrentTime
	Timer.GetMinimumDelay = GetMinimumDelay
	Timer.AddEvent = AddEvent
	Timer.RemoveEvent = RemoveEvent
	Timer.Refresh = function() Refresh(Timer) end
	
	return Timer
end

XenUtils = XenUtils or {}
XenUtils.CreateTimer = Create
