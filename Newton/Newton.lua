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
local kstrYes = Apollo.GetString("CRB_Yes")
local kstrNo = Apollo.GetString("CRB_No")

local kclrSettingDefault = ApolloColor.new("UI_TextHoloBodyCyan")
local kclrSettingOther = ApolloColor.new("UI_TextHoloBody")

local knEnforceSummoningActionInverval = -1

local kstrAddonPathScientistContent = "PathScientistContent"
local kstrAddonPathScientistCustomize = "PathScientistCustomize"


local NAME = "Newton"
local MAJOR, MINOR = NAME.."-2.0", 2

local GeminiLocale, GeminiLogging, LibDialog, inspect, glog, PathScientistCustomize

local TriggerList, TriggerBase, ScanbotManager, ScanbotTrigger, Configuration, Setting, SettingEnum, Configurable, oo

local SummoningChoice


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
local Newton = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon(
																NAME, 
																true, 
																{ 
																	"Drafto:Lib:inspect-1.2",
																	"Gemini:Logging-1.2",
																	"Gemini:Locale-1.0",	
																	"Gemini:DB-1.0",
																	"Gemini:LibDialog-1.0",
																	"Lib:ApolloFixes-1.0",
																	"DoctorVanGogh:Lib:Configuration",
																	"DoctorVanGogh:Lib:Configurable",
																	"DoctorVanGogh:Newton:ScanbotTrigger",
																	"DoctorVanGogh:Newton:TriggerList",																																			
																	"DoctorVanGogh:Newton:ScanbotManager",
																	"DoctorVanGogh:Lib:Setting",
																	"DoctorVanGogh:Lib:Setting:Enum",
																	"DoctorVanGogh:Lib:Loop:Multiple",
																	kstrAddonPathScientistContent
																}
															)
	
