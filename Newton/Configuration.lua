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

local GeminiLogging
local glog

local EventsHandler = {}

function EventsHandler:OnSignalEnumCoice(wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then
		return
	end
	
	local data = wndHandler:GetData()
	local value = data[1]
	local fnSetter = data[2]
	
	fnSetter(value)	
	
	wndHandler:GetParent():GetParent():GetParent():Close()
	--wndHandler:GetParent():GetParent()
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
	
	local bChecked = wndHandler:IsChecked()
	local fnSetter = wndHandler:GetData()
	
	if fnSetter and (type(fnSetter) == "function" or (type(fnSetter) == "table" and fnSetter.__call)) then
		fnSetter(bChecked)	
	end
	
end

function EventsHandler:SectionItemCheckChange( wndHandler, wndControl, eMouseButton )
	
	if wndHandler ~= wndControl then
		return
	end
	local wndItem = wndHandler:GetParent():GetParent()
	local wndElements = wndItem:FindChild("ElementsContainer")
	
	local bChecked = wndHandler:IsChecked()
	local bCurrentlyChecked = wndElements:IsVisible()
	
	if bChecked ~= bCurrentlyChecked then	
		Configuration:ExpandSection(wndItem, bChecked)
	end
end

function EventsHandler:ShowPopup( wndHandler, wndControl )
	if wndHandler ~= wndControl then
		return
	end
	
	wndHandler:ToFront()
end

function Configuration:OnLoad()
	GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.DEBUG,
		pattern = "%d [%c:%n] %l - %m",
		appender = "GeminiConsole"
	})	

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

	Configuration:SizeSectionToContent(wndItem)
	Configuration:UpdateCollapsibleSectionHeight(wndItem)	
	
	return wndItem
end

function Configuration:ExpandSection(wndSection, bExpanded)
	local wndElements = wndSection:FindChild("ElementsContainer")
	local nLeft, nTop, nRight, nBottom = wndSection:GetAnchorOffsets()
	local nElementsLeft, nElementsTop, nElementsRight, nElementsBottom = wndElements:GetAnchorOffsets()

	if bExpanded then
		local nHeight = wndElements:GetData()
		wndElements:Show(true)	
		wndSection:SetAnchorOffsets(nLeft, nTop, nRight, nTop + math.abs(nElementsTop) + math.abs(nElementsBottom) + nHeight)
		wndSection:SetSprite("BK3:UI_BK3_Holo_InsetHeaderThin")
	else
		wndSection:SetSprite("BK3:UI_BK3_Holo_InsetSimple")
		wndSection:SetAnchorOffsets(nLeft, nTop, nRight, nTop + math.abs(nElementsTop) + math.abs(nElementsBottom))		
		wndElements:Show(false)		
	end	
end

function Configuration:UpdateCollapsibleSectionHeight(wndSection)
	local wndContainer = wndSection:FindChild("ElementsContainer")
	wndContainer:SetData(wndContainer:GetHeight())
end

function Configuration:SizeSectionToContent(wndSection)
	local wndContainer = wndSection:FindChild("ElementsContainer")
	local nHeight = wndContainer:ArrangeChildrenVert(0)
	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	nHeight = nHeight + math.abs(nTop) + math.abs(nBottom)
	nLeft, nTop, nRight, nBottom = wndSection:GetAnchorOffsets()
	wndSection:SetAnchorOffsets(nLeft, nTop, nRight, nHeight)
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
	wndCheck:SetData(fnValueSetter)

	return wndItem, wndCheck
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
	
	return wndItem, wndDropdown
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
	local fnValueSetter = tOptions.fnValueSetter or Apollo.NoOp
	
	local wndDropdown = Apollo.LoadForm(self.xmlDoc, "HoloDropdownSmall",  wndParent, EventsHandler)	
	local value = fnValueGetter()
	
	tOptions.fnValueSetter = function(v)
		wndDropdown:SetText(tEnumNames[v] or tostring(v))
		return fnValueSetter(v)
	end
	
	wndDropdown:SetText(tEnumNames[value] or tostring(value))
	local wndPopup = self:CreatePopup(wndParent, tOptions)
	wndDropdown:AttachWindow(wndPopup)	
	
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
	
	glog:debug("%s", inspect(tOptions))
	
	local tEnum = tOptions.tEnum or {}
	local tEnumNames = tOptions.tEnumNames or {}
	local tEnumDescriptions = tOptions.tEnumDescriptions or {}
	local fnValueSetter = tOptions.fnValueSetter or Apollo.NoOp
	local strHeader = tOptions.strHeader
	local nMinWidth = math.max(tOptions.nMinWidth or 0, 80)
	
	local wndPopup = Apollo.LoadForm(self.xmlDoc, "HoloEnumPopup",  wndParent, EventsHandler)
	local wndContainer = wndPopup:FindChild("ElementList")
		
	wndPopup:FindChild("Header"):SetText(strHeader)		
	
	for idx, oElement in ipairs(tEnum) do
		local strFormName
		if #tEnum == 1 then
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
		local wndButton = wndElement:FindChild("Button")
		wndButton:SetText(strName)
		wndButton:SetData({oElement, fnValueSetter})
		local strDescription = tEnumDescriptions[oElement]
		if strDescription then
			wndButton:SetTooltip(tostring(strDescription))
		end
		
		local nTextWidth = Apollo.GetTextWidth("CRB_Button", strName)		
		nMinWidth = math.max(nMinWidth, nTextWidth)		
	end	
	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	local nHeightTotal = wndContainer:ArrangeChildrenVert(0)
	
	nMinWidth = nMinWidth + 14 			-- Button uses some hardcoded padding values left & right!
		
	wndPopup:SetAnchorOffsets(
		0, 
		0, 
		nMinWidth + math.abs(nLeft) + math.abs(nRight), 
		nHeightTotal + math.abs(nTop) + math.abs(nBottom)
	)
	return wndPopup
end

function Configuration:ToCallback(tTable, oKey) 
	if not tTable then
		error("Table may not be nil")
	end
	
	if not oKey then
		error("Key may not be nil")
	end
	
	local clb = tTable[oKey]
	if not clb then
		error("Key must exist in table.")
	end	
	
	if type(clb) ~="function" then
		error("Key in table must be a function")
	end
	
	return setmetatable(
		{
			owner = tTable,
			key = oKey
		},
		{
			__mode="v",
			__call=function(t, ...) 
				return t.owner[t.key](t.owner, unpack(arg))
			end
		}	
	)
	
	
end

Apollo.RegisterPackage(
	Configuration, 
	MAJOR, 
	MINOR, 
	{
		"Gemini:Logging-1.2"
	}
)