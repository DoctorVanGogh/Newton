-----------------------------------------------------------------------------------------------
-- Group bot summoning trigger
--
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
require "GroupLib"

local MAJOR,MINOR = "DoctorVanGogh:Newton:Triggers:Group", 1

local kstrFieldNameGroupType = "eGroupType"
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
local SettingEnum = Apollo.GetPackage("DoctorVanGogh:Lib:Setting:Enum").tPackage

local Trigger = APkg and APkg.tPackage

if not Trigger then
	Trigger = oo.class({}, TriggerBase)
end

Trigger.GroupTypes = {
	Regular = 1,
	Raid = 2,
	Any = 3	
}

function Trigger:__init() 
	self.log:debug("__init()")
	
	
	local o = TriggerBase:__init(
		self.localization["Default:Name"],
		self.localization["Default:Description"],
		MAJOR
	)		
	o[kstrFieldNameGroupType] = o[kstrFieldNameGroupType] or Trigger.GroupTypes.Raid
	
	if o:GetAction() == nil then 
		o:SetAction(TriggerBase.SummoningChoice.Dismiss)
	end
	
	local result = oo.rawnew(self, o)
	
	o:AddSetting(
		SettingEnum(
			self.localization["Group:GroupType"], 
			Trigger.GroupTypes, 
			{
				[Trigger.GroupTypes.Regular] = Apollo.GetString("Group_PartyName"),
				[Trigger.GroupTypes.Raid] = Apollo.GetString("Group_RaidName"),
				[Trigger.GroupTypes.Any] = self.localization["Trigger:Settings:Any"]			
			},
			function() return o:GetGroupType() end,
			function(eType) o:SetGroupType(eType) end,
			MAJOR..":GetGroupType"					
		)	
	)	
	
	if o:IsEnabled() then
		Apollo.RegisterEventHandler("Group_Updated", "OnGroupChanged", o)	
		Apollo.RegisterEventHandler("Group_Join", "OnGroupChanged", o)		
		Apollo.RegisterEventHandler("Group_Left", "OnGroupChanged", o)				
		o[kstrFieldNameEventsRegistered] = true		
	end		
	
	return result
end

function Trigger:OnEnabledChanged()
	if self:IsEnabled() and not self[kstrFieldNameEventsRegistered] then
		Apollo.RegisterEventHandler("Group_Updated", "OnGroupChanged", self)	
		Apollo.RegisterEventHandler("Group_Join", "OnGroupChanged", self)		
		Apollo.RegisterEventHandler("Group_Left", "OnGroupChanged", self)				
		self[kstrFieldNameEventsRegistered] = true			
	elseif not self:IsEnabled() and self[kstrFieldNameEventsRegistered] then	
		Apollo.RemoveEventHandler("Group_Updated", self)	
		Apollo.RemoveEventHandler("Group_Join", self)	
		Apollo.RemoveEventHandler("Group_Left", self)			
		self[kstrFieldNameEventsRegistered] = false			
	end
end

function Trigger:GetGroupType()
	return self[kstrFieldNameGroupType]
end

function Trigger:SetGroupType(eGroupType)
	if self[kstrFieldNameGroupType] == eGroupType then return end
	
	self[kstrFieldNameGroupType] = eGroupType
	
	self:OnGroupChanged()
end

function Trigger:OnGroupChanged()
	self.log:debug("OnGroupChanged")

	if not GroupLib.InGroup() then return end
	self:OnUpdateScanbotSummonStatus()
end

function Trigger:GetShouldSummonBot()
	self.log:debug("GetShouldSummonBot")

	if GroupLib.InGroup() then			
		local eGroupType = self:GetGroupType()
		
		return ((eGroupType == Trigger.GroupTypes.Any) or
			    (eGroupType == Trigger.GroupTypes.Regular and not GroupLib.InRaid()) or
			    (eGroupType == Trigger.GroupTypes.Raid and GroupLib.InRaid()))
				and self:GetAction()	
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