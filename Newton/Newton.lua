-----------------------------------------------------------------------------------------------
-- Client Lua Script for Newton
-- Copyright (c) DoctorVanGogh on Wildstar forums
-----------------------------------------------------------------------------------------------
 
require "GameLib"
require "PlayerPathLib"
require "ScientistScanBotProfile"
require "ApolloTimer"
require "ApolloColor"

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local kstrDefaultLogLevel = "WARN"
local kstrInitNoScientistWarning = "Player not a scientist - consider disabling Addon %s for this character!"
local kstrConfigNoScientistWarning = "Not a scientist - configuration disabled!"
local kstrYes = Apollo.GetString("CRB_Yes")
local kstrNo = Apollo.GetString("CRB_No")

local kclrSettingDefault = ApolloColor.new("UI_TextHoloBodyCyan")
local kclrSettingOther = ApolloColor.new("UI_TextHoloBody")

local knEnforceSummoningActionInverval = -1

local NAME = "Newton"
local MAJOR, MINOR = NAME.."-2.0", 2
local glog
local GeminiLocale
local GeminiLogging
local inspect
local TriggerList
local TriggerBase
local SummoningChoice
local ScanbotManager
local ScanbotTrigger
local Configuration
local SettingEnum
local oo 

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
local Newton = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon(
																NAME, 
																true, 
																{ 
																	"Gemini:Logging-1.2",
																	"Gemini:Locale-1.0",	
																	"Gemini:DB-1.0",
																	"DoctorVanGogh:Lib:Configuration",
																	"DoctorVanGogh:Newton:ScanbotTrigger",
																	"DoctorVanGogh:Newton:TriggerList",																																			
																	"DoctorVanGogh:Newton:ScanbotManager",
																	"DoctorVanGogh:Lib:Setting:Enum",
																	"DoctorVanGogh:Lib:Loop:Multiple"
																}
															)
	
local dbDefaults = {
	char = {
		persistScanbot = true,
		scanbotIndex = 0,
		currentProfileName = "Default"
	},
	global = {
		logLevel = "INFO"	
	},
	profile = { 
		triggerList = {
			{
				key = "DoctorVanGogh:Newton:Triggers:Stealth",
				values = {
					bEnabled = false,
					tSettings = {
						Action = 1
					}
				}
			}, {
				key = "DoctorVanGogh:Newton:Triggers:Challenge",
				values = {
					bEnabled = true,
					tSettings = {
						Action = 1,
						ChallengeType = 999
					}
				}
			}, {
				key = "DoctorVanGogh:Newton:Triggers:Group",
				values = {
					bEnabled = true,
					tSettings = {
						Action = 1,
						GroupType = 2
					}
				}
			}, {
				key = "DoctorVanGogh:Newton:Triggers:Instance",
				values = {
					bEnabled = true,
					tSettings = {
						Action = 1
					}
				}
			}, {
				key = "DoctorVanGogh:Newton:Triggers:PvpMatch",
				values = {
					bEnabled = true,
					tSettings = {
						Action = 1
					}
				}
			}, {
				key = "DoctorVanGogh:Newton:Triggers:Default",
				values = {
					bEnabled = true,
					tSettings = {
						Action = 0
					}
				}
			} 
		}
	}
}
	
	
local function SizeTriggerToSettingsHeight(wndTrigger)
	local wndContainer = wndTrigger:FindChild("SettingsContainer")
	local nHeight = wndContainer:ArrangeChildrenVert(0)
	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	nHeight = nHeight + math.abs(nTop) + math.abs(nBottom)
	nLeft, nTop, nRight, nBottom = wndTrigger:GetAnchorOffsets()
	wndTrigger:SetAnchorOffsets(nLeft, nTop, nRight, nHeight)
