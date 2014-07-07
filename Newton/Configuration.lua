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


-- @params tOptions
--	tEnum 			table of avaliable values
--  tEnumNames 	 	table of value names (tEnumNames[*Somevalue*] = "SomeValueDescription")
--  fnValueGetter   callback function to retrieve current value
--  fnValueSetter 	callback function to invoke on value selection
--  nMinWidth		minimum initial width for popup texts (currently unused)
--  strHeader		popup header
--  strDescription  Descriptive text
--  clrDescription  Color to use for description
function Configuration:CreateSettingItemEnum(wndParent, tOptions)
	if not self.ready then return end

	tOptions = tOptions or {}	
	local wndItem = Apollo.LoadForm(self.xmlDoc, "SettingItemEnum", wndParent, EventsHandler)
	local wndDropdownContainer = wndItem:FindChild("DropdownContainer")
	local wndDescription = wndItem:FindChild("Description")
	
	local wndDropdown = self:CreateDropdown(wndDropdownContainer, tOptions)
	wndDescription:SetText(tOptions.strDescription)
	if tOptions.clrDescription then
		wndDescription:SetTextColor(tOptions.clrDescription)
	end
	
	return wndDescription
end


-- @params tOptions
--	tEnum 			table of avaliable values
--  tEnumNames 	 	table of value names (tEnumNames[*Somevalue*] = "SomeValueDescription")
--  fnValueGetter   callback function to retrieve current value
--  fnValueSetter 	callback function to invoke on value selection
--  nMinWidth		minimum initial width for popup texts (currently unused)
--  strHeader		popup header
function Configuration:CreateDropdown(wndParent, tOptions)
	if not self.ready then return end

	tOptions = tOptions or {}	
	local tEnumNames = tOptions.tEnumNames or {}
	local fnValueGetter = tOptions.fnValueGetter or Apollo.NoOp
	
	local wndDropdown = Apollo.LoadForm(self.xmlDoc, "HoloDropdownSmall",  wndParent, EventsHandler)	
	local value = fnValueGetter()
	wndDropdown:SetText(tEnumNames[value] or tostring(value))
	wndDropdown:AttachWindow(self:CreatePopup(wndParent, tOptions))
	
	return wndDropdown
end


-- @params tOptions
--	tEnum 			table of avaliable values
--  tEnumNames 	 	table of value names (tEnumNames[*Somevalue*] = "SomeValueDescription")
--  fnValueSetter 	callback function to invoke on value selection
--  nMinWidth		minimum initial width for popup texts (currently unused)
--  strHeader		popup header
function Configuration:CreatePopup(wndParent, tOptions)
	if not self.ready then return end
		
	tOptions = tOptions or {}
	local tEnum = tOptions.tEnum or {}
	local tEnumNames = tOptions.tEnumNames or {}
	local fnValueSetter = tOptions.fnValueSetter or Apollo.NoOp
	local strHeader = tOptions.strHeader
	local nMinWidth = math.max(tOptions.nMinWidth or 0, 200)
	
	local wndPopup = Apollo.LoadForm(self.xmlDoc, "HoloEnumPopup",  wndParent, EventsHandler)
	local wndContainer = wndPopup:FindChild("ElementList")
	
	if strHeader then
		wndPopup:FindChild("Header"):SetText(strHeader)
	end
	
	for idx, oElement in ipairs(tEnum) do
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
		local strName = tEnumNames[oElement] or tostring(oElement)
		wndElement:SetText(strName)
		wndElement:SetData({oElement, fnValueSetter})
		
		local nTextWidth = Apollo.GetTextWidth("CRB_Button", strName)		
		nMinWidth = math.max(nMinWidth, nTextWidth)		
	end	
	return wndPopup
end

Apollo.RegisterPackage(
	Configuration, 
	MAJOR, 
	MINOR, 
	{
	}
)