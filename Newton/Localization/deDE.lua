-----------------------------------------------------------------------------------------------
-- deDE Localization for Newton
-- Copyright (c) DoctorVanGogh on Wildstar forums - All Rights reserved
-----------------------------------------------------------------------------------------------

local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("Newton", "deDE")
if L then
	L["Config"] = "Newton Einstellungen anzeigen"
	L["Section:General"] = "Allgemein"
	L["Section:Triggers"] = "Trigger"
	L["Section:Advanced"] = "Erweitert"
	L["Option:Persist"] = "Scanbot merken"

	L["Option:Profile"] = "Aktuelles Profil"
	L["Option:Profile:PopupHeader"] = "Profile"
	L["Option:Profile:New"] = "Neues Profil"
	L["Option:Profile:New:Message"] = "Einen eindeutigen Namen für das neue Profil wählen"
	L["Option:Profile:New:Label"] = "Profilname"
	L["Option:Profile:Delete"] = "Aktuelles Profil löschen"
	L["Option:Profile:Delete:Confirm"] = "Profil '%s' wirklich löschen?\nKann *nicht* rückgängig gemacht werden."
	L["Option:Profile:Triggers"] = "Auslöser"
	L["Option:Profile:Triggers:Explanation"] = [[Erklärung zu Triggern:

	Jeder Trigger kann je nach Situation eine von drei Aktionen ausführen: Den Bot rufen, wegschicken oder es dem Spieler überlassen. Diese Aktion kann man jeweils festlegen. Je nach Trigger können weitere Optionen vorhanden sein.
	Die Trigger arbeiten von oben nach unten, d.h. ein weiter oben liegender Trigger blockt mit seiner Aktion immer weiter unten liegende Trigger - entsprechend sollte man seine Trigger anordnen.
	]]
	L["Option:Trigger:Add"] = "Trigger hinzufügen"
	L["Option:Trigger:Enabled"] = "Aktiv: %s"
	L["Option:Trigger:Remove"] = "Trigger entfernen"
	L["Option:Trigger:Forward"] = "Nach oben"
	L["Option:Trigger:Backward"] = "Nach unten"
	L["Option:LogLevel:Newton"] = "Protokollstufe (Newton)"
	L["Option:LogLevel:ScanbotTrigger"] = "Protokollstufe (Scanbot Triggers)"
	L["Option:LogLevel:ScanbotManager"] = "Protokollstufe (ScanbotManager)"
	L["Option:LogLevel:Configurable"] = "Protokollstufe (Configurable)"
	L["Option:LogLevel:Setting"] = "Protokollstufe (Setting)"
	L["Option:LogLevel:Configuration"] = "Protokollstufe (Configuration UI Library)"
	L["Option:LogLevel:PopupHeader"] = "Stufen"
end

local M = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("Newton:Triggers", "deDE")
if M then
	-- global values
	M["Trigger:Settings:Any"] = "Beliebig"
	M["Trigger:Settings:All"] = "Alle"

	M["Actions:Summon"] = "Rufen"
	M["Actions:Dismiss"] = "Wegschicken"
	M["Actions:NoAction"] = "(nur manuell)"

	-- trigger specific values
	M["Challenge:Name"] = "Herrausforderung"
	M["Challenge:Description"] = "Wenn man auf einer bestimmten Art von Herausforderung ist, eine Aktion für den Bot ausführen"
	M["Challenge:ChallengeType"] = "Herrausforderungstyp"

	M["Default:Name"] = "Standard"
	M["Default:Description"] = "Standardmässig eine Aktion für den Bot ausführen"

	M["Group:Name"] = "Gruppe"
	M["Group:Description"] = "Wenn man in einer Gruppe eines bestimmten Typs ist, eine Aktion für den Bot ausführen"
	M["Group:GroupType"] = "Gruppentyp"

	M["Instance:Name"] = "Instanz"
	M["Instance:Description"] = "In einer Instanz eine Aktion für den Bot ausführen"

	M["PvpMatch:Name"] = "PVP Match"
	M["PvpMatch:Description"] = "in einem PVP Match eine Aktion für den Bot ausführen"

	M["Stealth:Name"] = "Tarnung"
	M["Stealth:Description"] = "Wenn man getarnt ist, eine Aktion für den Bot ausführen"
end