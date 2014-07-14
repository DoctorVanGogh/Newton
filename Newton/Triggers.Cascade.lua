-----------------------------------------------------------------------------------------------
-- Cascading bot summoning trigger
--
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
local MAJOR,MINOR = "DoctorVanGogh:Newton:Triggers:Cascade", 1

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

function Trigger:__init() 
	self.log:debug("__init()")
	
	local o = TriggerBase:__init()
	
	o.children = o.children or {}
	TriggerBase:__init(o)
	
	if o:GetAction() == nil then 	
		o:SetAction(TriggerBase.SummoningChoice.NoAction)
	end
	
	return oo.rawnew(self, o)
end

function Trigger:Add(tTrigger)
	self.log:debug("Add")

	if tTrigger == nil then
		error("Trigger must not be nil")
	end
		
	if not oo.instanceof(tTrigger, TriggerBase) then
		error("Can only add Triggers")
	end
	
	table.insert(self.children, tTrigger)
	
	tTrigger.RegisterCallback(self, TriggerBase.Event_UpdateScanbotSummonStatus, "OnChildScanbotStatusUpdated")	
end

function Trigger:OnChildScanbotStatusUpdated(event, bForceRestore)
	self.log:debug("OnChildScanbotStatusUpdated(%s)", tostring(bForceRestore))
	self:OnUpdateScanbotSummonStatus(bForceRestore)
end

function Trigger:GetShouldSummonBot()
	self.log:debug("GetShouldSummonBot")

	for idx, tTrigger in ipairs(self.children) do
		local childResult = tTrigger:GetShouldSummonBot()
		if childResult then
			return childResult
		end
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