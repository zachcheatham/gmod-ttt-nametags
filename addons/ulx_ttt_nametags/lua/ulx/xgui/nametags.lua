------------
-- MAIN
------------

xgui.prepareDataType("nametags")
xgui.prepareDataType("groupnametags")
xgui.prepareDataType("nametagrequests")

local xnametags = xlib.makepanel{parent=xgui.null}

xnametags.tabs = xlib.makepropertysheet{ x=-5, y=6, w=600, h=368, parent=xnametags, offloadparent=xgui.null }
xgui.addModule("Name Tags", xnametags, "icon16/palette.png", "xgui_managenametags")

-------------
-- Players --
-------------

xnametags.tags = xlib.makepanel{parent=xgui.null}

xnametags.tags.list = xlib.makelistview{x=5, y=5, w=572, h=295, parent=xnametags.tags}
xnametags.tags.list:AddColumn("Name")
xnametags.tags.list:AddColumn("Steam ID")
xnametags.tags.list:AddColumn("Tag")
xnametags.tags.list:AddColumn("Color")
xnametags.tags.list.OnRowRightClick = function(self, id, line)
	local menu = DermaMenu()
	menu:AddOption("Change...", function()  
		xgui.showNameTagEditor(false, line:GetValue(2), xgui.data.nametags[line:GetValue(2)])
	end )
	menu:AddOption("Remove", function()
		Derma_Query("Are you sure you want to remove " .. tostring(line:GetValue(1)) .. "'s name tag?", "XGUI WARNING", 
		"Remove", function()
			RunConsoleCommand("ulx", "removetagid", line:GetValue(2))
		end,
		"Cancel", function() end)
	end )
	menu:Open()
end

xlib.makebutton{x=5, y=305, w=100, label="Add Name Tag...", parent=xnametags.tags}.DoClick = function()
	xgui.showNameTagEditor(false)
end

function xnametags.populateNameTags(chunk)
	for steamID, tag in pairs(chunk) do
		xgui.queueFunctionCall(xnametags.addNameTagLine, "nametag", steamID, tag)
	end
end

function xnametags.addNameTagLine(steamID, tag)
	xnametags.tags.list:AddLine(tag.name, steamID, tag.content, (tag.rainbow and "Rainbow" or tag.r .. "," .. tag.g .. "," .. tag.b))
end

function xnametags.clearNameTags()
	xnametags.tags.list:Clear()
end

function xnametags.updateNameTags(tags)
	for steamID, tag in pairs(tags) do
		local found = false
		for i, v in pairs(xnametags.tags.list.Lines) do
			if v.Columns[2]:GetValue() == steamID then
				found = true
				
				v:SetColumnText(1, tag.name)
				v:SetColumnText(2, steamID)
				v:SetColumnText(3, tag.content)
				if tag.rainbow then
					v:SetColumnText(4, "Rainbow")
				else
					xgui.data.nametags[steamID].rainbow = nil -- Force this because xgui will only merge to that table
					v:SetColumnText(4, tag.r .. "," .. tag.g .. "," .. tag.b)
				end
				break
			end
		end
		if not found then
			local t = {}
			t[steamID] = tag
			xnametags.populateNameTags(t)
		end
	end
end

function xnametags.removeNameTags(steamIDs)
	for i, steamID in pairs(steamIDs) do
		for i, v in pairs(xnametags.tags.list.Lines) do
			if v.Columns[2]:GetValue() == steamID then
				xnametags.tags.list:RemoveLine(i)
				break
			end
		end
	end
end

xgui.hookEvent("nametags", "process", xnametags.populateNameTags)
xgui.hookEvent("nametags", "clear", xnametags.clearNameTags)
xgui.hookEvent("nametags", "add", xnametags.updateNameTags)
xgui.hookEvent("nametags", "remove", xnametags.removeNameTags)

xnametags.tabs:AddSheet("Players", xnametags.tags, "icon16/user.png", false, false, nil)

-------------
-- Groups --
-------------

xnametags.grouptags = xlib.makepanel{parent=xgui.null}

