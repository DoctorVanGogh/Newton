-----------------------------------------------------------------------------------------------
-- Base class for bot summoning triggers
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
require "PlayerPathLib"

local MAJOR,MINOR = "DoctorVanGogh:Newton:Triggers:Base", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Multiple").tPackage
local Configurable = Apollo.GetPackage("DoctorVanGogh:Lib:Configurable").tPackage
local SettingEnum = Apollo.GetPackage("DoctorVanGogh:Lib:Setting:Enum").tPackage
local inspect = Apollo.GetPackage("Drafto:Lib:inspect-1.2").tPackage
local glog


local Trigger = APkg and APkg.tPackage

local tRegistry = {}
setmetatable(tRegistry, { __mode="v"})

if not Trigger then
	Trigger = oo.class({}, Configurable )
end

Trigger.Event_UpdateScanbotSummonStatus = "UpdateScanbotSummonStatus"

Trigger.SummoningChoice = {
	Summon = 0,
	Dismiss = 1,
	NoAction = 2		-- different from 'nil' insofar as 'nil' will fall through to next clause in chain, NoAction will stop (used for 'manual only') setting
}

function Trigger:__init()
	self.log:debug("__init()")	
	
	local o = Configurable:__init()			
		
	o.callbacks = o.callbacks or Apollo.GetPackage("Gemini:CallbackHandler-1.0").tPackage:New(o)
	if o.enabled == nil then
		o.enabled = true
	end
	
	local result = oo.rawnew(self, o)
	
	local settingAction = SettingEnum(
		result:GetDescription(), 
		Trigger.SummoningChoice, 
		{
			[Trigger.SummoningChoice.Summon] = self.localization["Actions:Summon"],
			[Trigger.SummoningChoice.Dismiss] = self.localization["Actions:Dismiss"],
			[Trigger.SummoningChoice.NoAction] = self.localization["Actions:NoAction"],				
		},
		function() return o:GetAction() end,
		function(eAction) o:SetAction(eAction) end,
		"Action", 
		true
	)
		
	o:AddSetting(settingAction)			
		
	return result
end


function Trigger:OnLoad()
	-- import GeminiLocale
	local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
	self.localization = GeminiLocale:GetLocale("Newton:Triggers")
end

function Trigger:Register(tTrigger, strKey)
	if tTrigger == nil then
		error("Trigger must not be nil")
	end
	
	--[[	
	if not oo.instanceof(tTrigger, TriggerBase) then
		error("Can only register Triggers")
	end
	]]
	
	tRegistry[strKey] = tTrigger
end

function Trigger:GetRegisteredTriggers()
	return tRegistry
end

function Trigger:GetName()
	return nil
end

function Trigger:GetDescription()
	return nil
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

function Trigger:OnUpdateScanbotSummonStatus(bForceUpdate)	-- HACK: not clean, should only be available to protected members, would need 'scoped' model for that  - NYI
	self.log:debug("Trigger:OnUpdateScanbotSummonStatus(%s)", tostring(bForceUpdate))

	self.callbacks:Fire(Trigger.Event_UpdateScanbotSummonStatus, bForceUpdate)	
end

function Trigger:Enable(bEnable)
	self.log:debug("Enable(%s)", tostring(bEnable))
	if bEnable == self.enabled then return end
	
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
		"Gemini:Locale-1.0",		
		"DoctorVanGogh:Lib:Loop:Multiple",
		"Gemini:CallbackHandler-1.0",
		"DoctorVanGogh:Lib:Setting",
		"DoctorVanGogh:Lib:Setting:Enum",
		"DoctorVanGogh:Lib:Configurable"
	}
)