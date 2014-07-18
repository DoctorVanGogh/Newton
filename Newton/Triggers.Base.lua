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
local Serializable = Apollo.GetPackage("DoctorVanGogh:Lib:Serializable").tPackage
local ScanbotTrigger = Apollo.GetPackage("DoctorVanGogh:Newton:ScanbotTrigger").tPackage
local SettingEnum = Apollo.GetPackage("DoctorVanGogh:Lib:Setting:Enum").tPackage
local inspect = Apollo.GetPackage("Drafto:Lib:inspect-1.2").tPackage
local glog


local Trigger = APkg and APkg.tPackage

local tRegistry = {}
setmetatable(tRegistry, { __mode="v"})

if not Trigger then
	Trigger = oo.class({}, Configurable, Serializable, ScanbotTrigger)
end

Trigger.SummoningChoice = {
	Summon = 0,
	Dismiss = 1,
	NoAction = 2		-- different from 'nil' insofar as 'nil' will fall through to next clause in chain, NoAction will stop (used for 'manual only') setting
}

function Trigger:__init()
	self.log:debug("__init()")	
	
	local o = {}
	
	Serializable:__init(o)
	Configurable:__init(o)		
	ScanbotTrigger:__init(o)
		
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

function Trigger:GetName()
	return nil
end

function Trigger:GetDescription()
	return nil
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


-- [DE]SERIALIZATION
function Trigger:Serialize()
	local t = {
		bEnabled = self:IsEnabled(),
		tSettings = {}		
	}
	for s in self:GetSettingsEnumerator() do
		t.tSettings[s:GetKey()] = s:GetValue()
	end
	return t
end

function Trigger:Deserialize(tSink)
	self:Enable(false)
	
	if tSink.tSettings then
		for s in self:GetSettingsEnumerator() do
			local value = tSink.tSettings[s:GetKey()]
			if value then
				s:SetValue(value)
			end
		end	
	end	
	
	self:Enable(tSink.bEnabled or false)
end

-- TRIGGER REGISTRY
function Trigger:Register(tTrigger, strKey)
	if tTrigger == nil then
		error("Trigger must not be nil")
	end
	
	--[[
	if not oo.subclassof(tTrigger, TriggerBase) then
		error("Can only register Triggers")
	end
	--]]
	
	
	tRegistry[strKey] = tTrigger
end

function Trigger:GetRegisteredTriggers()
	return tRegistry
end

function Trigger:GetRegistryKey(tTrigger)
	if not tTrigger then
		error("Trigger must not be nil")		
	end
	
	self.log:debug("%s", tostring(oo.instanceof(tTrigger, Trigger)))		
	
	if not oo.instanceof(tTrigger, Trigger) then
		error("Can only query Triggers")
	end	
	
	for idx, tRegisteredTrigger in pairs(tRegistry) do
		if oo.instanceof(tTrigger, tRegisteredTrigger) then
			return idx
		end
	end
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
		"DoctorVanGogh:Lib:Configurable",
		"DoctorVanGogh:Lib:Serializable"
	}
)