xnametags.grouptags.list = xlib.makelistview{x=5, y=5, w=572, h=295, parent=xnametags.grouptags}
xnametags.grouptags.list:AddColumn("Group")
xnametags.grouptags.list:AddColumn("Tag")
xnametags.grouptags.list:AddColumn("Color")
xnametags.grouptags.list.OnRowRightClick = function(self, id, line)
	local menu = DermaMenu()
	menu:AddOption("Change...", function()  
		xgui.showNameTagEditor(true, line:GetValue(1), xgui.data.groupnametags[line:GetValue(1)])
	end )
	menu:AddOption("Remove", function()
		Derma_Query("Are you sure you want to remove " .. tostring(line:GetValue(1)) .. "'s tag?", "XGUI WARNING", 
		"Remove", function()
			RunConsoleCommand("ulx", "removegrouptag", line:GetValue(1))
		end,
		"Cancel", function() end)
	end )
	menu:Open()
end

xlib.makebutton{x=5, y=305, w=100, label="Add Group Tag...", parent=xnametags.grouptags}.DoClick = function()
	xgui.showNameTagEditor(true)
end

function xnametags.populateGroupTags(chunk)
	for group, tag in pairs(chunk) do
		xgui.queueFunctionCall(xnametags.addGroupTagLine, "grouptag", group, tag)
	end
end

function xnametags.addGroupTagLine(group, tag)
	xnametags.grouptags.list:AddLine(group, tag.content, (tag.rainbow and "Rainbow" or tag.r .. "," .. tag.g .. "," .. tag.b))
end

function xnametags.clearGroupTags()
	xnametags.grouptags.list:Clear()
end

function xnametags.updateGroupTags(tags)
	for group, tag in pairs(tags) do		
		local found = false
		for i, v in pairs(xnametags.grouptags.list.Lines) do
			if v.Columns[1]:GetValue() == group then
				found = true
				v:SetColumnText(1, group)
				v:SetColumnText(2, tag.content)
				if tag.rainbow then
					v:SetColumnText(3, "Rainbow")
				else
					xgui.data.groupnametags[group].rainbow = nil -- Force this because xgui will only merge to that table
					v:SetColumnText(3, tag.r .. "," .. tag.g .. "," .. tag.b)
				end
				break
			end
		end
		if not found then
			local t = {}
			t[group] = tag
			xnametags.populateGroupTags(t)
		end
	end
end

function xnametags.removeGroupTags(groups)
	for i, group in pairs(groups) do
		for i, v in pairs(xnametags.grouptags.list.Lines) do
			if v.Columns[1]:GetValue() == group then
				xnametags.grouptags.list:RemoveLine(i)
				break
			end
		end
	end
end

xgui.hookEvent("groupnametags", "process", xnametags.populateGroupTags)
xgui.hookEvent("groupnametags", "clear", xnametags.clearGroupTags)
xgui.hookEvent("groupnametags", "add", xnametags.updateGroupTags)
xgui.hookEvent("groupnametags", "remove", xnametags.removeGroupTags)

xnametags.tabs:AddSheet("Groups", xnametags.grouptags, "icon16/group.png", false, false, nil)

------------
-- APPROVALS
------------

xnametags.approvallist = xlib.makepanel{parent=xgui.null}

xnametags.approvallist.list = xlib.makelistview{x=5, y=5, w=400, h=310, parent=xnametags.approvallist}
xnametags.approvallist.list:AddColumn("Name / Steam ID")
xnametags.approvallist.list:AddColumn("Type")
xnametags.approvallist.list:AddColumn("Tag")

local previewlabel = xlib.makelabel{x=410, y=5, label="Preview:", parent=xnametags.approvallist}
local previewpane = xlib.makepanel{x=410, y=22, w=165, h=24, parent=xnametags.approvallist}
previewpane:SetBackgroundColor(Color(0,0,0))

xnametags.approvallist.previewText = xlib.makelabel{x=0, y=0, label="Click a Request", parent=previewpane}
xnametags.approvallist.previewText:SetColor(Color(255, 255, 255))
xnametags.approvallist.previewText:SetFont("treb_small")
xnametags.approvallist.previewText:SizeToContents()
xnametags.approvallist.previewText:Center()

xnametags.approvallist.approveButton = xlib.makebutton{x=410, y=51, w=165, label="Approve", disabled=true, parent=xnametags.approvallist}
xnametags.approvallist.approveButton.DoClick = function(self)
	self:SetDisabled(true)
	xnametags.approvallist.denyButton:SetDisabled(true)
	
	RunConsoleCommand("ulx", "approvetag", xnametags.approvallist.list:GetLine(xnametags.approvallist.list:GetSelectedLine()):GetValue(4))
	
	xnametags.approvallist.previewText:SetColor(Color(0,255,0))
	xnametags.approvallist.previewText:SetText("Approved!")
	xnametags.approvallist.previewText:SizeToContents()
	xnametags.approvallist.previewText:Center()
