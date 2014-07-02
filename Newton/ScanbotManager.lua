-----------------------------------------------------------------------------------------------
-- ScanbotManager for Newton
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------
require "PlayerPathLib"

-- local constants
local kstrScientistSetScanBotProfileFunctionName = "ScientistSetScanBotProfile"
local kstrFieldScanbotIndex = "nScanbotIndex"

local MAJOR,MINOR = "DoctorVanGogh:Newton:ScanbotManager", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Base").tPackage
local inspect = Apollo.GetPackage("Drafto:Lib:inspect-1.2").tPackage
local GeminiHook
local glog

local ScanbotManager = APkg and APkg.tPackage

if not ScanbotManager then
	local o = {	}	
	ScanbotManager = oo.class{ o }
end

-- internal local functions
local function GetScanbotProfileIndexFromProfile(currentProfile)
	if currentProfile == nil then
		return nil
	end
	for idx, profile in ipairs(PlayerPathLib.ScientistAllGetScanBotProfiles()) do
		if currentProfile == profile then
			return idx			
		end		
	end
end 

local function RestoreScanbot(nIndex, bForceRestore)
	glog:debug("RestoreScanbot(%s)", tostring(bForceRestore))
		
	local currentProfile = PlayerPathLib.ScientistGetScanBotProfile()	
	-- check if correct bot already selected
	if bForceRestore or (currentProfile and GetScanbotProfileIndexFromProfile(currentProfile) ~= nIndex) then					
		--  select correct bot
		local profile = PlayerPathLib.ScientistAllGetScanBotProfiles()[nIndex]			
		if profile then		
			PlayerPathLib.ScientistSetScanBotProfile(profile)
		end			
	end		
end

local function SummonScanbot(bSummon)
	glog:debug("SummonScanbot(%s)", tostring(bSummon))

	if bSummon ~= PlayerPathLib.ScientistHasScanBot() then	
		PlayerPathLib.ScientistToggleScanBot()	
	end	
end

function ScanbotManager:__init(nScanbotIndex)
	self.log:debug("ScanbotManager:__init(%s)", tostring(nScanbotIndex))	
	local o = {}
	-- store current scanbot
	o[kstrFieldScanbotIndex] = nScanbotIndex or GetScanbotProfileIndexFromProfile(PlayerPathLib.ScientistGetScanBotProfile())
	
	GeminiHook:Embed(o)

	local result = oo.rawnew(self, o)
	if not o:IsHooked(PlayerPathLib, kstrScientistSetScanBotProfileFunctionName) then
		o:PostHook(PlayerPathLib, kstrScientistSetScanBotProfileFunctionName)	
	end	
	
	return result
end

function ScanbotManager:OnLoad()
	-- import GeminiLogging
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.DEBUG,
		pattern = "%d [%c:%n] %l - %m",
		appender = "GeminiConsole"
	})	
	
	self.log = glog
	
	-- import GeminiHook
	GeminiHook = Apollo.GetPackage("Gemini:Hook-1.0").tPackage	
end

function ScanbotManager:GetScanbotIndex()
	return self[kstrFieldScanbotIndex]
end

function ScanbotManager:SetScanbotIndex(nIndex, bForceUpdate)
	if nIndex == nil then return end
	
	if nIndex ~= self.nScanbotIndex or bForceUpdate then
		self[kstrFieldScanbotIndex] = nIndex
		RestoreScanbot(nIndex, bForceUpdate)
	end
end

function ScanbotManager:RestoreSelectionToCurrentScanbot(bForceRestore)
	self.log:debug("RestoreSelectionToCurrentScanbot")

	if not self[kstrFieldScanbotIndex] then return end
	
	RestoreScanbot(self[kstrFieldScanbotIndex], bForceRestore)
end

function ScanbotManager:ForceRestoreOnNextSummon()
	self.bForceRestoreOnNextSummon = true
end

function ScanbotManager:SummonBot(bSummon, bForceRestore)
	self.log:debug("SummonBot(%s, %s)", tostring(bSummon), tostring(bForceRestore))
	if bSummon and self.bForceRestoreOnNextSummon then
		self.bForceRestoreOnNextSummon = nil
		bForceRestore = true
	end
	
	self:RestoreSelectionToCurrentScanbot(bForceRestore)

	local player = GameLib.GetPlayerUnit()

	if player then
		if bSummon ~= nil then
			SummonScanbot(bSummon)
		end
	end
end

ScanbotManager[kstrScientistSetScanBotProfileFunctionName] = function(self, tProfile)
	local index =  GetScanbotProfileIndexFromProfile(tProfile)
	self.log:debug("%s(%i)", kstrScientistSetScanBotProfileFunctionName, index)
	self[kstrFieldScanbotIndex] = index
end



Apollo.RegisterPackage(
	ScanbotManager, 
	MAJOR, 
	MINOR, 
	{
		"Drafto:Lib:inspect-1.2",
		"Gemini:Logging-1.2",	
		"Gemini:Hook-1.0",
		"DoctorVanGogh:Lib:Loop:Base",
		"Gemini:CallbackHandler-1.0"
	}
)