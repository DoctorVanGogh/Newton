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

function EventsHandler:SettingCheckChanged( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then
		return
	end
	
	local fnSetter = wndHandler:GetData()
	fnSetter(wndHandler:IsChecked())			
end

function EventsHandler:SectionItemCheckChange( wndHandler, wndControl, eMouseButton )
	
	if wndHandler ~= wndControl then
		return
	end
	local wndItem = wndHandler:GetParent():GetParent()
	local wndElements = wndItem:FindChild("ElementsContainer")
	
	local bChecked = wndHandler:IsChecked()
	local bCurrenlyChecked = wndElements:IsVisible()
	

	if bChecked ~= bCurrenlyChecked then
		local nLeft, nTop, nRight, nBottom = wndElements:GetAnchorOffsets()
		
		local nHeight = math.abs(nBottom - nTop)
		Print(tostring(nHeight).. " ".. tostring(bChecked))
		nLeft, nTop, nRight, nBottom = wndItem:GetAnchorOffsets()		
		if bChecked then
			wndItem:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeight)
			wndElements:Show(true)			
		else
			wndItem:SetAnchorOffsets(nLeft, nTop, nRight, nBottom - nHeight)
			wndElements:Show(false)		
		end
	end
end

function Configuration:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Configuration.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)		
end





function Configuration:OnDocumentReady()
	self.ready = true
end

-- @params tOptions
--  strDescription  	Descriptive text
--  clrDescription  	Color to use for description
function Configuration:CreateSection(wndParent, tOptions)
	if not self.ready then return end

	tOptions = tOptions or {}	
	
	local wndItem = Apollo.LoadForm(self.xmlDoc, "SectionItem", wndParent, nil)	

	local wndDescription = wndItem:FindChild("Title")
	wndDescription:SetText(tOptions.strDescription)
	if tOptions.clrDescription then
		wndDescription:SetTextColor(tOptions.clrDescription)
	end	

	return wndItem
end

-- @params tOptions
--  strDescription  	Descriptive text
--  clrDescription  	Color to use for description
function Configuration:CreateSectionCollapsible(wndParent, tOptions)
	if not self.ready then return end

	tOptions = tOptions or {}	
	
	local wndItem = Apollo.LoadForm(self.xmlDoc, "SectionItemCollapsible", wndParent, EventsHandler)	

	local wndDescription = wndItem:FindChild("EnableBtn")
	wndDescription:SetText(tOptions.strDescription)
	if tOptions.clrDescription then
		wndDescription:SetTextColor(tOptions.clrDescription)
	end	

	return wndItem
end


-- @params tOptions
--  fnValueSetter 		callback function to invoke on value selection
--  fnValueGetter   	callback function to retrieve current value
--  strDescription  	Descriptive text
--  clrDescription  	Color to use for description
function Configuration:CreateSettingItemBoolean(wndParent, tOptions)
	if not self.ready then return end

	tOptions = tOptions or {}			
	local fnValueGetter = tOptions.fnValueGetter or Apollo.NoOp
	local fnValueSetter = tOptions.fnValueSetter or Apollo.NoOp	
	local wndItem = Apollo.LoadForm(self.xmlDoc, "SettingItemBoolean", wndParent, EventsHandler)	

	local wndDescription = wndItem:FindChild("Description")
	wndDescription:SetText(tOptions.strDescription)
	if tOptions.clrDescription then
		wndDescription:SetTextColor(tOptions.clrDescription)
	end
	
	local wndCheck = wndItem:FindChild("Check")
	wndCheck:SetCheck(fnValueGetter())

	return wndItem
end

-- @params tOptions
--	tEnum 				table of avaliable values
--  tEnumNames 	 		table of value names (tEnumNames[*Somevalue*] = "SomeValueName")
--  tEnumDescriptions	table of value descriptions (used as tooltip) (tEnumDescriptions[*SomeValue*] = "SomeTooltip")
--  fnValueSetter 		callback function to invoke on value selection
--  fnValueGetter   	callback function to retrieve current value
--  nMinWidth			minimum initial width for popup texts (currently unused)
--  strHeader			popup header
--  strDescription  	Descriptive text
--  clrDescription  	Color to use for description
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
	
	return wndItem
end


-- @params tOptions
--	tEnum 				table of avaliable values
--  tEnumNames 	 		table of value names (tEnumNames[*Somevalue*] = "SomeValueName")
--  tEnumDescriptions	table of value descriptions (used as tooltip) (tEnumDescriptions[*SomeValue*] = "SomeTooltip")
--  fnValueSetter 		callback function to invoke on value selection
--  fnValueGetter   	callback function to retrieve current value
--  nMinWidth			minimum initial width for popup texts (currently unused)
--  strHeader			popup header
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
--	tEnum 				table of avaliable values
--  tEnumNames 	 		table of value names (tEnumNames[*Somevalue*] = "SomeValueName")
--  tEnumDescriptions	table of value descriptions (used as tooltip) (tEnumDescriptions[*SomeValue*] = "SomeTooltip")
--  fnValueSetter 		callback function to invoke on value selection
--  nMinWidth			minimum initial width for popup texts (currently unused)
--  strHeader			popup header
function Configuration:CreatePopup(wndParent, tOptions)
	if not self.ready then return end
		
	tOptions = tOptions or {}
	local tEnum = tOptions.tEnum or {}
	local tEnumNames = tOptions.tEnumNames or {}
	local tEnumDescriptions = tOptions.tEnumDescriptions or {}
	local fnValueSetter = tOptions.fnValueSetter or Apollo.NoOp
	local strHeader = tOptions.strHeader
	local nMinWidth = math.max(tOptions.nMinWidth or 0, 0)
	
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
			elseif idx == #tEnum then
				strFormName = "HoloEnumPopupElementBottom"
			else
				strFormName = "HoloEnumPopupElementMiddle"		
			end
		end
		
		local wndElement = Apollo.LoadForm(self.xmlDoc, strFormName, wndContainer, EventsHandler)
		local strName = tEnumNames[oElement] or tostring(oElement)
		wndElement:SetText(strName)
		wndElement:SetData({oElement, fnValueSetter})
		local strDescription = tEnumDescriptions[oElement]
		if strDescription then
			wndElement:SetTooltip(tostring(strDescription))
		end
		
		local nTextWidth = Apollo.GetTextWidth("CRB_Button", strName)		
		nMinWidth = math.max(nMinWidth, nTextWidth)		
	end	
	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	local nHeightTotal = wndContainer:ArrangeChildrenVert(0)
	
	wndPopup:SetAnchorOffsets(
		0, 
		0, 
		nMinWidth + math.abs(nLeft) + math.abs(nRight), 
		nHeightTotal + math.abs(nTop) + math.abs(nBottom)
	)
	return wndPopup
end

Apollo.RegisterPackage(
	Configuration, 
	MAJOR, 
	MINOR, 
	{
	}
)