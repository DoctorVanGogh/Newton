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
local kstrFieldActiveChallenges = "tActiveChallenges"

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Multiple").tPackage
local inspect = Apollo.GetPackage("Drafto:Lib:inspect-1.2").tPackage
local TriggerBase = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Base").tPackage
local SettingEnum = Apollo.GetPackage("DoctorVanGogh:Lib:Setting:Enum").tPackage

local Trigger = APkg and APkg.tPackage

if not Trigger then
	Trigger = oo.class({}, TriggerBase)
end


Trigger.ChallengeTypes = {
	Ability = 1,
	Combat = 2,
	General = 3,	
	Item = 4,
	Activate = 5,
	Any = 999
}

local ktChallengeTypeToInternalEnum = {
	[ChallengesLib.ChallengeType_Combat] = Trigger.ChallengeTypes.Combat,
	[ChallengesLib.ChallengeType_General] = Trigger.ChallengeTypes.General,
	[ChallengesLib.ChallengeType_Item] = Trigger.ChallengeTypes.Item,
	[ChallengesLib.ChallengeType_Ability] = Trigger.ChallengeTypes.Ability,
	[ChallengesLib.ChallengeType_ChecklistActivate] = Trigger.ChallengeTypes.Activate
}


local function IsRelevantMatchingChallenge(eMonitoredChallengesType, clgChallenge)
	return clgChallenge:IsActivated() 
		   and (eMonitoredChallengesType == Trigger.ChallengeTypes.Any or eMonitoredChallengesType == ktChallengeTypeToInternalEnum[clgChallenge:GetType() or -1])
end

function Trigger:__init() 
	self.log:debug("__init()")
	
	local o = TriggerBase:__init()	
	o[kstrFieldNameChallengeType] = o[kstrFieldNameChallengeType] or Trigger.ChallengeTypes.Any	
	
	if o:GetAction() == nil then 
		o:SetAction(TriggerBase.SummoningChoice.Dismiss)
	end
	
	local result = oo.rawnew(self, o)
		
	o:AddSetting(
		SettingEnum(
			self.localization["Challenge:ChallengeType"], 
			{
				Trigger.ChallengeTypes.Ability,
				Trigger.ChallengeTypes.Combat,
				Trigger.ChallengeTypes.General,
				Trigger.ChallengeTypes.Item,
				Trigger.ChallengeTypes.Activate,
				Trigger.ChallengeTypes.Any,
			}, {
				[Trigger.ChallengeTypes.Ability] = Apollo.GetString("Challenges_AbilityChallenge"),
				[Trigger.ChallengeTypes.Combat] = Apollo.GetString("Challenges_CombatChallenge"),
				[Trigger.ChallengeTypes.General] = Apollo.GetString("Challenges_GeneralChallenge"),
				[Trigger.ChallengeTypes.Item] = Apollo.GetString("Challenges_ItemChallenge"),
				[Trigger.ChallengeTypes.Activate] = Apollo.GetString("Challenges_ActivateChallenge"),
				[Trigger.ChallengeTypes.Any] = self.localization["Trigger:Settings:Any"]
			},
			function() return o:GetChallengeType() end,
			function(eType) o:SetChallengeType(eType) end,
			"ChallengeType"							
		)	
	)	
	
	if o:IsEnabled() then	
		o[kstrFieldActiveChallenges] = o:InitNumActivateChallenges()	
	
		Apollo.RegisterEventHandler("ChallengeAbandon", 			"OnChallengeEnd", o)
		Apollo.RegisterEventHandler("ChallengeFailTime", 			"OnChallengeEnd", o)
		Apollo.RegisterEventHandler("ChallengeFailArea", 			"OnChallengeEnd", o)
		Apollo.RegisterEventHandler("ChallengeActivate", 			"OnChallengeStart", o)
		Apollo.RegisterEventHandler("ChallengeCompleted", 			"OnChallengeEnd", o)
		Apollo.RegisterEventHandler("ChallengeFailGeneric", 		"OnChallengeEnd", o)	
				
		o[kstrFieldNameEventsRegistered] = true				
	else
		o[kstrFieldActiveChallenges] = {}	
	end		
	
	return result
end


function Trigger:OnEnabledChanged()
	if self:IsEnabled() and not self[kstrFieldNameEventsRegistered] then
		Apollo.RegisterEventHandler("ChallengeAbandon", 			"OnChallengeEnd", self)
		Apollo.RegisterEventHandler("ChallengeFailTime", 			"OnChallengeEnd", self)
		Apollo.RegisterEventHandler("ChallengeFailArea", 			"OnChallengeEnd", self)
		Apollo.RegisterEventHandler("ChallengeActivate", 			"OnChallengeStart", self)
		Apollo.RegisterEventHandler("ChallengeCompleted", 			"OnChallengeEnd", self)
		Apollo.RegisterEventHandler("ChallengeFailGeneric", 		"OnChallengeEnd", self)	
				
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

function Trigger:GetName()
	return self.localization["Challenge:Name"]
end

function Trigger:GetDescription()
	return self.localization["Challenge:Description"]
end

function Trigger:GetChallengeType()
	return self[kstrFieldNameChallengeType]
end

function Trigger:SetChallengeType(eChallengeType)
	if self[kstrFieldNameChallengeType] == eChallengeType then return end
	
	self[kstrFieldNameChallengeType] = eChallengeType
	
	self:OnChallengeUpdate()
end


function Trigger:InitNumActivateChallenges()
	self.log:debug("InitNumActivateChallenges")	

	local result = {}

	local tChallengeData = ChallengesLib.GetActiveChallengeList()
	if tChallengeData == nil then return end

	local eChallengeType = self:GetChallengeType()
	
	for idx, clgCurrent in pairs(tChallengeData) do
		if IsRelevantMatchingChallenge(eChallengeType, clgCurrent) then
			table.insert(result, clgCurrent)
		end
	end
	
	return result
end


function Trigger:OnChallengeStart(challenge)
	self.log:debug("OnChallengeStart")
	
	if IsRelevantMatchingChallenge(self:GetChallengeType(), challenge) then
		-- sometimes we get multiple events for a single challenge - this screws up our count
		local challengeId = challenge:GetId()
		for idx, tRunningChallenge in ipairs(self[kstrFieldActiveChallenges]) do
			if tRunningChallenge:GetId() == challengeId then
				return
			end
		end	
		table.insert(self[kstrFieldActiveChallenges], challenge)		
		self:OnUpdateScanbotSummonStatus()
	end
end

function Trigger:OnChallengeEnd(ntIdChallenge)	-- Fail events pass challengge as 1st param, abandon & complete pass id 
	self.log:debug("OnChallengeEnd")
	
	if type(ntIdChallenge) == "userdata" then			
		ntIdChallenge = ntIdChallenge:GetId()
	end
		
	for idx, clgCurrent in ipairs(self[kstrFieldActiveChallenges]) do
		if clgCurrent:GetId() == ntIdChallenge then		
			table.remove(self[kstrFieldActiveChallenges], idx)			
			self:OnUpdateScanbotSummonStatus()			
			return
		end
	end
end

function Trigger:GetShouldSummonBot()
	self.log:debug("GetShouldSummonBot Count=%s", tostring(#self[kstrFieldActiveChallenges]))
	
	if #self[kstrFieldActiveChallenges] > 0 then
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
		"DoctorVanGogh:Lib:Setting:Enum",		
		"DoctorVanGogh:Lib:Loop:Multiple"
	}
)
	
TriggerBase:Register(Trigger, MAJOR)
	
	

