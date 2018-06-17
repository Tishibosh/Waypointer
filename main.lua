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
Waypointer.name = "Waypointer"
Waypointer.slashName = "wp"
Waypointer.version = "0.1"
Waypointer.x = 500
Waypointer.y = 500
Waypointer.buttonX = 200
Waypointer.buttonY = 200
Waypointer.lang = "English"
Waypointer.isButtonShown = true
Waypointer.isButtonLocked = false
Waypointer.hideEmptyZones = false
Waypointer.saveUnknownQuests = false
Waypointer.ignoredQuests = {}
Waypointer.completedRepeatQuests = {}
Waypointer.questCoords = {}
Waypointer.unknownQuestCoords = {}
Waypointer.unknownQuestDetails = {}
Waypointer.startCount = 0
Waypointer.faction = "None"
Waypointer.player = "None"
Waypointer.IgnoreZone = "Ignored"

local REWARD_FILTER_TYPE = 1
local NOTORIETY_FILTER_TYPE = 2
local SCOPE_FILTER_TYPE = 3

--
-- Main functions
--


local function GetQuestLocationString(questId, x, z)
	return "|" .. questId .. "|" .. x .. "|" .. z
end

local function BroadcastSavedQuests()
	local block = 50
	local count = 1
	local locations = ""
	for questId, coordStr in pairs(Waypointer.questCoords) do
		if count >= block then
			Waypointer.AsyncHandler:OneOffCallback(function() BroadcastQuests(locations) end)
			count = 1
			locations = ""
		end

		local coords = XenUtils.Utils.Split(coordStr, ",")
		locations = locations .. GetQuestLocationString(questId, coords[1], coords[2])
		count = count + 1
	end
	
	if locations ~= "" then
		Waypointer.AsyncHandler:OneOffCallback(function() BroadcastQuests(locations) end)
	end

	Waypointer.lastSharedCoords = os.time()
end

local function InternalGetZoneName(zoneName, lang)
	if zoneName ~= nil then
		local internalZoneName = zoneName:gsub('%s%(%d+%)', '')
		
		if lang == "Francais" then
			if Waypointer.French2EnglishZoneMap[internalZoneName] ~= nil then
				return internalZoneName
			elseif Waypointer.FrenchZoneMap[internalZoneName] ~= nil then
				return Waypointer.FrenchZoneMap[internalZoneName]
			end
		elseif lang == "Deutsch" then
			if Waypointer.German2EnglishZoneMap[internalZoneName] ~= nil then
				return internalZoneName
			elseif Waypointer.GermanZoneMap[internalZoneName] ~= nil then
				return Waypointer.GermanZoneMap[internalZoneName]
			end
		else
			if Waypointer.FrenchZoneMap[internalZoneName] ~= nil then
				return internalZoneName
			elseif Waypointer.German2EnglishZoneMap[internalZoneName] ~= nil then
				return Waypointer.German2EnglishZoneMap[internalZoneName]
			elseif Waypointer.French2EnglishZoneMap[internalZoneName] ~= nil then
				return Waypointer.French2EnglishZoneMap[internalZoneName]
			end
		end
		
		return internalZoneName
	end
	
	return ""
end

local function GetZoneName(zoneName)
	return InternalGetZoneName(zoneName, Waypointer.lang)
end

local function GetEnglishZoneName(zoneName)
	return InternalGetZoneName(zoneName, "English")
end

local function GetQuestCoords(giver, questId)
	local coords = Waypointer.KnownQuestCoords[questId]
	if coords ~= nil then
		return coords
	end
	
	coords = Waypointer.questCoords[questId]
	if coords ~= nil then
		return coords
	end
	
	if giver ~= nil and giver.OriginalID ~= "0" and giver.Coords ~= nil then
		return giver.Coords
	end
	
	return ""
end

local function GetNPCText(questId, giverId)
	local giver = Waypointer.Givers[giverId]
	if giver == nil or giver.OriginalID == "0" then
		local coords = GetQuestCoords(giver, questId)
		if coords ~= nil and coords ~= "" then
			return " [" .. coords .. "]"
		else
			return ""
		end
	else
		local ret
		if Waypointer.lang == "Francais" then
			ret = "Début: " .. giver.French
		elseif Waypointer.lang == "Deutsch" then
			ret = "Start: " .. giver.German
		else
			ret = "Start: " .. giver.English
		end
		
		return ret .. " - " .. GetZoneName(giver.Zone) .. " [" .. GetQuestCoords(giver, questId) .. "]"
	end
end

local function GetQuestName(id)
	if Waypointer.lang == "Francais" then
		return Waypointer.Quests[id].French
	elseif Waypointer.lang == "Deutsch" then
		return Waypointer.Quests[id].German
	end
	
	return Waypointer.Quests[id].English
end

local function GetQuestText(id)
	local npc = GetNPCText(id, Waypointer.Quests[id].NPC)
	local ret = ""
	if Waypointer.Quests[id].LocType ~= "Never" then
		ret = Waypointer.Quests[id].LocType .. " location " .. npc .. "\n"
	elseif npc ~= "" then
		ret = npc .. "\n"
	end

	local desc
	if Waypointer.lang == "Francais" then
		desc = Waypointer.Quests[id].FrenchDescription
	elseif Waypointer.lang == "Deutsch" then
		desc = Waypointer.Quests[id].GermanDescription
	else
		desc = Waypointer.Quests[id].EnglishDescription
	end
	if desc == nil then
		desc = ""
	end
	
	if ret ~= "" or desc ~= "" then
		return ret .. desc
	else
		return "Empty"
	end
end

local function HideQuestPopup()
	if Inspect.System.Secure() ~= true then
		Waypointer.parentFrame.questPopupMenu:Hide()
	end
end

local function SetQuestText()
	local item = Waypointer.parentFrame.list:GetSelectedValue()
	if item == nil then
		Waypointer.parentFrame.quest:SetText(Waypointer.GetLocaleValue("Select Zone and Filter for descriptions"))
	else
		Waypointer.parentFrame.quest:SetText(GetQuestText(item))
	end

	HideQuestPopup()	
	Waypointer.parentFrame.ignoredPopupMenu:Hide()
end

local function IsWeeklyQuest(quest)
	if quest ~= nil and quest.LocType == "Weekly" then
		return true
	end
	
	return false
end

local function IsDailyQuest(quest)
	if quest ~= nil and quest.LocType == "Daily" then
		return true
	end
	
	return false
