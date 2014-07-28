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
		return true
	end		
end

function TriggerList:Remove(tTrigger)
	self.log:debug("Remove")

	if tTrigger == nil then
		error("Trigger must not be nil")
	end
	
	if not oo.instanceof(tTrigger, TriggerBase) then
		self.log:warn("Element must be Trigger")
	end		
	
	local index
	for idx, t in ipairs(self.children) do
		if t == tTrigger then
			index = idx
			break
		end
	end	
	
	if index and table.remove(self.children, index) then
		tTrigger:UnregisterAllCallbacks(self)
		
		return true
	else
		self.log:warn("Trigger to remove not in list")
	end	
end

function TriggerList:Get(index)
	return self.children[index]
end



function TriggerList:Forward(tTrigger)
	self.log:debug("Forward")

	if tTrigger == nil then
		error("Trigger must not be nil")
	end
	
	if not oo.instanceof(tTrigger, TriggerBase) then
		self.log:warn("Element must be Trigger")
	end		

	local index
	for idx, t in ipairs(self.children) do
		if t == tTrigger then
			index = idx
			break
		end
	end
	
	if index then
		if index > 1 then
			local tSwap = self.children[index - 1]
			self.children[index - 1] = self.children[index]
			self.children[index] = tSwap
			
			return true
		end
	else
		self.log:warn("Trigger not in list")		
	end
end

function TriggerList:Backward(tTrigger)
	self.log:debug("Backward")

	if tTrigger == nil then
		error("Trigger must not be nil")
	end
	
	if not oo.instanceof(tTrigger, TriggerBase) then
		self.log:warn("Element must be Trigger")
	end		

	local index
	for idx, t in ipairs(self.children) do
		if t == tTrigger then
			index = idx
			break
		end
	end
	
	if index then
		if index < #self.children then
			local tSwap = self.children[index + 1]
			self.children[index + 1] = self.children[index]
			self.children[index] = tSwap
			
			return true
		end
	else
		self.log:warn("Trigger not in list")		
	end
end

function TriggerList:GetEnumerator()
	if not self.children then return Apollo.NoOp end

	local i = 0
	local n = table.getn(self.children)
	
	return 	function()
				i = i + 1
				if i <= n then return self.children[i] end
			end
end

function TriggerList:GetCount()
	return table.getn(self.children)
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
		if tTrigger.UnregisterAllCallbacks then
			tTrigger.UnregisterAllCallbacks(self)
		end
	end
	
	self.children = {}
	
	for idx, tComposite in ipairs(tSink) do

		local key = tComposite.key
		local tValue = tComposite.values
		self.log:debug("%s = %s", tostring(key), inspect(tValue))
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
	
	self:OnUpdateScanbotSummonStatus(true)
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