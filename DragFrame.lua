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
local addon, Waypointer = ...
Waypointer.DragFrame = {}

local function MouseDown(dragFrame)
	local mouse = Inspect.Mouse()
	dragFrame.x = dragFrame.frame:GetLeft()
	dragFrame.y = dragFrame.frame:GetTop()
	dragFrame.xOffset = dragFrame.x - mouse.x
	dragFrame.yOffset = dragFrame.y - mouse.y
	dragFrame.dragging = true
end

local function MouseMove(dragFrame, x, y)
	if dragFrame.dragging == true and dragFrame.enabled == true then
		dragFrame.x = x + dragFrame.xOffset
		dragFrame.y = y + dragFrame.yOffset
		if dragFrame.changedCallback then
			dragFrame.changedCallback(dragFrame)
		end
	end
end

local function MouseUp(dragFrame)
	dragFrame.dragging = false
end

function Waypointer.DragFrame.Create(parentFrame, width, height, changedCallback)
	local dragFrame = {}
	
	dragFrame.dragging = false
	dragFrame.enabled = true
	dragFrame.frame = UI.CreateFrame("Frame", "WaypointerDragFrame", parentFrame)
	dragFrame.frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT")
	dragFrame.frame:SetPoint("BOTTOMRIGHT", parentFrame, "TOPLEFT", width, height)
	dragFrame.width = width
	dragFrame.height = height
	dragFrame.changedCallback = changedCallback
	dragFrame.frame:SetMouseMasking("limited")
	dragFrame.frame.Event.RightUp = function () MouseUp(dragFrame) end
	dragFrame.frame.Event.RightUpoutside = function () MouseUp(dragFrame) end
	dragFrame.frame.Event.RightDown = function () MouseDown(dragFrame) end
	dragFrame.frame.Event.MouseMove = function (event, x, y) MouseMove(dragFrame, x, y) end
	
	return dragFrame
end

function Waypointer.DragFrame.SetEnabled(dragFrame, isEnabled)
	dragFrame.enabled = isEnabled
end