end

local function IsQuestLocType(quest)
	if IsWeeklyQuest(quest) or IsDailyQuest(quest) then
		return true
	end
	
	return false
end

local function IsQuestCompleted(quest)
	if quest.completed == true then
		local lastCompleted = Waypointer.completedRepeatQuests[quest.ID]
		if lastCompleted == nil then
			return true
		else
			if IsDailyQuest(quest) then
				if lastCompleted > Waypointer.resetDailyTime then
					return true
				end
			elseif IsWeeklyQuest(quest) then
				if lastCompleted > Waypointer.resetWeeklyTime then
					return true
				end				
			else
				return true
			end
		end
	end
	
	return false
end

local function IsQuestInFilter(quest, filterType, filterString, faction)
	if faction ~= "None" and faction ~= Waypointer.faction then
		return false
	end
	
	if filterString == "None - Show All" then
		return true
	end

	if filterString == "UnLocType" then
		return quest.LocType == "Never"
	end
	
	if filterString == "Confounding Contraption" then
		return quest.LocType == "Confounding Contraption"
	end
	
end

local function GetFilterType(englishFilter)
	local filterType = NOTORIETY_FILTER_TYPE
	if Waypointer.Scopes[englishFilter] ~= nil then
		filterType = SCOPE_FILTER_TYPE
	elseif Waypointer.Rewards[englishFilter] ~= nil then
		filterType = REWARD_FILTER_TYPE
	end
	
	return filterType
end

local function RedrawList()
	Waypointer.parentFrame.list:SetItems({})
	local zoneName = GetEnglishZoneName(Waypointer.parentFrame.select:GetSelectedItem())
	if zoneName ~= nil and Waypointer.ZoneQuestMap[zoneName] ~= nil then
		local englishFilter = Waypointer.GetEnglishValue(Waypointer.parentFrame.filter:GetSelectedItem())
		
		local filterType = GetFilterType(englishFilter)
		local questNames = {}
		local items = {}
		local values = {}
		for _, id in ipairs(Waypointer.ZoneQuestMap[zoneName]) do
			local quest = Waypointer.Quests[id]
			if quest ~= nil then
				if IsQuestCompleted(quest) == false and IsQuestInFilter(quest, filterType, englishFilter, quest.Faction) == true then
					local name = GetQuestName(id)
					if questNames[name] == nil then
						questNames[name] = 1
						table.insert(items, name)
						values[name] = id
					end
				end
			end
		end
		
		table.sort(items)
		
		local questIds = {}
		for _, name in ipairs(items) do
			table.insert(questIds, values[name])
		end

		Waypointer.parentFrame.list:SetItems(items, questIds)
		if #items == 1 then
			Waypointer.parentFrame.list:SetSelectedItem(items[1])
		else
			SetQuestText()
		end
	else
		SetQuestText()
	end
end

local function CountCompletedZoneQuests(questIds)
	local count = 0
	local totalCount = 0
	if questIds ~= nil then
		local englishFilter = Waypointer.GetEnglishValue(Waypointer.parentFrame.filter:GetSelectedItem())
		local filterType = GetFilterType(englishFilter)
		for _, questId in ipairs(questIds) do
			if questId ~= nil and Waypointer.Quests[questId] ~= nil then
				local faction = Waypointer.Quests[questId].Faction
				if IsQuestInFilter(Waypointer.Quests[questId], filterType, englishFilter, faction) == true then
					if IsQuestCompleted(Waypointer.Quests[questId]) == false then
						count = count + 1
					end
				
					totalCount = totalCount + 1
				end
			end			
		end
	end
	
	return count, totalCount
end

local function RedrawZoneNames()
	local selectedZone = GetEnglishZoneName(Waypointer.parentFrame.select:GetSelectedItem())

	local items = {}
	for name, questIds in pairs(Waypointer.ZoneQuestMap) do
		local count = CountCompletedZoneQuests(questIds)
		local zoneName = GetZoneName(name)
		if (zoneName ~= "") then
			if Waypointer.hideEmptyZones ~= true or count > 0 then
				local zoneName = zoneName .. " (" .. count .. ")"
				if name == selectedZone then
					selectedZone = zoneName
				end
				
				table.insert(items, zoneName)
			end
		end
	end
	
	table.sort(items)
	Waypointer.parentFrame.select:SetItems(items)
	Waypointer.parentFrame.select:SetSelectedItem(selectedZone)
end

local function GetZoneTooltip()
	local tip = ""
	
	local playerDetails = Inspect.Unit.Detail("player")
	if playerDetails ~= nil and playerDetails.zone ~= nil then
		local zoneDetails = Inspect.Zone.Detail(playerDetails.zone)
		if zoneDetails ~= nil and zoneDetails.name ~= nil then
			local zoneName = GetEnglishZoneName(zoneDetails.name)
			local questIds = Waypointer.ZoneQuestMap[zoneName]
			if questIds ~= nil then
				local count, totalCount = CountCompletedZoneQuests(questIds)
				tip = zoneDetails.name .. " " .. count .. " out of " .. totalCount
			end
		end
	end
	
	return tip
end

local function SelectCurrentZone()
	local playerDetails = Inspect.Unit.Detail("player")
	if playerDetails ~= nil and playerDetails.zone ~= nil then
		local zone = Inspect.Zone.Detail(playerDetails.zone)
		if zone ~= nil and zone.name ~= nil then
			local currentZoneName = GetZoneName(zone.name)
			local items = Waypointer.parentFrame.select:GetItems()
			for _, zoneName in ipairs(items) do
				if GetZoneName(zoneName) == currentZoneName then
					Waypointer.parentFrame.select:SetSelectedItem(zoneName)
				end
			end
		end
	end
end

local function RedrawLabels()
	Waypointer.parentFrame.label:SetText(Waypointer.GetLocaleValue("Zone"))
	Waypointer.parentFrame.filterLabel:SetText(Waypointer.GetLocaleValue("Filter"))
	Waypointer.parentFrame.langLabel:SetText(Waypointer.GetLocaleValue("Language"))
	Waypointer.parentFrame.quest:SetText(Waypointer.GetLocaleValue("Select quest to see description"))
	Waypointer.parentFrame.showButtonCheck:SetText(Waypointer.GetLocaleValue("Show icon button"))
	Waypointer.parentFrame.lockButtonCheck:SetText(Waypointer.GetLocaleValue("Lock icon button"))
	Waypointer.parentFrame.hideZoneCheck:SetText(Waypointer.GetLocaleValue("Hide zones with no quests"))
	Waypointer.parentFrame.coordLabel:SetText(Waypointer.GetLocaleValue("Unlisted Locations"))
