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
	self.eventsByMsg = {}
end

local function AddCallback(self, msg, callback)
	if next(self.eventsByID) == nil then
		self:AddEvent()
	end
	
	local eventID = InternalGetID(self)
	self.eventsByID[eventID] = callback
	
	local msgTable = self.eventsByMsg[msg]
	if msgTable == nil then
		msgTable = {}
	end
	
	msgTable[eventID] = true
	
	if self.eventsByMsg[msg] == nil then
		self.eventsByMsg[msg] = msgTable
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
	elseif eventTable ~= nil and eventTable.message ~= nil then
		local msgTable = self.eventsByMsg[eventTable.message]
		if msgTable ~= nil then
			local hasEvents = false
			for eventID, _ in pairs(msgTable) do
				local callback = self.eventsByID[eventID]
				if callback ~= nil then
					hasEvents = true
					callback()
				end
			end
			
			if hasEvents == false then
				self.eventsByMsg[eventTable.message] = nil
			end
		end
	end
end

local function AddEvent(self)
	Command.Event.Attach(Event.Chat.Notify, self.Refresh, "XenUtils.ChatNotifyManager.Refresh")
end

local function RemoveEvent(self)
	Command.Event.Detach(Event.Chat.Notify, self.Refresh, "XenUtils.ChatNotifyManager.Refresh")
end

local function Create()
	local Chat = {}
	Chat.eventsByID = {}
	Chat.eventsByMsg = {}
	Chat.eventID = 0

	Chat.Clear = Clear
	Chat.AddCallback = AddCallback
	Chat.RemoveCallback = RemoveCallback
	Chat.AddEvent = AddEvent
	Chat.RemoveEvent = RemoveEvent
	
	Chat.Refresh = function(h, a) Refresh(Chat, a) end
	
	return Chat
end

XenUtils = XenUtils or {}
XenUtils.CreateChatNotify = Create
