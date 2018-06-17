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
local function OneOffHandler(self)
	local handler = self.oneOffHandler
	if handler ~= nil then
		local handlerFn = table.remove(handler, 1)
		if handlerFn ~= nil then
			handlerFn()
		else
			handler = nil
		end
	end
		
	if handler == nil then
		Command.Event.Detach(Event.System.Update.Begin, self.oneOffWrapperFn, "XenUtils_OneOffHandler_" .. self.name)
		self.oneOffHandler = nil
		self.oneOffWrapperFn = nil
	end
end

local function OneOffCallback(self, handlerFn)
	local handler = self.oneOffHandler
	if handler == nil then
		handler = {}
		self.oneOffHandler = handler
		self.oneOffWrapperFn = function() OneOffHandler(self) end
		Command.Event.Attach(Event.System.Update.Begin, self.oneOffWrapperFn, "XenUtils_OneOffHandler_" .. self.name)
	end
	
	table.insert(handler, handlerFn)
end

function StopHandler(self, handler)
	if handler ~= nil then
		Command.Event.Detach(Event.System.Update.Begin, handler.wrapperFn, "XenUtils.AsyncHandler." .. self.name .. "." .. handler.name)
		self.handlers[handler.name] = nil
		if handler.stopFn ~= nil then
			self:OneOffCallback(function() handler.stopFn(handler.stateTable) end)
		end
	end
end

local function AsyncHandlerFunction(self, handler)
	if handler.handlerFn(handler.stateTable) ~= true then
		self:StopHandler(handler)
	end
end

local function StartHandler(self, name, handlerFn, stateTable, stopFn)
	self.handlerCount = self.handlerCount + 1

	local handler = {}
	handler.stateTable = stateTable
	handler.name = name .. self.handlerCount
	handler.handlerFn = handlerFn
	handler.stopFn = stopFn
	handler.wrapperFn = function() AsyncHandlerFunction(self, handler) end
	
	self.handlers[handler.name] = handler
	Command.Event.Attach(Event.System.Update.Begin, handler.wrapperFn, "XenUtils.AsyncHandler." .. self.name .. "." .. handler.name)
	
	return handler
end

local function Create(name)
	local asyncHandler = {}
	asyncHandler.name = name
	asyncHandler.handlers = {}
	asyncHandler.handlerCount = 0
	
	-- Public interface
	asyncHandler.OneOffCallback = OneOffCallback
	asyncHandler.StartHandler = StartHandler
	asyncHandler.StopHandler = StopHandler
	
	return asyncHandler
end

XenUtils = XenUtils or {}
XenUtils.CreateAsyncHandler = Create
