-----------------------------------------------------------------------------------------------
-- Client Lua Script for Newton
-- Copyright (c) DoctorVanGogh on Wildstar forums
-----------------------------------------------------------------------------------------------
 
require "GameLib"
require "PlayerPathLib"
require "ScientistScanBotProfile"
require "ApolloTimer"

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local kstrDefaultLogLevel = "WARN"
local kstrInitNoScientistWarning = "Player not a scientist - consider disabling Addon %s for this character!"
local kstrConfigNoScientistWarning = "Not a scientist - configuration disabled!"

local knEnforceSummoningActionInverval = -1

local NAME = "Newton"
local MAJOR, MINOR = NAME.."-1.0", 1
local glog
local GeminiLocale
local GeminiLogging
local inspect
local Triggers = {}
local SummoningChoice
local ScanbotManager
local Configuration

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
local Newton = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon(
																NAME, 
																true, 
																{ 
																	"Gemini:Logging-1.2",
																	"Gemini:Locale-1.0",	
																	"DoctorVanGogh:Lib:Configuration",
																	"DoctorVanGogh:Newton:Triggers:Base",	
																	"DoctorVanGogh:Newton:Triggers:Cascade",																	
																	"DoctorVanGogh:Newton:Triggers:Group",
																	"DoctorVanGogh:Newton:Triggers:Challenge",
																	"DoctorVanGogh:Newton:Triggers:Stealth",																	
																	"DoctorVanGogh:Newton:Triggers:Instance",
																	"DoctorVanGogh:Newton:Triggers:PvpMatch",
																	"DoctorVanGogh:Newton:Triggers:Default",
																	"DoctorVanGogh:Newton:ScanbotManager"
																}
															)

