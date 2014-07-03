-----------------------------------------------------------------------------------------------
-- Challenge bot summoning trigger
--
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
require "Challenges"
require "ChallengesLib"

local MAJOR,MINOR = "DoctorVanGogh:Newton:Triggers:Challenge", 1

local kstrFieldNameEventsRegistered = "bEventsRegistered"
local kstrFieldNameChallengeType = "eChallengeType"

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


Trigger.ChallengeTypes = {
	Ability = 1,
	Combat = 2,
	General = 3,	
	Item = 4,
	Any = 999
}

local ktChallengeTypeToInternalEnum = {
	[ChallengesLib.ChallengeType_Combat] = Trigger.ChallengeTypes.Combat,
	[ChallengesLib.ChallengeType_General] = Trigger.ChallengeTypes.General,
	[ChallengesLib.ChallengeType_Item] = Trigger.ChallengeTypes.Item,
	[ChallengesLib.ChallengeType_Ability] = Trigger.ChallengeTypes.Ability,
}


function Trigger:__init(o) 
	self.log:debug("Trigger:__init()")
	
	o = o or {}
	o[kstrFieldNameChallengeType] = o[kstrFieldNameChallengeType] or Trigger.ChallengeTypes.Any
	TriggerBase:__init(o)
	
	if o:GetAction() == nil then 
		o:SetAction(TriggerBase.SummoningChoice.Dismiss)
	end
	
	if o:IsEnabled() then	
		Apollo.RegisterEventHandler("ChallengeAbandon", 			"OnChallengeUpdate", o)
		Apollo.RegisterEventHandler("ChallengeFailTime", 			"OnChallengeUpdate", o)
		Apollo.RegisterEventHandler("ChallengeFailArea", 			"OnChallengeUpdate", o)
		Apollo.RegisterEventHandler("ChallengeActivate", 			"OnChallengeUpdate", o)
		Apollo.RegisterEventHandler("ChallengeCompleted", 			"OnChallengeUpdate", o)
		Apollo.RegisterEventHandler("ChallengeFailGeneric", 		"OnChallengeUpdate", o)	
				
		o[kstrFieldNameEventsRegistered] = true		
	end		
	
	return oo.rawnew(self, o)
end

function Trigger:OnEnabledChanged()
	if self:IsEnabled() and not self[kstrFieldNameEventsRegistered] then
		Apollo.RegisterEventHandler("ChallengeAbandon", 			"OnChallengeUpdate", self)
		Apollo.RegisterEventHandler("ChallengeFailTime", 			"OnChallengeUpdate", self)
		Apollo.RegisterEventHandler("ChallengeFailArea", 			"OnChallengeUpdate", self)
		Apollo.RegisterEventHandler("ChallengeActivate", 			"OnChallengeUpdate", self)
		Apollo.RegisterEventHandler("ChallengeCompleted", 			"OnChallengeUpdate", self)
		Apollo.RegisterEventHandler("ChallengeFailGeneric", 		"OnChallengeUpdate", self)	
				
		self[kstrFieldNameEventsRegistered] = true			
	elseif not self:IsEnabled() and self[kstrFieldNameEventsRegistered] then	
		Apollo.RemoveEventHandler("ChallengeAbandon", self)	
		Apollo.RemoveEventHandler("ChallengeFailTime", self)	
		Apollo.RemoveEventHandler("ChallengeFailArea", self)	
		Apollo.RemoveEventHandler("ChallengeActivated", self)	
		Apollo.RemoveEventHandler("ChallengeCompleted", self)
		Apollo.RemoveEventHandler("ChallengeFailGeneric", self)		
		self[kstrFieldNameEventsRegistered] = false			
	end
end

function Trigger:GetChallengeType()
	return self[kstrFieldNameChallengeType]
end

function Trigger:SetChallengeType(eChallengeType)
	if self[kstrFieldNameChallengeType] == eChallengeType then return end
	
	self[kstrFieldNameChallengeType] = eChallengeType
	
	self:OnChallengeUpdate()
end


function Trigger:OnChallengeUpdate(...)
	self.log:debug("OnChallengeUpdate - %s", inspect(arg))

	self:OnUpdateScanbotSummonStatus()
end

function Trigger:GetShouldSummonBot()
	self.log:debug("GetShouldSummonBot")

	local tChallengeData = ChallengesLib.GetActiveChallengeList()
	if tChallengeData == nil then return end

	local eChallengeType = self:GetChallengeType()
	
	for idx, clgCurrent in pairs(tChallengeData) do
		if clgCurrent:IsActivated() and (eChallengeType == Trigger.ChallengeTypes.Any or eChallengeType == ktChallengeTypeToInternalEnum[clgCurrent:GetType() or -1]) then
			return self:GetAction()
		end
	end

	return nil
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
	
	
	
	

