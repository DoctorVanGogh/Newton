-----------------------------------------------------------------------------------------------
-- Instance bot summoning trigger
--
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
require "GroupLib"

local MAJOR,MINOR = "DoctorVanGogh:Newton:Triggers:Instance", 1

local kstrFieldNameEventsRegistered = "bEventsRegistered"

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
	self.log:debug("__init()")
	
	o = o or {}
	TriggerBase:__init(o)	
	
	if o:GetAction() == nil then 
		o:SetAction(TriggerBase.SummoningChoice.Dismiss) 
	end
	
	if o:IsEnabled() then
		Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", o)				
		o[kstrFieldNameEventsRegistered] = true		
	end		
	
	return oo.rawnew(self, o)
end


function Trigger:OnEnabledChanged()
	if self:IsEnabled() and not self[kstrFieldNameEventsRegistered] then
		Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", o)				
		self[kstrFieldNameEventsRegistered] = true			
	elseif not self:IsEnabled() and self[kstrFieldNameEventsRegistered] then	
		Apollo.RemoveEventHandler("ChangeWorld", self)				
		self[kstrFieldNameEventsRegistered] = false			
	end
end

function Trigger:GetName()
	return self.localization["Instance:Name"]
end

function Trigger:GetDescription()
	return self.localization["Instance:Description"]
end

function Trigger:OnChangeWorld()
	self.log:debug("OnChangeWorld")
	self:OnUpdateScanbotSummonStatus()
end

function Trigger:GetShouldSummonBot()
	self.log:debug("GetShouldSummonBot")

	if GroupLib:InInstance() then
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