function Newton:OnInitialize()
	GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.INFO,
		pattern = "%d [%c:%n] %l - %m",
		appender = "GeminiConsole"
	})	
	
	inspect = Apollo.GetPackage("Drafto:Lib:inspect-1.2").tPackage

	GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage		
	self.localization = GeminiLocale:GetLocale(NAME)
		
	Apollo.RegisterSlashCommand("newton", "OnSlashCommand", self)
	
	--if PlayerPathLib.GetPlayerPathType() ~= PathMission.PlayerPathType_Scientist then
	--	glog:warn(self.localization[kstrInitNoScientistWarning], NAME)
	--	self.bDisabled = true
	--	return
	--end		

	self.log = glog

	glog:debug("OnInitialize")
	
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("NewtonForm.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)	
	
	Triggers.Base = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Base").tPackage	
	Triggers.Default = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Default").tPackage
	Triggers.Stealth = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Stealth").tPackage
	Triggers.Cascade = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Cascade").tPackage
	Triggers.Group = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Group").tPackage
	Triggers.Instance = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Instance").tPackage
	Triggers.PvpMatch = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:PvpMatch").tPackage
	Triggers.Challenge = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Challenge").tPackage
	
	ScanbotManager = Apollo.GetPackage("DoctorVanGogh:Newton:ScanbotManager").tPackage			
	
	SummoningChoice = Triggers.Default.SummoningChoice
	
	Configuration = Apollo.GetPackage("DoctorVanGogh:Lib:Configuration").tPackage
end


-- Called when player has loaded and entered the world
function Newton:OnEnable()
	glog:debug("OnEnable")

	self.ready = true
	
	self.scanbotManager = ScanbotManager(self.nPersistedScanbotIndex)
		
	local cascadeTrigger = Triggers.Cascade()
		
	cascadeTrigger:Add(Triggers.Stealth{enabled = false})
	cascadeTrigger:Add(Triggers.Challenge())
	cascadeTrigger:Add(Triggers.Group())	
	cascadeTrigger:Add(Triggers.PvpMatch())	
	cascadeTrigger:Add(Triggers.Instance())			
	cascadeTrigger:Add(Triggers.Default())	
	cascadeTrigger.RegisterCallback(self, Triggers.Default.Event_UpdateScanbotSummonStatus, "OnScanbotStatusUpdated")
	
	self.trigger = cascadeTrigger
	
	self:OnScanbotStatusUpdated(true)		
end

function Newton:OnSlashCommand(strCommand, strParam)
	if self.wndMain then
		self:ToggleWindow()
	else
		if self.bDisabled then
			glog:warn(self.localization[kstrConfigNoScientistWarning])
		end
	end
end

function Newton:OnConfigure(sCommand, sArgs)
	if self.wndMain then
		self.wndMain:Show(false)
		self:ToggleWindow()
	else
		if self.bDisabled then
			glog:warn(self.localization[kstrConfigNoScientistWarning])
		end
	end
end

function Newton:OnDocumentReady()
	glog:debug("OnDocumentReady")

	if self.xmlDoc == nil then
		return
	end
	
	self:InitializeForm()		

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	
end

function Newton:InitializeForm()
	local wndMain = Apollo.LoadForm(self.xmlDoc, "NewtonConfigForm", nil, self)	

	self.wndMain = wndMain
	wndMain:FindChild("HeaderLabel"):SetText(MAJOR)	
	
	-- build configuration ui
	local wndContent = wndMain:FindChild("Content")
	
	-- Sections
	local wndGeneral = Configuration:CreateSection(wndContent, { strDescription = self.localization["Section:General"] })
	local wndTriggers = Configuration:CreateSection(wndContent, { strDescription = self.localization["Section:Triggers"] })
	local wndAdvanced = Configuration:CreateSectionCollapsible(wndContent, { strDescription = self.localization["Section:Advanced"] })
	
	-- Section: 'General'
	local wndElementsContainer = wndGeneral:FindChild("ElementsContainer")
	Configuration:CreateSettingItemBoolean(
		wndElementsContainer, 
		{
			strDescription = self.localization["Option:Persist"],
			fnValueGetter = function() 
				return self:GetPersistScanbot() 
			end,
			fnValueSetter = function(value) 
				self:SetPersistScanbot(value) 
			end			
		}
	)
	local nHeight = wndElementsContainer:ArrangeChildrenVert(0)
	local nLeft, nTop, nRight, nBottom = wndElementsContainer:GetAnchorOffsets()
	nHeight = nHeight + math.abs(nTop) + math.abs(nBottom)
	nLeft, nTop, nRight, nBottom = wndGeneral:GetAnchorOffsets()
	wndGeneral:SetAnchorOffsets(nLeft, nTop, nRight, nHeight)

	-- Section: 'Triggers'
	-- TODO
	
	
	-- Section: 'Advanced'
	wndElementsContainer = wndAdvanced:FindChild("ElementsContainer")
	Configuration:CreateSettingItemEnum(
		wndElementsContainer, 
		{
			tEnum = {
				"DEBUG", "INFO", "WARN", "FATAL", "ERROR"
			},
			strHeader = self.localization["Option:LogLevel:PopupHeader"],
			strDescription = self.localization["Option:LogLevel"],
			fnValueGetter = function() 
				return self.strLogLevel
			end,
			fnValueSetter = function(value) 
				self.strLogLevel = value
				self.log:SetLevel(value)
			end			
		}
	)
	nHeight = wndElementsContainer:ArrangeChildrenVert(0)
	nLeft, nTop, nRight, nBottom = wndElementsContainer:GetAnchorOffsets()
	nHeight = nHeight + math.abs(nTop) + math.abs(nBottom)
	nLeft, nTop, nRight, nBottom = wndAdvanced:GetAnchorOffsets()
	wndAdvanced:SetAnchorOffsets(nLeft, nTop, nRight, nHeight)
		
	wndContent:ArrangeChildrenVert()
		
	GeminiLocale:TranslateWindow(self.localization, self.wndMain)				
	
	wndMain:Show(false, true);
	
		
	self.xmlDoc = nil	
	
	if knEnforceSummoningActionInverval > 0 then
		self.tSummoningEnforcementTimer = ApolloTimer.Create(knEnforceSummoningActionInverval, true, "OnEnforceSummoningActionCheck", self)
	end
	
	
	local wndAddBtn = self.wndMain:FindChild("AddTriggerBtn")
	
--	tEnum 				table of avaliable values
--  tEnumNames 	 		table of value names (tEnumNames[*Somevalue*] = "SomeValueName")
--  tEnumDesciptions	table of value descriptions (used as tooltip) (tEnumDesciptions[*SomeValue*] = "SomeTooltip")
--  fnValueSetter 		callback function to invoke on value selection
--  nMinWidth			minimum initial width for popup texts (currently unused)
--  strHeader			popup header	
	
	local tOptions = {
		tEnum = {},
		tEnumNames = {},
		tEnumDescriptions = {},
		strHeader = "Lorem Ipsum"
	}
	for key, trigger in pairs(Triggers.Base:GetRegisteredTriggers()) do
		table.insert(tOptions.tEnum, trigger)
		tOptions.tEnumNames[trigger] = trigger:GetName()
		tOptions.tEnumDescriptions[trigger] = trigger:GetDescription()		
	end
	
	local popup = Configuration:CreatePopup(wndAddBtn, tOptions)
	wndAddBtn:AttachWindow(popup)		
	
	
	
	--self.wndMain:FindChild("AutoSummonCheckbox"):SetCheck(self:GetAutoSummonScanbot())
	--self.wndMain:FindChild("PersistBotChoiceCheckbox"):SetCheck(self:GetPersistScanbot())	
	--self.wndMain:FindChild("LogLevelButton"):SetText(self.strLogLevel)	
end

function Newton:OnWindowManagementReady()
    Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "Newton"})
