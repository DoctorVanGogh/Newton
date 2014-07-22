-----------------------------------------------------------------------------------------------
-- enUS Localization for Newton
-- Copyright (c) DoctorVanGogh on Wildstar forums - All Rights reserved
-----------------------------------------------------------------------------------------------

local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("Newton", "enUS", true)
L["Config"] = "Show Newton config"
L["Section:General"] = "General"
L["Section:Triggers"] = "Triggers"
L["Section:Advanced"] = "Advanced"
L["Option:Persist"] = "Remember Scanbot"

L["Option:Profile"] = "Current Profile"
L["Option:Profile:PopupHeader"] = "Profiles"
L["Option:Profile:New"] = "New Profile"
L["Option:Profile:New:Message"] = "Select a unique name for the new profile"
L["Option:Profile:New:Label"] = "Profile name"
L["Option:Profile:Delete"] = "Delete current profile"
L["Option:Profile:Delete:Confirm"] = "Really delete profile '%s'?\nThis *cannot* be undone."
L["Option:Profile:Triggers"] = "Triggers"
L["Option:Profile:Triggers:Explanation"] = [[Explanation on Triggers:

Each Trigger performs one of three actions on a certain condition. It may automatically summon the bot, dismiss it, or simply leave it up to the user. This can be configured. Depending on the trigger it may have additional options.
Triggers work in a top down manner, meaning that the topmost trigger always takes precendence and blocks any triggers further down from performing actions - arrange your triggers accordingly.
]]
L["Option:Trigger:Add"] = "Add Trigger"
L["Option:Trigger:Enabled"] = "Enabled: %s"
L["Option:Trigger:Remove"] = "Remove trigger"
L["Option:Trigger:Forward"] = "Move up"
L["Option:Trigger:Backward"] = "Move down"
L["Option:LogLevel:Newton"] = "Log Level (Newton)"
L["Option:LogLevel:ScanbotTrigger"] = "Log Level (Scanbot Triggers)"
L["Option:LogLevel:ScanbotManager"] = "Log Level (ScanbotManager)"
L["Option:LogLevel:Configurable"] = "Log Level (Configurable)"
L["Option:LogLevel:Setting"] = "Log Level (Setting)"
L["Option:LogLevel:Configuration"] = "Log Level (Configuration UI Library)"
L["Option:LogLevel:PopupHeader"] = "Levels"


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