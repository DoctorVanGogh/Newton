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

-- GeminiGUI Window definitions
local tHoloDropdownSmallDef = {
	AnchorOffsets = { 0, -12, 0, 12 },
	AnchorPoints = { 0, 0.5, 1, 0.5 },
	Class = "Button", 
	Base = "CRB_Basekit:kitBtn_Dropdown_TextBaseHolo", 
	Font = "DefaultButton", 
	ButtonType = "Check", 
	DT_VCENTER = true, 
	DT_CENTER = true, 
	BGColor = "UI_BtnBGDefault", 
	TextColor = "UI_BtnTextDefault", 
	NormalTextColor = "UI_BtnTextHoloNormal", 
	PressedTextColor = "UI_BtnTextHoloPressed", 
	FlybyTextColor = "UI_BtnTextHoloFlyby", 
	PressedFlybyTextColor = "UI_BtnTextHoloPressedFlyby", 
	DisabledTextColor = "UI_BtnTextHoloDisabled", 
	Name = "HoloDropdownSmall", 
	WindowSoundTemplate = "HoloDropdownToggle", 
}
local tHoloEnumPopupDef = {
	AnchorOffsets = { 0, 0, 200, 200 },
	AnchorPoints = "TOPRIGHT",
	RelativeToClient = true, 
	BGColor = "UI_WindowBGDefault", 
	TextColor = "UI_WindowTextDefault", 
	Name = "HoloEnumPopup", 
	Picture = true, 
	SwallowMouseClicks = true, 
	Overlapped = true, 
	NoClip = true, 
	CloseOnExternalClick = true, 
	Visible = false, 
	Events = {
		WindowShow = "ShowPopup",
	},
	Children = {
		{
			AnchorOffsets = { 0, 22, 0, -163 },
			AnchorPoints = "FILL",
			RelativeToClient = true, 
			Font = "CRB_InterfaceSmall", 
			Text = "[Header]", 
			BGColor = "UI_WindowBGDefault", 
			TextColor = "UI_WindowTitleYellow", 
			Name = "Header", 
			DT_CENTER = true, 
		},
		{
			AnchorOffsets = { -20, -23, 20, 22 },
			AnchorPoints = "FILL",
			RelativeToClient = true, 
			BGColor = "UI_WindowBGDefault", 
			TextColor = "UI_WindowTextDefault", 
			Name = "HoloFrame", 
			Sprite = "BK3:sprHolo_Alert_Flyout", 
			Picture = true, 
			IgnoreMouse = true, 
			NoClip = true, 
		},
		{
			AnchorOffsets = { -33, 22, -10, 42 },
			AnchorPoints = "TOPRIGHT",
			Class = "Button", 
			Base = "CRB_Basekit:kitBtn_Holo_Close2", 
			Font = "DefaultButton", 
			ButtonType = "PushButton", 
			DT_VCENTER = true, 
			DT_CENTER = true, 
			BGColor = "UI_BtnBGDefault", 
			TextColor = "UI_BtnTextDefault", 
			NormalTextColor = "UI_BtnTextDefault", 
			PressedTextColor = "UI_BtnTextDefault", 
			FlybyTextColor = "UI_BtnTextDefault", 
			PressedFlybyTextColor = "UI_BtnTextDefault", 
			DisabledTextColor = "UI_BtnTextDefault", 
			Name = "CloseBtn", 
			Template = "HoloWindowSound", 
			Events = {
				ButtonSignal = "OnClosePopup",
			},
		},
		{
			AnchorOffsets = { 20, 44, -20, -23 },
			AnchorPoints = "FILL",
			RelativeToClient = true, 
			BGColor = "UI_WindowBGDefault", 
			TextColor = "UI_WindowTextDefault", 
			Name = "ElementList", 
			IgnoreMouse = true, 
			Overlapped = true, 
		},
	},
}

