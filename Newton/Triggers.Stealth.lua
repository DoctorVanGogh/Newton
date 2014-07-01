-----------------------------------------------------------------------------------------------
-- Stealth bot summoning trigger
--
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
require "GameLib"

local MAJOR,MINOR = "DoctorVanGogh:Newton:Triggers:Stealth", 1

local kstrFieldNameEventsRegistered = "bEventsRegistered"
local kstrFieldNameIsStealthed = "bIsStealthed"
local kstrStealthCheckTimerName = MAJOR..":Timer"

local nStealthId = 38784

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

function Trigger:__init(o) 
	self.log:debug("Trigger:__init()")
	
	o = o or {}
	TriggerBase:__init(o)
	
	if o:GetAction() == nil then 
		o:SetAction(TriggerBase.SummoningChoice.Dismiss) 
	end
	
	
	local result = oo.rawnew(self, o)
	
	Apollo.CreateTimer(kstrStealthCheckTimerName, 250, true)	
	Apollo.RegisterTimerHandler(kstrStealthCheckTimerName, "OnStealthCheckTimer", o)	
	
	if o:IsEnabled() then
		Apollo.StartTimer(kstrStealthCheckTimerName)
	else
		Apollo.StopTimer(kstrStealthCheckTimerName)	
	end		
			
	return result
end

function Trigger:OnEnabledChanged()
	if o:IsEnabled() then
		Apollo.StartTimer(kstrStealthCheckTimerName)
	else
		Apollo.StopTimer(kstrStealthCheckTimerName)	
	end	
end


function Trigger:IsStealthed()
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then return end
	local buffs = unitPlayer:GetBuffs()
	if buffs then
		local bIsStealthed = false
		for k, v in pairs(buffs.arBeneficial) do
			if v.splEffect:GetId() == nStealthId then
				return true				
			end
		end
	end
	return false
end


function Trigger:OnStealthCheckTimer()
	self.log:debug("OnStealthCheckTimer")
	
	local bIsStealthed = self:IsStealthed()
	
	if self[kstrFieldNameIsStealthed] ~= bIsStealthed then
		self[kstrFieldNameIsStealthed] = bIsStealthed
		self:OnUpdateScanbotSummonStatus()
	end	
end

function Trigger:GetShouldSummonBot()
	self.log:debug("GetShouldSummonBot")

	if self[kstrFieldNameIsStealthed] then
		return self:GetAction()
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
		"DoctorVanGogh:Lib:Loop:Multiple"
	}
)