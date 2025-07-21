-- Chinese Simplified localization for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Get current locale
local currentLocale = GetLocale()

-- Chinese Simplified locale table
local zhCNLocale = {
    -- UI Elements
    ["STATS"] = "统计",
    ["SEARCH"] = "搜索",
    ["SEARCH_PLACEHOLDER"] = "搜索坐骑、团队副本或首领...",
    ["CLEAR_ALL"] = "清除全部",
    ["CLOSE"] = "关闭",
    ["SELECT_ALL"] = "全选",
    ["BACK"] = "返回",
    ["FILTERS"] = "过滤器",
    ["ENHANCED_TOOLTIPS"] = "增强提示",
    ["VERSION"] = "版本",
    
    -- Status Messages
    ["COLLECTED"] = "已收集",
    ["NOT_COLLECTED"] = "未收集",
    ["LOCKED_OUT"] = "已锁定",
    ["NO_LOCKOUT"] = "无锁定",
    ["AVAILABLE_NOW"] = "现在可用",
    ["NEXT_ATTEMPT"] = "下次尝试",
    ["LOCKOUT"] = "锁定",
    ["UNKNOWN"] = "未知",
    
    -- Column Headers
    ["MOUNT_NAME"] = "坐骑名称",
    ["RAID_SOURCE"] = "团队副本/来源",
    ["BOSS"] = "首领",
    ["DROP_RATE"] = "掉落率",
    ["EXPANSION"] = "资料片",
    ["ATTEMPTS"] = "尝试次数",
    ["LOCKOUT_STATUS"] = "锁定状态",
    ["COORDINATES"] = "地图",
    
    -- Filter Options
    ["ALL"] = "全部",
    ["COLLECTED"] = "已收集",
    ["UNCOLLECTED"] = "未收集",
    ["RAID"] = "团队副本",
    ["DUNGEON"] = "地下城",
    ["NORMAL"] = "普通",
    ["HEROIC"] = "英雄",
    ["MYTHIC"] = "史诗",
    
    -- Info Panel
    ["ATTEMPT_TRACKING"] = "尝试追踪",
    ["STATUS_LOCKOUT"] = "状态与锁定",
    ["DESCRIPTION"] = "描述",
    ["TOTAL_ATTEMPTS"] = "总尝试次数",
    ["MORE_CHARACTERS"] = " 个更多角色",
    ["COLLECTORS_BOUNTY"] = "收藏家奖励：",
    ["COLLECTORS_BOUNTY_BONUS"] = "+5%掉落几率",
    ["COLLECTED_ON"] = "收集于：",
    ["NO_DESCRIPTION"] = "暂无描述。",
    ["RAID"] = "团队副本",
    ["BOSS"] = "首领",
    ["ZONE"] = "区域",
    
    -- Slash Commands
    ["HELP_TITLE"] = "可用命令：",
    ["HELP_OPEN"] = "/rm - 打开/关闭主界面",
    ["HELP_HELP"] = "/rm help - 显示此帮助信息",
    ["HELP_STATS"] = "/rm stats - 显示统计视图",
    ["HELP_RESET"] = "/rm reset - 重置所有尝试数据（需确认）",
    ["HELP_REFRESH"] = "/rm refresh - 刷新坐骑收集数据",
    ["HELP_VERIFY"] = "/rm verify - 验证尝试次数与暴雪统计数据",
    ["UNKNOWN_COMMAND"] = "未知命令：%s。使用 |cFFFFFF00/rm help|r 查看可用命令。",
    ["RESET_CONFIRMATION"] = "确定要重置所有尝试数据吗？此操作无法撤销！",
    ["RESET_CONFIRM_AGAIN"] = "在10秒内再次输入 |cFFFFFF00/rm reset|r 确认。",
    ["RESET_COMPLETE"] = "所有尝试数据已重置。",
    ["REFRESH_SCANNING"] = "正在扫描您的坐骑收集...",
    ["REFRESH_COMPLETE"] = "坐骑收集已刷新。",
    ["VERIFY_COMPLETE"] = "尝试验证完成。",
    
    -- Statistics
    ["DETAILED_STATS"] = "详细坐骑收集统计",
    ["OVERALL_STATS"] = "总体统计",
    ["BY_EXPANSION"] = "按资料片",
    ["MOST_ATTEMPTED"] = "尝试最多的坐骑",
    ["ATTEMPTS_TEXT"] = "次尝试",
    
    -- Tooltips
    ["SEARCH_HELP"] = "搜索帮助",
    ["SEARCH_HELP_LINE1"] = "• 输入任何单词搜索坐骑名称、团队副本、首领",
    ["SEARCH_HELP_LINE2"] = "• 使用引号进行精确短语搜索：\"Onyxian Drake\"",
    ["SEARCH_HELP_LINE3"] = "• 多个单词搜索所有术语：ice crown",
    ["SEARCH_HELP_LINE4"] = "• 按Enter立即搜索",
    ["SEARCH_HELP_LINE5"] = "• 按Escape清除搜索",
    ["CLEAR_FILTERS_TIP"] = "清除所有过滤器",
    ["PROGRESS_TOOLTIP"] = "坐骑收集进度",
    ["PROGRESS_FORMAT"] = "已收集：|cFF00FF00%d|r / |cFFFFFFFF%d|r (|cFFFFFF00%.1f%%|r)",
    
    -- Messages
    ["LOADED_MESSAGE"] = "v%s 已加载！使用 |cFFFFFF00/rm|r 打开坐骑追踪器。",
    ["SCANNING_FIRST_TIME"] = "首次扫描您的坐骑收集...",
    ["STATS_VIEW_DISPLAYED"] = "统计视图已显示。",
    ["STATS_VIEW_UNAVAILABLE"] = "统计视图不可用。",
    ["ACTIVE_FILTERS"] = "活动过滤器：%s",
    ["NO_FILTERS_ACTIVE"] = "无活动过滤器 - 显示所有坐骑",
    ["NO_MOUNTS_FOUND"] = "未找到符合您条件的坐骑。",
    ["NEW_MOUNT_COLLECTED"] = "获得新坐骑！坐骑ID：%d",
    ["DIFFICULTY_SET"] = "%s设置为%s",
    ["TOMTOM_WAYPOINT_SET"] = "TomTom路径点已为%s设置",
    ["COULD_NOT_FIND_MAP_ID"] = "找不到区域的地图ID：%s",
    ["WAYPOINT_SET"] = "为%s在%s（%.1f，%.1f）设置路径点",
    ["MOUNT_LOCATION"] = "%s位置：%s（%s）- %.1f，%.1f",
    ["INSTALL_TOMTOM"] = "安装TomTom插件以获得更好的跨资料片路径点支持",
    ["TRAVEL_GUIDE"] = "RaidMount旅行指南：%s",
    ["CROSS_EXPANSION_TRAVEL"] = "跨资料片旅行：%s -> %s（%s）",
    ["TRAVEL_NEEDED"] = "需要旅行：%s -> %s（%s）",
    ["INSTANCE_EXPANSION_INFO"] = "副本：%s | 资料片：%s",
    
    -- Errors
    ["ERROR_HEADERS_NOT_INIT"] = "RaidMount：警告 - HeaderTexts未初始化",
    ["ERROR_HEADER_DATA_MISSING"] = "RaidMount：警告 - 索引%d的标题数据缺失",
    ["ERROR_RAIDMOUNT_NIL"] = "RaidMount：错误 - RaidMount表为nil。确保RaidMount.lua在RaidMountUI.lua之前加载。",
}

-- If current locale is Chinese Simplified, use Chinese Simplified locale
if currentLocale == "zhCN" then
    RaidMount.LOCALE = zhCNLocale
end 