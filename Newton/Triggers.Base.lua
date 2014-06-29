-----------------------------------------------------------------------------------------------
-- Base class for bot summoning triggers
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
local MAJOR,MINOR = "DoctorVanGogh:Newton:Triggers:Base", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Base").tPackage

local Trigger = APkg and APkg.tPackage

-- Base only defines callbacks and GetShouldSummonBot method
if not Trigger then
	local o = {	}	
	o.enabled = true
	o.callbacks = Apollo.GetPackage("Gemini:CallbackHandler-1.0").tPackage:New(o)
	
	Trigger = oo.class{ o }
end

Trigger.Event_UpdateScanbotSummonStatus = "UpdateScanbotSummonStatus"

-- Return values: true/false/nil		- true = 'should summon', false = 'must not summon', nil = 'indterminate'
function Trigger:GetShouldSummonBot()
	return nil
end

function Trigger:OnUpdateScanbotSummonStatus(bForceRestore)	-- HACK: not clean, should only be available to protected members, would need 'scoped' model for that  - NYI
	self.callbacks:Fire(Trigger.Event_UpdateScanbotSummonStatus, bForceRestore)
end

function Trigger:Enable(bEnable)
	self.enabled = bEnable	
	if self.OnEnabledChanged ~= nil then
		self:OnEnabledChanged()
	end
end

function Trigger:IsEnabled()
	return self.enabled;
end


Apollo.RegisterPackage(
	Trigger, 
	MAJOR, 
	MINOR, 
	{
		"DoctorVanGogh:Lib:Loop:Base",
		"Gemini:CallbackHandler-1.0"
	}
)