local tSectionItemDef = {
	AnchorOffsets = { 0, 0, 0, 106 },
	AnchorPoints = "HFILL",
	RelativeToClient = true, 
	BGColor = "UI_WindowBGDefault", 
	TextColor = "UI_WindowTextDefault", 
	Name = "SectionItem", 
	Border = true, 
	Picture = true, 
	SwallowMouseClicks = true, 
	Escapable = true, 
	Overlapped = true, 
	Sprite = "BK3:UI_BK3_Holo_InsetHeaderThin", 
	Children = {
		{
			AnchorOffsets = { 0, 0, 0, 35 },
			AnchorPoints = "HFILL",
			RelativeToClient = true, 
			BGColor = "UI_WindowBGDefault", 
			TextColor = "UI_WindowTextDefault", 
			Name = "Header", 
			Children = {
				{
					AnchorOffsets = { 6, 4, -4, -4 },
					AnchorPoints = "FILL",
					RelativeToClient = true, 
					Font = "CRB_HeaderMedium", 
					Text = "[Title]", 
					BGColor = "UI_WindowBGDefault", 
					TextColor = "UI_WindowTitleYellow", 
					Name = "Title", 
					DT_VCENTER = true, 
				},
			},
		},
		{
			AnchorOffsets = { 2, 37, -2, -4 },
			AnchorPoints = "FILL",
			RelativeToClient = true, 
			BGColor = "UI_WindowBGDefault", 
			TextColor = "UI_WindowTextDefault", 
			Name = "ElementsContainer", 
		},
	},
}
local tSectionItemCollapsibleDef = {
	AnchorOffsets = { 0, 0, 0, 106 },
	AnchorPoints = "HFILL",
	RelativeToClient = true, 
	BGColor = "UI_WindowBGDefault", 
	TextColor = "UI_WindowTextDefault", 
	Name = "SectionItemCollapsible", 
	Border = true, 
	Picture = true, 
	SwallowMouseClicks = true, 
	Escapable = true, 
	Overlapped = true, 
	Sprite = "BK3:UI_BK3_Holo_InsetHeaderThin", 
	Children = {
		{
			AnchorOffsets = { 0, 0, 0, 35 },
			AnchorPoints = "HFILL",
			RelativeToClient = true, 
			BGColor = "UI_WindowBGDefault", 
			TextColor = "UI_WindowTextDefault", 
			Name = "Header", 
			Children = {
				{
					AnchorOffsets = { 6, 4, -4, -4 },
					AnchorPoints = "FILL",
					Class = "Button", 
					Base = "BK3:btnHolo_ExpandCollapseSmall", 
					Font = "CRB_HeaderMedium", 
					ButtonType = "Check", 
					DT_VCENTER = true, 
					BGColor = "UI_BtnBGDefault", 
					TextColor = "UI_WindowTitleYellow", 
					NormalTextColor = "UI_BtnTextDefault", 
					PressedTextColor = "UI_BtnTextDefault", 
					FlybyTextColor = "UI_BtnTextDefault", 
					PressedFlybyTextColor = "UI_BtnTextDefault", 
					DisabledTextColor = "UI_BtnTextDefault", 
					Name = "EnableBtn", 
					DrawAsCheckbox = true, 
					UseWindowTextColor = true, 
					Text = "[Title]", 
					WindowSoundTemplate = "HoloDropdownToggle", 
					TooltipFont = "CRB_InterfaceSmall", 
					CheckboxRight = true, 
					Events = {
						ButtonCheck = "SectionItemCheckChange",
						ButtonUncheck = "SectionItemCheckChange",
					},
				},
			},
		},
		{
			AnchorOffsets = { 2, 37, -2, -2 },
			AnchorPoints = "FILL",
			RelativeToClient = true, 
			BGColor = "UI_WindowBGDefault", 
			TextColor = "UI_WindowTextDefault", 
			Name = "ElementsContainer", 
		},
	},
}