end

local function ZoneSelected()
	RedrawList()
end

local function BuildFilterList()
	local defaultValue = Waypointer.GetLocaleValue("None - Show All")
	local filters = {}
	table.insert(filters, defaultValue)
	table.insert(filters, Waypointer.GetLocaleValue("Confounding Contraption"))
	table.insert(filters, Waypointer.GetLocaleValue("Puzzle"))
	table.insert(filters, Waypointer.GetLocaleValue("Rare"))
	table.insert(filters, Waypointer.GetLocaleValue("QuestMob"))
	
	
	if Waypointer.Scopes == nil then
		local scopeMap = {}
		scopeMap[Waypointer.GetEnglishValue("Story")] = 1
		scopeMap[Waypointer.GetEnglishValue("Saga")] = 1
		
		Waypointer.Scopes = scopeMap
	end
	
	if Waypointer.Rewards == nil then
		local rewardMap = {}
		local count = 0
		for _, name in ipairs(filters) do
			if count > 1 then
				local key = Waypointer.GetEnglishValue(name)
				if Waypointer.Scopes[key] == nil then
					rewardMap[key] = 1
				end
			end
			
			count = count + 1
		end
		
		Waypointer.Rewards = rewardMap
	end
	
	if Waypointer.Factions == nil then
		local factions = {}
		for _, entry in pairs(Waypointer.Quests) do
			if entry.Notoriety ~= nil then
				for notoriety, _ in pairs(entry.Notoriety) do
					factions[notoriety] = 1
				end
			end
			
			if entry.RepeatNotoriety ~= nil then
				for notoriety, _ in pairs(entry.RepeatNotoriety) do
					factions[notoriety] = 1
				end
			end
		end
		
		Waypointer.Factions = factions
	end
	
	local factions = {}
	for faction, _ in pairs(Waypointer.Factions) do
		table.insert(factions, Waypointer.GetLocaleValue(faction))
	end
	
	table.sort(factions)
	for _, faction in ipairs(factions) do
		table.insert(filters, faction)
	end
	
	Waypointer.parentFrame.filter:SetItems(filters)
	Waypointer.parentFrame.filter:SetSelectedItem(defaultValue)
end

local function FilterSelected()
	RedrawZoneNames()
	RedrawList()
	SetQuestText()
end

local function EnsureFrameOnScreen(frame, x, y)
	local screenWidth = UIParent:GetWidth()
	local screenHeight = UIParent:GetHeight()
	
	local newX = x
	local newY = y

	if newX + frame:GetWidth() > screenWidth then
		newX = screenWidth - frame:GetWidth()
	end
	
	if newY + frame:GetHeight() > screenHeight then
		newY = screenHeight - frame:GetHeight()
	end
	
	if newX < 0 then
		newX = 0
	end
	
	if newY < 0 then
		newY = 0
	end
	
	frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", newX, newY)
	return newX, newY
end

local function SetButtonCoords(x, y)
	local newX, newY = EnsureFrameOnScreen(Waypointer.button, x, y)
	Waypointer.buttonX = newX
	Waypointer.buttonY = newY
	Waypointer.button:SetPoint("TOPLEFT", UIParent, "TOPLEFT", Waypointer.buttonX, Waypointer.buttonY)
end

local function EnsureOnScreen()
	EnsureFrameOnScreen(Waypointer.button, Waypointer.button:GetLeft(), Waypointer.button:GetTop())
	EnsureFrameOnScreen(Waypointer.parentFrame, Waypointer.parentFrame:GetLeft(), Waypointer.parentFrame:GetTop())
end

local function GetQuestIDString(originalID)
	return string.sub(originalID, 1, 9)
end

local function UpdatedCompletedLocType(quests)
	local changed = false
	if quests ~= nil then
		for id, _ in pairs(quests) do
			local questId = GetQuestIDString(id)
			local quest = Waypointer.Quests[questId]
			if quest ~= nil then
				if IsQuestCompleted(quest) ~= true then
					changed = true
					
					if IsQuestLocType(quest) == true then
						Waypointer.completedRepeatQuests[questId] = Inspect.Time.Server()
						quest.completed = true
					end
				end
				
			end
		end
	end
end

local function UpdatedCompleted(quests)
	local changed = false
	if quests ~= nil then
		for id, _ in pairs(quests) do
			local questId = GetQuestIDString(id)
			local quest = Waypointer.Quests[questId]
			if quest ~= nil then
				if IsQuestCompleted(quest) ~= true then
					changed = true
					
					if IsQuestLocType(quest) ~= true then
						quest.completed = true
					end
				end
				
			end
		end
	end

	RedrawZoneNames()
end

local function RefreshCompleted()
	local quests = Inspect.Quest.Complete()
	UpdatedCompleted(quests)
end

local function SetResetTimes()
	local st = Inspect.Time.Server()
	local serverTable = os.date("*t", st)
	serverTable.hour = 4
	serverTable.min = 0
	serverTable.sec = 0
	Waypointer.resetDailyTime = os.time(serverTable)
	
	if serverTable.wday >= 4 then
		local offset = (serverTable.wday - 4) * 24 * 60 * 60
		Waypointer.resetWeeklyTime = Waypointer.resetDailyTime - offset
	else
		local offset = (3 + serverTable.wday) * 24 * 60 * 60
		Waypointer.resetWeeklyTime = Waypointer.resetDailyTime - offset
	end
end

local function GetPlayerCoords()
	local playerDetail = Inspect.Unit.Detail("player")
	if playerDetail ~= nil then
		return math.floor(playerDetail.coordX), math.floor(playerDetail.coordZ)
	end
	
	return nil, nil
end

local function SaveQuestCoords(questId, x, z)
	if questId ~= nil and x ~= nil and z ~= nil and Waypointer.KnownQuestCoords[questId] == nil and Waypointer.questCoords[questId] == nil then
		Waypointer.questCoords[questId] = x .. "," .. z
		return true
	end
	
	return false
end

