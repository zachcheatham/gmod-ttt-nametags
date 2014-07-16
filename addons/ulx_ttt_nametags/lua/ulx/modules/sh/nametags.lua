local CATEGORY_NAME = "Name Tags"

local function isOnline(steamID)
	for k, v in ipairs(player.GetAll()) do
		if v:SteamID() == steamID then
			return v
		end
	end
	
	return false
end

function ulx.tag(calling_ply, target_ply, content, red, green, blue)
	local tag = {content=content, r=red, g=green, b=blue}
	
	ulx.connectedNameTags[target_ply:SteamID()] = tag
	ulx.broadcastNameTag(target_ply:SteamID(), tag)
	
	tag.name = target_ply:Nick()
	ulx.nameTags[target_ply:SteamID()] = tag
	ulx.saveNameTags()
	
	ulx.fancyLogAdmin(calling_ply, "#A changed the name tag of #T", target_ply)

	local t = {}
	t[target_ply:SteamID()] = tag
	xgui.addData({}, "nametags", t)
end

local tag = ulx.command(CATEGORY_NAME, "ulx tag", ulx.tag, "!tag")
tag:addParam{type=ULib.cmds.PlayerArg}
tag:addParam{type=ULib.cmds.StringArg, hint="content"}
tag:addParam{type=ULib.cmds.NumArg, max=255, min=0, default=255, hint="red"}
tag:addParam{type=ULib.cmds.NumArg, max=255, min=0, default=255, hint="green"}
tag:addParam{type=ULib.cmds.NumArg, max=255, min=0, default=255, hint="blue"}
tag:defaultAccess(ULib.ACCESS_SUPERADMIN)
tag:help("Sets the target's name tag.")

function ulx.tagid(calling_ply, steamID, content, red, green, blue)
	local name
	steamID = steamID:upper()
	
	if ULib.ucl.users[steamID] and ULib.ucl.users[steamID].name then
		name = ULib.ucl.users[steamID].name
	elseif ulx.nameTags[steamID] and ulx.nameTags[steamID].name then
		name = ulx.nameTags[steamID].name
	end
	
	local tag = {content=content, r=red, g=green, b=blue}
	
	if isOnline(steamID) then
		ulx.connectedNameTags[steamID] = tag
		ulx.broadcastNameTag(steamID, tag)
	end
	
	if name then tag.name = name end
	ulx.nameTags[steamID] = tag
	ulx.saveNameTags()
	
	ulx.fancyLogAdmin(calling_ply, "#A changed the name tag of #s", (name and name or steamID))
	
	local t = {}
	t[steamID] = tag
	xgui.addData({}, "nametags", t)
end

local tagid = ulx.command(CATEGORY_NAME, "ulx tagid", ulx.tagid, "!tagid")
tagid:addParam{type=ULib.cmds.StringArg, hint="Steam ID"}
tagid:addParam{type=ULib.cmds.StringArg, hint="content"}
tagid:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="red"}
tagid:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="green"}
tagid:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="blue"}
tagid:defaultAccess(ULib.ACCESS_SUPERADMIN)
tagid:help("Sets a name tag by Steam ID.")

function ulx.removetag(calling_ply, target_ply)
	ulx.nameTags[target_ply:SteamID()] = nil
	ulx.connectedNameTags[target_ply:SteamID()] = nil
	ulx.broadcastNameTag(target_ply:SteamID(), nil)
	ulx.fancyLogAdmin(calling_ply, "#A removed #T's name tag", target_ply)
	ulx.saveNameTags()
	
	xgui.removeData({}, "nametags", {target_ply:SteamID()})
end

local removetag = ulx.command(CATEGORY_NAME, "ulx removetag", ulx.removetag, "!removetag")
removetag:addParam{type=ULib.cmds.PlayerArg}
removetag:defaultAccess(ULib.ACCESS_SUPERADMIN)
removetag:help("Removes the target's name tag.")

function ulx.removetagid(calling_ply, steamID)
	steamID = steamID:upper()

	ulx.nameTags[steamID] = nil
	ulx.connectedNameTags[steamID] = nil
	ulx.broadcastNameTag(steamID, nil)
	
	if ULib.ucl.users[steamID] and ULib.ucl.users[steamID].name then
		ulx.fancyLogAdmin(calling_ply, "#A removed #s's name tag", ULib.ucl.users[steamID].name)
	else
		ulx.fancyLogAdmin(calling_ply, "#A removed the name tag from #s", steamID)
	end
	
	ulx.saveNameTags()
	
	xgui.removeData({}, "nametags", {steamID})