local dbDefaults = {
	char = {
		persistScanbot = true,
		scanbotIndex = 1,
		currentProfileName = "Default"
	},
	global = {
		logLevels = {
			['*'] = 'INFO'
		}
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
	
	-- store loads of package references
	ScanbotTrigger = Apollo.GetPackage("DoctorVanGogh:Newton:ScanbotTrigger").tPackage
	
	TriggerList = Apollo.GetPackage("DoctorVanGogh:Newton:TriggerList").tPackage
	TriggerBase = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Base").tPackage
		
	ScanbotManager = Apollo.GetPackage("DoctorVanGogh:Newton:ScanbotManager").tPackage			
	
	SummoningChoice = TriggerBase.SummoningChoice
	
	Configuration = Apollo.GetPackage("DoctorVanGogh:Lib:Configuration").tPackage
	Configurable = Apollo.GetPackage("DoctorVanGogh:Lib:Configurable").tPackage
	
	SettingEnum = Apollo.GetPackage("DoctorVanGogh:Lib:Setting:Enum").tPackage
	Setting = Apollo.GetPackage("DoctorVanGogh:Lib:Setting").tPackage
	
	LibDialog = Apollo.GetPackage("Gemini:LibDialog-1.0").tPackage
	
	oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Multiple").tPackage
	
	PathScientistCustomize = Apollo.GetAddon(kstrAddonPathScientistCustomize)
	
	if PathScientistCustomize then
		self:SetupScanbotCustomizeAdditions()
	else
		Apollo.RegisterEventHandler("ObscuredAddonVisible", "OnObscuredAddonVisible", self)
	end	
	
	
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, dbDefaults, true)
	self.db.RegisterCallback(self, "OnDatabaseShutdown", "DatabaseShutdown")
	
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")	
	self.db.RegisterCallback(self, "OnProfileDeleted", "UpdateTriggerUI")
	
	-- Create dialog closures over addon instance
	LibDialog:Register(
		"remove",
		{
			icon = "IconSprites:Icon_BuffWarplots_critical_hit",
			buttons = {
			  {
				text = kstrYes,
				OnClick = function(settings, data, reason)
					local index
					local tProfiles = self.db:GetProfiles()
					local strNewActiveProfile
					if data == tProfiles[1] then
						-- if we remove the 1st one, make 2nd active
						strNewActiveProfile = tProfiles[2]
					else
						-- if we remove anything but 1st, just make 1st active
						strNewActiveProfile = tProfiles[1]					
					end
					self.db:SetProfile(strNewActiveProfile)			
					self.db.char.currentProfileName = strNewActiveProfile
					self.db:DeleteProfile(data)
					self.wndProfilesDropdown:SetText(strNewActiveProfile)					
				end,
			  },
			  {
				color = "Red",
				text = kstrNo,
				OnClick = function(settings, data, reason)
					-- DO NOTHING
				end,
			  },
			},
			OnShow = function(settings, data)
				settings:SetText(string.format(self.localization["Option:Profile:Delete:Confirm"], data))			
			end,			
			showWhileDead=true,
		}
	)	

	local fnValidateDialogText = function(settings, data, text)
		-- simple function to validate profile names (unique and non null)
		local index			
		
		if not text or text == "" then
			index = -1
		end						
		for idx, strProfile in ipairs(data.profiles or {}) do
			if strProfile == text then
				index = idx
				break
			end
		end
		
		local wndOkButton = settings.wndDialog:FindChild("ButtonContainer"):GetChildren()[1]
		
		if index then
			wndOkButton:Enable(false)
			data.text = nil
		else
			wndOkButton:Enable(true)							
			data.text = text
		end	
	end
		
	LibDialog:Register(
		"create",
		{
			buttons = {
				{
					text = Apollo.GetString("CRB_Ok"),
					OnClick = function(settings, data, reason)
						if data.text then
							self.db:SetProfile(data.text)
							self.wndProfilesDropdown:SetText(data.text)
						end
					end,
				},
				{
					color = "Red",
					text = Apollo.GetString("CRB_Cancel"),
					OnClick = function(settings, data, reason)
						-- do nothing
					end,
				},
			},
			editboxes = {
				{
					label=self.localization["Option:Profile:New:Label"],
					order = 10,
					OnTextChanged = fnValidateDialogText,	
				},
			},		
			OnShow = fnValidateDialogText,			
			text=self.localization["Option:Profile:New:Message"],
			hideOnEscape = true,
			showWhileDead = true,		  
		}
	)
	
end

-- Called when player has loaded and entered the world
function Newton:OnEnable()
	glog:debug("OnEnable")

	self.ready = true	
			
	self.log:SetLevel(self.db.global.logLevels.Newton)	
	ScanbotManager.log:SetLevel(self.db.global.logLevels.ScanbotManager)	
	ScanbotTrigger.log:SetLevel(self.db.global.logLevels.ScanbotTrigger)	
	Configuration.log:SetLevel(self.db.global.logLevels.Configuration)	
	Setting.log:SetLevel(self.db.global.logLevels.Setting)	
	Configurable.log:SetLevel(self.db.global.logLevels.Configurable)
	
	local triggerList = TriggerList()
	self.trigger = triggerList
	self.trigger.RegisterCallback(self, TriggerList.Event_UpdateScanbotSummonStatus, "OnScanbotStatusUpdated")				

	self.scanbotManager = ScanbotManager(self.db.char.scanbotIndex)	
	
	self:UpdateTriggerList()
	if self.wndTriggers then
		self:UpdateTriggerUI()
	end
	
	self:OnScanbotStatusUpdated(true)		
end

local function CreateProfileSelectionOptions(self)
	return {
		tEnum = self.db:GetProfiles(),
		strHeader = self.localization["Option:Profile:PopupHeader"],
		strDescription = self.localization["Option:Profile"],
		fnValueGetter = function() return self.db.char.currentProfileName end,
		fnValueSetter = function(value) 
			self.db:SetProfile(value) 				
			self.db.char.currentProfileName = value		
			self.wndProfilesDropdown:SetText(value)
		end
	}
end

-- builds the main config ui - most of this happens dynamically
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
								return self.db.char.persistScanbot 
							end,
			fnValueSetter = function(v) 
								self.db.char.persistScanbot = v
							end
		}
	)
	Configuration:SizeSectionToContent(wndGeneral)

	-- Section: 'Triggers'		
	wndElementsContainer = wndTriggers:FindChild("ElementsContainer")
	local _, wndDropdown = Configuration:CreateSettingItemEnum(
		wndElementsContainer,
		CreateProfileSelectionOptions(self)
	)
	self.wndProfilesDropdown = wndDropdown
	-- add/remove button to dropdown
	local nLeft, nTop, nRight, nBottom = wndDropdown:GetAnchorOffsets()
	local wndAddElement = Apollo.LoadForm(self.xmlDoc, "AddElementButton", wndDropdown:GetParent(), self)
	local wndRemoveElement = Apollo.LoadForm(self.xmlDoc, "RemoveElementButton", wndDropdown:GetParent(), self)
	wndDropdown:SetAnchorOffsets(nLeft + wndAddElement:GetWidth(), nTop, nRight - wndRemoveElement:GetWidth(), nBottom)
	wndAddElement:Enable(true)
	wndAddElement:SetTooltip(self.localization["Option:Profile:New"])
	wndRemoveElement:Enable(#self.db:GetProfiles() > 1)
	wndRemoveElement:SetTooltip(self.localization["Option:Profile:Delete"])
	wndDropdown:Enable(true)
	
	local wndTriggersBlock = Apollo.LoadForm(self.xmlDoc, "TriggersBlock", wndElementsContainer, self)
	local wndAddBtn = wndTriggersBlock:FindChild("AddTriggerBtn")
	wndAddBtn:SetTooltip(self.localization["Option:Trigger:Add"])
			
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
	
	wndTriggersBlock:ArrangeChildrenVert(0)
	Configuration:SizeSectionToContent(wndTriggers)

	
	
	-- Section: 'Advanced'
	wndElementsContainer = wndAdvanced:FindChild("ElementsContainer")
	
	local function CreateAdvancedEnumSetting(strDescriptionLocalizationKey, strKeyLogLevels, oLog)
		Configuration:CreateSettingItemEnum(
			wndElementsContainer, 
			{
				tEnum = GeminiLogging.LEVEL,
				strHeader = self.localization["Option:LogLevel:PopupHeader"],
				strDescription = self.localization[strDescriptionLocalizationKey],
				fnValueGetter = function() 
					return self.db.global.logLevels[strKeyLogLevels]
				end,
				fnValueSetter = function(value) 
					self.db.global.logLevels[strKeyLogLevels] = value
					oLog:SetLevel(value)
				end			
			}
		)		
	end
	CreateAdvancedEnumSetting("Option:LogLevel:Newton", "Newton", self.log)
	CreateAdvancedEnumSetting("Option:LogLevel:ScanbotManager", "ScanbotManager", ScanbotManager.log)	
	CreateAdvancedEnumSetting("Option:LogLevel:ScanbotTrigger", "ScanbotTrigger", ScanbotTrigger.log)
	CreateAdvancedEnumSetting("Option:LogLevel:Configurable", "Configurable", Configurable.log)			
	CreateAdvancedEnumSetting("Option:LogLevel:Setting", "Setting", Setting.log)	
	CreateAdvancedEnumSetting("Option:LogLevel:Configuration", "Configuration", Configuration.log)
	
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

function Newton:OnDocumentReady()
	glog:debug("OnDocumentReady")

	if self.xmlDoc == nil then
		return
	end
	
	self:InitializeForm()		
		
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	
end

function Newton:UpdateTriggerUI()
	if self.wndTriggers and self.trigger then
	
		-- update profiles dropdown
		self.wndProfilesDropdown:DestroyChildren()
		local wndPopup = Configuration:CreatePopup(self.wndProfilesDropdown, CreateProfileSelectionOptions(self))
		self.wndProfilesDropdown:AttachWindow(wndPopup)		
		
		local wndRemoveElement = self.wndMain:FindChild("RemoveElementButton")
		wndRemoveElement:Enable(#self.db:GetProfiles() > 1)	
	
		-- update triggers list
		local wndElementsContainer = self.wndTriggers:FindChild("ElementsContainer")
		wndElementsContainer:DestroyChildren()
		
		local idx = 0
		local nCount = self.trigger:GetCount()
		for tTrigger in self.trigger:GetEnumerator() do
			-- enumerate all triggers
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
			wndUp:SetTooltip(self.localization["Option:Trigger:Forward"])
			local wndDown = wndTrigger:FindChild("DownBtn")
			wndDown:Enable(idx < nCount )
			wndDown:SetTooltip(self.localization["Option:Trigger:Backward"])
			
			local wndRemoveItemBtn = wndTrigger:FindChild("RemoveItemBtn")
			wndRemoveItemBtn:Enable(true)
			wndRemoveItemBtn:SetTooltip(self.localization["Option:Trigger:Remove"])
						
			local wndSettingsContainer = wndTrigger:FindChild("SettingsContainer")
			
			-- add ui per setting
			for tSetting in tTrigger:GetSettingsEnumerator() do
				local wndSetting
				
				local clrSetting
				if tSetting:GetKey() then
					clrSetting = kclrSettingDefault
				else
					clrSetting = kclrSettingOther
				end
				
				-- currently we only know (and support) enum-like settings
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
			
			self.log:debug("Added Trigger - Height=%f", wndTrigger:GetHeight())
		end

				
		-- size triggers list correctly
		local nTriggersHeight = wndElementsContainer:ArrangeChildrenVert(0)
		self.log:debug("Calculated total height for trigger list: %f", nTriggersHeight)
		
		local nLeft, nTop, nRight, nBottom = wndElementsContainer:GetAnchorOffsets()
		wndElementsContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTriggersHeight)
		self.log:debug("Actual height for trigger list: %f", wndElementsContainer:GetHeight())
		
		-- size entire triggers block correctly (incl. profile selection and explanation)
		local nHeight = self.wndTriggers:ArrangeChildrenVert(0)
		self.log:debug("Calculated height Triggers block: %f", nHeight)
				
		nLeft, nTop, nRight, nBottom = self.wndTriggers:GetAnchorOffsets()
		self.wndTriggers:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
		self.log:debug("Actual height for Triggers block: %f", self.wndTriggers:GetHeight())
			
		-- size containing 'triggers' section correctly
		Configuration:SizeSectionToContent(self.wndTriggers:GetParent():GetParent())
		self.log:debug("Actual height for Triggers Section: %f", self.wndTriggers:GetParent():GetParent():GetHeight())
		
		-- size entire config scroll area correctly
		self.wndMain:FindChild("Content"):ArrangeChildrenVert(0)
	end
end

function Newton:OnWindowManagementReady()
    Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "Newton"})
