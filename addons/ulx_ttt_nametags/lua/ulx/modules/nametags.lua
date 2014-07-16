local NAMETAG_FILE = "data/ulx/nametags.txt"
local NAMETAG_GROUPS_FILE = "data/ulx/nametags_groups.txt"
local NAMETAG_REQUEST_FILE = "data/ulx/nametag_requests.txt"
local NAMETAG_NOTIFICATIONS_FILE = "data/ulx/nametag_notifications.txt"

ulx.nameTags = {}
ulx.connectedNameTags = {}
ulx.groupNameTags = {}
ulx.nameTagRequests = {}
ulx.nameTagNotifications = {}

local NameTagNotificationStatus = {APPROVED = 0, DENIED = 1}

local function isOnline(steamID)
	for k, v in ipairs(player.GetAll()) do
		if v:SteamID() == steamID then
			return true
		end
	end
	
	return false
end

local function reloadTags()
	-- Read files
	ulx.nameTags = ULib.parseKeyValues(ULib.removeCommentHeader(ULib.fileRead(NAMETAG_FILE), "/" ))
	ulx.groupNameTags = ULib.parseKeyValues(ULib.removeCommentHeader(ULib.fileRead(NAMETAG_GROUPS_FILE), "/" ))
	ulx.nameTagRequests = ULib.parseKeyValues(ULib.removeCommentHeader(ULib.fileRead(NAMETAG_REQUEST_FILE), "/" ))
	ulx.nameTagNotifications = ULib.parseKeyValues(ULib.removeCommentHeader(ULib.fileRead(NAMETAG_NOTIFICATIONS_FILE), "/" ))
	
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
	
	-- TODO: Figure out how to completely refresh the xgui data
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
function ulx.broadcastNameTag(id, nametag, ply_exempt)
	for i,ply in ipairs(player.GetAll()) do
		if ply ~= ply_exempt then
			ULib.clientRPC(_, "ulx.updateNameTag", id, nametag)
		end
	end
end

-- Send only connected name tags to a player
function ulx.sendNameTags(ply)
	if table.Count(ulx.nameTags) > 0 then
		ULib.clientRPC(ply, "ulx.populateNameTags", ulx.connectedNameTags)
	end
end

-- Hooks

hook.Add("PlayerInitialSpawn", "loadNameTags", function(ply)
	local steamid = ply:SteamID()
	
	if ulx.nameTags[steamid] then	
		-- Associate a name with the name tag if we don't have one
		if not ulx.nameTags[steamid].name then
			ulx.nameTags[steamid].name = ply:Nick()
			ulx.saveNameTags()
			
			-- Inform XGUI
			local t = {}
			t[steamid] = ulx.nameTags[steamid]
			xgui.addData({}, "nametags", t)
		end
		
		-- Copy table into connected nametags
		ulx.connectedNameTags[steamid] = {content=ulx.nameTags[steamid].content}
		if ulx.nameTags[steamid].rainbow then
			ulx.connectedNameTags[steamid].rainbow = true
		else
			ulx.connectedNameTags[steamid].r = ulx.nameTags[steamid].r
			ulx.connectedNameTags[steamid].g = ulx.nameTags[steamid].g
			ulx.connectedNameTags[steamid].b = ulx.nameTags[steamid].b
		end
		
		-- Broadcast
		ulx.broadcastNameTag(steamid, ulx.connectedNameTags[steamid], ply)	-- Inform everyone that a new name tag has connected
	end
	
	-- Send new player all connected name tags
	ulx.sendNameTags(ply)
	
	if ulx.nameTagRequests[steamid] then
		-- Associate a name with the request if we don't have one
		if not ulx.nameTagRequests[steamid] then
			ulx.nameTagRequests[steamid]["name"] = ply:Nick()
			ulx.saveNameTagRequests()
			
			-- Inform XGUI
			local t = {}
			t[steamid] = ulx.nameTagRequests[steamid]
			xgui.addData({}, "nametagrequests", t)
		end
		
		-- Notify that his tag is still pending approval
		ULib.tsay(ply, "[Notice] Your name tag request is pending approval.")
	elseif ulx.nameTagNotifications[steamid] then
		if ulx.nameTagNotifications[steamid] == NameTagNotificationStatus.APPROVED then
			ULib.tsay(ply, "[Notice] Your name tag has been approved!")
		elseif ulx.nameTagNotifications[steamid] == NameTagNotificationStatus.DENIED then
			ULib.tsay(ply, "[Notice] Your name tag has been denied.")
		end
		
		ulx.nameTagNotifications[steamid] = nil
		ulx.saveNameTagNotifications()
	end
end)

hook.Add("PlayerDisconnected", "unloadNameTag", function(ply)
	ulx.connectedNameTags[ply:SteamID()] = nil
end)

-- Run

reloadTags()