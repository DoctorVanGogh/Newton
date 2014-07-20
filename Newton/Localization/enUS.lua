-----------------------------------------------------------------------------------------------
-- enUS Localization for Newton
-- Copyright (c) DoctorVanGogh on Wildstar forums - All Rights reserved
-----------------------------------------------------------------------------------------------

local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("Newton", "enUS", true)
L["Section:General"] = "General"
L["Section:Triggers"] = "Triggers"
L["Section:Advanced"] = "Advanced"
L["Option:Persist"] = "Remember Scanbot"
L["Option:LogLevel"] = "Log Level"
L["Option:LogLevel:PopupHeader"] = "Levels"
L["Option:Profile"] = "Current Profile"
L["Option:Profile:PopupHeader"] = "Profiles"
L["Option:Profile:New"] = "New Profile"
L["Option:Profile:Delete"] = "Delete current profile"
L["Option:Profile:Triggers"] = "Triggers"
L["Option:Profile:Triggers:Explanation"] = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
L["Option:Trigger:Enabled"] = "Enabled: %s"



L["Player not a scientist - consider disabling Addon %s for this character!"] = true
L["Not a scientist - configuration disabled!"] = true


local M = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("Newton:Triggers", "enUS", true)
-- global values
M["Trigger:Settings:Any"] = "Any"
M["Trigger:Settings:All"] = "All"

M["Actions:Summon"] = "Summon"
M["Actions:Dismiss"] = "Dismiss"
M["Actions:NoAction"] = "(Manual only)"

-- trigger specific values
M["Challenge:Name"] = "Challenge"
M["Challenge:Description"] = "When on a challenge of a certain type, perform an action for the scanbot"
M["Challenge:ChallengeType"] = "Challenge type"

M["Default:Name"] = "Default"
M["Default:Description"] = "By default, perform an action for the scanbot"

M["Group:Name"] = "Group"
M["Group:Description"] = "When in a group of a certain type, perform an action for the scanbot"
M["Group:GroupType"] = "Group type"

M["Instance:Name"] = "Instance"
M["Instance:Description"] = "When in an instance, perform an action for the scanbot"

M["PvpMatch:Name"] = "PVP Match"
M["PvpMatch:Description"] = "When in a PVP Match, perform an action for the scanbot"

M["Stealth:Name"] = "Stealth"
M["Stealth:Description"] = "When stealthed, perform an action for the scanbot"