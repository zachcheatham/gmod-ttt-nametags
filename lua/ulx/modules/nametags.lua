---------------
--- Defines ---
---------------
local NAMETAG_FILE = "data/ulx/nametags.txt"
local NAMETAG_GROUPS_FILE = "data/ulx/nametags_groups.txt"
local NAMETAG_REQUEST_FILE = "data/ulx/nametag_requests.txt"
local NAMETAG_NOTIFICATIONS_FILE = "data/ulx/nametag_notifications.txt"
local NAMETAG_APPROVED = 0
local NAMETAG_DENIED = 1

---------------
--- Helpers ---
---------------
local function isOnline(steamID)
	for k, v in ipairs(player.GetAll()) do
		if v:SteamID() == steamID then
			return true
		end
	end
	
	return false
end

----------------------
--- Data Functions ---
----------------------
ulx.nameTags = {}
ulx.connectedNameTags = {}
ulx.groupNameTags = {}
ulx.nameTagRequests = {}
ulx.nameTagNotifications = {}

local function reloadTags()
	-- Read files
	ulx.nameTags = ULib.fileExists(NAMETAG_FILE) and ULib.parseKeyValues(ULib.fileRead(NAMETAG_FILE), "/" ) or {}
	ulx.groupNameTags = ULib.fileExists(NAMETAG_GROUPS_FILE) and ULib.parseKeyValues(ULib.fileRead(NAMETAG_GROUPS_FILE), "/" ) or {}
	ulx.nameTagRequests =  ULib.fileExists(NAMETAG_REQUEST_FILE) and ULib.parseKeyValues(ULib.fileRead(NAMETAG_REQUEST_FILE), "/" ) or {}
	ulx.nameTagNotifications = ULib.fileExists(NAMETAG_REQUEST_FILE) and ULib.parseKeyValues(ULib.fileRead(NAMETAG_NOTIFICATIONS_FILE), "/" ) or {}
	
	for k, v in pairs(ulx.nameTags) do
		if not v.rainbow then
			if not v.r then
				ulx.nameTags[k].r = 255
			end
			
			if not v.g then
				ulx.nameTags[k].g = 255
			end
			
			if not v.b then
				ulx.nameTags[k].b = 255
			end
		end
	end
	
	-- Add connected players to connected name tags
	ulx.connectedNameTags = {}
	for steamID, tag in pairs(ulx.nameTags) do
		if isOnline(steamID) then
			-- COPY! table
			ulx.connectedNameTags[steamID] = {content=tag.content}
			if tag.rainbow then
				ulx.connectedNameTags[steamID].rainbow = true
			else
				ulx.connectedNameTags[steamID].r = tag.r
				ulx.connectedNameTags[steamID].g = tag.g
				ulx.connectedNameTags[steamID].b = tag.b
			end
		end	
	end
	-- Merge in groups so we can send them all to the client at the same time
	table.Merge(ulx.connectedNameTags, ulx.groupNameTags)
	
	-- Tell everyone the current tags
	ulx.broadcastNameTags()
end

function ulx.saveNameTags()
	ULib.fileWrite(NAMETAG_FILE, ULib.makeKeyValues(ulx.nameTags))
end

function ulx.saveGroupNameTags()
	ULib.fileWrite(NAMETAG_GROUPS_FILE, ULib.makeKeyValues(ulx.groupNameTags))
end

function ulx.saveNameTagRequests()
	ULib.fileWrite(NAMETAG_REQUEST_FILE, ULib.makeKeyValues(ulx.nameTagRequests))
end

function ulx.saveNameTagNotifications()
	ULib.fileWrite(NAMETAG_NOTIFICATIONS_FILE, ULib.makeKeyValues(ulx.nameTagNotifications))
end

-- Send all connected name tags to all players
function ulx.broadcastNameTags()
	if table.Count(ulx.connectedNameTags) > 0 then
		ULib.clientRPC(_, "ulx.populateNameTags", ulx.connectedNameTags)
	end
end

-- Send name tag to all players
function ulx.broadcastNameTag(id, nameTag, exempt)
	for i,ply in ipairs(player.GetAll()) do
		if ply ~= exempt then
			ULib.clientRPC(_, "ulx.updateNameTag", id, nameTag)
		end
	end
end

-- Send only connected name tags to a player
function ulx.sendNameTags(ply)
	if table.Count(ulx.connectedNameTags) > 0 then
		ULib.clientRPC(ply, "ulx.populateNameTags", ulx.connectedNameTags)
	end
end

-------------
--- Hooks ---
-------------
local function loadNameTags(ply)
	local steamID = ply:SteamID()
	
	if ulx.nameTags[steamID] then	
		-- Associate a name with the name tag if we don't have one
		if not ulx.nameTags[steamID].name then
			ulx.nameTags[steamID].name = ply:Nick()
			ulx.saveNameTags()
			
			-- Inform XGUI
			local t = {}
			t[steamID] = ulx.nameTags[steamID]
			xgui.addData({}, "nametags", t)
		end
		
		-- Copy table into connected nametags
		ulx.connectedNameTags[steamID] = {content=ulx.nameTags[steamID].content}
		if ulx.nameTags[steamID].rainbow then
			ulx.connectedNameTags[steamID].rainbow = true
		else
			ulx.connectedNameTags[steamID].r = ulx.nameTags[steamID].r
			ulx.connectedNameTags[steamID].g = ulx.nameTags[steamID].g
			ulx.connectedNameTags[steamID].b = ulx.nameTags[steamID].b
		end
		
		-- Broadcast
		ulx.broadcastNameTag(steamID, ulx.connectedNameTags[steamID], ply)	-- Inform everyone that a new name tag has connected
	end
	
	-- Send new player all connected name tags
	ulx.sendNameTags(ply)
	
	-- Player has a pending tag request
	if ulx.nameTagRequests[steamID] then
		-- Associate a name with the request if we don't have one
		if not ulx.nameTagRequests[steamID] then
			ulx.nameTagRequests[steamID]["name"] = ply:Nick()
			ulx.saveNameTagRequests()
			
			-- Inform XGUI
			local t = {}
			t[steamID] = ulx.nameTagRequests[steamID]
			xgui.addData({}, "nametagrequests", t)
		end
		
		-- Notify that his tag is still pending approval
		ULib.tsay(ply, "[Notice] Your name tag request is pending approval.")
	-- Notify player of things that happened while they were away
	elseif ulx.nameTagNotifications[steamID] then
		if ulx.nameTagNotifications[steamID] == NAMETAG_APPROVED then
			ULib.tsay(ply, "[Notice] Your name tag has been approved!")
		elseif ulx.nameTagNotifications[steamID] == NAMETAG_DENIED then
			ULib.tsay(ply, "[Notice] Your name tag has been denied.")
		end
		
		ulx.nameTagNotifications[steamID] = nil
		ulx.saveNameTagNotifications()
	end
end
hook.Add("PlayerInitialSpawn", "loadNameTags", loadNameTags)

local function unloadNameTag(ply)
	ulx.connectedNameTags[ply:SteamID()] = nil
end
hook.Add("PlayerDisconnected", "unloadNameTag", unloadNameTag)

---------------
--- Runtime ---
---------------
reloadTags()