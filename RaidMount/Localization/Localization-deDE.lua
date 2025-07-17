-- German localization for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Get current locale
local currentLocale = GetLocale()

-- German locale table
local deDELocale = {
	-- UI Elements
	["STATS"] = "Statistiken",
	["SEARCH"] = "Suchen",
	["SEARCH_PLACEHOLDER"] = "Mounts, Schlachtzüge oder Bosse suchen...",
	["CLEAR_ALL"] = "Alle löschen",
	["CLOSE"] = "Schließen",
	["SELECT_ALL"] = "Alle auswählen",
	["BACK"] = "Zurück",
	["FILTERS"] = "Filter",
	["ENHANCED_TOOLTIPS"] = "Erweiterte Tooltips",
	["VERSION"] = "Version",

	-- Status Messages
	["COLLECTED"] = "Gesammelt",
	["NOT_COLLECTED"] = "Nicht gesammelt",
	["LOCKED_OUT"] = "Ausgesperrt",
	["NO_LOCKOUT"] = "Keine Sperre",
	["AVAILABLE_NOW"] = "Jetzt verfügbar",
	["NEXT_ATTEMPT"] = "Nächster Versuch",
	["LOCKOUT"] = "Sperre",
	["UNKNOWN"] = "Unbekannt",

	-- Column Headers
	["MOUNT_NAME"] = "Mount Name",
	["RAID_SOURCE"] = "Schlachtzug/Quelle",
	["BOSS"] = "Boss",
	["DROP_RATE"] = "Drop-Rate",
	["EXPANSION"] = "Erweiterung",
	["ATTEMPTS"] = "Versuche",
	["LOCKOUT_STATUS"] = "Sperre",
	["COORDINATES"] = "Karte",

	-- Filter Options
	["ALL"] = "Alle",
	["COLLECTED"] = "Gesammelt",
	["UNCOLLECTED"] = "Nicht gesammelt",
	["RAID"] = "Schlachtzug",
	["DUNGEON"] = "Dungeon",
	["NORMAL"] = "Normal",
	["HEROIC"] = "Heroisch",
	["MYTHIC"] = "Mythisch",

	-- Info Panel
	["ATTEMPT_TRACKING"] = "VERSUCHS-VERFOLGUNG",
	["STATUS_LOCKOUT"] = "STATUS & SPERRE",
	["DESCRIPTION"] = "BESCHREIBUNG",
	["TOTAL_ATTEMPTS"] = "Gesamte Versuche",
	["MORE_CHARACTERS"] = " weitere Charaktere",
	["COLLECTORS_BOUNTY"] = "Sammler-Bonus:",
	["COLLECTORS_BOUNTY_BONUS"] = "+5% Drop-Chance",
	["COLLECTED_ON"] = "Gesammelt:",
	["NO_DESCRIPTION"] = "Keine Beschreibung verfügbar.",
	["RAID"] = "Schlachtzug",
	["BOSS"] = "Boss",
	["ZONE"] = "Zone",

	-- Slash Commands
	["HELP_TITLE"] = "Verfügbare Befehle:",
	["HELP_OPEN"] = "/rm - Hauptinterface öffnen/schließen",
	["HELP_HELP"] = "/rm help - Diese Hilfe anzeigen",
	["HELP_STATS"] = "/rm stats - Statistik-Ansicht anzeigen",
	["HELP_RESET"] = "/rm reset - Alle Versuchsdaten zurücksetzen (mit Bestätigung)",
	["HELP_REFRESH"] = "/rm refresh - Mount-Sammlung aktualisieren",
	["HELP_VERIFY"] = "/rm verify - Versuchszahlen gegen Blizzard-Statistiken prüfen",
	["UNKNOWN_COMMAND"] = "Unbekannter Befehl: %s. Verwende |cFFFFFF00/rm help|r für verfügbare Befehle.",
	["RESET_CONFIRMATION"] = "Bist du sicher, dass du ALLE Versuchsdaten zurücksetzen möchtest? Dies kann nicht rückgängig gemacht werden!",
	["RESET_CONFIRM_AGAIN"] = "Tippe |cFFFFFF00/rm reset|r erneut innerhalb von 10 Sekunden zur Bestätigung.",
	["RESET_COMPLETE"] = "Alle Versuchsdaten wurden zurückgesetzt.",
	["REFRESH_SCANNING"] = "Mount-Sammlung wird gescannt...",
	["REFRESH_COMPLETE"] = "Mount-Sammlung aktualisiert.",
	["VERIFY_COMPLETE"] = "Versuch-Überprüfung abgeschlossen.",

	-- Statistics
	["DETAILED_STATS"] = "Detaillierte Mount-Sammlungs-Statistiken",
	["OVERALL_STATS"] = "Gesamtstatistiken",
	["BY_EXPANSION"] = "Nach Erweiterung",
	["MOST_ATTEMPTED"] = "Am meisten versuchte Mounts",
	["ATTEMPTS_TEXT"] = "Versuche",

	-- Tooltips
	["SEARCH_HELP"] = "Suchhilfe",
	["SEARCH_HELP_LINE1"] = "• Tippe ein Wort, um Mount-Namen, Schlachtzüge, Bosse zu suchen",
	["SEARCH_HELP_LINE2"] = "• Verwende Anführungszeichen für exakte Phrasen: \"Onyxian Drake\"",
	["SEARCH_HELP_LINE3"] = "• Mehrere Wörter suchen nach allen Begriffen: ice crown",
	["SEARCH_HELP_LINE4"] = "• Drücke Enter für sofortige Suche",
	["SEARCH_HELP_LINE5"] = "• Drücke Escape zum Löschen der Suche",
	["CLEAR_FILTERS_TIP"] = "Alle Filter löschen",
	["PROGRESS_TOOLTIP"] = "Mount-Sammlungs-Fortschritt",
	["PROGRESS_FORMAT"] = "Gesammelt: |cFF00FF00%d|r / |cFFFFFFFF%d|r (|cFFFFFF00%.1f%%|r)",

	-- Messages
	["LOADED_MESSAGE"] = "v%s geladen! Verwende |cFFFFFF00/rm|r um den Mount-Tracker zu öffnen.",
	["SCANNING_FIRST_TIME"] = "Mount-Sammlung wird zum ersten Mal gescannt...",
	["STATS_VIEW_DISPLAYED"] = "Statistik-Ansicht angezeigt.",
	["STATS_VIEW_UNAVAILABLE"] = "Statistik-Ansicht nicht verfügbar.",
	["ACTIVE_FILTERS"] = "Aktive Filter: %s",
	["NO_FILTERS_ACTIVE"] = "Keine aktiven Filter - zeige alle Mounts",
	["NO_MOUNTS_FOUND"] = "Keine Mounts gefunden, die deinen Kriterien entsprechen.",

	-- Errors
	["ERROR_HEADERS_NOT_INIT"] = "RaidMount: Warnung - HeaderTexts nicht initialisiert",
	["ERROR_HEADER_DATA_MISSING"] = "RaidMount: Warnung - Header-Daten fehlen für Index %d",
	["ERROR_RAIDMOUNT_NIL"] = "RaidMount: Fehler - RaidMount-Tabelle ist nil. Stelle sicher, dass RaidMount.lua vor RaidMountUI.lua geladen wird.",
}

-- If current locale is German, use German locale
if currentLocale == "deDE" then
	RaidMount.LOCALE = deDELocale
end