end

xnametags.approvallist.denyButton = xlib.makebutton{x=410, y=76, w=165, label="Deny", disabled=true, parent=xnametags.approvallist}
xnametags.approvallist.denyButton.DoClick = function(self)
	self:SetDisabled(true)
	xnametags.approvallist.approveButton:SetDisabled(true)
	
	RunConsoleCommand("ulx", "denytag", xnametags.approvallist.list:GetLine(xnametags.approvallist.list:GetSelectedLine()):GetValue(4))
	
	xnametags.approvallist.previewText:SetColor(Color(255,0,0))
	xnametags.approvallist.previewText:SetText("Denied!")
	xnametags.approvallist.previewText:SizeToContents()
	xnametags.approvallist.previewText:Center()
end

xnametags.approvallist.list.OnRowSelected = function(self, line)
	local request = xgui.data.nametagrequests[self:GetLine(line):GetValue(4)]
	xnametags.approvallist.previewText:SetColor(Color(request.r, request.g, request.b))
	xnametags.approvallist.previewText:SetText(request.content)
	xnametags.approvallist.previewText:SizeToContents()
	xnametags.approvallist.previewText:Center()
	
	xnametags.approvallist.denyButton:SetDisabled(false)
	xnametags.approvallist.approveButton:SetDisabled(false)
end

function xnametags.populateNameTagRequests(chunk)
	for steamID, request in pairs(chunk) do
		xgui.queueFunctionCall(xnametags.addNameTagRequestLine, "nametagrequest", steamID, request)
	end
end

function xnametags.addNameTagRequestLine(steamID, request)
	xnametags.approvallist.list:AddLine(request.name or steamID, request.new == true and "New" or "Change", request.content, steamID)
end

function xnametags.clearNameTagRequests()
	xnametags.approvallist.list:Clear()
end

function xnametags.updateNameTagRequests(requests)
	for steamID, request in pairs(requests) do
		local found = false
		for i, v in pairs(xnametags.approvallist.list.Lines) do
			if v.Columns[4]:GetValue() == steamID then
				found = true
				v:SetColumnText(1, request.name or steamID)
				v:SetColumnText(2, request.new == true and "New" or "Change")
				v:SetColumnText(3, request.content)
				v:SetColumnText(4, steamID)
				break
			end
		end
		if not found then
			local t = {}
			t[steamID] = request
			xnametags.populateNameTagRequests(t)
		end
	end
end

function xnametags.removeNameTagRequests(steamIDs)	
	for i, steamID in pairs(steamIDs) do
		for i, v in pairs(xnametags.approvallist.list.Lines) do
			if v.Columns[4]:GetValue() == steamID then
				xnametags.approvallist.list:RemoveLine(i)
				break
			end
		end	
	end
end

xgui.hookEvent("nametagrequests", "process", xnametags.populateNameTagRequests)
xgui.hookEvent("nametagrequests", "clear", xnametags.clearNameTagRequests)
xgui.hookEvent("nametagrequests", "add", xnametags.updateNameTagRequests)
xgui.hookEvent("nametagrequests", "remove", xnametags.removeNameTagRequests)

xnametags.tabs:AddSheet("Pending Approval", xnametags.approvallist, "icon16/application_view_list.png", false, false, nil)

------------------
-- Misc ----------
------------------

