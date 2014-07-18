-----------------------------------------------------------------------------------------------
-- Bot summonning trigger list
--
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
local MAJOR,MINOR = "DoctorVanGogh:Newton:TriggerList", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Multiple").tPackage
local TriggerBase = Apollo.GetPackage("DoctorVanGogh:Newton:Triggers:Base").tPackage
local ScanbotTrigger = Apollo.GetPackage("DoctorVanGogh:Newton:ScanbotTrigger").tPackage
local Serializable = Apollo.GetPackage("DoctorVanGogh:Lib:Serializable").tPackage

local glog

local TriggerList = APkg and APkg.tPackage

if not TriggerList then
	TriggerList = oo.class({}, ScanbotTrigger)
end

function TriggerList:__init(o) 
	self.log:debug("__init()")

	o = o or {}
	ScanbotTrigger:__init(o)		
	o.children = o.children or {}
	
	return oo.rawnew(self, o)
end


function TriggerList:Add(tTrigger)
	self.log:debug("Add")

	if tTrigger == nil then
		error("Trigger must not be nil")
	end
	
	if not oo.instanceof(tTrigger, Serializable) then
		self.log:warn("Added element not serializable - will be lost on ui reload")
	end	
			
	table.insert(self.children, tTrigger)
	if oo.instanceof(tTrigger, TriggerBase) then
		tTrigger.RegisterCallback(self, ScanbotTrigger.Event_UpdateScanbotSummonStatus, "OnChildScanbotStatusUpdated")		
	end		
end

function TriggerList:OnChildScanbotStatusUpdated(event, bForceRestore)
	self.log:debug("OnChildScanbotStatusUpdated(%s)", tostring(bForceRestore))
	self:OnUpdateScanbotSummonStatus(bForceRestore)
end

function TriggerList:GetShouldSummonBot()
	self.log:debug("GetShouldSummonBot")

	for idx, tTrigger in ipairs(self.children) do
		local childResult = tTrigger:GetShouldSummonBot()
		if childResult then
			return childResult
		end
	end
end

function TriggerList:Serialize()
	local result = {}
	for idx, tElement in ipairs(self.children) do
		local value, key
		if oo.instanceof(tElement, Serializable) then
			value = tElement:Serialize()
		end
		if oo.instanceof(tElement, TriggerBase) then
			key = TriggerBase:GetRegistryKey(tElement)
		end
		
		table.insert(result, { key = key, values = value })	
	end
	
	return result
end

function TriggerList:Deserialize(tSink)	
	for idx, tTrigger in ipairs(self.children) do
		tTrigger.UnregisterAllCallbacks(self)
	end
	
	self.children = {}
	
	for key, tValue in pairs(tSink) do
		local tTriggerClass = TriggerBase:GetRegisteredTriggers()[key]
		local tTrigger
		if tTriggerClass then
			tTrigger = tTriggerClass()
			tTrigger:Deserialize(tValue)
		else
			tTrigger = tValue
		end	
		self:Add(tTrigger)
	end
end


Apollo.RegisterPackage(
	TriggerList, 
	MAJOR, 
	MINOR, 
	{	
		"DoctorVanGogh:Lib:Serializable",
		"DoctorVanGogh:Newton:ScanbotTrigger",
		"DoctorVanGogh:Newton:Triggers:Base",
		"DoctorVanGogh:Lib:Loop:Multiple"
	}
)