end

function Newton:SetupScanbotCustomizeAdditions()
	-- inject 'cogs' icon into scanbot customization
	if PathScientistCustomize and PathScientistCustomize.wndMain then
		local wndOpenConfig = Apollo.LoadForm(self.xmlDoc, "SciConfigureBtn", PathScientistCustomize.wndMain, self)
		wndOpenConfig:SetTooltip(self.localization["Config"])
		GeminiLocale:TranslateWindow(self.localization, wndOpenConfig)					
	end
end

function Newton:OnObscuredAddonVisible(strAddonName)
	self.log:debug("OnObscuredAddonVisible - %s", tostring(strAddonName))

	if strAddonName == kstrAddonPathScientistCustomize then
		PathScientistCustomize = Apollo.GetAddon(kstrAddonPathScientistCustomize)
		
		Apollo.RemoveEventHandler("ObscuredAddonVisible", self)
		
		-- delay our init call to allow Apollo.LoadForm to finish, and PathScientistCusomize to set it's wndMain...
		Apollo.RegisterEventHandler("VarChange_FrameCount", "DelaySetupScanbotCustomizeAdditions", self)		
	end
end

function Newton:DelaySetupScanbotCustomizeAdditions()
	Apollo.RemoveEventHandler("VarChange_FrameCount", self)
	self:SetupScanbotCustomizeAdditions()
