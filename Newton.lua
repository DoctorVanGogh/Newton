-----------------------------------------------------------------------------------------------
-- Client Lua Script for Newton
-- Copyright (c) DoctorVanGogh on Wildstar forums
-----------------------------------------------------------------------------------------------
 
require "GameLib"
require "PlayerPathLib"
require "ScientistScanBotProfile"

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local GetScanbotProfileIndexFromProfile = function(currentProfile)
	if currentProfile == nil then
		return nil
	end
	for idx, profile in ipairs(PlayerPathLib.ScientistAllGetScanBotProfiles()) do
		if currentProfile == profile then
			return idx			
		end		
	end
end 

local MAJOR, MINOR = "Newton-1.0", 1
local ksScanbotCooldownTimer = "NewtonScanBotCoolDownTimer"
local glog

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

local Newton = Apollo.GetPackage("Gemini:Addon-1.0").tPackage:NewAddon("Newton", false, { "Gemini:Logging-1.2" }, "Gemini:Hook-1.0")

function Newton:OnInitialize()
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.INFO,
		pattern = "%d [%c:%n] %l - %m",
		appender = "GeminiConsole"
	})	

	self.log = glog
	
	if PlayerPathLib.GetPlayerPathType() ~= PathMission.PlayerPathType_Scientist then
		return
	end	
		
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("NewtonForm.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)	
	

	-- Do additional Addon initialization here		
	Apollo.RegisterTimerHandler(ksScanbotCooldownTimer, "OnScanBotCoolDownTimer", self)
	
	self.bScanbotOnCooldown = false			
end


-- Called when player has loaded and entered the world
function Newton:OnEnable()
	glog:debug(string.format("OnEnable"))

	self.ready = true
	if GameLib.IsCharacterLoaded() and self:GetAutoSummonScanbot() then
		if not self:GetScanbotOnCooldown() then
			self:TrySummonScanbot(nil, true)
		end
	else
		glog:debug("Character not yet created - delaying bot summon")
		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnNewtonUpdate", self)
	end
end

function Newton:OnSlashCommand(strCommand, strParam)
	self:ToggleWindow()
end

function Newton:OnDocumentReady()
	glog:debug(string.format("OnEnable"))

	if self.xmlDoc == nil then
		return
	end
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "NewtonConfigForm", nil, self)
	self.wndMain:FindChild("HeaderLabel"):SetText(MAJOR)
	self.xmlDoc = nil;
	
	Apollo.RegisterSlashCommand("newton", "OnSlashCommand", self)
	self.wndMain:Show(false);
end

-----------------------------------------------------------------------------------------------
-- Newton logic
-----------------------------------------------------------------------------------------------

function Newton:OnPlayerPathScientistScanBotCooldown(fTime) -- iTime is cooldown time in MS (5250)
	glog:debug(string.format("OnPlayerPathScientistScanBotCooldown(%f)", fTime))

	fTime = math.max(1, fTime) -- TODO TEMP Lua Hack until fTime is valid
	Apollo.CreateTimer(ksScanbotCooldownTimer, fTime, false)
	self:SetScanbotOnCooldown(true)
end

function Newton:OnScanBotCoolDownTimer()
	self:SetScanbotOnCooldown(false)
end

function Newton:GetAutoSummonScanbot()
	return self.bAutoSummonScanbot or false
end

function Newton:SetAutoSummonScanbot(bValue)
	glog:debug(
		string.format(
			"SetAutoSummonScanbot(%s) - cooldown=%s,isloaded=%s", 
			tostring(bValue), 
			tostring(self:GetScanbotOnCooldown()), 
			tostring(GameLib.IsCharacterLoaded())
		)
	)

	if self.bAutoSummonScanbot == bValue then
		return
	end	
	
	self.bAutoSummonScanbot = bValue

	if bValue then	
		Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)	
		Apollo.RegisterEventHandler("CombatLogMount", "OnCombatLogMount", self)
		Apollo.RegisterEventHandler("PlayerPathScientistScanBotCooldown", "OnPlayerPathScientistScanBotCooldown", self)			
		
			
		if not self:GetScanbotOnCooldown() then
			self:TrySummonScanbot(nil)
		end
	else
		Apollo.RemoveEventHandler("ChangeWorld", self)	
		Apollo.RemoveEventHandler("CombatLogMount", self)
		Apollo.RemoveEventHandler("PlayerPathScientistScanBotCooldown", self)			
	end
end


function Newton:OnChangeWorld()
	glog:debug(string.format("OnChangeWorld: IsCharacterLoaded=%s, self=%s", tostring(GameLib.IsCharacterLoaded()),tostring(self)))
	
	if self == nil or not self.ready then
		return
	end

	if GameLib.IsCharacterLoaded() then
		if not self:GetScanbotOnCooldown() then
			self:TrySummonScanbot()
		end
	else
		glog:debug("Character not yet created - delaying bot summon")
		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnNewtonUpdate", self)
	end
end

function Newton:OnNewtonUpdate()
	local bIsCharacterLoaded = GameLib.IsCharacterLoaded()

	glog:debug(string.format("OnNewtonUpdate: IsCharacterLoaded=%s", tostring(bIsCharacterLoaded)))

	if not bIsCharacterLoaded then
		return
	end
		
	self:TrySummonScanbot(nil, true)
	
	Apollo.RemoveEventHandler("VarChange_FrameCount", self)	