local function SaveUnknownQuestCoords(questId, id, x, z)
	if questId ~= nil and x ~= nil and z ~= nil and Waypointer.unknownQuestCoords[questId] == nil then
		Waypointer.unknownQuestCoords[questId] = id .. "|" .. x .. "|" .. z
		return true
	end
	
	return false
end

local function CleanQuestCoords()
	local cleanUpTable = {}
	
	local unknownCleanupTable = {}
	if Waypointer.unknownQuestCoords ~= nil then
		for questId, unknownCoords in pairs(Waypointer.unknownQuestCoords) do
			if Waypointer.KnownQuestCoords[questId] ~= nil then
				table.insert(unknownCleanupTable, questId)
			elseif Waypointer.Quests[questId] ~= nil and Waypointer.questCoords ~= nil then
				local dataParts = XenUtils.Utils.Split(unknownCoords, "|")
				if dataParts ~= nil then
					Waypointer.questCoords[questId] = dataParts[2] .. "," .. dataParts[3]
					table.insert(unknownCleanupTable, questId)
				end
			end
		end
	end
	
	for _, questId in ipairs(unknownCleanupTable) do
		Waypointer.unknownQuestCoords[questId] = nil
	end
	
	if Waypointer.questCoords ~= nil then
		for questId, _ in pairs(Waypointer.questCoords) do
			if Waypointer.KnownQuestCoords[questId] ~= nil then
				table.insert(cleanUpTable, questId)
			end
		end
	end
	
	for _, questId in ipairs(cleanUpTable) do
		Waypointer.questCoords[questId] = nil
	end
	
	local unknownQuestCleanupTable = {}
	if Waypointer.unknownQuestDetails ~= nil then
		for questId, _ in pairs(Waypointer.unknownQuestDetails) do
			if Waypointer.Quests[questId] ~= nil then
				table.insert(unknownQuestCleanupTable, questId)
			end
		end
	end
	
	for _, questId in ipairs(unknownQuestCleanupTable) do
		Waypointer.unknownQuestDetails[questId] = nil
	end
end

local function StoreUnknownQuestDetails(questId, originalID)
	if Waypointer.unknownQuestDetails ~= nil and Waypointer.unknownQuestDetails[questId] == nil then
		local args = {}
		args[originalID] = true
		local questDetails = Inspect.Quest.Detail(args)
		if questDetails ~= nil and questDetails[originalID] ~= nil then
			local questTab = {
				ID = questId,
				OriginalID = originalID,
				LocType = "Never",
				Faction = "None",
				Notoriety = { },
				RepeatNotoriety = { },
				LevelRange = "65-70",
				Rewards = { },
				RepeatRewards = { },
				NPC = "n00000000",
				Scope = { },
				completed = false
			}
			
			local dets = questDetails[originalID]
			questTab.English = dets.name
			questTab.French = dets.name
			questTab.German = dets.name
			questTab.Zone = dets.categoryName
			questTab.EnglishDescription = dets.summary
			questTab.FrenchDescription = dets.summary
			questTab.GermanDescription = dets.summary
			
			Waypointer.unknownQuestDetails[questId] = questTab
		end
	end
end

local function QuestAccepted(h, quests)
	if quests ~= nil then
		for id, _ in pairs(quests) do
			local questId = GetQuestIDString(id)
			local quest = Waypointer.Quests[questId]
			if quest ~= nil then
				local x, z = GetPlayerCoords()
				local saved = SaveQuestCoords(questId, x, z)
				if saved == true then
					local locationString = GetQuestLocationString(questId, x, z)
					BroadcastQuests(locationString)
				end
			elseif Waypointer.saveUnknownQuests == true then
				local x, z = GetPlayerCoords()
				local saved = SaveUnknownQuestCoords(questId, id, x, z)
				StoreUnknownQuestDetails(questId, id)
			end
		end
	end
end

local function QuestComplete(h, questTable)
	SetResetTimes()
	UpdatedCompletedLocType(questTable)
	RefreshCompleted()
	if Waypointer.parentFrame:GetVisible() == true then
		RedrawList()
	end
end

local function SaveVariables(h, addon)
	if addon == Waypointer.name then
		-- now copy saved group to settings so that they can be preserved on logout
		Waypointer_SavedVariables = {}
		Waypointer_SavedVariables.version = Waypointer.version
		Waypointer_SavedVariables.x = Waypointer.parentFrame:GetLeft()
		Waypointer_SavedVariables.y = Waypointer.parentFrame:GetTop()
		Waypointer_SavedVariables.buttonX = Waypointer.buttonX
		Waypointer_SavedVariables.buttonY = Waypointer.buttonY
		Waypointer_SavedVariables.lang = Waypointer.lang
		Waypointer_SavedVariables.isButtonShown = Waypointer.isButtonShown
		Waypointer_SavedVariables.isButtonLocked = Waypointer.isButtonLocked
		Waypointer_SavedVariables.hideEmptyZones = Waypointer.hideEmptyZones
		Waypointer_SavedVariables.saveUnknownQuests = Waypointer.saveUnknownQuests
		
		CleanQuestCoords()
		Waypointer_SavedVariables.questCoords = Waypointer.questCoords
		Waypointer_SavedVariables.lastSharedCoords = Waypointer.lastSharedCoords
		if Waypointer.saveUnknownQuests ~= true then
			Waypointer_SavedVariables.unknownQuestCoords = {}
			Waypointer_SavedVariables.unknownQuestDetails = {}
		else
			Waypointer_SavedVariables.unknownQuestCoords = Waypointer.unknownQuestCoords
			Waypointer_SavedVariables.unknownQuestDetails = Waypointer.unknownQuestDetails
		end
		
		Waypointer_SavedVariables.unknownZoneMap = nil
		
		Waypointer_SavedCharacterVariables = {}
		Waypointer_SavedCharacterVariables.ignoredQuests = Waypointer.ignoredQuests
		Waypointer_SavedCharacterVariables.completedRepeatQuests = Waypointer.completedRepeatQuests
	end
end

local function ToggleVisibility()
	if Waypointer.parentFrame:GetVisible() == true then
		Waypointer.parentFrame:SetVisible(false)
	else
		EnsureOnScreen()
		SelectCurrentZone()
		RedrawList()
		Waypointer.parentFrame:SetVisible(true)
	end
end

local function SlashHandler(h, args)
	if args == "share" then
		BroadcastSavedQuests()
		BroadcastMessage("ShareQuestLocations")
	elseif args == "soundoff" then
		Waypointer.printVersions = true
		BroadcastMessage("SoundOff")
	else
		ToggleVisibility()
	end