end

local removetagid = ulx.command(CATEGORY_NAME, "ulx removetagid", ulx.removetagid, "!removetagid")
removetagid:addParam{type=ULib.cmds.StringArg, hint="SteamID"}
removetagid:defaultAccess(ULib.ACCESS_SUPERADMIN)
removetagid:help("Removes a name tag by Steam ID.")

function ulx.grouptag(calling_ply, group, content, red, green, blue)
	if not ULib.ucl.groups[group] then
		ULib.tsayError(calling_ply, "That is not a valid group")
		return
	end
	
	local tag = {content=content, r=red, g=green, b=blue}
	
	ulx.groupNameTags[group] = tag
	ulx.broadcastNameTag(group, ulx.groupNameTags[group])
	ulx.saveGroupNameTags()
	
	ulx.fancyLogAdmin(calling_ply, "#A set the group name tag of #s.", group)
	
	local t = {}
	t[group] = tag
	xgui.addData({}, "groupnametags", t)
end

local grouptag = ulx.command(CATEGORY_NAME, "ulx grouptag", ulx.grouptag, "!grouptag")
grouptag:addParam{type=ULib.cmds.StringArg, hint="group"}
grouptag:addParam{type=ULib.cmds.StringArg, hint="content"}
grouptag:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="red"}
grouptag:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="green"}
grouptag:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="blue"}
grouptag:defaultAccess(ULib.ACCESS_SUPERADMIN)
grouptag:help("Sets a group's name tag.")

function ulx.removegrouptag(calling_ply, group)
	ulx.nameTags[group] = nil
	ulx.connectedNameTags[group] = nil
	ulx.broadcastNameTag(group, nil)
	
	ulx.fancyLogAdmin(calling_ply, "#A removed the group name tag from #s", group)
	
	ulx.saveGroupNameTags()
	
	xgui.removeData({}, "groupnametags", {group})
end

local removegrouptag = ulx.command(CATEGORY_NAME, "ulx removegrouptag", ulx.removegrouptag, "!removegrouptag")
removegrouptag:addParam{type=ULib.cmds.StringArg, hint="group"}
removegrouptag:defaultAccess(ULib.ACCESS_SUPERADMIN)
removegrouptag:help("Removes a name tag from a group.")

function ulx.approvetag(calling_ply, steamID)
	local request = ulx.nameTagRequests[steamID]
	
	if request then
		local name = request.name
		local online = isOnline(steamID)
		
		-- Update the name if we can
		if ULib.ucl.users[steamID] and ULib.ucl.users[steamID].name then
			name = ULib.ucl.users[steamID] and ULib.ucl.users[steamID].name
		end
		
		-- Put new tag in le table
		ulx.nameTags[steamID] = {content=request.content, r=request.r, g=request.g, b=request.b}
		
		-- Push the update to everyone if player is online
		if online then
			ulx.connectedNameTags[steamID] = ulx.nameTags[steamID]
			ulx.broadcastNameTag(steamID, ulx.nameTags[steamID])
		end
		
		-- Save the name (afterwards so we dont send the name to players)
		if name then
			ulx.nameTags[steamID]["name"] = name
		end
		
		-- Remove the request
		ulx.nameTagRequests[steamID] = nil
		
		-- Query a notification to the player if he's not here to see his nametag get approved
		if not online then
			ulx.nameTagNotifications[steamID] = ulx.NameTagNotificationStatus.APPROVED
			ulx.saveNameTagNotifications()
		end
		
		-- Save
		ulx.saveNameTags()
		ulx.saveNameTagRequests()
		
		-- Update XGUI
		xgui.removeData({}, "nametagrequests", {steamID})
		local t = {}
		t[steamID] = ulx.nameTags[steamID]
		xgui.addData({}, "nametags", t)
		
		-- Announce
		ulx.fancyLogAdmin(calling_ply, "#A approved #s's new name tag.", name or steamID)
	else
		ULib.tsayError(calling_ply, "That Steam ID doesn't have a pending name tag request.")
	end
end

local approvetag = ulx.command(CATEGORY_NAME, "ulx approvetag", ulx.approvetag, "!approvetag")
approvetag:addParam{type=ULib.cmds.StringArg, hint="Steam ID"}
approvetag:defaultAccess(ULib.ACCESS_SUPERADMIN)
approvetag:help("Approves a player's name tag request.")