function xgui.showNameTagEditor(group, id, tag)
	local window = xlib.makeframe{label=(id and (group and "Change Group Tag" or "Change Name Tag") or (group and "Add Group Tag" or "Add Name Tag")), w=250, h=(id and 273 or 298), skin=xgui.settings.skin}
	local ystart = 25
	
	local idBox
	if not id then
		local idLabel = xlib.makelabel{x=(group and 15 or 5), y=34, label=(group and "Group: " or "Steam ID:"), parent=window}
	
		idBox = xlib.makecombobox{x=(group and 50 or 55), y=30, w=(group and 195 or 190), enableinput=true, selectall=true, parent=window}
		if group then
			for k,v in pairs(ULib.ucl.groups) do
				idBox:AddChoice(k, k)
			end
		else
			for k,v in pairs(player.GetAll()) do
				if not xgui.data.nametags[v:SteamID()] then
					idBox:AddChoice(v:Nick(), v:SteamID())
				end
			end
		end
		
		idBox.OnSelect = function(self, index, value, data)
			self:SetValue(data)
		end
		
		ystart = 50
	end
	
	local contentLabel = xlib.makelabel{x=((id or group) and 5 or 10), y=ystart+8, label="Content:", parent=window}
	local contentBox = xlib.maketextbox{x=((id or group) and 50 or 55), y=ystart+5, w=((id or group) and 195 or 190), parent=window, selectall=true}
	if id then
		contentBox:SetValue(tag.content)
	end
	
	local colorLabel = xlib.makelabel{x=5, y=ystart+30, label="Color:", parent=window}	
	local colorPicker = xlib.makecolorpicker{x=5, y=ystart+47, parent=window}
	if id and not tag.rainbow then
		colorPicker:SetColor(Color(tag.r, tag.g, tag.b))
	elseif id and tag.rainbow then
		colorPicker:SetDisabled(true)
	end
	colorPicker:SetWidth(240)
	colorPicker:SetHeight(125)
	colorPicker.ColorCube:SetWidth(220)
	colorPicker.ColorCube:SetPos(20,0)
	colorPicker.RGBBar:SetPos(0,0)
	colorPicker.txtR:SetPos(0,105)
	colorPicker.txtG:SetPos(40,105)
	colorPicker.txtB:SetPos(80,105)
	colorPicker:SetDrawBackground(false)
	
	if id and tag.rainbow then
		local rainbowCheckbox = xlib.makecheckbox{x=179, y=ystart+154, w=50, label="Rainbow", parent=window}
		rainbowCheckbox:SetChecked(true)
		rainbowCheckbox:SetDisabled(true)
		
		rainbowCheckbox.OnChange = function(self)
			if self:GetChecked() then
				colorPicker:SetDisabled(true)
				ulx.createNametagRainbow(previewText)
			else
				colorPicker:SetDisabled(false)
				ulx.removeNametagRainbow(previewText)
				previewText:SetColor(colorPicker:GetColor())
			end
		end
	end
	
	local previewLabel = xlib.makelabel{x=5, y=ystart+177, label="Preview:", parent=window}
	local previewPanel = xlib.makepanel{x=5, y=ystart+194, w=240, h=24, parent=window}
	previewPanel:SetBackgroundColor(Color(0,0,0))
	
	local previewText = xlib.makelabel{parent=previewPanel}
	previewText:SetFont("treb_small")
	if id then
		previewText:SetText(tag.content)
		previewText:SizeToContents()
		previewText:Center()
		
		if not tag.rainbow then
			previewText:SetColor(Color(tag.r, tag.g, tag.b))
		else
			ulx.createNametagRainbow(previewText)
		end
	end
	
	contentBox.OnTextChanged = function(self)
		previewText:SetText(self:GetText())
		previewText:SizeToContents()
		previewText:Center()
	end
	
	colorPicker.OnChangeImmediate = function(self, color)
		previewText:SetColor(color)
	end
	
	local addButton = xlib.makebutton({x=5, y=ystart+223, w=100, label=(id and "Update Name Tag" or "Add Name Tag"), parent=window})
	addButton.DoClick = function()
		if string.len(contentBox:GetValue()) > 0 and (id or string.len(idBox:GetValue()) > 0) then
			if group then
				if not id and not ULib.ucl.groups[idBox:GetValue()] then
					Derma_Query("That group doesn't exist!", "Invalid Group", "Okay", function() end)
					return
				end
			else
				if not id and not ULib.isValidSteamID(idBox:GetValue()) then
					Derma_Query("The Steam ID you've entered is invalid!", "Invalid Steam ID", "Okay", function() end)
					return
				end
			end
		
			if rainbowCheckbox:GetChecked() then
				RunConsoleCommand("ulx", (group and "grouptag" or "tagid"), id or idBox:GetValue(), contentBox:GetText(), 1)
			else
				local color = colorPicker:GetColor()
				RunConsoleCommand("ulx", (group and "grouptag" or "tagid"), id or idBox:GetValue(), contentBox:GetText(), 0, color.r, color.g, color.b)
			end
			window:Remove()
		else
			Derma_Query("Please fill in all the text boxes.", "Incomplete.", "Okay", function() end)
		end
	end
	local cancelButton = xlib.makebutton({x=110, y=ystart+223, w=50, label="Cancel", parent=window})
	cancelButton.DoClick = function()
		window:Remove()
	end
end