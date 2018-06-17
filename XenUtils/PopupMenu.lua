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

local function ShowHightlight(self, item)
	local margin = 0
	self.highlightItem = item
	self.highlightTop:SetPoint("TOPLEFT", item, "TOPLEFT", 0, -margin)
	self.highlightTop:SetPoint("TOPRIGHT", item, "TOPRIGHT", 0, -margin)
	self.highlightBottom:SetPoint("TOPLEFT", item, "BOTTOMLEFT", 0, margin)
	self.highlightBottom:SetPoint("TOPRIGHT", item, "BOTTOMRIGHT", 0, margin)
	self.highlightTop:SetVisible(true)
	self.highlightBottom:SetVisible(true)
	self.highlightItem:SetFontColor(1, 1, 1, 1)
end

local function HideHightlight(self, item)
	if item == self.highlightItem then
		self.highlightTop:SetVisible(false)
		self.highlightBottom:SetVisible(false)
		
		if item ~= nil then
			self.highlightItem:SetFontColor(0.8, 0.8, 0.8, 1)
			self.highlightItem = nil
		end
	end
end

local function SelectItem(self, item)
	self:Hide()
	
	if item.callback ~= nil and type(item.callback) == "function" then
		item.callback()
	end
end

local function SetItemEnabled(self, item, enabled)
	if enabled == true then
		item:SetFontColor(0.8, 0.8, 0.8, 1)
		item.Event.MouseIn = function() ShowHightlight(self, item) end
		item.Event.MouseOut = function() HideHightlight(self, item) end
		if type(item.callback) == "string" then
			item.Event.LeftClick = item.callback
			item.Event.LeftUp = function() SelectItem(self, item) end
		else
			item.Event.LeftClick = function() SelectItem(self, item) end
			item.Event.LeftUp = function() end
		end
	else
		HideHightlight(self, item)
		item:SetFontColor(0.5, 0.5, 0.5, 1)
		item.Event.MouseIn = function() end
		item.Event.MouseOut = function() end
		item.Event.LeftClick = function() end
	end
end

