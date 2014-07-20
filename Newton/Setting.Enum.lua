-----------------------------------------------------------------------------------------------
-- Setting definition for enumerable item
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------

local MAJOR,MINOR = "DoctorVanGogh:Lib:Setting:Enum", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Simple").tPackage
local SettingBase = Apollo.GetPackage("DoctorVanGogh:Lib:Setting").tPackage

local Setting = APkg and APkg.tPackage

if not Setting then
	local o = {	}	
	Setting = oo.class(o, SettingBase)
end


function Setting:__init(strfnGetDescription, tValues, tValueNames, fnGetter, fnSetter, tag)
	SettingBase.log:debug("__init")	
	local o = SettingBase:__init(strfnGetDescription, fnGetter, fnSetter, tag)
		
	o.tValues = tValues or {}
	o.tValueNames = tValueNames or {}
			
	-- sanitize values	
	
	local result = oo.rawnew(self, o)
	-- do post base init
	
	return result
end

function Setting:GetValues()
	return self.tValues
end

function Setting:GetValueName(oValue)
	return self.tValueNames[oValue]
end

function Setting:GetNames()
	return self.tValueNames
end


Apollo.RegisterPackage(
	Setting, 
	MAJOR, 
	MINOR, 
	{
		"DoctorVanGogh:Lib:Loop:Simple",
		"DoctorVanGogh:Lib:Setting"
	}
)