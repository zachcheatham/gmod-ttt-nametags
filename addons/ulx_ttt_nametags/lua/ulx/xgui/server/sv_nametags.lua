local nametags = {}

function nametags.init()
	ULib.ucl.registerAccess("xgui_managenametags", "superadmin", "Allows creating, approving, and editing nametags in XGUI.", "XGUI")

	xgui.addDataType("nametags", function() return ulx.nameTags end, "xgui_managenametags", 60, 0)
	xgui.addDataType("nametagrequests", function() return ulx.nameTagRequests end, "xgui_managenametags", 60, 0)
	xgui.addDataType("groupnametags", function() return ulx.groupNameTags end, "xgui_managenametags", 60, 0)
end

xgui.addSVModule("nametags", nametags.init, nametags.postinit)