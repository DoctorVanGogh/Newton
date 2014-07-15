-----------------------------------------------------------------------------------------------
-- ScanbotTrigger definition
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------

local MAJOR,MINOR = "DoctorVanGogh:Newton:ScanbotTrigger", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Base").tPackage
local glog

local ScanbotTrigger = APkg and APkg.tPackage

if not ScanbotTrigger then
	ScanbotTrigger = oo.class{}
end

ScanbotTrigger.Event_UpdateScanbotSummonStatus = "UpdateScanbotSummonStatus"

function ScanbotTrigger:__init(o)
	o = o or {}

	o.callbacks = o.callbacks or Apollo.GetPackage("Gemini:CallbackHandler-1.0").tPackage:New(o)
end

function ScanbotTrigger:OnLoad()
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.INFO,
		pattern = "%d [%c:%n] %l - %m",
		appender = "GeminiConsole"
	})	
	
	self.log = glog
end

function ScanbotTrigger:GetCallbacks()	
	return self.callbacks;
end

--- Return this trigger's decision on bot summoming.
-- Will return one of the Trigger.SummoningChoice values or nil trigger has no choice to make
-- @return nil or one of the Trigger.SummoningChoice fields
-- @see Trigger.SummoningChoices
function ScanbotTrigger:GetShouldSummonBot()
	self.log:debug("GetShouldSummonBot()")
	return nil
end

function ScanbotTrigger:OnUpdateScanbotSummonStatus(bForceUpdate)	
	self.log:debug("OnUpdateScanbotSummonStatus(%s)", tostring(bForceUpdate))

	self.callbacks:Fire(ScanbotTrigger.Event_UpdateScanbotSummonStatus, bForceUpdate)	
end


Apollo.RegisterPackage(
	ScanbotTrigger, 
	MAJOR, 
	MINOR, 
	{
		"Gemini:Logging-1.2",	
		"DoctorVanGogh:Lib:Loop:Base",
		"Gemini:CallbackHandler-1.0",		
	}
)