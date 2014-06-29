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
local glog

local Trigger = APkg and APkg.tPackage

-- Base only defines callbacks and GetShouldSummonBot method
if not Trigger then
	local o = {	}	
	Trigger = oo.class{ o }
end

Trigger.Event_UpdateScanbotSummonStatus = "UpdateScanbotSummonStatus"


function Trigger:OnLoad()
	-- import GeminiLogging
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.DEBUG,
		pattern = "%d [%c:%n] %l - %m",
		appender = "GeminiConsole"
	})	
	
	self.log = glog
end


function Trigger:GetCallbacks()
	if not self.callbacks then
		self.callbacks = Apollo.GetPackage("Gemini:CallbackHandler-1.0").tPackage:New(o)	
	end
	
	return self.callbacks;
end

-- Return values: true/false/nil		- true = 'should summon', false = 'must not summon', nil = 'indterminate'
function Trigger:GetShouldSummonBot()
	self.log:debug("Trigger(Base):GetShouldSummonBot()")
	return nil
end

function Trigger:OnUpdateScanbotSummonStatus()	-- HACK: not clean, should only be available to protected members, would need 'scoped' model for that  - NYI
	self.log:debug("Trigger:OnUpdateScanbotSummonStatus")

	self:GetCallbacks():Fire(Trigger.Event_UpdateScanbotSummonStatus)
	self.log:debug("Trigger:OnUpdateScanbotSummonStatus DONE")
	
end

function Trigger:Enable(bEnable)
	self.enabled = bEnable	
	if self.OnEnabledChanged ~= nil then
		self:OnEnabledChanged()
	end
end

function Trigger:IsEnabled()
	return self.enabled or false;
end


Apollo.RegisterPackage(
	Trigger, 
	MAJOR, 
	MINOR, 
	{
		"Gemini:Logging-1.2",	
		"DoctorVanGogh:Lib:Loop:Base",
		"Gemini:CallbackHandler-1.0"
	}
)