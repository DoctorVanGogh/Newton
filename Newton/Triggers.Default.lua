-----------------------------------------------------------------------------------------------
-- Default bot summoning trigger
--	Will *always* say 'call bot', and triggers extra summoning checks on initialization, world change & dismounting
--
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
require "GameLib"

local MAJOR,MINOR = "DoctorVanGogh:Newton:Triggers:Default", 1

local ksScanbotCooldownTimer = "Newton:Triggers:Default:ScanBotCoolDownTimer"

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Multiple").tPackage
local TriggerBase = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Base").tPackage
local glog

local Trigger = APkg and APkg.tPackage

if not Trigger then
	local o = { }
	Trigger = oo.class(o, TriggerBase)
end

function Trigger:__init() 
	self:OnUpdateScanbotSummonStatus()

	self.bScanbotOnCooldown = false
	
	if self:IsEnabled() then
		Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)	
		Apollo.RegisterEventHandler("CombatLogMount", "OnCombatLogMount", self)		
		Apollo.RegisterEventHandler("PlayerPathScientistScanBotCooldown", "OnPlayerPathScientistScanBotCooldown", self)				
		self.bEventsRegistered = true		
	end
end


function Trigger:OnLoad()
	-- import GeminiLogging
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.DEBUG,
		pattern = "%d [%c:%n] %l - %m",
		appender = "GeminiConsole"
	})	
	
	self.log = glog
	
	Apollo.RegisterTimerHandler(ksScanbotCooldownTimer, "OnScanBotCoolDownTimer", self)
end


function Trigger:GetShouldSummonBot()
	return not self.bScanbotOnCooldown
end

function Trigger:OnEnabledChanged()
	if self:IsEnabled() and not self.bEventsRegistered then
		Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)	
		Apollo.RegisterEventHandler("CombatLogMount", "OnCombatLogMount", self)		
		Apollo.RegisterEventHandler("PlayerPathScientistScanBotCooldown", "OnPlayerPathScientistScanBotCooldown", self)									
		self.bEventsRegistered = true		
	elseif not self:IsEnabled() and self.bEventsRegistered then
		Apollo.RemoveEventHandler("ChangeWorld", self)	
		Apollo.RemoveEventHandler("CombatLogMount", self)	
		Apollo.RemoveEventHandler("PlayerPathScientistScanBotCooldown", self)			
		self.bEventsRegistered = false			
	end
end


function Trigger:OnChangeWorld()
	self.log:debug("OnChangeWorld")
	self:OnUpdateScanbotSummonStatus(true)
end


function Trigger:OnCombatLogMount(tEventArgs)
	self.log:debug("OnCombatLogMount, dismounted=%s", tostring(tEventArgs.bDismounted))

	if tEventArgs.bDismounted then
		self:OnUpdateScanbotSummonStatus()
	end
end

function Trigger:OnPlayerPathScientistScanBotCooldown(fTime) -- fTime is cooldown time in MS (5250)
	self.log:debug("OnPlayerPathScientistScanBotCooldown(%f)", fTime)

	fTime = math.max(1, fTime) -- TODO TEMP Lua Hack until fTime is valid
	Apollo.CreateTimer(ksScanbotCooldownTimer, fTime, false)
	
	if self.bScanbotOnCooldown then
		return
	end
	self.bScanbotOnCooldown = true
	self:OnUpdateScanbotSummonStatus()
end

function Trigger:OnScanBotCoolDownTimer()
	if not self.bScanbotOnCooldown then
		return
	end	
	
	self.bScanbotOnCooldown = false
	self:OnUpdateScanbotSummonStatus()	
end

Apollo.RegisterPackage(
	Trigger, 
	MAJOR, 
	MINOR, 
	{	
		"Gemini:Logging-1.2",
		"DoctorVanGogh:Newton:Triggers:Base",
		"DoctorVanGogh:Lib:Loop:Multiple"
	}
)