end

local function IgnoreQuest(id)
	if id ~= nil and Waypointer.ignoredQuests[id] == nil then
		local zone = InternalIgnoreQuest(id)
		if zone ~= nil then
			Waypointer.ignoredQuests[id] = zone
			RedrawZoneNames()
			RedrawList()
		end
	end
end

local function InternalIgnoreQuest(id)
	if id ~= nil then
		local quest = Waypointer.Quests[id]
		if quest ~= nil then
			local zoneMap = Waypointer.ZoneQuestMap[quest.Zone]
			if zoneMap ~= nil then
				local found = nil
				for indx, questId in ipairs(zoneMap) do
					if questId == id then
						found = indx
						break
					end
				end
				
				if found ~= nil then
					table.remove(zoneMap, found)
					table.insert(Waypointer.ZoneQuestMap[Waypointer.IgnoreZone], id)
					return quest.Zone
				end
			end
		end
	end
end

local function IgnoreQuest(id)
	if id ~= nil and Waypointer.ignoredQuests[id] == nil then
		local zone = InternalIgnoreQuest(id)
		if zone ~= nil then
			Waypointer.ignoredQuests[id] = zone
			RedrawZoneNames()
			RedrawList()
		end
	end
end

local function IgnoreQuests()
	for id, _ in pairs(Waypointer.ignoredQuests) do
		InternalIgnoreQuest(id)
	end
end

local function RestoreQuest(id)
	if id ~= nil then
		local zone = Waypointer.ignoredQuests[id]
		if zone ~= nil then
			local zoneMap = Waypointer.ZoneQuestMap[zone]
			if zoneMap ~= nil then
				table.insert(zoneMap, id)
			end
			
			local zoneMap = Waypointer.ZoneQuestMap[Waypointer.IgnoreZone]
			if zoneMap ~= nil then
				local found = nil
				for indx, questId in ipairs(zoneMap) do
					if questId == id then
						found = indx
						break
					end
				end
				
				if found ~= nil then
					table.remove(zoneMap, found)
				end
			end
		end
		
		Waypointer.ignoredQuests[id] = nil
		RedrawZoneNames()
		RedrawList()
	end
end

