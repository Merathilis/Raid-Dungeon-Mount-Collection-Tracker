-- Traditional Chinese localization for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Get current locale
local currentLocale = GetLocale()

-- Traditional Chinese locale table
local zhTWLocale = {
    -- UI Elements
    ["STATS"] = "統計",
    ["SEARCH"] = "搜索",
    ["SEARCH_PLACEHOLDER"] = "搜索坐騎、團隊副本或首領...",
    ["CLEAR_ALL"] = "清除全部",
    ["CLOSE"] = "關閉",
    ["SELECT_ALL"] = "全選",
    ["BACK"] = "返回",
    ["FILTERS"] = "過濾器",
    ["ENHANCED_TOOLTIPS"] = "增強提示",
    ["VERSION"] = "版本",
    
    -- Status Messages
    ["COLLECTED"] = "已收集",
    ["NOT_COLLECTED"] = "未收集",
    ["LOCKED_OUT"] = "已鎖定",
    ["NO_LOCKOUT"] = "無鎖定",
    ["AVAILABLE_NOW"] = "現在可用",
    ["NEXT_ATTEMPT"] = "下次嘗試",
    ["LOCKOUT"] = "鎖定",
    ["UNKNOWN"] = "未知",
    
    -- Column Headers
    ["MOUNT_NAME"] = "坐騎名稱",
    ["RAID_SOURCE"] = "團隊副本/來源",
    ["BOSS"] = "首領",
    ["DROP_RATE"] = "掉落率",
    ["EXPANSION"] = "資料片",
    ["ATTEMPTS"] = "嘗試次數",
    ["LOCKOUT_STATUS"] = "鎖定狀態",
    ["COORDINATES"] = "地圖",
    
    -- Filter Options
    ["ALL"] = "全部",
    ["COLLECTED"] = "已收集",
    ["UNCOLLECTED"] = "未收集",
    ["RAID"] = "團隊副本",
    ["DUNGEON"] = "地下城",
    ["NORMAL"] = "普通",
    ["HEROIC"] = "英雄",
    ["MYTHIC"] = "史詩",
    
    -- Info Panel
    ["ATTEMPT_TRACKING"] = "嘗試追蹤",
    ["STATUS_LOCKOUT"] = "狀態與鎖定",
    ["DESCRIPTION"] = "描述",
    ["TOTAL_ATTEMPTS"] = "總嘗試次數",
    ["MORE_CHARACTERS"] = " 個更多角色",
    ["COLLECTORS_BOUNTY"] = "收藏家獎勵：",
    ["COLLECTORS_BOUNTY_BONUS"] = "+5%掉落幾率",
    ["COLLECTED_ON"] = "收集於：",
    ["NO_DESCRIPTION"] = "暫無描述。",
    ["RAID"] = "團隊副本",
    ["BOSS"] = "首領",
    ["ZONE"] = "區域",
    
    -- Slash Commands
    ["HELP_TITLE"] = "可用命令：",
    ["HELP_OPEN"] = "/rm - 打開/關閉主界面",
    ["HELP_HELP"] = "/rm help - 顯示此幫助訊息",
    ["HELP_STATS"] = "/rm stats - 顯示統計視圖",
    ["HELP_RESET"] = "/rm reset - 重置所有嘗試數據（需確認）",
    ["HELP_REFRESH"] = "/rm refresh - 刷新坐騎收集數據",
    ["HELP_VERIFY"] = "/rm verify - 驗證嘗試次數與暴雪統計數據",
    ["UNKNOWN_COMMAND"] = "未知命令：%s。使用 |cFFFFFF00/rm help|r 查看可用命令。",
    ["RESET_CONFIRMATION"] = "確定要重置所有嘗試數據嗎？此操作無法撤銷！",
    ["RESET_CONFIRM_AGAIN"] = "在10秒內再次輸入 |cFFFFFF00/rm reset|r 確認。",
    ["RESET_COMPLETE"] = "所有嘗試數據已重置。",
    ["REFRESH_SCANNING"] = "正在掃描您的坐騎收集...",
    ["REFRESH_COMPLETE"] = "坐騎收集已刷新。",
    ["VERIFY_COMPLETE"] = "嘗試驗證完成。",
    
    -- Statistics
    ["DETAILED_STATS"] = "詳細坐騎收集統計",
    ["OVERALL_STATS"] = "總體統計",
    ["BY_EXPANSION"] = "按資料片",
    ["MOST_ATTEMPTED"] = "嘗試最多的坐騎",
    ["ATTEMPTS_TEXT"] = "次嘗試",
    
    -- Tooltips
    ["SEARCH_HELP"] = "搜索幫助",
    ["SEARCH_HELP_LINE1"] = "• 輸入任何單詞搜索坐騎名稱、團隊副本、首領",
    ["SEARCH_HELP_LINE2"] = "• 使用引號進行精確短語搜索：\"Onyxian Drake\"",
    ["SEARCH_HELP_LINE3"] = "• 多個單詞搜索所有術語：ice crown",
    ["SEARCH_HELP_LINE4"] = "• 按Enter立即搜索",
    ["SEARCH_HELP_LINE5"] = "• 按Escape清除搜索",
    ["CLEAR_FILTERS_TIP"] = "清除所有過濾器",
    ["PROGRESS_TOOLTIP"] = "坐騎收集進度",
    ["PROGRESS_FORMAT"] = "已收集：|cFF00FF00%d|r / |cFFFFFFFF%d|r (|cFFFFFF00%.1f%%|r)",
    
    -- Messages
    ["LOADED_MESSAGE"] = "v%s 已加載！使用 |cFFFFFF00/rm|r 打開坐騎追蹤器。",
    ["SCANNING_FIRST_TIME"] = "首次掃描您的坐騎收集...",
    ["STATS_VIEW_DISPLAYED"] = "統計視圖已顯示。",
    ["STATS_VIEW_UNAVAILABLE"] = "統計視圖不可用。",
    ["ACTIVE_FILTERS"] = "活動過濾器：%s",
    ["NO_FILTERS_ACTIVE"] = "無活動過濾器 - 顯示所有坐騎",
    ["NO_MOUNTS_FOUND"] = "未找到符合您條件的坐騎。",
    ["NEW_MOUNT_COLLECTED"] = "獲得新坐騎！坐騎ID：%d",
    ["DIFFICULTY_SET"] = "%s設定為%s",
    ["TOMTOM_WAYPOINT_SET"] = "TomTom路徑點已為%s設定",
    ["COULD_NOT_FIND_MAP_ID"] = "找不到區域的地圖ID：%s",
    ["WAYPOINT_SET"] = "為%s在%s（%.1f，%.1f）設定路徑點",
    ["MOUNT_LOCATION"] = "%s位置：%s（%s）- %.1f，%.1f",
    ["INSTALL_TOMTOM"] = "安裝TomTom插件以獲得更好的跨資料片路徑點支援",
    ["TRAVEL_GUIDE"] = "RaidMount旅行指南：%s",
    ["CROSS_EXPANSION_TRAVEL"] = "跨資料片旅行：%s -> %s（%s）",
    ["TRAVEL_NEEDED"] = "需要旅行：%s -> %s（%s）",
    ["INSTANCE_EXPANSION_INFO"] = "副本：%s | 資料片：%s",
    
    -- Errors
    ["ERROR_HEADERS_NOT_INIT"] = "RaidMount：警告 - HeaderTexts未初始化",
    ["ERROR_HEADER_DATA_MISSING"] = "RaidMount：警告 - 索引%d的標題數據缺失",
    ["ERROR_RAIDMOUNT_NIL"] = "RaidMount：錯誤 - RaidMount表為nil。確保RaidMount.lua在RaidMountUI.lua之前加載。",
}

-- If current locale is Traditional Chinese, use Traditional Chinese locale
if currentLocale == "zhTW" then
    RaidMount.LOCALE = zhTWLocale
end 
