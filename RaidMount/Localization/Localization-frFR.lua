-- French localization for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Get current locale
local currentLocale = GetLocale()

-- French locale table
local frFRLocale = {
    -- UI Elements
    ["STATS"] = "Statistiques",
    ["SEARCH"] = "Rechercher",
    ["SEARCH_PLACEHOLDER"] = "Rechercher des montures, raids ou boss...",
    ["CLEAR_ALL"] = "Tout effacer",
    ["CLOSE"] = "Fermer",
    ["SELECT_ALL"] = "Tout sélectionner",
    ["BACK"] = "Retour",
    ["FILTERS"] = "Filtres",
    ["ENHANCED_TOOLTIPS"] = "Infobulles améliorées",
    ["VERSION"] = "Version",
    
    -- Status Messages
    ["COLLECTED"] = "Collecté",
    ["NOT_COLLECTED"] = "Non collecté",
    ["LOCKED_OUT"] = "Verrouillé",
    ["NO_LOCKOUT"] = "Aucun verrouillage",
    ["AVAILABLE_NOW"] = "Disponible maintenant",
    ["NEXT_ATTEMPT"] = "Prochaine tentative",
    ["LOCKOUT"] = "Verrouillage",
    ["UNKNOWN"] = "Inconnu",
    
    -- Column Headers
    ["MOUNT_NAME"] = "Nom de la monture",
    ["RAID_SOURCE"] = "Raid/Source",
    ["BOSS"] = "Boss",
    ["DROP_RATE"] = "Taux de drop",
    ["EXPANSION"] = "Extension",
    ["ATTEMPTS"] = "Tentatives",
    ["LOCKOUT_STATUS"] = "Verrouillage",
    ["COORDINATES"] = "Carte",
    
    -- Filter Options
    ["ALL"] = "Tous",
    ["COLLECTED"] = "Collecté",
    ["UNCOLLECTED"] = "Non collecté",
    ["RAID"] = "Raid",
    ["DUNGEON"] = "Donjon",
    ["NORMAL"] = "Normal",
    ["HEROIC"] = "Héroïque",
    ["MYTHIC"] = "Mythique",
    
    -- Info Panel
    ["ATTEMPT_TRACKING"] = "SUIVI DES TENTATIVES",
    ["STATUS_LOCKOUT"] = "STATUT & VERROUILLAGE",
    ["DESCRIPTION"] = "DESCRIPTION",
    ["TOTAL_ATTEMPTS"] = "Total des tentatives",
    ["MORE_CHARACTERS"] = " autres personnages",
    ["COLLECTORS_BOUNTY"] = "Prime du collectionneur :",
    ["COLLECTORS_BOUNTY_BONUS"] = "+5% de chance de drop",
    ["COLLECTED_ON"] = "Collecté :",
    ["NO_DESCRIPTION"] = "Aucune description disponible.",
    ["RAID"] = "Raid",
    ["BOSS"] = "Boss",
    ["ZONE"] = "Zone",
    
    -- Slash Commands
    ["HELP_TITLE"] = "Commandes disponibles :",
    ["HELP_OPEN"] = "/rm - Ouvrir/fermer l'interface principale",
    ["HELP_HELP"] = "/rm help - Afficher ce message d'aide",
    ["HELP_STATS"] = "/rm stats - Afficher la vue des statistiques",
    ["HELP_RESET"] = "/rm reset - Réinitialiser toutes les données de tentatives (avec confirmation)",
    ["HELP_REFRESH"] = "/rm refresh - Actualiser les données de collection de montures",
    ["HELP_VERIFY"] = "/rm verify - Vérifier les compteurs de tentatives contre les statistiques Blizzard",
    ["UNKNOWN_COMMAND"] = "Commande inconnue : %s. Utilisez |cFFFFFF00/rm help|r pour les commandes disponibles.",
    ["RESET_CONFIRMATION"] = "Êtes-vous sûr de vouloir réinitialiser TOUTES les données de tentatives ? Cela ne peut pas être annulé !",
    ["RESET_CONFIRM_AGAIN"] = "Tapez |cFFFFFF00/rm reset|r à nouveau dans les 10 secondes pour confirmer.",
    ["RESET_COMPLETE"] = "Toutes les données de tentatives ont été réinitialisées.",
    ["REFRESH_SCANNING"] = "Analyse de votre collection de montures...",
    ["REFRESH_COMPLETE"] = "Collection de montures actualisée.",
    ["VERIFY_COMPLETE"] = "Vérification des tentatives terminée.",
    
    -- Statistics
    ["DETAILED_STATS"] = "Statistiques détaillées de la collection de montures",
    ["OVERALL_STATS"] = "Statistiques globales",
    ["BY_EXPANSION"] = "Par extension",
    ["MOST_ATTEMPTED"] = "Montures les plus tentées",
    ["ATTEMPTS_TEXT"] = "tentatives",
    
    -- Tooltips
    ["SEARCH_HELP"] = "Aide de recherche",
    ["SEARCH_HELP_LINE1"] = "• Tapez un mot pour rechercher des noms de montures, raids, boss",
    ["SEARCH_HELP_LINE2"] = "• Utilisez des guillemets pour des phrases exactes : \"Onyxian Drake\"",
    ["SEARCH_HELP_LINE3"] = "• Plusieurs mots recherchent tous les termes : ice crown",
    ["SEARCH_HELP_LINE4"] = "• Appuyez sur Entrée pour rechercher immédiatement",
    ["SEARCH_HELP_LINE5"] = "• Appuyez sur Échap pour effacer la recherche",
    ["CLEAR_FILTERS_TIP"] = "Effacer tous les filtres",
    ["PROGRESS_TOOLTIP"] = "Progrès de la collection de montures",
    ["PROGRESS_FORMAT"] = "Collecté : |cFF00FF00%d|r / |cFFFFFFFF%d|r (|cFFFFFF00%.1f%%|r)",
    
    -- Messages
    ["LOADED_MESSAGE"] = "v%s chargé ! Utilisez |cFFFFFF00/rm|r pour ouvrir le suivi de montures.",
    ["SCANNING_FIRST_TIME"] = "Analyse de votre collection de montures pour la première fois...",
    ["STATS_VIEW_DISPLAYED"] = "Vue des statistiques affichée.",
    ["STATS_VIEW_UNAVAILABLE"] = "Vue des statistiques non disponible.",
    ["ACTIVE_FILTERS"] = "Filtres actifs : %s",
    ["NO_FILTERS_ACTIVE"] = "Aucun filtre actif - affichage de toutes les montures",
    ["NO_MOUNTS_FOUND"] = "Aucune monture trouvée correspondant à vos critères.",
    
    -- Errors
    ["ERROR_HEADERS_NOT_INIT"] = "RaidMount : Avertissement - HeaderTexts non initialisé",
    ["ERROR_HEADER_DATA_MISSING"] = "RaidMount : Avertissement - Données d'en-tête manquantes pour l'index %d",
    ["ERROR_RAIDMOUNT_NIL"] = "RaidMount : Erreur - Table RaidMount est nil. Assurez-vous que RaidMount.lua est chargé avant RaidMountUI.lua.",
}

-- If current locale is French, use French locale
if currentLocale == "frFR" then
    RaidMount.LOCALE = frFRLocale
end 