local function AddItem(self, text, callback)
	local item = UI.CreateFrame("Text", self.name .. ".item." .. (#self.items + 1), self)
	item.callback = callback

	local secureMode = self:GetSecureMode()
	if secureMode == "restricted" then
		item:SetSecureMode(secureMode)
	end

	item:SetText(text)
	item:SetMouseMasking("limited")
	SetItemEnabled(self, item, true)
	
	if #self.items == 0 then
		item:SetPoint("TOPLEFT", self, "TOPLEFT", 10, 5)
		item:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, 5)
	else
		item:SetPoint("TOPLEFT", self.items[#self.items], "BOTTOMLEFT", 0, 5)
		item:SetPoint("TOPRIGHT", self.items[#self.items], "BOTTOMRIGHT", 0, 5)
	end
	
	local height = item:GetBottom() - self:GetTop() + 5
	self:SetHeight(height)
	
	table.insert(self.items, item)
	return #self.items
end

local function EnableItem(self, itemNumber, enabled)
	local item = self.items[itemNumber]
	if item ~= nil then
		SetItemEnabled(self, item, enabled)
	end
end

local function SetItemCallback(self, itemNumber, callback)
	local item = self.items[itemNumber]
	if item ~= nil then
		item.callback = callback
	end
end

local function Show(self)
	local secureMode = self:GetSecureMode()
	if secureMode == "restricted" and Inspect.System.Secure() == true then
		return
	end

	local mouse = Inspect.Mouse()
	self:SetPoint("TOPLEFT", self.parent, "TOPLEFT", mouse.x, mouse.y)
	HideHightlight(self, self.highlightItem)
	self:SetVisible(true)
end

local function Hide(self)
	local secureMode = self:GetSecureMode()
	if secureMode == "restricted" and Inspect.System.Secure() == true then
		return
	end

	HideHightlight(self, self.highlightItem)
	self:SetVisible(false)
end

local function CreatePopupFrame(name, parent, width)
	local widget = UI.CreateFrame("Frame", name, parent)
	widget.name = name
	widget.parent = parent
	widget.items = {}
	
	local secureMode = parent:GetSecureMode()
	if secureMode == "restricted" then
		widget:SetSecureMode(secureMode)
	end
	
	widget:SetLayer(1000000)
	widget:SetVisible(false)
	widget:SetBackgroundColor(0, 0, 0, 1)
	widget:SetWidth(width)
	
	widget.topLeftTexture = UI.CreateFrame("Texture", name .. "topLeftTexture", widget)
	widget.topLeftTexture:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 0)
	widget.topLeftTexture:SetTexture("XenUtils", "Textures/PopupTopLeft.png")
	widget.topLeftTexture:SetLayer(widget:GetLayer() + 1)

	widget.topRightTexture = UI.CreateFrame("Texture", name .. "topRightTexture", widget)
	widget.topRightTexture:SetPoint("TOPRIGHT", widget, "TOPRIGHT", 0, 0)
	widget.topRightTexture:SetTexture("XenUtils", "Textures/PopupTopRight.png")
	widget.topRightTexture:SetLayer(widget:GetLayer() + 1)

	widget.bottomLeftTexture = UI.CreateFrame("Texture", name .. "bottomLeftTexture", widget)
	widget.bottomLeftTexture:SetPoint("BOTTOMLEFT", widget, "BOTTOMLEFT", 0, 0)
	widget.bottomLeftTexture:SetTexture("XenUtils", "Textures/PopupBottomLeft.png")
	widget.bottomLeftTexture:SetLayer(widget:GetLayer() + 1)

	widget.bottomRightTexture = UI.CreateFrame("Texture", name .. "bottomRightTexture", widget)
	widget.bottomRightTexture:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", 0, 0)
	widget.bottomRightTexture:SetTexture("XenUtils", "Textures/PopupBottomRight.png")
	widget.bottomRightTexture:SetLayer(widget:GetLayer() + 1)

	widget.topTexture = UI.CreateFrame("Texture", name .. "topTexture", widget)
	widget.topTexture:SetPoint("TOPLEFT", widget.topLeftTexture, "TOPRIGHT", 0, 0)
	widget.topTexture:SetPoint("TOPRIGHT", widget.topRightTexture, "TOPLEFT", 0, 0)
	widget.topTexture:SetTexture("XenUtils", "Textures/PopupTop.png")
	widget.topTexture:SetLayer(widget:GetLayer() + 1)

	widget.bottomTexture = UI.CreateFrame("Texture", name .. "bottomTexture", widget)
	widget.bottomTexture:SetPoint("BOTTOMLEFT", widget.bottomLeftTexture, "BOTTOMRIGHT", 0, 0)
	widget.bottomTexture:SetPoint("BOTTOMRIGHT", widget.bottomRightTexture, "BOTTOMLEFT", 0, 0)
	widget.bottomTexture:SetTexture("XenUtils", "Textures/PopupBottom.png")
	widget.bottomTexture:SetLayer(widget:GetLayer() + 1)

	widget.leftTexture = UI.CreateFrame("Texture", name .. "leftTexture", widget)
	widget.leftTexture:SetPoint("TOPLEFT", widget.topLeftTexture, "BOTTOMLEFT", 0, 0)
	widget.leftTexture:SetPoint("BOTTOMLEFT", widget.bottomLeftTexture, "TOPLEFT", 0, 0)
	widget.leftTexture:SetTexture("XenUtils", "Textures/PopupLeft.png")
	widget.leftTexture:SetLayer(widget:GetLayer() + 1)

	widget.rightTexture = UI.CreateFrame("Texture", name .. "rightTexture", widget)
	widget.rightTexture:SetPoint("TOPRIGHT", widget.topRightTexture, "BOTTOMRIGHT", 0, 0)
	widget.rightTexture:SetPoint("BOTTOMRIGHT", widget.bottomRightTexture, "TOPRIGHT", 0, 0)
	widget.rightTexture:SetTexture("XenUtils", "Textures/PopupRight.png")
	widget.rightTexture:SetLayer(widget:GetLayer() + 1)
	
	widget.highlightTop = UI.CreateFrame("Texture", name .. "highlightTop", widget)
	widget.highlightTop:SetTexture("XenUtils", "Textures/PopupHighlight.png")
	widget.highlightTop:SetLayer(widget:GetLayer() + 1)
	widget.highlightTop:SetVisible(false)
	
	widget.highlightBottom = UI.CreateFrame("Texture", name .. "highlightBottom", widget)
	widget.highlightBottom:SetTexture("XenUtils", "Textures/PopupHighlight.png")
	widget.highlightBottom:SetLayer(widget:GetLayer() + 1)
	widget.highlightBottom:SetVisible(false)
	
	return widget
end

local function Create(name, context, width)	
	local widget = CreatePopupFrame(name, context, width)
	
	-- Public interface
	widget.AddItem = AddItem
	widget.EnableItem = EnableItem
	widget.SetItemCallback = SetItemCallback
	widget.Show = Show
	widget.Hide = Hide
	
	return widget
end

XenUtils = XenUtils or {}
XenUtils.CreatePopupMenu = Create
