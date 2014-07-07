-----------------------------------------------------------------------------------------------
-- Pvp match bot summoning trigger
--
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
require "MatchingGame"

local MAJOR,MINOR = "DoctorVanGogh:Newton:Triggers:PvpMatch", 1

local kstrFieldNameEventsRegistered = "bEventsRegistered"

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Multiple").tPackage
local inspect = Apollo.GetPackage("Drafto:Lib:inspect-1.2").tPackage
local TriggerBase = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Instance").tPackage

local Trigger = APkg and APkg.tPackage

if not Trigger then
	Trigger = oo.class({}, TriggerBase)
end

function Trigger:__init(o) 
	self.log:debug("Trigger:__init()")
	
	o = o or {}
	TriggerBase:__init(o)
	
	if o:GetAction() == nil then 
		o:SetAction(TriggerBase.SummoningChoice.NoAction) 
	end
	
	if o:IsEnabled() then
		Apollo.RegisterEventHandler("MatchEntered", "OnMatchEnterExit", o)			
		Apollo.RegisterEventHandler("MatchExited", "OnMatchEnterExit", o)		
		Apollo.RegisterEventHandler("ChangeWorld", "OnMatchEnterExit", o)						
		o[kstrFieldNameEventsRegistered] = true		
	end		
	
	return oo.rawnew(self, o)
end

function Trigger:GetName()
	return self.localization["PvpMatch:Name"]
end

function Trigger:GetDescription()
	return self.localization["PvpMatch:Description"]
end


function Trigger:OnEnabledChanged()
	if self:IsEnabled() and not self[kstrFieldNameEventsRegistered] then
		Apollo.RegisterEventHandler("MatchEntered", "OnMatchEnterExit", self)			
		Apollo.RegisterEventHandler("MatchExited", "OnMatchEnterExit", self)					
		Apollo.RegisterEventHandler("ChangeWorld", "OnMatchEnterExit", self)	
		self[kstrFieldNameEventsRegistered] = true			
	elseif not self:IsEnabled() and self[kstrFieldNameEventsRegistered] then	
		Apollo.RemoveEventHandler("MatchEntered", self)				
		Apollo.RemoveEventHandler("MatchExited", self)		
		Apollo.RemoveEventHandler("ChangeWorld", self)	
		self[kstrFieldNameEventsRegistered] = false			
	end
end

function Trigger:OnMatchEnterExit()
	self.log:debug("OnMatchEnterExit")
	self:OnUpdateScanbotSummonStatus()
end

function Trigger:GetShouldSummonBot()
	self.log:debug("GetShouldSummonBot")

	if MatchingGame:IsInPVPGame() then
		return self:GetAction()
	else
		return nil
	end
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

TriggerBase:Register(Trigger, MAJOR)