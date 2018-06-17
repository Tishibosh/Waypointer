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
XenUtils.Utils = {}

--
-- Main functions
--

function XenUtils.Utils.ArrayInsert(tab, arrayName, item)
	if not tab[arrayName] then
		tab[arrayName] = {}
	end
	
	table.insert(tab[arrayName], item)
end

function XenUtils.Utils.GetValue(value, default)
	if value ~= nil then
		return value
	else
		return default
	end
end

-- This function was taken from http://lua-users.org/wiki/StringTrim
function XenUtils.Utils.Trim(s)
  return s:match'^%s*(.*%S)' or ''
end

-- This function was taken from http://lua-users.org/wiki/SplitJoin
function XenUtils.Utils.Split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
		table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

-- This function is from http://lua-users.org/wiki/LuaXml
local function ParseXMLArgs(s)
  local arg = {}
  string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
    arg[w] = a
  end)
  return arg
end

-- This function is from http://lua-users.org/wiki/LuaXml
function XenUtils.Utils.ParseXMLString(s)
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, {label=label, xarg=ParseXMLArgs(xarg), empty=1})
    elseif c == "" then   -- start tag
      top = {label=label, xarg=ParseXMLArgs(xarg)}
      table.insert(stack, top)   -- new level
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[#stack].label)
  end
  return stack[1]
end

local function dumpTable(tab, level)
	for key, val in pairs(tab) do
		if type(val) == "table" then
			print (level .. ".  Key=" .. key .. " val is table")
			dumpTable(val, level + 1)
		else
			print (level .. ".  key=" .. key .. " val=" .. val)
		end
	end
end

function XenUtils.Utils.test()
	--local str = "<table><value key=\"key1\" type=\"bool\">true</value><value key=\"key 2\" type=\"number\">12</value><value key=\"key three\" type=\"table\"><table><value key=\"key1\" type=\"string\">String value</value></table></value></table>"
	local str = "<event warningName=\"AWAY\" eventType=\"7\"><scope isSolo=\"true\" inRaid=\"true\" inCombat=\"true\"/><health targetName=\"\" isLess=\"true\" pct=\"10\"><unitSpec>player</unitSpec></health></event>"
	local tab = XenUtils.Utils.ParseXMLString(str)
	dump(Utility.Serialize.Inline(tab) )
	--dumpTable(tab, 1)
	WarnMe.tempTable = tab

end

function XenUtils.Utils.Round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

