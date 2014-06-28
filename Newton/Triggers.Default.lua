-----------------------------------------------------------------------------------------------
-- Default bot summoning trigger
--	Will *always* say 'call bot', and triggers extra summoning checks on initialization, world change & dismounting
--
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
require GameLib

local MAJOR,MINOR = "DoctorVanGogh:Newton:Triggers:Default", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Multiple").tPackage
local TriggerBase = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Base").tPackage
local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
local glog = GeminiLogging:GetLogger({
	level = GeminiLogging.INFO,
	pattern = "%d [%c:%n] %l - %m",
	appender = "GeminiConsole"
})	

local Trigger = APkg and APkg.tPackage

if not Trigger then
	local o = { }
	Trigger = oo.class(o, TriggerBase)
end

function Trigger:__init() {
	self.log = glog

	self:OnUpdateScanbotSummonStatus()
	
	if self:IsEnabled() then
		Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)	
		Apollo.RegisterEventHandler("CombatLogMount", "OnCombatLogMount", self)		
		self.bEventsRegistered = true		
	end
}

function Trigger:GetShouldSummonBot()
	return true
end

function Trigger:OnEnabledChanged()
	if self:IsEnabled() and not self.bEventsRegistered then
		Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)	
		Apollo.RegisterEventHandler("CombatLogMount", "OnCombatLogMount", self)		
		self.bEventsRegistered = true		
	elseif not self:IsEnabled() and self.bEventsRegistered then
		Apollo.RemoveEventHandler("ChangeWorld", self)	
		Apollo.RemoveEventHandler("CombatLogMount", self)	
		self.bEventsRegistered = false			
	end
end


function Trigger:OnChangeWorld()
	self.log:debug("OnChangeWorld")
	self:OnUpdateScanbotSummonStatus()
end


function Trigger:OnCombatLogMount(tEventArgs)
	self:debug("OnCombatLogMount, dismounted=%s", tostring(tEventArgs.bDismounted))

	if tEventArgs.bDismounted then
		self:OnUpdateScanbotSummonStatus()
	end
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