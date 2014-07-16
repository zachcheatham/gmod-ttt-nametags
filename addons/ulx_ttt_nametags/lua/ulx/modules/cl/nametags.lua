---------------
--- Helpers ---
---------------
-- "Borrowed" function from EZRanks
local function rainbow()
	local red = math.sin(.5 * RealTime()) * 127 + 128
	local green = math.sin(.5 * RealTime() + 2) * 127 + 128
	local blue = math.sin(.5 * RealTime() + 4) * 127 + 128
	return Color(red, green, blue)
end

----------------------
--- Data Functions ---
----------------------
function ulx.populateNameTags(tags)
	ulx.nameTags = {}
	
	for steamid, tag in pairs(tags) do
		if tag.r and tag.g and tag.b then
			tag.color = Color(tag.r, tag.g, tag.b)
		end
		
		tag.r = nil
		tag.g = nil
		tag.b = nil
		
		ulx.nameTags[steamid] = tag
	end
end

function ulx.updateNameTag(steamid, tag)
	if not ulx.nameTags then
		ulx.nameTags = {}
	end
	
	if tag then
		if tag.r and tag.g and tag.b then
			tag.color = Color(tag.r, tag.g, tag.b)
		end
		
		tag.r = nil
		tag.g = nil
		tag.b = nil

		ulx.nameTags[steamid] = tag
	else
		ulx.nameTags[steamid] = nil
	end
end

-------------
--- HOOKS ---
-------------
function ulx.createNametagRainbow(lbl, parent)
	lbl.rainbowCreated = true
	
	lbl.Think = function(self)
		self:SetTextColor(rainbow())
	end
	
	if parent then
		parent.nick.Think = function(self)
			self:SetTextColor(rainbow())
		end
	end
end

function ulx.removeNametagRainbow(lbl, parent)
	lbl.Think = nil
	
	if parent then
		parent.nick.Think = nil
	end
	
	lbl.rainbowCreated = false
end

NAMETAG_COL_ID = 5
local function insertColumn(pnl)
	local col = pnl:AddColumn("", function(ply, lbl)
		if ulx.nameTags and ulx.nameTags[ply:SteamID()] then
			if ulx.nameTags[ply:SteamID()].rainbow then
				if not lbl.rainbowCreated then
					ulx.createNametagRainbow(lbl, pnl)
				end
			else
				lbl:SetColor(ulx.nameTags[ply:SteamID()].color)
				if lbl.rainbowCreated then
					ulx.removeNametagRainbow(lbl, pnl)
				end
			end
			return ulx.nameTags[ply:SteamID()].content
		elseif ulx.nameTags and ulx.nameTags[ply:GetUserGroup()] then
			if ulx.nameTags[ply:GetUserGroup()].rainbow then
				if not lbl.rainbowCreated then
					ulx.createNametagRainbow(lbl, pnl)
				end
			else
				lbl:SetColor(ulx.nameTags[ply:GetUserGroup()].color)
				if lbl.rainbowCreated then
					ulx.removeNametagRainbow(lbl, pnl)
				end
			end
			return ulx.nameTags[ply:GetUserGroup()].content
		else
			if lbl.rainbowCreated then
				pnl.nick.Think = nil
				lbl.Think = nil
				lbl.rainbowCreated = false
			end
		end
		return ""
	end, 0)
	
	-- Resize some things
	if not pnl.ply_groups then
		local oldLayoutColumns = pnl.LayoutColumns
		pnl.LayoutColumns = function(p)
			oldLayoutColumns(p)
			pnl.cols[5]:SizeToContents()
			pnl.cols[5]:SetPos(pnl:GetWide() - (90*5) - pnl.cols[5]:GetWide()/2, (SB_ROW_HEIGHT - pnl.cols[5]:GetTall()) / 2)
		end
	end
end
hook.Add("TTTScoreboardColumns", "TTTNameTagsColumn", insertColumn)

local function colorForPlayer(ply)
	if ulx.nameTags and ulx.nameTags[ply:SteamID()] then
		if ulx.nameTags[ply:SteamID()].rainbow then
			return nil
		else
			return ulx.nameTags[ply:SteamID()].color
		end
	elseif ulx.nameTags and ulx.nameTags[ply:GetUserGroup()] then
		if ulx.nameTags[ply:GetUserGroup()].rainbow then
			return nil
		else
			return ulx.nameTags[ply:GetUserGroup()].color
		end
	else
		return nil
	end
end
hook.Add("TTTScoreboardColorForPlayer", "TTTNameTagsColor", colorForPlayer)

local function addMenuOption(menu)
	local opt = false
	if LocalPlayer():query("ulx tag") then
		menu:AddSpacer()
		opt = menu:AddOption("Change Tag", function()
			ulx.showNameTagAdminScoreboardWindow(menu.Player)
		end)
	elseif ulx.nameTags[LocalPlayer():SteamID()] then
		menu:AddSpacer()
		opt = menu:AddOption("Request Tag", function()
			ulx.showNameTagScoreboardWindow(menu.Player)
		end)
	end
	
	if opt then
		opt:SetIcon("icon16/palette.png")
		opt:SetTextInset(0,0)
	end
