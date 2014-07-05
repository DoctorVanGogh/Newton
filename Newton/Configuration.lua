-----------------------------------------------------------------------------------------------
-- Comfiguration package
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------

local MAJOR,MINOR = "DoctorVanGogh:Lib:Configuration", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end



local Configuration = APkg and APkg.tPackage or {}

local EventsHandler = {}

function EventsHandler:OnSignalEnumCoice(wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then
		return
	end
	
	local data = wndHandler:GetData()
	local value = data[1]
	local fnSetter = data[2]
	
	fnSetter(value)	
	
	wndHandler:GetParent():GetParent():Close()
end

function EventsHandler:OnClosePopup(wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then
		return
	end
	
	wndHandler:GetParent():Close()
end

function Configuration:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Configuration.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)		
end

function Configuration:OnDocumentReady()
	self.ready = true
end

function Configuration:CreateDropdown(tOptions, tNames, fnGetValue, fnSetValue, nMinWidth, strHeader)
	if not self.ready then return end

	local wndDropdown = Apollo.LoadForm(self.xmlDoc, "HoloDropdownSmall",  nil, EventsHandler)	
	wndDropdown:SetText(tNames[fnGetValue()])
	wndDropdown:AttachWindow(self:CreatePopup(wndDropdown, tOptions, tNames, fnSetValue, nMinWidth, strHeader))
	
	return wndDropdown
end


function Configuration:CreatePopup(wndParent, tOptions, tNames, fnSetValue, nMinWidth, strHeader)
	if not self.ready then return end
	
	local wndPopup = Apollo.LoadForm(self.xmlDoc, "HoloEnumPopup",  wndParent, EventsHandler)
	local wndContainer = wndPopup:FindChild("ElementList")
	local nMinWidth = nMinWidth or 0
	nMinWidth = math.max(nMinWidth, 200)
	
	if strHeader then
		wndPopup:FindChild("Header"):SetText(strHeader)
	end
	
	for idx, tElement in ipairs(tOptions) do
		local strFormName
		if #tOptions == 1 then
			strFormName = "HoloEnumPopupElementSingle"
		else
			if idx == 1 then
				strFormName = "HoloEnumPopupElementTop"
			elseif idx == #tOptions then
				strFormName = "HoloEnumPopupElementBottom"
			else
				strFormName = "HoloEnumPopupElementMiddle"		
			end
		end
		
		local wndElement = Apollo.LoadForm(self.xmlDoc, strFormName, wndContainer, EventsHandler)
		wndElement:SetText(tNames[tElement])
		wndElement:SetData({tElement, fnSetValue})
		
		local nTextWidth = Apollo.GetTextWidth("CRB_Button",tNames[tElement])		
		nMinWidth = math.max(nMinWidth, nTextWidth)		
	end
	--[[
	local nLeft, nTop, nRight, nBottom = wndPopup:GetAnchorOffsets()
	local nParentTop = nTop	
	nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	local nHeightTotal = wndContainer:ArrangeChildrenVert(0)
	
	wndPopup:SetAnchorOffsets(
		0, 
		nParentTop, 
		nMinWidth + math.abs(nLeft) + math.abs(nRight), 
		nParentTop + nHeightTotal + math.abs(nTop) + math.abs(nBottom)
	)
	]]
	
	return wndPopup
end

Apollo.RegisterPackage(
	Configuration, 
	MAJOR, 
	MINOR, 
	{
	}
)