end

function Newton:OnCombatLogMount(tEventArgs)
	glog:debug(string.format("OnCombatLogMount, dismounted=%s", tostring(tEventArgs.bDismounted)))

	if tEventArgs.bDismounted and self:GetAutoSummonScanbot() and not self:GetScanbotOnCooldown()  then
		self:TrySummonScanbot(true)
	end
end

function Newton:GetScanbotOnCooldown()
	return self.bScanbotOnCooldown 
end


function Newton:SetScanbotOnCooldown(bValue)
	glog:debug(string.format("SetScanbotOnCooldown(%s)", tostring(bValue)))

	if self.bScanbotOnCooldown == bValue then
		return
	end	
	
	self.bScanbotOnCooldown = bValue

	if not self.bScanbotOnCooldown and self:GetAutoSummonScanbot() then
		self:TrySummonScanbot()
	end
end

function Newton:TrySummonScanbot(bSummon, bForceRestore)
	glog:debug(string.format("TrySummonScanbot(%s, %s)", tostring(bSummon), tostring(bForceUpdate)))

	self:RestoreScanbot(bForceRestore)

	if not self:GetScanbotOnCooldown() then
		local player = GameLib.GetPlayerUnit()
		
		if player then
			if bSummon == nil then
				bSummon = not player:IsMounted()
			end
		
			self:SummonScanbot(bSummon)
		end
	end
end

function Newton:SummonScanbot(bSummon)
	glog:debug(string.format("SummonScanbot(%s)", tostring(bSummon)))

	if bSummon and not PlayerPathLib.ScientistHasScanBot() then	
		PlayerPathLib.ScientistToggleScanBot()	
	end	
end


-- persistence logic

function Newton:GetPersistScanbot()
	return self.bPersistScanbot
end

function Newton:SetPersistScanbot(bValue, nScanbotProfileIndex)
	glog:debug(string.format("SetPersistScanbot(%s, %i)", tostring(bValue), nScanbotProfileIndex))

	if bValue == self:GetPersistScanbot() then
		return
	end
	
	self.bPersistScanbot = bValue
	
	if bValue then
		self.nScanbotProfileIndex = nScanbotProfileIndex or GetScanbotProfileIndexFromProfile(PlayerPathLib.ScientistGetScanBotProfile())
		self:PostHook(PlayerPathLib, "ScientistSetScanBotProfile")	
	else
		self:Unhook(PlayerPathLib, "ScientistSetScanBotProfile")
	end	
end


function Newton:RestoreScanbot(bForceRestore)

	glog:debug(string.format("RestoreScanbot(%s)", tostring(bForceRestore)))

		
	local currentProfile = PlayerPathLib.ScientistGetScanBotProfile()	
	-- check if correct bot already selected
	if bForceRestore or (currentProfile and GetScanbotProfileIndexFromProfile(currentProfile) ~= self.nScanbotProfileIndex) then					
		--  select correct bot
		local profile = PlayerPathLib.ScientistAllGetScanBotProfiles()[self.nScanbotProfileIndex]			
		if profile then		
			PlayerPathLib.ScientistSetScanBotProfile(profile)
		end			
	end		
end



function Newton:ScientistSetScanBotProfile(tProfile)
	local index =  GetScanbotProfileIndexFromProfile(tProfile)
	
	glog:debug(string.format("ScientistSetScanBotProfile(%i)", index))

	self.nScanbotProfileIndex = index
end

-----------------------------------------------------------------------------------------------
-- Persistence
-----------------------------------------------------------------------------------------------
function Newton:OnSaveSettings(eLevel)
	-- We save at character level,
	if (eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character) then
		return
	end

	glog:debug("OnSaveSettings")	
		
	local tSave = { 
		version = {
			MAJOR = MAJOR,
			MINOR = MINOR
		}, 
		nScanbotProfileIndex = self.nScanbotProfileIndex,
		bAutoSummonScanbot = self:GetAutoSummonScanbot()
		bPersistScanbot = self:GetPersistScanbot()
	}
	
	return tSave
end


function Newton:OnRestoreSettings(eLevel, tSavedData)
	-- We restore at character level,
	if (eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character) then
		return
	end
	
	glog:debug("OnRestoreSettings")
	
	if not tSavedData or tSavedData.version.MAJOR ~= MAJOR then
		self:SetAutoSummonScanbot(true)
		self:SetPersistScanbot(true)
		return
	end	
	
	self:SetAutoSummonScanbot(tSavedData.bAutoSummonScanbot or false)
	self:SetPersistScanbot(tSavedData.bPersistScanbot or false, tSavedData.nScanbotProfileIndex)	
end


---------------------------------------------------------------------------------------------------
-- NewtonConfigForm Functions
---------------------------------------------------------------------------------------------------
function Newton:ToggleWindow()
	if self.wndMain:IsVisible() then
		self.wndMain:Close()
	else
		self.wndMain:FindChild("AutoSummonCheckbox"):SetCheck(self:GetAutoSummonScanbot())
		self.wndMain:FindChild("PersistBotChoiceCheckbox"):SetCheck(self:GetPersistScanbot())
	
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