function ulx.denytag(calling_ply, steamID)
	local request = ulx.nameTagRequests[steamID]
	if request then
		ulx.nameTagRequests[steamID] = nil
		ulx.saveNameTagRequests()
		
		-- Queue a notification
		if not isOnline(steamID) then
			ulx.nameTagNotifications[steamID] = ulx.NameTagNotificationStatus.DENIED
			ulx.saveNameTagNotifications()
		end
		
		-- Update XGUI
		xgui.removeData({}, "nametagrequests", {steamID})
		
		-- Announce
		if ULib.ucl.users[steamID] and ULib.ucl.users[steamID].name then
			ulx.fancyLogAdmin(calling_ply, "#A denied #s's name tag request.", ULib.ucl.users[steamID].name)
		else
			ulx.fancyLogAdmin(calling_ply, "#A denied #s's name tag request.", steamID)
		end
	else
		ULib.tsayError(calling_ply, "That Steam ID doesn't have a pending name tag request.")
	end
end

local denytag = ulx.command(CATEGORY_NAME, "ulx denytag", ulx.denytag, "!denytag")
denytag:addParam{type=ULib.cmds.StringArg, hint="Steam ID"}
denytag:defaultAccess(ULib.ACCESS_SUPERADMIN)
denytag:help("Denies a player's name tag request.")

function ulx.requesttag(calling_ply, content, red, green, blue)
	if not calling_ply.SteamID then ULib.tsayError(calling_ply, "Only players can use this command.") return end
	
	if ulx.nameTags[calling_ply:SteamID()] then	
		local exists = (ulx.nameTagRequests[calling_ply:SteamID()] and true or false)
		
		ulx.nameTagRequests[calling_ply:SteamID()] = {name=calling_ply:Nick(), content=content, r=red, g=green, b=blue, new=false}
		ulx.saveNameTagRequests()
		
		if exists then
			ULib.tsay(calling_ply, "Your name tag request has been updated.")
		else
			ULib.tsay(calling_ply, "Your name tag request has been submitted.")
		end
		
		local t = {}
		t[calling_ply:SteamID()] = ulx.nameTagRequests[calling_ply:SteamID()]
		xgui.addData({}, "nametagrequests", t)
	else
		ULib.tsayError(calling_ply, "You may only request a tag if you have an existing one.")
	end
end

local requesttag = ulx.command(CATEGORY_NAME, "ulx requesttag", ulx.requesttag, "!requesttag")
requesttag:addParam{type=ULib.cmds.StringArg, hint="Content"}
requesttag:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="red"}
requesttag:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="green"}
requesttag:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="blue"}
requesttag:defaultAccess(ULib.ACCESS_ALL)
requesttag:help("Request a name tag.")

function ulx.addtagrequest(calling_ply, steamID, content, red, green, blue)
	if not ULib.isValidSteamID(steamID) then
		ULib.tsayError(calling_ply, "That is not a valid Steam ID")
		return
	end

	local exists = (ulx.nameTags[steamID] and true or false)
	local update = (ulx.nameTagRequests[steamID] and true or false)
	
	ulx.nameTagRequests[steamID] = {content=content, r=red, g=green, b=blue, new=not exists}
	
	local online = isOnline(steamID)
	if online then
		ulx.nameTagRequests[steamID]["name"] = online:Nick()
		
		if update then
			ULib.tsay(online, "Your name tag request has been updated. (DID YOU ACTUALLY BUY A SECOND ONE?!)")
			-- Because this command should only really be called after a paypal payment
		else
			ULib.tsay(online, "Your name tag request has been submitted.")
		end
	elseif ulx.nameTags[steamID] and ulx.nameTags[steamID].name then
		ulx.nameTagRequests[steamID]["name"] = ulx.nameTags[steamID].name
	end
	
	ulx.saveNameTagRequests()
	
	ULib.tsay(calling_ply, "Request submitted.")
	
	local t = {}
	t[steamID] = ulx.nameTagRequests[steamID]
	xgui.addData({}, "nametagrequests", t)
end

local addtagrequest = ulx.command(CATEGORY_NAME, "ulx addtagrequest", ulx.addtagrequest, "!addtagrequest")
addtagrequest:addParam{type=ULib.cmds.StringArg, hint="SteamID"}
addtagrequest:addParam{type=ULib.cmds.StringArg, hint="Content"}
addtagrequest:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="red"}
addtagrequest:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="green"}
addtagrequest:addParam{type=ULib.cmds.NumArg, max=255, min=0, hint="blue"}
addtagrequest:defaultAccess(ULib.ACCESS_SUPERADMIN)
addtagrequest:help("Add a name tag request by Steam ID.")