end
hook.Add("SQCMenu", "NameTagsOption", addMenuOption)

--------------------------
--- Scoreboard Dialogs ---
--------------------------
function ulx.showNameTagRequestDialog()
	local w,h = 250,189
	
	local frame = vgui.Create("DFrame")
	frame:SetSize(w, h)
	frame:SetTitle("Name Tag Change Request")
	frame:Center()
	
	local contentbox = vgui.Create("DTextEntry", frame)
	contentbox:SetValue(ulx.nameTags[LocalPlayer():SteamID()].content)
	contentbox:StretchToParent(5, 30, 5, 0)
	contentbox:SetTall(25)
	
	local colormixer = vgui.Create("DColorMixer", frame)
	colormixer:SetColor(ulx.nameTags[LocalPlayer():SteamID()].color)
	colormixer:SetWangs(true)
	colormixer:SetAlphaBar(false)
	colormixer:SetPalette(false)
	colormixer:StretchToParent(5, 60, 5, 0)
	colormixer:SetTall(68)
	
	local previewpanel = vgui.Create("DPanel", frame)
	previewpanel:SetBackgroundColor(Color(0, 0, 0))
	previewpanel:StretchToParent(5, 133, 5, 0)
	previewpanel:SetTall(24)
	
	local previewtext = vgui.Create("DLabel", previewpanel)
	previewtext:SetFont("treb_small")
	previewtext:SetText(ulx.nameTags[LocalPlayer():SteamID()].content)	
	previewtext:SetColor(ulx.nameTags[LocalPlayer():SteamID()].color)	
	previewtext:SizeToContents()
	previewtext:Center()
	
	
	local submitButton = vgui.Create("DButton", frame)	
	submitButton:SetText("Submit Request")
	submitButton:SetWidth(100)
	submitButton:SetPos(5, 162)
	
	submitButton.DoClick = function()
		local color = colormixer:GetColor()
		RunConsoleCommand("ulx", "requesttag", contentbox:GetValue(), color.r, color.g, color.b)
		frame:Remove()
	end
	
	colormixer.ValueChanged = function(self, color)
		previewtext:SetColor(color)
	end
	
	contentbox.OnTextChanged = function(self)
		previewtext:SetText(contentbox:GetValue())
		previewtext:SizeToContents()
		previewtext:Center()
	end
	
	frame:MakePopup()
end

function ulx.showNameTagDialog(target_ply)
	if ulx.nameTags[target_ply:SteamID()] and ulx.nameTags[target_ply:SteamID()].rainbow then
		Derma_Query("You may only change rainbow tags via the data file!", "Rainbow Tags", "Okay")
		return
	end
	
	local steamID = target_ply:SteamID()
	local w,h = 250,189
	
	local frame = vgui.Create("DFrame")
	frame:SetSize(w, h)
	frame:SetTitle(Format("Set %s's Name Tag", target_ply:Nick()))
	frame:Center()
	
	local contentbox = vgui.Create("DTextEntry", frame)
	if ulx.nameTags[steamID] then
		contentbox:SetValue(ulx.nameTags[steamID].content)
	end
	contentbox:StretchToParent(5, 30, 5, 0)
	contentbox:SetTall(25)
	
	local colormixer = vgui.Create("DColorMixer", frame)
	if ulx.nameTags[steamID] then
		colormixer:SetColor(ulx.nameTags[steamID].color)
	end
	colormixer:SetWangs(true)
	colormixer:SetAlphaBar(false)
	colormixer:SetPalette(false)
	colormixer:StretchToParent(5, 60, 5, 0)
	colormixer:SetTall(68)
	
	local previewpanel = vgui.Create("DPanel", frame)
	previewpanel:SetBackgroundColor(Color(0, 0, 0))
	previewpanel:StretchToParent(5, 133, 5, 0)
	previewpanel:SetTall(24)
	
	local previewtext = vgui.Create("DLabel", previewpanel)
	previewtext:SetFont("treb_small")
	if ulx.nameTags[steamID] then
		previewtext:SetText(ulx.nameTags[steamID].content)	
		previewtext:SetColor(ulx.nameTags[steamID].color)
	else
		previewtext:SetText("")
	end
	previewtext:SizeToContents()
	previewtext:Center()
	
	local submitButton = vgui.Create("DButton", frame)	
	submitButton:SetText("Set Tag")
	submitButton:SetWidth(100)
	submitButton:SetPos(5, 162)

	submitButton.DoClick = function()
		local color = colormixer:GetColor()
		RunConsoleCommand("ulx", "tag", target_ply:Nick(), contentbox:GetValue(), color.r, color.g, color.b)
		frame:Remove()
	end
	
	colormixer.ValueChanged = function(self, color)
		previewtext:SetColor(color)
	end
	
	contentbox.OnTextChanged = function(self)
		previewtext:SetText(contentbox:GetValue())
		previewtext:SizeToContents()
		previewtext:Center()
	end
	
	frame:MakePopup()
end