end

-----------------------------------------------------------------------------------------------
-- Newton logic
-----------------------------------------------------------------------------------------------


function Newton:GetAutoSummonScanbot()
	return self.bAutoSummonScanbot or false
end

function Newton:SetAutoSummonScanbot(bValue)
	glog:debug(
		"SetAutoSummonScanbot(%s) - isloaded=%s", 
		tostring(bValue), 		
		tostring(GameLib.IsCharacterLoaded())		
	)

	if self.bAutoSummonScanbot == bValue then
		return
	end	
	
	self.bAutoSummonScanbot = bValue

end

function Newton:OnEnforceSummoningActionCheck()
	self:OnScanbotStatusUpdated()
end

function Newton:OnScanbotStatusUpdated(event, bForceRestore)
	glog:debug("OnScanbotStatusUpdated(%s)", tostring(bForceRestore))
	local eShouldSummonBot = self.trigger:GetShouldSummonBot()
	glog:debug("  Summon action: %s", tostring(eShouldSummonBot))
	
	if eShouldSummonBot == nil or eShouldSummonBot == SummoningChoice.NoAction then
		if self.tSummoningEnforcementTimer then
			self.tSummoningEnforcementTimer:Stop()	
		end
		if bForceRestore then
			self.scanbotManager:ForceRestoreOnNextSummon()
		end
	
		return
	end
	
	if GameLib.IsCharacterLoaded() then
		self.scanbotManager:SummonBot(eShouldSummonBot == SummoningChoice.Summon, bForceRestore)
		if self.tSummoningEnforcementTimer then
			self.tSummoningEnforcementTimer:Start()
		end
	else
		if bForceRestore then
			self.bForceRestore = bForceRestore
		end
		self.eShouldSummonBot = eShouldSummonBot
		glog:debug("Character not yet created - delaying (de)summon")
		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnNewtonUpdate", self)		
	end
end