end	
	
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
	
	ScanbotTrigger = Apollo.GetPackage("DoctorVanGogh:Newton:ScanbotTrigger").tPackage
	
	TriggerList = Apollo.GetPackage("DoctorVanGogh:Newton:TriggerList").tPackage
	TriggerBase = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Base").tPackage
		
	ScanbotManager = Apollo.GetPackage("DoctorVanGogh:Newton:ScanbotManager").tPackage			
	
	SummoningChoice = TriggerBase.SummoningChoice
	
	Configuration = Apollo.GetPackage("DoctorVanGogh:Lib:Configuration").tPackage
	
	SettingEnum = Apollo.GetPackage("DoctorVanGogh:Lib:Setting:Enum").tPackage
	
	oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Multiple").tPackage
	
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, dbDefaults, true)
	self.db.RegisterCallback(self, "OnDatabaseShutdown", "DatabaseShutdown")
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")	
end

-- Called when player has loaded and entered the world
function Newton:OnEnable()
	glog:debug("OnEnable")

	self.ready = true
	
	
	local triggerList = TriggerList()
	self.trigger = triggerList
	self.trigger.RegisterCallback(self, TriggerList.Event_UpdateScanbotSummonStatus, "OnScanbotStatusUpdated")
			
	self:SetPersistScanbot(self.db.char.persistScanbot)
	self.strLogLevel = self.db.global.logLevel
	self.log:SetLevel(self.strLogLevel)
	self.scanbotManager = ScanbotManager(self.db.char.scanbotIndex)	
	
	self:UpdateTriggerList()
	if self.wndTriggers then
		self:UpdateTriggerUI()
	end
	
	self:OnScanbotStatusUpdated(true)		
end


function Newton:OnProfileChanged(db, profile)
	self:UpdateTriggerList()
	self:UpdateTriggerUI()
end

function Newton:UpdateTriggerList(bSkipWindowUpdate)
	self.trigger:Deserialize(self.db.profile.triggerList)
end

function Newton:UpdateTriggerUI()
	if self.wndTriggers and self.trigger then
		local wndElementsContainer = self.wndTriggers:FindChild("ElementsContainer")
		wndElementsContainer:DestroyChildren()
		
		local idx = 0
		local nCount = self.trigger:GetCount()
		for tTrigger in self.trigger:GetEnumerator() do
			idx = idx + 1 
			local wndTrigger = Apollo.LoadForm(self.xmlDoc, "TriggerItem", wndElementsContainer, self)			
			wndTrigger:SetData(tTrigger)	
						
			local wndEnableBtn = wndTrigger:FindChild("EnableBtn")			
			wndEnableBtn:SetText(tTrigger:GetName())
			wndEnableBtn:SetCheck(tTrigger:IsEnabled())
			
			local strEnabled
			if tTrigger:IsEnabled() then
				strEnabled = kstrYes
			else
				strEnabled = kstrNo
			end
			
			wndEnableBtn:SetTooltip(string.format(self.localization["Option:Trigger:Enabled"], strEnabled))
			
			local wndUp = wndTrigger:FindChild("UpBtn")
			wndUp:Enable(idx > 1)			
			local wndDown = wndTrigger:FindChild("DownBtn")
			wndDown:Enable(idx < nCount )
			
			local wndRemoveItemBtn = wndTrigger:FindChild("RemoveItemBtn")
			wndRemoveItemBtn:Enable(true)
			
			local wndSettingsContainer = wndTrigger:FindChild("SettingsContainer")
			
			for tSetting in tTrigger:GetSettingsEnumerator() do
				local wndSetting
				
				local clrSetting
				if tSetting:GetKey() then
					clrSetting = kclrSettingDefault
				else
					clrSetting = kclrSettingOther
				end
				
				if oo.instanceof(tSetting, SettingEnum) then
				
					local tOptions = {
						tEnum = tSetting:GetValues(),
						tEnumNames = tSetting:GetNames(),						
						strDescription = tSetting:GetDescription(),
						clrDescription = clrSetting,
						fnValueGetter = function() return tSetting:GetValue() end,
						fnValueSetter = function(value) 
							local result = tSetting:SetValue(value) 
							self:UpdateProfile()
							return result								
						end							
					}
					
					wndSetting = Configuration:CreateSettingItemEnum(
						wndSettingsContainer,
						tOptions
					)
				end				
			end				
			-- size each trigger correctly
			SizeTriggerToSettingsHeight(wndTrigger)												
		end

		-- size triggers list correctly
		local nTriggersHeight = wndElementsContainer:ArrangeChildrenVert(0)
		local nLeft, nTop, nRight, nBottom = wndElementsContainer:GetAnchorOffsets()
		wndElementsContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTriggersHeight)
		
		-- size entire triggers block correctly (incl. profile selection and explanation)
		local nHeight = self.wndTriggers:ArrangeChildrenVert(0)
		nLeft, nTop, nRight, nBottom = self.wndTriggers:GetAnchorOffsets()
		self.wndTriggers:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)

		-- size containing 'triggers' section correctly
		Configuration:SizeSectionToContent(self.wndTriggers:GetParent():GetParent())
		
		-- size entire config scroll area correctly
		self.wndMain:FindChild("Content"):ArrangeChildrenVert(0)
	end
