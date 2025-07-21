-- Spanish localization for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Get current locale
local currentLocale = GetLocale()

-- Spanish locale table
local esESLocale = {
    -- UI Elements
    ["STATS"] = "Estadísticas",
    ["SEARCH"] = "Buscar",
    ["SEARCH_PLACEHOLDER"] = "Buscar monturas, bandas o jefes...",
    ["CLEAR_ALL"] = "Limpiar todo",
    ["CLOSE"] = "Cerrar",
    ["SELECT_ALL"] = "Seleccionar todo",
    ["BACK"] = "Atrás",
    ["FILTERS"] = "Filtros",
    ["ENHANCED_TOOLTIPS"] = "Tooltips mejorados",
    ["VERSION"] = "Versión",
    
    -- Status Messages
    ["COLLECTED"] = "Coleccionado",
    ["NOT_COLLECTED"] = "No coleccionado",
    ["LOCKED_OUT"] = "Bloqueado",
    ["NO_LOCKOUT"] = "Sin bloqueo",
    ["AVAILABLE_NOW"] = "Disponible ahora",
    ["NEXT_ATTEMPT"] = "Próximo intento",
    ["LOCKOUT"] = "Bloqueo",
    ["UNKNOWN"] = "Desconocido",
    
    -- Column Headers
    ["MOUNT_NAME"] = "Nombre de la montura",
    ["RAID_SOURCE"] = "Banda/Fuente",
    ["BOSS"] = "Jefe",
    ["DROP_RATE"] = "Tasa de drop",
    ["EXPANSION"] = "Expansión",
    ["ATTEMPTS"] = "Intentos",
    ["LOCKOUT_STATUS"] = "Bloqueo",
    ["COORDINATES"] = "Mapa",
    
    -- Filter Options
    ["ALL"] = "Todos",
    ["COLLECTED"] = "Coleccionado",
    ["UNCOLLECTED"] = "No coleccionado",
    ["RAID"] = "Banda",
    ["DUNGEON"] = "Mazmorra",
    ["NORMAL"] = "Normal",
    ["HEROIC"] = "Heroico",
    ["MYTHIC"] = "Mítico",
    
    -- Info Panel
    ["ATTEMPT_TRACKING"] = "SEGUIMIENTO DE INTENTOS",
    ["STATUS_LOCKOUT"] = "ESTADO & BLOQUEO",
    ["DESCRIPTION"] = "DESCRIPCIÓN",
    ["TOTAL_ATTEMPTS"] = "Total de intentos",
    ["MORE_CHARACTERS"] = " personajes más",
    ["COLLECTORS_BOUNTY"] = "Recompensa del coleccionista:",
    ["COLLECTORS_BOUNTY_BONUS"] = "+5% probabilidad de drop",
    ["COLLECTED_ON"] = "Coleccionado:",
    ["NO_DESCRIPTION"] = "No hay descripción disponible.",
    ["RAID"] = "Banda",
    ["BOSS"] = "Jefe",
    ["ZONE"] = "Zona",
    
    -- Slash Commands
    ["HELP_TITLE"] = "Comandos disponibles:",
    ["HELP_OPEN"] = "/rm - Abrir/cerrar la interfaz principal",
    ["HELP_HELP"] = "/rm help - Mostrar este mensaje de ayuda",
    ["HELP_STATS"] = "/rm stats - Mostrar vista de estadísticas",
    ["HELP_RESET"] = "/rm reset - Restablecer todos los datos de intentos (con confirmación)",
    ["HELP_REFRESH"] = "/rm refresh - Actualizar datos de colección de monturas",
    ["HELP_VERIFY"] = "/rm verify - Verificar contadores de intentos contra estadísticas de Blizzard",
    ["UNKNOWN_COMMAND"] = "Comando desconocido: %s. Usa |cFFFFFF00/rm help|r para comandos disponibles.",
    ["RESET_CONFIRMATION"] = "¿Estás seguro de que quieres restablecer TODOS los datos de intentos? ¡Esto no se puede deshacer!",
    ["RESET_CONFIRM_AGAIN"] = "Escribe |cFFFFFF00/rm reset|r de nuevo en 10 segundos para confirmar.",
    ["RESET_COMPLETE"] = "Todos los datos de intentos han sido restablecidos.",
    ["REFRESH_SCANNING"] = "Escaneando tu colección de monturas...",
    ["REFRESH_COMPLETE"] = "Colección de monturas actualizada.",
    ["VERIFY_COMPLETE"] = "Verificación de intentos completada.",
    
    -- Statistics
    ["DETAILED_STATS"] = "Estadísticas detalladas de colección de monturas",
    ["OVERALL_STATS"] = "Estadísticas generales",
    ["BY_EXPANSION"] = "Por expansión",
    ["MOST_ATTEMPTED"] = "Monturas más intentadas",
    ["ATTEMPTS_TEXT"] = "intentos",
    
    -- Tooltips
    ["SEARCH_HELP"] = "Ayuda de búsqueda",
    ["SEARCH_HELP_LINE1"] = "• Escribe cualquier palabra para buscar nombres de monturas, bandas, jefes",
    ["SEARCH_HELP_LINE2"] = "• Usa comillas para frases exactas: \"Onyxian Drake\"",
    ["SEARCH_HELP_LINE3"] = "• Múltiples palabras buscan todos los términos: ice crown",
    ["SEARCH_HELP_LINE4"] = "• Presiona Enter para buscar inmediatamente",
    ["SEARCH_HELP_LINE5"] = "• Presiona Escape para limpiar búsqueda",
    ["CLEAR_FILTERS_TIP"] = "Limpiar todos los filtros",
    ["PROGRESS_TOOLTIP"] = "Progreso de colección de monturas",
    ["PROGRESS_FORMAT"] = "Coleccionado: |cFF00FF00%d|r / |cFFFFFFFF%d|r (|cFFFFFF00%.1f%%|r)",
    
    -- Messages
    ["LOADED_MESSAGE"] = "¡v%s cargado! Usa |cFFFFFF00/rm|r para abrir el rastreador de monturas.",
    ["SCANNING_FIRST_TIME"] = "Escaneando tu colección de monturas por primera vez...",
    ["STATS_VIEW_DISPLAYED"] = "Vista de estadísticas mostrada.",
    ["STATS_VIEW_UNAVAILABLE"] = "Vista de estadísticas no disponible.",
    ["ACTIVE_FILTERS"] = "Filtros activos: %s",
    ["NO_FILTERS_ACTIVE"] = "No hay filtros activos - mostrando todas las monturas",
    ["NO_MOUNTS_FOUND"] = "No se encontraron monturas que coincidan con tus criterios.",
    ["NEW_MOUNT_COLLECTED"] = "¡Nueva montura obtenida! ID de montura: %d",
    ["DIFFICULTY_SET"] = "%s está configurado en %s",
    ["TOMTOM_WAYPOINT_SET"] = "Punto de referencia TomTom establecido para %s",
    ["COULD_NOT_FIND_MAP_ID"] = "No se pudo encontrar el ID del mapa para la zona: %s",
    ["WAYPOINT_SET"] = "Punto de referencia establecido para %s en %s (%.1f, %.1f)",
    ["MOUNT_LOCATION"] = "Ubicación de %s: %s (%s) - %.1f, %.1f",
    ["INSTALL_TOMTOM"] = "Instala el addon TomTom para mejor soporte de puntos de referencia cross-expansion",
    ["TRAVEL_GUIDE"] = "Guía de viaje RaidMount: %s",
    ["CROSS_EXPANSION_TRAVEL"] = "Viaje cross-expansion: %s -> %s (%s)",
    ["TRAVEL_NEEDED"] = "Viaje necesario: %s -> %s (%s)",
    ["INSTANCE_EXPANSION_INFO"] = "Instancia: %s | Expansión: %s",
    
    -- Errors
    ["ERROR_HEADERS_NOT_INIT"] = "RaidMount: Advertencia - HeaderTexts no inicializado",
    ["ERROR_HEADER_DATA_MISSING"] = "RaidMount: Advertencia - Datos de encabezado faltantes para el índice %d",
    ["ERROR_RAIDMOUNT_NIL"] = "RaidMount: Error - Tabla RaidMount es nil. Asegúrate de que RaidMount.lua se cargue antes que RaidMountUI.lua.",
}

-- If current locale is Spanish, use Spanish locale
if currentLocale == "esES" then
    RaidMount.LOCALE = esESLocale
end 