function Newton:OnNewtonUpdate()
	local bIsCharacterLoaded = GameLib.IsCharacterLoaded()

	glog:debug("OnNewtonUpdate: IsCharacterLoaded=%s", tostring(bIsCharacterLoaded))

	if not bIsCharacterLoaded then
		return
	end
	
	local bForceRestore = self.bForceRestore
	if bForceRestore ~= nil then
		self.bForceRestore = nil
	end
		
	self.scanbotManager:SummonBot(self.eShouldSummonBot == SummoningChoice.Summon, bForceRestore)
	
	self.eShouldSummonBot = nil
	
	Apollo.RemoveEventHandler("VarChange_FrameCount", self)	
end


-- persistence logic
function Newton:GetPersistScanbot()
	return self.bPersistScanbot
end

function Newton:SetPersistScanbot(bValue)
	glog:debug("SetPersistScanbot(%s)", tostring(bValue))

	if bValue == self:GetPersistScanbot() then
		return
	end
	
	self.bPersistScanbot = bValue
end


-----------------------------------------------------------------------------------------------
-- Persistence
-----------------------------------------------------------------------------------------------
function Newton:OnSave(eLevel)
	glog:debug("OnSaveSettings(%s)", tostring(eLevel))	
	
	-- We save at character level,
	if (eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character) then
		return
	end

		
	local tSave = { 
		version = {
			MAJOR = MAJOR,
			MINOR = MINOR
		}, 
		nScanbotProfileIndex = self.scanbotManager:GetScanbotIndex(),
		bAutoSummonScanbot = self:GetAutoSummonScanbot(),
		bPersistScanbot = self:GetPersistScanbot(),
		strLogLevel = self.strLogLevel
	}
		
	glog:debug("Persist: %s", inspect(tSave))
	
	return tSave
end


function Newton:OnRestore(eLevel, tSavedData)
	glog:debug("OnRestoreSettings(%s)=%s", tostring(eLevel), inspect(tSavedData))	

	-- We restore at character level,
	if (eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character) then
		return
	end

	if not tSavedData or tSavedData.version.MAJOR ~= MAJOR then
		self:SetAutoSummonScanbot(true)
		self:SetPersistScanbot(true)
		self.strLogLevel = kstrDefaultLogLevel		
	else
		self:SetAutoSummonScanbot(tSavedData.bAutoSummonScanbot or false)
		self:SetPersistScanbot(tSavedData.bPersistScanbot)
		self.nPersistedScanbotIndex = tSavedData.nScanbotProfileIndex
		self.strLogLevel = tSavedData.strLogLevel or kstrDefaultLogLevel		
	end	
	
	self.log:SetLevel(self.strLogLevel)	
end


---------------------------------------------------------------------------------------------------
-- NewtonConfigForm Functions
---------------------------------------------------------------------------------------------------
function Newton:ToggleWindow()
	if self.wndMain:IsVisible() then
		self.wndMain:Close()
	else
		self.wndMain:Show(true)
		self.wndMain:ToFront()
	end
end

function Newton:OnAutoSummonCheck( wndHandler, wndControl, eMouseButton )
	self:SetAutoSummonScanbot(wndControl:IsChecked())
end

function Newton:OnPersistScanbotCheck( wndHandler, wndControl, eMouseButton )
	self:SetPersistScanbot(wndControl:IsChecked())
end


function Newton:AdvancedCheckToggle( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then
		return
	end	
	
	local wndAdvanced = self.wndMain:FindChild("AdvancedContainer")
	local wndContent = self.wndMain:FindChild("Content")
		
	if wndHandler:IsChecked() then
		wndAdvanced:Show(true)	
	else
		wndAdvanced:Show(false)	
		wndContent:SetVScrollPos(0)
	end	

	wndContent:ArrangeChildrenVert()
end


function Newton:OnSelectLogLevelFormClose( wndHandler, wndControl, eMouseButton )
	local wndForm = wndControl:GetParent() 
	wndForm:Close()
end


function Newton:LogLevelSelectSignal( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then
		return
	end

	wndControl:GetParent():Close()	
		
	local text = wndControl:GetText()
	self.strLogLevel = text
	self.log:SetLevel(text)	
	self.wndMain:FindChild("LogLevelButton"):SetText(text)
end