local tSettingItemBooleanDef = {
	AnchorOffsets = { 0, 0, 0, 35 },
	AnchorPoints = "HFILL",
	RelativeToClient = true, 
	Font = "CRB_InterfaceMedium", 
	BGColor = "UI_WindowBGDefault", 
	TextColor = "UI_TextHoloBody", 
	Name = "SettingItemBoolean", 
	DT_WORDBREAK = true, 
	Children = {
		{
			AnchorOffsets = { 6, 2, 343, -2 },
			AnchorPoints = { 0, 0, 0.67, 1 },
			RelativeToClient = true, 
			Font = "CRB_InterfaceMedium_BO", 
			Text = "[Description]", 
			BGColor = "UI_WindowBGDefault", 
			TextColor = "UI_TextHoloTitle", 
			Name = "Description", 
			DT_VCENTER = true, 
		},
		{
			AnchorOffsets = { -29, 3, 0, 0 },
			AnchorPoints = "VFILLRIGHT",
			Class = "Button", 
			Base = "BK3:btnHolo_Check", 
			Font = "CRB_Button", 
			ButtonType = "Check", 
			DT_VCENTER = true, 
			DT_CENTER = true, 
			BGColor = "UI_BtnBGDefault", 
			TextColor = "UI_BtnTextDefault", 
			NormalTextColor = "UI_BtnTextHoloNormal", 
			PressedTextColor = "UI_BtnTextHoloPressed", 
			FlybyTextColor = "UI_BtnTextHoloFlyby", 
			PressedFlybyTextColor = "UI_BtnTextHoloPressedFlyby", 
			DisabledTextColor = "UI_BtnTextHoloDisabled", 
			Name = "Check", 
			CheckboxRight = true, 
			DrawAsCheckbox = false, 
			WindowSoundTemplate = "HoloButtonSmall", 
			Events = {
				ButtonCheck = "SettingCheckChanged",
				ButtonUncheck = "SettingCheckChanged",
			},
		},
	},
}
local tSettingItemEnumDef = {
	AnchorOffsets = { 0, 0, 0, 35 },
	AnchorPoints = "HFILL",
	RelativeToClient = true, 
	Font = "CRB_InterfaceMedium", 
	BGColor = "", 
	TextColor = "UI_TextHoloTitle", 
	Name = "SettingItemEnum", 
	DT_WORDBREAK = true, 
	Overlapped = true, 
	Children = {
		{
			AnchorOffsets = { 6, 2, -2, -2 },
			AnchorPoints = { 0, 0, 0.67, 1 },
			RelativeToClient = true, 
			Font = "CRB_InterfaceMedium_BO", 
			Text = "[Description]", 
			BGColor = "UI_WindowBGDefault", 
			TextColor = "UI_TextHoloTitle", 
			Name = "Description", 
			DT_VCENTER = true, 
		},
		{
			AnchorOffsets = { 2, 2, -2, -2 },
			AnchorPoints = { 0.67, 0, 1, 1 },
			RelativeToClient = true, 
			BGColor = "UI_WindowBGDefault", 
			TextColor = "UI_WindowTextDefault", 
			Name = "DropdownContainer", 
		},
	},
}

