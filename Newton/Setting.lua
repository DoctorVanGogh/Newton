-----------------------------------------------------------------------------------------------
-- Setting definition
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------

local MAJOR,MINOR = "DoctorVanGogh:Lib:Setting", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Base").tPackage
local inspect = Apollo.GetPackage("Drafto:Lib:inspect-1.2").tPackage
local glog

local Setting = APkg and APkg.tPackage

if not Setting then
	Setting = oo.class{}
end


function Setting:__init(strfnGetDescription, fnGetter, fnSetter, key, ...)
	self.log:debug("__init()")	
	
	local fnDescription
	if type(strfnGetDescription) == "string" then
		fnGetDescription = function() return strfnGetDescription end
	else
		fnGetDescription = strfnGetDescription
	end
	
	local o = {
		fnGetDescription = fnGetDescription or Apollo.NoOp,
		fnGetter = fnGetter or Apollo.NoOp,
		fnSetter = fnSetter or Apollo.NoOp,
		oKey = key,
		oTag = arg
	}
	-- sanitize values

	local result = oo.rawnew(self, o)
	-- do post base init

	
	return result
end

function Setting:OnLoad()
	-- import GeminiLogging
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.INFO,
		pattern = "%d [%c:%n] %l - %m",
		appender = "GeminiConsole"
	})	
	
	self.log = glog
end

function Setting:GetDescription()
	return self.fnGetDescription()
end

function Setting:GetValue(...)
	return self.fnGetter(unpack(arg))
end

function Setting:SetValue(...)
	return self.fnSetter(unpack(arg))	
end

function Setting:GetKey()
	return self.oKey
end

function Setting:GetTag()
	return self.oTag
end

Apollo.RegisterPackage(
	Setting, 
	MAJOR, 
	MINOR, 
	{
		"Drafto:Lib:inspect-1.2",
		"Gemini:Logging-1.2",	
		"DoctorVanGogh:Lib:Loop:Base"
	}
)