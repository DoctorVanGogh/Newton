-----------------------------------------------------------------------------------------------
-- Configurable item definition
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------

local MAJOR,MINOR = "DoctorVanGogh:Lib:Configurable", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Simple").tPackage
local inspect = Apollo.GetPackage("Drafto:Lib:inspect-1.2").tPackage
local Setting = Apollo.GetPackage("DoctorVanGogh:Lib:Setting").tPackage
local glog

local Configurable = APkg and APkg.tPackage

if not Configurable then	
	Configurable = oo.class{}
end


function Configurable:__init(strName)
	self.log:debug("__init(%s)", tostring(strName))	
	local o =  {
		strName = strName,
		settings = {}
	}

	return oo.rawnew(self, o)
end

function Configurable:OnLoad()
	-- import GeminiLogging
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.DEBUG,
		pattern = "%d [%c:%n] %l - %m",
		appender = "GeminiConsole"
	})	
	
	self.log = glog
end

function Configurable:GetName()
	return self.strName
end

function Configurable:GetSettingsEnumerator()
	if not self.settings then return Apollo.NoOp end

	local i = 0
	local n = table.getn(self.settings)
	
	return 	function()
				i = i + 1
				if i <= n then return self.settings[i] end
			end
end

function Configurable:AddSetting(setting)	
	if not oo.instanceof(setting, Setting) then
		error("Can only add Settings.")
	end
	
	table.insert(self.settings, setting)		
end

Apollo.RegisterPackage(
	Configurable, 
	MAJOR, 
	MINOR, 
	{
		"Drafto:Lib:inspect-1.2",
		"Gemini:Logging-1.2",	
		"DoctorVanGogh:Lib:Loop:Base",
		"DoctorVanGogh:Lib:Setting"
	}
)