local function MessageHandler(h, from, messageType, channel, identifier, data)
	if identifier ~= "Waypointer" or from == Waypointer.player then
		return
	end
	
	local dataParts = XenUtils.Utils.Split(data, "|")
	if dataParts ~= nil then
		if dataParts[1] == "QuestLocations" then
		--print("Receiving")
			local indx = 2
			while indx < (#dataParts - 1) do
				questId = dataParts[indx]
				x = tonumber(dataParts[indx+1])
				z = tonumber(dataParts[indx+2])

				local quest = Waypointer.Quests[questId]
				if quest ~= nil then
					SaveQuestCoords(questId, x, z)
				end
				
				indx = indx + 3
			end
		elseif dataParts[1] == "ShareQuestLocations" then
		--print("Sharing")
			BroadcastSavedQuests()
		elseif dataParts[1] == "SoundOff" then
			BroadcastMessage("Version|" .. Waypointer.version .. "|" .. Waypointer.player)
		elseif dataParts[1] == "Version" then
			if Waypointer.printVersions == true then
				print(data)
			end
		end
	end
end

local function RegisterPostStartupEvents()
	Command.Event.Attach(Command.Slash.Register(Waypointer.slashName), SlashHandler, "Waypointer.SlashHandler")
	Command.Event.Attach(Event.Addon.SavedVariables.Save.Begin, SaveVariables, "Waypointer.SaveVariables")
	Command.Event.Attach(Event.Quest.Complete, QuestComplete, "Waypointer.QuestComplete")
	Command.Event.Attach(Event.Quest.Accept, QuestAccepted, "Waypointer.QuestAccepted")
	Command.Event.Attach(Event.Message.Receive, MessageHandler, "Waypointer.MessageHandler")
	Command.Message.Accept(nil, "Waypointer")
end

local function BuildZoneMaps()
	Waypointer.French2EnglishZoneMap = {}
	for english, french in pairs(Waypointer.FrenchZoneMap) do
		Waypointer.French2EnglishZoneMap[french] = english
	end
	
	Waypointer.German2EnglishZoneMap = {}
	for english, german in pairs(Waypointer.GermanZoneMap) do
		Waypointer.German2EnglishZoneMap[german] = english
	end
end

local function HideSettings()
	Waypointer.parentFrame.settingsFrame:SetVisible(false)
	
	Waypointer.isButtonShown = Waypointer.parentFrame.showButtonCheck:GetChecked()
	Waypointer.isButtonLocked = Waypointer.parentFrame.lockButtonCheck:GetChecked()
	Waypointer.hideEmptyZones = Waypointer.parentFrame.hideZoneCheck:GetChecked()
	Waypointer.lang = Waypointer.parentFrame.langSelect:GetSelectedItem()
	Waypointer.parentFrame.coordText:SetKeyFocus(false)

	
	Waypointer.button:SetVisible(Waypointer.isButtonShown)
	Waypointer.DragFrame.SetEnabled(Waypointer.dragFrame, not Waypointer.isButtonLocked)
	
	Waypointer.SetLocale()
	RedrawLabels()
	BuildFilterList()
	RedrawZoneNames()
	RedrawList()
	SetQuestText()
	
	Waypointer.parentFrame.mainFrame:SetVisible(true)
end

local function Startup()
	if Waypointer.startup == true then
		local quests = Inspect.Quest.Complete()
		if quests == nil then
			return true
		end
		
		local playerDetails = Inspect.Unit.Detail("player")
		if playerDetails == nil or playerDetails.alliance == nil or playerDetails.name == nil then
			return true
		end
		
		Waypointer.player = playerDetails.name
		
		if playerDetails.alliance == "guardian" or playerDetails.alliance == "Guardian" then
			Waypointer.faction = "Guardian"
		else
			Waypointer.faction = "Defiant"
		end
		
		SetButtonCoords(Waypointer.buttonX, Waypointer.buttonY)
		
		SetResetTimes()
		
		IgnoreQuests()
		
		CleanQuestCoords()
		
		BuildZoneMaps()
		
		BuildFilterList()
		
		UpdatedCompleted(quests)
		
		Waypointer.startup = false

		HideSettings()
		
		RegisterPostStartupEvents()
		
		local currentTime = os.time()
		if Waypointer.lastSharedCoords == nil or Waypointer.lastSharedCoords + (60 * 60 * 24 * 7) < currentTime then
			BroadcastSavedQuests()
		end
	end
	
	return false
end

local function GetQuestCoordList()
	local coordList = ""
	for id, coords in pairs(Waypointer.questCoords) do
		coordList = coordList .. id .. " = " .. coords .. "\n"
	end
	
	return coordList
end

local function ShowSettings()
	Waypointer.parentFrame.mainFrame:SetVisible(false)
	
	Waypointer.parentFrame.showButtonCheck:SetChecked(Waypointer.isButtonShown)
	Waypointer.parentFrame.lockButtonCheck:SetChecked(Waypointer.isButtonLocked)
	Waypointer.parentFrame.hideZoneCheck:SetChecked(Waypointer.hideEmptyZones)
	Waypointer.parentFrame.langSelect:SetSelectedItem(Waypointer.lang)
	Waypointer.parentFrame.coordText:SetText(GetQuestCoordList())
	
	Waypointer.parentFrame.settingsFrame:SetVisible(true)
end

local function ToggleSettings()
	if Waypointer.parentFrame.mainFrame:GetVisible() == true then
		ShowSettings()
	else
		HideSettings()
	end
end

local function LangSelected(item)
	Waypointer.lang = item
	Waypointer.SetLocale()
	RedrawLabels()
end

local function ShowQuestPopup(Waypointer, WaypointerWindow)
	if Inspect.System.Secure() ~= true then
		local id = WaypointerWindow.list:GetSelectedValue()
		if id ~= nil then
			local quest = Waypointer.Quests[id]
			if quest ~= nil then
				local englishZoneName = GetEnglishZoneName(WaypointerWindow.select:GetSelectedItem())
				if englishZoneName == Waypointer.IgnoreZone then
					WaypointerWindow.ignoredPopupMenu:Show()
				else
					local giver = Waypointer.Givers[quest.NPC]
					local questCoords = GetQuestCoords(giver, id)
					local questWorld = Waypointer.ZoneWorldMap[englishZoneName]
					local thisWorld = ""
					if questWorld ~= nil and questCoords ~= "" then
						local playerDetail = Inspect.Unit.Detail("player")
						if playerDetail ~= nil and playerDetail.zone ~= nil then
							local zoneDetail = Inspect.Zone.Detail(playerDetail.zone)
							if zoneDetail ~= nil then
								local thisZone = GetEnglishZoneName(zoneDetail.name)
								if thisZone ~= nil then
									thisWorld = Waypointer.ZoneWorldMap[thisZone]
								end
							end
						end
					end
					
					if questWorld ~= nil and questWorld == thisWorld then
						local coords = XenUtils.Utils.Split(questCoords, ",")
						
						if coords ~= nil and #coords == 2 then 
							WaypointerWindow.questPopupMenu:SetItemCallback(WaypointerWindow.questPopupMenu.markItem, "setwaypoint " .. coords[1] .. " " .. coords[2])
							WaypointerWindow.questPopupMenu:EnableItem(WaypointerWindow.questPopupMenu.markItem, true)
						else
							WaypointerWindow.questPopupMenu:EnableItem(WaypointerWindow.questPopupMenu.markItem, false)
						end
					else
						WaypointerWindow.questPopupMenu:EnableItem(WaypointerWindow.questPopupMenu.markItem, false)
					end
					
					WaypointerWindow.questPopupMenu:Show()
				end
			end
		end
	end
 end

local function Create()
	local margin = 5
	local parent = UI.CreateContext(Waypointer.name .. "Context")
	local WaypointerWindow = UI.CreateFrame("SimpleWindow", "WaypointerWindow", parent)
	WaypointerWindow:SetVisible(false)
	WaypointerWindow:SetCloseButtonVisible(true)
	WaypointerWindow:SetTitle("Waypointer")
	WaypointerWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT", Waypointer.x, Waypointer.y)
	WaypointerWindow:SetWidth(450)
	WaypointerWindow.settingsButton = UI.CreateFrame("Texture", "WaypointerSettingsButton", WaypointerWindow)
	WaypointerWindow.settingsButton:SetTexture(Waypointer.name, "SettingsButton32.png")
	WaypointerWindow.settingsButton:SetPoint("TOPLEFT", WaypointerWindow, "TOPLEFT", 10, 18)
	local settingsButtonGlow = UI.CreateFrame("Texture", "WaypointerSettingsButton", WaypointerWindow.settingsButton)
	settingsButtonGlow:SetTexture(Waypointer.name, "SettingsButtonGlow32.png")
	settingsButtonGlow:SetAllPoints(WaypointerWindow.settingsButton)
	settingsButtonGlow:SetVisible(false)
	WaypointerWindow.settingsButton:SetMouseMasking("limited")
	WaypointerWindow.settingsButton.Event.LeftClick = function() ToggleSettings() end
	WaypointerWindow.settingsButton.Event.MouseIn = function() settingsButtonGlow:SetVisible(true) end
	WaypointerWindow.settingsButton.Event.MouseOut = function() settingsButtonGlow:SetVisible(false) end
	
	WaypointerWindow.mainFrame = UI.CreateFrame("Frame", "WaypointerMainFrame", WaypointerWindow:GetContent())
	WaypointerWindow.mainFrame:SetAllPoints()
	
	WaypointerWindow.label = UI.CreateFrame("Text", "WaypointerLabel", WaypointerWindow.mainFrame)
	WaypointerWindow.label:SetPoint("TOPLEFT", WaypointerWindow.mainFrame, "TOPLEFT", margin, margin)
	WaypointerWindow.select = UI.CreateFrame("SimpleSelect", "WaypointerSelect", WaypointerWindow.mainFrame)
	WaypointerWindow.select:SetPoint("TOPLEFT", WaypointerWindow.label, "BOTTOMLEFT", 0, margin)
	WaypointerWindow.select:SetWidth(200)
	WaypointerWindow.select:SetHeight(19)
	WaypointerWindow.select:SetItems({})
	WaypointerWindow.select.Event.ItemSelect = function(view, item) ZoneSelected(item) end
	
	WaypointerWindow.filterLabel = UI.CreateFrame("Text", "WaypointerFilterLabel", WaypointerWindow.mainFrame)
	WaypointerWindow.filterLabel:SetPoint("TOPRIGHT", WaypointerWindow.mainFrame, "TOPRIGHT", -margin, margin)
	WaypointerWindow.filter = UI.CreateFrame("SimpleSelect", "WaypointerFilter", WaypointerWindow.mainFrame)
	WaypointerWindow.filter:SetPoint("TOPRIGHT", WaypointerWindow.filterLabel, "BOTTOMRIGHT", 0, margin)
	WaypointerWindow.filter:SetWidth(200)
	WaypointerWindow.filter:SetHeight(19)
	WaypointerWindow.filter:SetItems({})
	WaypointerWindow.filter.Event.ItemSelect = function(view, item) FilterSelected(item) end
	
	WaypointerWindow.questScrollView = UI.CreateFrame("SimpleScrollView", "WaypointerScrollView", WaypointerWindow.mainFrame)
	WaypointerWindow.questScrollView:SetPoint("TOPLEFT", WaypointerWindow.mainFrame, "BOTTOMLEFT", margin, -margin-122)
	WaypointerWindow.questScrollView:SetPoint("BOTTOMRIGHT", WaypointerWindow.mainFrame, "BOTTOMRIGHT", -margin, -margin)
	WaypointerWindow.questScrollView:SetBorder(1, 1, 1, 1, 1)
	WaypointerWindow.quest = UI.CreateFrame("Text", "WaypointerQuest", WaypointerWindow.mainFrame)
	WaypointerWindow.quest:SetWordwrap(true)
	WaypointerWindow.quest:SetHeight(200)
	WaypointerWindow.questScrollView:SetContent(WaypointerWindow.quest)

	WaypointerWindow.listScrollView = UI.CreateFrame("SimpleScrollView", "WaypointerScrollView", WaypointerWindow.mainFrame)
	WaypointerWindow.listScrollView:SetPoint("TOPLEFT", WaypointerWindow.select, "BOTTOMLEFT", 0, margin)
	WaypointerWindow.listScrollView:SetPoint("BOTTOMRIGHT", WaypointerWindow.questScrollView, "TOPRIGHT", 0, -margin)
	WaypointerWindow.listScrollView:SetBorder(1, 1, 1, 1, 1)
	WaypointerWindow.list = UI.CreateFrame("SimpleList", "WaypointerList", WaypointerWindow.listScrollView)
	WaypointerWindow.list:SetItems({})
	WaypointerWindow.list.Event.ItemSelect = function(view, item, quest) SetQuestText() end
	WaypointerWindow.listScrollView:SetContent(WaypointerWindow.list)
	
	local restrictedParent = UI.CreateContext(Waypointer.name .. "RestrictedContext")
	restrictedParent:SetSecureMode("restricted")
	restrictedParent:SetStrata("topmost")
	WaypointerWindow.questPopupMenu = XenUtils.CreatePopupMenu("QuestPopup", restrictedParent, 130)
	WaypointerWindow.questPopupMenu.markItem = WaypointerWindow.questPopupMenu:AddItem(Waypointer.GetLocaleValue("Mark quest start"), "setwaypoint 3000 4000")
	WaypointerWindow.questPopupMenu:AddItem(Waypointer.GetLocaleValue("Ignore quest"), function() IgnoreQuest(WaypointerWindow.list:GetSelectedValue()) end)
	
	local unrestrictedParent = UI.CreateContext(Waypointer.name .. "UnrestrictedContext")
	unrestrictedParent:SetStrata("topmost")
	WaypointerWindow.ignoredPopupMenu = XenUtils.CreatePopupMenu("IgnoredPopup", unrestrictedParent, 100)
	WaypointerWindow.ignoredPopupMenu:AddItem(Waypointer.GetLocaleValue("Restore quest"), function() RestoreQuest(WaypointerWindow.list:GetSelectedValue()) end)
	
	WaypointerWindow.quest:SetMouseMasking("limited")
	WaypointerWindow.quest.Event.RightClick = function() ShowQuestPopup(Waypointer, WaypointerWindow) end
	WaypointerWindow.quest.Event.LeftDown = function() HideQuestPopup() WaypointerWindow.ignoredPopupMenu:Hide() end
	
	WaypointerWindow.settingsFrame = UI.CreateFrame("Frame", "WaypointerSettingsFrame", WaypointerWindow:GetContent())
	WaypointerWindow.settingsFrame:SetAllPoints()
	WaypointerWindow.settingsFrame:SetVisible(false)
	
	WaypointerWindow.langLabel = UI.CreateFrame("Text", "WaypointerLabel", WaypointerWindow.settingsFrame)
	WaypointerWindow.langLabel:SetPoint("TOPLEFT", WaypointerWindow.settingsFrame, "TOPLEFT", margin * 4, margin * 4)
	WaypointerWindow.langSelect = UI.CreateFrame("SimpleSelect", "WaypointerLangSelect", WaypointerWindow.settingsFrame)
	WaypointerWindow.langSelect:SetPoint("TOPLEFT", WaypointerWindow.langLabel, "TOPRIGHT", margin, 0)
	WaypointerWindow.langSelect:SetWidth(70)
	WaypointerWindow.langSelect:SetHeight(19)
	local items = {}
	table.insert(items, "English")
	table.insert(items, "Deutsch")
	table.insert(items, "Francais")
	table.sort(items)
	WaypointerWindow.langSelect:SetItems(items)
	WaypointerWindow.langSelect:SetSelectedItem(Waypointer.lang)
	WaypointerWindow.langSelect.Event.ItemSelect = function(view, item) LangSelected(item) end
	
	WaypointerWindow.showButtonCheck = UI.CreateFrame("SimpleCheckbox", "WaypointerHideButton", WaypointerWindow.settingsFrame)
	WaypointerWindow.showButtonCheck:SetPoint("TOPLEFT", WaypointerWindow.langLabel, "BOTTOMLEFT", 0, margin * 2)

	WaypointerWindow.lockButtonCheck = UI.CreateFrame("SimpleCheckbox", "WaypointerHideButton", WaypointerWindow.settingsFrame)
	WaypointerWindow.lockButtonCheck:SetPoint("TOPLEFT", WaypointerWindow.showButtonCheck, "BOTTOMLEFT", 0, margin * 2)

	WaypointerWindow.hideZoneCheck = UI.CreateFrame("SimpleCheckbox", "WaypointerHideZone", WaypointerWindow.settingsFrame)
	WaypointerWindow.hideZoneCheck:SetPoint("TOPLEFT", WaypointerWindow.lockButtonCheck, "BOTTOMLEFT", 0, margin * 2)
	
	WaypointerWindow.settingsOK = UI.CreateFrame("RiftButton", "WaypointerSettingsOK", WaypointerWindow.settingsFrame)
	WaypointerWindow.settingsOK:SetPoint("BOTTOMCENTER", WaypointerWindow.settingsFrame, "BOTTOMCENTER", 0, - (margin * 2))
	WaypointerWindow.settingsOK:SetText("OK")
	WaypointerWindow.settingsOK.Event.LeftClick = function() HideSettings() end

	WaypointerWindow.coordLabel = UI.CreateFrame("Text", "WaypointerCoordLabel", WaypointerWindow.settingsFrame)
	WaypointerWindow.coordLabel:SetPoint("TOPLEFT", WaypointerWindow.hideZoneCheck, "BOTTOMLEFT", 0, margin * 2)
	WaypointerWindow.coordText = UI.CreateFrame("SimpleTextArea", "WaypointerCoordText", WaypointerWindow.settingsFrame)
	WaypointerWindow.coordText:SetPoint("TOPLEFT", WaypointerWindow.coordLabel, "BOTTOMLEFT", 0, margin)
	WaypointerWindow.coordText:SetPoint("BOTTOMRIGHT", WaypointerWindow.settingsOK, "TOPCENTER", 0, -margin * 4)
	WaypointerWindow.coordText:SetBorder(1, 1, 1, 1, 1)

	WaypointerWindow.thxLabel = UI.CreateFrame("Text", "WaypointerThxLabel", WaypointerWindow.settingsFrame)
	WaypointerWindow.thxLabel:SetPoint("TOPLEFT", WaypointerWindow.coordText, "TOPRIGHT", margin * 2, 0)
	WaypointerWindow.thxLabel:SetText("Coordinates provided by:")
	WaypointerWindow.thxText = UI.CreateFrame("Text", "WaypointerThxText", WaypointerWindow.settingsFrame)
	WaypointerWindow.thxText:SetPoint("TOPLEFT", WaypointerWindow.thxLabel, "BOTTOMLEFT", 0, margin)
	WaypointerWindow.thxText:SetPoint("BOTTOMLEFT", WaypointerWindow.coordText, "BOTTOMRIGHT", margin * 3, 0)
	WaypointerWindow.thxText:SetWordwrap(true)
	WaypointerWindow.thxText:SetWidth(150)
	WaypointerWindow.thxText:SetText("Caduto@PrimyMcPrime")

	local button = UI.CreateFrame("Texture", "WaypointerButton", parent)
	button:SetTexture(Waypointer.name, "icon.png")
	button.Event.LeftClick = function() ToggleVisibility() end
	Waypointer.button = button
	Waypointer.dragFrame = Waypointer.DragFrame.Create(button, button:GetWidth(), button:GetHeight(), function(dragFrame) SetButtonCoords(dragFrame.x, dragFrame.y) end)
	WaypointerWindow.tooltip = UI.CreateFrame("SimpleTooltip", "WaypointerTooltip", parent)
	WaypointerWindow.tooltip:InjectEvents(Waypointer.dragFrame.frame, GetZoneTooltip)
	button:SetVisible(false)
	
	Waypointer.parent = parent
	Waypointer.parentFrame = WaypointerWindow

	EnsureOnScreen()
	RedrawLabels()
	ShowSettings()
end


--
-- Event Handlers
--
local function TryStartup()
	Waypointer.startCount = Waypointer.startCount + 1
	if Waypointer.startCount % 50 == 0 then
		return Startup()
	end
	
	return true
end

local function Initialise(h, addon)
	if addon == Waypointer.name then
		Waypointer.startup = true
		Create()
		Waypointer.AsyncHandler = XenUtils.CreateAsyncHandler("Waypointer")
		Waypointer.AsyncHandler:StartHandler("Startup", TryStartup)
	end
end

local function GetSavedValue(value, default)
	if value ~= nil then
		return value
	else
		return default
	end
end

local function LoadVariables(h, addon)
	if addon == Waypointer.name then
		-- now that variables are loaded and saved positions restored we can create frame
		if Waypointer_SavedVariables then
			Waypointer.x = GetSavedValue(Waypointer_SavedVariables.x, 100)
			Waypointer.y = GetSavedValue(Waypointer_SavedVariables.y, 20)
			Waypointer.buttonX = GetSavedValue(Waypointer_SavedVariables.buttonX, 50)
			Waypointer.buttonY = GetSavedValue(Waypointer_SavedVariables.buttonY, 20)
			Waypointer.lang = GetSavedValue(Waypointer_SavedVariables.lang, "English")
			Waypointer.isButtonShown = GetSavedValue(Waypointer_SavedVariables.isButtonShown, true)
			Waypointer.isButtonLocked = GetSavedValue(Waypointer_SavedVariables.isButtonLocked, false)
			Waypointer.hideEmptyZones = GetSavedValue(Waypointer_SavedVariables.hideEmptyZones, true)
			Waypointer.saveUnknownQuests = GetSavedValue(Waypointer_SavedVariables.saveUnknownQuests, false)
			Waypointer.lastSharedCoords = Waypointer_SavedVariables.lastSharedCoords
			Waypointer.questCoords = GetSavedValue(Waypointer_SavedVariables.questCoords, {})
			Waypointer.unknownQuestCoords = GetSavedValue(Waypointer_SavedVariables.unknownQuestCoords, {})
			Waypointer.unknownQuestDetails = GetSavedValue(Waypointer_SavedVariables.unknownQuestDetails, {})

			CleanQuestCoords()
		end
		
		if Waypointer_SavedCharacterVariables then
			Waypointer.ignoredQuests = GetSavedValue(Waypointer_SavedCharacterVariables.ignoredQuests, {})
			Waypointer.completedRepeatQuests = GetSavedValue(Waypointer_SavedCharacterVariables.completedRepeatQuests, {})
		end
		
		Waypointer.SetLocale()
	end	
end

--
-- Register events
--
Command.Event.Attach(Event.Addon.Load.End, Initialise, "Waypointer.Initialise")
Command.Event.Attach(Event.Addon.SavedVariables.Load.End, LoadVariables, "Waypointer.LoadVariables")