end

function Newton:UpdateProfile()
	self.db.profile.triggerList = self.trigger:Serialize()
end

function Newton:DatabaseShutdown(db)
	self.db.char.persistScanbot = self:GetPersistScanbot()
	self.db.char.scanbotIndex = self.scanbotManager:GetScanbotIndex()
	self.db.global.logLevel = self.strLogLevel
	self:UpdateProfile()
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
	local wndAdvanced = Configuration:CreateSectionCollapsible(
		wndContent, 
		{ 
			strDescription = self.localization["Section:Advanced"],
			fnCallbackExpandCollapse = function() 
				wndContent:ArrangeChildrenVert(0)
			end
		}
	)
	
	-- Section: 'General'
	local wndElementsContainer = wndGeneral:FindChild("ElementsContainer")
	Configuration:CreateSettingItemBoolean(
		wndElementsContainer, 
		{
			strDescription = self.localization["Option:Persist"],
			fnValueGetter = function() 
								return self:GetPersistScanbot() 
							end,
			fnValueSetter = function(v) 
								self:SetPersistScanbot(v)
							end
		}
	)
	Configuration:SizeSectionToContent(wndGeneral)

	-- Section: 'Triggers'
	wndElementsContainer = wndTriggers:FindChild("ElementsContainer")
	local _, wndDropdown = Configuration:CreateSettingItemEnum(
		wndElementsContainer,
		{
			tEnum = { 
				self.db:GetProfiles()
			},
			strHeader = self.localization["Option:Profile:PopupHeader"],
			strDescription = self.localization["Option:Profile"],
			fnValueGetter = function() return self.db.char.currentProfileName end
			--fnValueSetter = ...
		}
	)
	-- add/remove button to dropdown
	local nLeft, nTop, nRight, nBottom = wndDropdown:GetAnchorOffsets()
	local wndAddElement = Apollo.LoadForm(self.xmlDoc, "AddElementButton", wndDropdown:GetParent(), self)
	local wndRemoveElement = Apollo.LoadForm(self.xmlDoc, "RemoveElementButton", wndDropdown:GetParent(), self)
	wndDropdown:SetAnchorOffsets(nLeft + wndAddElement:GetWidth(), nTop, nRight - wndRemoveElement:GetWidth(), nBottom)
	wndAddElement:Enable(false)
	wndRemoveElement:Enable(false)
	wndDropdown:Enable(false)
	
	local wndTriggersBlock = Apollo.LoadForm(self.xmlDoc, "TriggersBlock", wndElementsContainer, self)
	
	local wndAddBtn = wndTriggersBlock:FindChild("AddTriggerBtn")
			
	local tOptions = {
		tEnum = {},
		tEnumNames = {},
		tEnumDescriptions = {},	
		fnValueSetter = function(tTriggerClass)			
			if self.trigger:Add(tTriggerClass()) then
				self:UpdateProfile()
				self:UpdateTriggerUI()				
			end
		end
	} 
	for key, trigger in pairs(TriggerBase:GetRegisteredTriggers()) do
		table.insert(tOptions.tEnum, trigger)
		tOptions.tEnumNames[trigger] = trigger:GetName()		
		tOptions.tEnumDescriptions[trigger] = trigger:GetDescription()
	end
	
	local popup = Configuration:CreatePopup(wndAddBtn, tOptions)
	wndAddBtn:AttachWindow(popup)			
	
	
	wndTriggersBlock:ArrangeChildrenVert()
	Configuration:SizeSectionToContent(wndTriggers)

	
	
	-- Section: 'Advanced'
	wndElementsContainer = wndAdvanced:FindChild("ElementsContainer")
	Configuration:CreateSettingItemEnum(
		wndElementsContainer, 
		{
			tEnum = GeminiLogging.LEVEL,
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
	
	Configuration:SizeSectionToContent(wndAdvanced)
	Configuration:UpdateCollapsibleSectionHeight(wndAdvanced)
	Configuration:ExpandSection(wndAdvanced, false)
		
	wndContent:ArrangeChildrenVert(0)
		
	GeminiLocale:TranslateWindow(self.localization, self.wndMain)				
	
	wndMain:Show(false, true);
		
	self.wndTriggers = wndTriggersBlock
		
	if self.trigger then
		self:UpdateTriggerUI()
	end		
		
	if knEnforceSummoningActionInverval > 0 then
		self.tSummoningEnforcementTimer = ApolloTimer.Create(knEnforceSummoningActionInverval, true, "OnEnforceSummoningActionCheck", self)
	end
		
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



function Newton:AddElementSignal( wndHandler, wndControl, eMouseButton )
end

function Newton:RemoveElementSignal( wndHandler, wndControl, eMouseButton )
end

function Newton:TriggerItemEnableSignal(wndHandler, wndControl, eMouseButton )
	self.log:debug("TriggerItemEnableSignal")
	if wndControl ~= wndHandler then return end
	
	local tTrigger = wndHandler:GetParent():GetParent():GetData()
	
	tTrigger:Enable(wndHandler:IsChecked())	
	local strEnabled
	if wndHandler:IsChecked() then
		strEnabled = kstrYes
	else
		strEnabled = kstrNo
	end	
	wndHandler:SetTooltip(string.format(self.localization["Option:Trigger:Enabled"], strEnabled))		
	
	self:UpdateProfile()
end

function Newton:RemoveTrigger( wndHandler, wndControl, eMouseButton )
	self.log:debug("RemoveTrigger")
	if wndControl ~= wndHandler then return end
	
	local tTrigger = wndHandler:GetParent():GetParent():GetData()
	
	if self.trigger:Remove(tTrigger) then
		self:UpdateProfile()
		self:UpdateTriggerUI()		
	end
end

function Newton:TriggerForward( wndHandler, wndControl, eMouseButton )
	self.log:debug("TriggerForward")
	if wndControl ~= wndHandler then return end
	
	local tTrigger = wndHandler:GetParent():GetParent():GetData()
	
	if self.trigger:Forward(tTrigger) then
		self:UpdateProfile()
		self:UpdateTriggerUI()		
	end
end


function Newton:TriggerBackward( wndHandler, wndControl, eMouseButton )
	self.log:debug("TriggerBackward")
	if wndControl ~= wndHandler then return end
	
	local tTrigger = wndHandler:GetParent():GetParent():GetData()
	
	if self.trigger:Backward(tTrigger) then
		self:UpdateProfile()
		self:UpdateTriggerUI()		
	end
end



