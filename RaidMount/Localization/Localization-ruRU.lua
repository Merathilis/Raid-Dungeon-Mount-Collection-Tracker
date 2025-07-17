-- Russian localization for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Get current locale
local currentLocale = GetLocale()

-- Russian locale table
local ruRULocale = {
	-- UI Elements
	["STATS"] = "Статистика",
	["SEARCH"] = "Поиск",
	["SEARCH_PLACEHOLDER"] = "Поиск маунтов, рейдов или боссов...",
	["CLEAR_ALL"] = "Очистить все",
	["CLOSE"] = "Закрыть",
	["SELECT_ALL"] = "Выбрать все",
	["BACK"] = "Назад",
	["FILTERS"] = "Фильтры",
	["ENHANCED_TOOLTIPS"] = "Улучшенные подсказки",
	["VERSION"] = "Версия",

	-- Status Messages
	["COLLECTED"] = "Получен",
	["NOT_COLLECTED"] = "Не получен",
	["LOCKED_OUT"] = "Заблокирован",
	["NO_LOCKOUT"] = "Нет блокировки",
	["AVAILABLE_NOW"] = "Доступен сейчас",
	["NEXT_ATTEMPT"] = "Следующая попытка",
	["LOCKOUT"] = "Блокировка",
	["UNKNOWN"] = "Неизвестно",

	-- Column Headers
	["MOUNT_NAME"] = "Название маунта",
	["RAID_SOURCE"] = "Рейд/Источник",
	["BOSS"] = "Босс",
	["DROP_RATE"] = "Шанс выпадения",
	["EXPANSION"] = "Дополнение",
	["ATTEMPTS"] = "Попытки",
	["LOCKOUT_STATUS"] = "Блокировка",
	["COORDINATES"] = "Карта",

	-- Filter Options
	["ALL"] = "Все",
	["COLLECTED"] = "Получен",
	["UNCOLLECTED"] = "Не получен",
	["RAID"] = "Рейд",
	["DUNGEON"] = "Подземелье",
	["NORMAL"] = "Обычный",
	["HEROIC"] = "Героический",
	["MYTHIC"] = "Эпохальный",

	-- Info Panel
	["ATTEMPT_TRACKING"] = "ОТСЛЕЖИВАНИЕ ПОПЫТОК",
	["STATUS_LOCKOUT"] = "СТАТУС & БЛОКИРОВКА",
	["DESCRIPTION"] = "ОПИСАНИЕ",
	["TOTAL_ATTEMPTS"] = "Всего попыток",
	["MORE_CHARACTERS"] = " персонажей еще",
	["COLLECTORS_BOUNTY"] = "Награда коллекционера:",
	["COLLECTORS_BOUNTY_BONUS"] = "+5% шанс выпадения",
	["COLLECTED_ON"] = "Получен:",
	["NO_DESCRIPTION"] = "Описание недоступно.",
	["RAID"] = "Рейд",
	["BOSS"] = "Босс",
	["ZONE"] = "Зона",

	-- Slash Commands
	["HELP_TITLE"] = "Доступные команды:",
	["HELP_OPEN"] = "/rm - Открыть/закрыть основной интерфейс",
	["HELP_HELP"] = "/rm help - Показать это сообщение помощи",
	["HELP_STATS"] = "/rm stats - Показать вид статистики",
	["HELP_RESET"] = "/rm reset - Сбросить все данные попыток (с подтверждением)",
	["HELP_REFRESH"] = "/rm refresh - Обновить данные коллекции маунтов",
	["HELP_VERIFY"] = "/rm verify - Проверить счетчики попыток против статистики Blizzard",
	["UNKNOWN_COMMAND"] = "Неизвестная команда: %s. Используйте |cFFFFFF00/rm help|r для доступных команд.",
	["RESET_CONFIRMATION"] = "Вы уверены, что хотите сбросить ВСЕ данные попыток? Это нельзя отменить!",
	["RESET_CONFIRM_AGAIN"] = "Введите |cFFFFFF00/rm reset|r снова в течение 10 секунд для подтверждения.",
	["RESET_COMPLETE"] = "Все данные попыток были сброшены.",
	["REFRESH_SCANNING"] = "Сканирование вашей коллекции маунтов...",
	["REFRESH_COMPLETE"] = "Коллекция маунтов обновлена.",
	["VERIFY_COMPLETE"] = "Проверка попыток завершена.",

	-- Statistics
	["DETAILED_STATS"] = "Подробная статистика коллекции маунтов",
	["OVERALL_STATS"] = "Общая статистика",
	["BY_EXPANSION"] = "По дополнениям",
	["MOST_ATTEMPTED"] = "Самые попытки маунтов",
	["ATTEMPTS_TEXT"] = "попыток",

	-- Tooltips
	["SEARCH_HELP"] = "Помощь по поиску",
	["SEARCH_HELP_LINE1"] = "• Введите любое слово для поиска имен маунтов, рейдов, боссов",
	["SEARCH_HELP_LINE2"] = "• Используйте кавычки для точных фраз: \"Onyxian Drake\"",
	["SEARCH_HELP_LINE3"] = "• Несколько слов ищут все термины: ice crown",
	["SEARCH_HELP_LINE4"] = "• Нажмите Enter для немедленного поиска",
	["SEARCH_HELP_LINE5"] = "• Нажмите Escape для очистки поиска",
	["CLEAR_FILTERS_TIP"] = "Очистить все фильтры",
	["PROGRESS_TOOLTIP"] = "Прогресс коллекции маунтов",
	["PROGRESS_FORMAT"] = "Получено: |cFF00FF00%d|r / |cFFFFFFFF%d|r (|cFFFFFF00%.1f%%|r)",

	-- Messages
	["LOADED_MESSAGE"] = "v%s загружен! Используйте |cFFFFFF00/rm|r для открытия трекера маунтов.",
	["SCANNING_FIRST_TIME"] = "Сканирование вашей коллекции маунтов впервые...",
	["STATS_VIEW_DISPLAYED"] = "Вид статистики отображается.",
	["STATS_VIEW_UNAVAILABLE"] = "Вид статистики недоступен.",
	["ACTIVE_FILTERS"] = "Активные фильтры: %s",
	["NO_FILTERS_ACTIVE"] = "Нет активных фильтров - показывать все маунты",
	["NO_MOUNTS_FOUND"] = "Маунты, соответствующие вашим критериям, не найдены.",

	-- Errors
	["ERROR_HEADERS_NOT_INIT"] = "RaidMount: Предупреждение - HeaderTexts не инициализирован",
	["ERROR_HEADER_DATA_MISSING"] = "RaidMount: Предупреждение - Данные заголовка отсутствуют для индекса %d",
	["ERROR_RAIDMOUNT_NIL"] = "RaidMount: Ошибка - Таблица RaidMount равна nil. Убедитесь, что RaidMount.lua загружен перед RaidMountUI.lua.",
}

-- If current locale is Russian, use Russian locale
if currentLocale == "ruRU" then
	RaidMount.LOCALE = ruRULocale
end
