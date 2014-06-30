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
local inspect = Apollo.GetPackage("Drafto:Lib:inspect-1.2").tPackage
local glog

local Trigger = APkg and APkg.tPackage

if not Trigger then
	local o = {	}	
	o.enabled = true
	Trigger = oo.class{ o }
end

Trigger.Event_UpdateScanbotSummonStatus = "UpdateScanbotSummonStatus"

Trigger.SummoningChoice = {
	Summon = 0,
	Dismiss = 1,
	NoAction = 2		-- different from 'nil' insofar as 'nil' will fall through to next clause in chain, NoAction will stop (used for 'manual only') setting
}

function Trigger:__init(o)
	self.log:debug("Trigger:__init()")	
	o = o or {}
	o.callbacks = o.callbacks or Apollo.GetPackage("Gemini:CallbackHandler-1.0").tPackage:New(o)
	o.enabled = true
	
	return oo.rawnew(self, o)
end


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
	return self.callbacks;
end

--- Return this trigger's decision on bot summoming.
-- Will return one of the Trigger.SummoningChoice values or nil trigger has no choice to make
-- @return nil or one of the Trigger.SummoningChoice fields
-- @see Trigger.SummoningChoices
function Trigger:GetShouldSummonBot()
	self.log:debug("Trigger(Base):GetShouldSummonBot()")
	return nil
end

function Trigger:OnUpdateScanbotSummonStatus()	-- HACK: not clean, should only be available to protected members, would need 'scoped' model for that  - NYI
	self.log:debug("Trigger:OnUpdateScanbotSummonStatus")

	self.callbacks:Fire(Trigger.Event_UpdateScanbotSummonStatus)	
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


function Trigger:GetAction()
	return self.eAction
end

function Trigger:SetAction(eAction)
	if self.eAction == eAction then return end
		
	self.eAction = eAction
	
	self:OnUpdateScanbotSummonStatus()
end


Apollo.RegisterPackage(
	Trigger, 
	MAJOR, 
	MINOR, 
	{
		"Drafto:Lib:inspect-1.2",
		"Gemini:Logging-1.2",	
		"DoctorVanGogh:Lib:Loop:Base",
		"Gemini:CallbackHandler-1.0"
	}
)