local tHoloEnumPopupElementSingleDef = {
	AnchorOffsets = { 0, 0, 0, 28 },
	AnchorPoints = "HFILL",
	RelativeToClient = true, 
	BGColor = "UI_WindowBGDefault", 
	TextColor = "UI_WindowTextDefault", 
	Name = "HoloEnumPopupElementSingle", 
	SwallowMouseClicks = true, 
	Children = {
		{
			AnchorOffsets = { 0, 0, 0, 30 },
			AnchorPoints = "HFILL",
			Class = "Button", 
			Base = "BK3:btnHolo_ListView_Simple", 
			Font = "CRB_Button", 
			ButtonType = "PushButton", 
			DT_VCENTER = true, 
			DT_CENTER = true, 
			BGColor = "UI_BtnBGDefault", 
			TextColor = "UI_BtnTextHoloNormal", 
			NormalTextColor = "UI_BtnTextHoloNormal", 
			PressedTextColor = "UI_BtnTextHoloPressed", 
			FlybyTextColor = "UI_BtnTextHoloFlyby", 
			PressedFlybyTextColor = "UI_BtnTextHoloPressedFlyby", 
			DisabledTextColor = "UI_BtnTextHoloDisabled", 
			Name = "Button", 
			Template = "HoloWindowSound", 
			WindowSoundTemplate = "HoloButtonSmall", 
			TooltipFont = "CRB_InterfaceSmall", 
			Overlapped = true, 
			Events = {
				ButtonSignal = "OnSignalEnumCoice",
			},
		},
	},
}
local tHoloEnumPopupElementTopDef = {
	AnchorOffsets = { 0, 0, 0, 28 },
	AnchorPoints = "HFILL",
	RelativeToClient = true, 
	BGColor = "UI_WindowBGDefault", 
	TextColor = "UI_WindowTextDefault", 
	Name = "HoloEnumPopupElementTop", 
	SwallowMouseClicks = true, 
	Children = {
		{
			AnchorOffsets = { 0, 0, 0, 30 },
			AnchorPoints = "HFILL",
			Class = "Button", 
			Base = "BK3:btnHolo_ListView_Top", 
			Font = "CRB_Button", 
			ButtonType = "PushButton", 
			DT_VCENTER = true, 
			DT_CENTER = true, 
			BGColor = "UI_BtnBGDefault", 
			TextColor = "UI_BtnTextHoloNormal", 
			NormalTextColor = "UI_BtnTextHoloNormal", 
			PressedTextColor = "UI_BtnTextHoloPressed", 
			FlybyTextColor = "UI_BtnTextHoloFlyby", 
			PressedFlybyTextColor = "UI_BtnTextHoloPressedFlyby", 
			DisabledTextColor = "UI_BtnTextHoloDisabled", 
			Name = "Button", 
			Template = "HoloWindowSound", 
			WindowSoundTemplate = "HoloButtonSmall", 
			TooltipFont = "CRB_InterfaceSmall", 
			Overlapped = true, 
			Events = {
				ButtonSignal = "OnSignalEnumCoice",
			},
		},
	},
}
local tHoloEnumPopupElementMiddleDef = {
	AnchorOffsets = { 0, 0, 0, 28 },
	AnchorPoints = "HFILL",
	RelativeToClient = true, 
	BGColor = "UI_WindowBGDefault", 
	TextColor = "UI_WindowTextDefault", 
	Name = "HoloEnumPopupElementMiddle", 
	SwallowMouseClicks = true, 
	Children = {
		{
			AnchorOffsets = { 0, 0, 0, 30 },
			AnchorPoints = "HFILL",
			Class = "Button", 
			Base = "BK3:btnHolo_ListView_Mid", 
			Font = "CRB_Button", 
			ButtonType = "PushButton", 
			DT_VCENTER = true, 
			DT_CENTER = true, 
			BGColor = "UI_BtnBGDefault", 
			TextColor = "UI_BtnTextHoloNormal", 
			NormalTextColor = "UI_BtnTextHoloNormal", 
			PressedTextColor = "UI_BtnTextHoloPressed", 
			FlybyTextColor = "UI_BtnTextHoloFlyby", 
			PressedFlybyTextColor = "UI_BtnTextHoloPressedFlyby", 
			DisabledTextColor = "UI_BtnTextHoloDisabled", 
			Name = "Button", 
			Template = "HoloWindowSound", 
			WindowSoundTemplate = "HoloButtonSmall", 
			TooltipFont = "CRB_InterfaceSmall", 
			Overlapped = true, 
			Events = {
				ButtonSignal = "OnSignalEnumCoice",
			},
		},
	},
}
local tHoloEnumPopupElementBottomDef = {
	AnchorOffsets = { 0, 0, 0, 28 },
	AnchorPoints = "HFILL",
	RelativeToClient = true, 
	BGColor = "UI_WindowBGDefault", 
	TextColor = "UI_WindowTextDefault", 
	Name = "HoloEnumPopupElementBottom", 
	SwallowMouseClicks = true, 
	Children = {
		{
			AnchorOffsets = { 0, 0, 0, 30 },
			AnchorPoints = "HFILL",
			Class = "Button", 
			Base = "BK3:btnHolo_ListView_Btm", 
			Font = "CRB_Button", 
			ButtonType = "PushButton", 
			DT_VCENTER = true, 
			DT_CENTER = true, 
			BGColor = "UI_BtnBGDefault", 
			TextColor = "UI_BtnTextHoloNormal", 
			NormalTextColor = "UI_BtnTextHoloNormal", 
			PressedTextColor = "UI_BtnTextHoloPressed", 
			FlybyTextColor = "UI_BtnTextHoloFlyby", 
			PressedFlybyTextColor = "UI_BtnTextHoloPressedFlyby", 
			DisabledTextColor = "UI_BtnTextHoloDisabled", 
			Name = "Button", 
			Template = "HoloWindowSound", 
			WindowSoundTemplate = "HoloButtonSmall", 
			TooltipFont = "CRB_InterfaceSmall", 
			Overlapped = true, 
			Events = {
				ButtonSignal = "OnSignalEnumCoice",
			},
		},
	},
}

