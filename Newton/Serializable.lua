-----------------------------------------------------------------------------------------------
-- Serializable definition
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------

local MAJOR,MINOR = "DoctorVanGogh:Lib:Serializable", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Base").tPackage

local Serializable = APkg and APkg.tPackage

if not Serializable then
	Serializable = oo.class{}
end

function Serializable:__init(o)
	o = o or {}
	return oo.rawnew(self, o)
end

function Serializable:Serialize()
	return nil
end

function Serializable:Deserialize(tSink)	
end



Apollo.RegisterPackage(
	Serializable, 
	MAJOR, 
	MINOR, 
	{
		"DoctorVanGogh:Lib:Loop:Base"
	}
)