end

function Newton:OnProfileChanged(db, profile)
	self:UpdateTriggerList()
	self:UpdateTriggerUI()
end

function Newton:UpdateTriggerList(bSkipWindowUpdate)
	self.trigger:Deserialize(self.db.profile.triggerList)
end

function Newton:UpdateProfile()
	self.db.profile.triggerList = self.trigger:Serialize()
end

function Newton:DatabaseShutdown(db)
	if self.db.char.persistScanbot then
		self.db.char.scanbotIndex = self.scanbotManager:GetScanbotIndex()
	else
		self.db.char.scanbotIndex = dbDefaults.char.scanbotIndex
	end	
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

-----------------------------------------------------------------------------------------------
-- Newton logic
-----------------------------------------------------------------------------------------------
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
	self.log:debug("AddElementSignal")
	if wndControl ~= wndHandler then return end
	
	LibDialog:Spawn("create", { profiles = self.db:GetProfiles() })	
end

function Newton:RemoveElementSignal( wndHandler, wndControl, eMouseButton )
	self.log:debug("RemoveElementSignal")
	if wndControl ~= wndHandler then return end
	
	LibDialog:Spawn("remove", self.db:GetCurrentProfile())
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

function Newton:OnOpenConfigureNewton(wndHandler, wndControl, eMouseButton )
	self.log:debug("OnOpenConfigureNewton")
	if wndControl ~= wndHandler then return end
	
	self:OnConfigure()
end