-- shared event handler table for window elements
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
		local fnCallback = wndHandler:GetData()
		if fnCallback then
			fnCallback()
		end
	end
end

function EventsHandler:ShowPopup( wndHandler, wndControl )
	if wndHandler ~= wndControl then
		return
	end
	
	wndHandler:Invoke()
end


-- Configuration definition
function Configuration:OnLoad()
	GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.INFO,
		pattern = "%d [%c:%n] %l - %m",
		appender = "GeminiConsole"
	})	
	self.log = glog

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
--  strDescription  			Descriptive text
--  clrDescription  			Color to use for description
--  fnCallbackExpandCollapse	Callback to invoke on expand/collapse
function Configuration:CreateSectionCollapsible(wndParent, tOptions)
	if not self.ready then return end

	tOptions = tOptions or {}	
	
	local wndItem = Apollo.LoadForm(self.xmlDoc, "SectionItemCollapsible", wndParent, EventsHandler)	

	local wndDescription = wndItem:FindChild("EnableBtn")
	wndDescription:SetText(tOptions.strDescription)
	if tOptions.clrDescription then
		wndDescription:SetTextColor(tOptions.clrDescription)
	end	
	wndDescription:SetData(tOptions.fnCallbackExpandCollapse)		
	
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
	self.log:debug("Calculated heeight for section content: %f", nHeight)
	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	nHeight = nHeight + math.abs(nTop) + math.abs(nBottom)
	nLeft, nTop, nRight, nBottom = wndSection:GetAnchorOffsets()
	wndSection:SetAnchorOffsets(nLeft, 0, nRight, nHeight)
	self.log:debug("Actual heeight for section content: %f", wndSection:GetHeight())	
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

function Configuration:ToCallback(tTable, oKey, ...) 
	if not tTable then
		error("Table may not be nil")
	end
	
	if not oKey then
		error("Key may not be nil")
	end
	
	local clb = tTable[oKey]
	if not clb then
		error(string.format("Key '%s' must exist in table.", tostring(oKey)))
	end	
	
	if type(clb) ~="function" then
		error("Key in table must be a function")
	end
			
	local result =  setmetatable(
		{
			owner = tTable,
			key = oKey,
			args = arg
		},
		{
			-- GOTCHA: can't use weak values, t.args would get collected otherwise (no external references)
			__call=function(t, ...) 
				if t.args and #t.args ~= 0 then
					local tArgs = {}
					for _, v in ipairs(t.args) do table.insert(tArgs, v) end
					for _, v in ipairs(arg) do table.insert(tArgs, v) end					
					
					return t.owner[t.key](t.owner, unpack(tArgs))					
				else
					return t.owner[t.key](t.owner, unpack(arg))
				end
			end
		}	
	)
	return result
end

Apollo.RegisterPackage(
	Configuration, 
	MAJOR, 
	MINOR, 
	{
		"Gemini:Logging-1.2"
	}
)