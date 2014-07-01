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
local inspect = Apollo.GetPackage("Drafto:Lib:inspect-1.2").tPackage
local TriggerBase = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Base").tPackage

local Trigger = APkg and APkg.tPackage

if not Trigger then
	Trigger = oo.class({}, TriggerBase)
end

function Trigger:__init(o) 
	self.log:debug("Trigger:__init()")
	
	o = o or {}
	TriggerBase:__init(o)

	if o:GetAction() == nil then 	
		o:SetAction(TriggerBase.SummoningChoice.Summon)
	end
	
	if o:IsEnabled() then
		Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", o)	
		Apollo.RegisterEventHandler("CombatLogMount", "OnCombatLogMount", o)		
		Apollo.RegisterEventHandler("PlayerPathScientistScanBotCooldown", "OnPlayerPathScientistScanBotCooldown", o)				
		o.bEventsRegistered = true		
	end		
	
	o.bScanbotOnCooldown = false

	Apollo.RegisterTimerHandler(ksScanbotCooldownTimer, "OnScanBotCoolDownTimer", o)	
	
	o:OnUpdateScanbotSummonStatus()	
	
	return oo.rawnew(self, o)
end


function Trigger:GetShouldSummonBot()
	self.log:debug("Trigger(Default):GetShouldSummonBot()")
	
	if self.bScanbotOnCooldown then
		return nil
	else
		return self:GetAction()	
	end
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
		"Drafto:Lib:inspect-1.2",
		"DoctorVanGogh:Newton:Triggers:Base",
		"DoctorVanGogh:Lib:Loop:Multiple"
	}
)