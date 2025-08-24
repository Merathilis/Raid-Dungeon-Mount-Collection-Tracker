local addonName, RaidMount = ...

-- Slash command handler
SLASH_RAIDMOUNT1 = "/rm"

SlashCmdList["RAIDMOUNT"] = function(msg)
    -- Ensure initialization when user interacts with addon
    RaidMount.EnsureInitialized()

    local command = msg:lower():trim()

    if command == "" then
        RaidMount.ShowUI()
    elseif command == "help" then
        RaidMount.ShowHelpCommands()
    elseif command == "stats" then
        RaidMount.ShowStatsCommand()
    elseif command == "reset" then
        RaidMount.ResetCommand()
    elseif command == "refresh" then
        RaidMount.RefreshCommand()
    elseif command == "verify" then
        RaidMount.VerifyCommand()
    elseif command == "refreshchars" then
        if RaidMount.PopulateCharacterMountData then
            RaidMount.PopulateCharacterMountData()
            RaidMount.PrintAddonMessage("Refreshed character mount data from statistics", false)
        else
            RaidMount.PrintAddonMessage("Character data refresh function not available", true)
        end
    elseif command == "refreshlockouts" then
        if RaidMount.EnhancedLockout and RaidMount.EnhancedLockout.RefreshLockouts then
            RaidMount.EnhancedLockout:RefreshLockouts()
            RaidMount.PrintAddonMessage("Forced lockout refresh completed", false)
        else
            RaidMount.PrintAddonMessage("Lockout refresh function not available", true)
        end
    elseif command == "refreshraidinfo" then
        if RaidMount.EnhancedLockout and RaidMount.EnhancedLockout.GetEnhancedLockoutData then
            local enhancedData = RaidMount.EnhancedLockout:GetEnhancedLockoutData()
            RaidMount.PrintAddonMessage("Enhanced lockout data refresh completed. Found " .. #enhancedData .. " raids", false)
        else
            RaidMount.PrintAddonMessage("Enhanced lockout data function not available", true)
        end

    elseif command == "characters" or command == "chars" then
        if RaidMount.UpdateCharacterChecker then
            RaidMount.UpdateCharacterChecker()
        else
            RaidMount.PrintAddonMessage("Character checker not available", true)
        end
    
    elseif command == "clearcache" then
        if RaidMount.ClearTooltipCache then
            RaidMount.ClearTooltipCache()
            RaidMount.PrintAddonMessage("Cleared tooltip cache", false)
        else
            RaidMount.PrintAddonMessage("Tooltip cache function not available", true)
        end
    elseif command == "version" then
        print("|cFF33CCFFRaid|r|cFFFF0000Mount|r v" .. RaidMount.ADDON_VERSION)
    elseif command == "sound" then
        if not RaidMountSettings then RaidMountSettings = {} end
        RaidMountSettings.mountDropSound = not RaidMountSettings.mountDropSound
        local status = RaidMountSettings.mountDropSound and "enabled" or "disabled"
        RaidMount.PrintAddonMessage("Mount drop sound " .. status, false)
    elseif command == "testdropdowns" then
        if RaidMount.TestDropdowns then
            RaidMount.TestDropdowns()
        else
            RaidMount.PrintAddonMessage("Dropdown test function not available", true)
        end
    elseif command == "icecrown" or command == "icc" then
        if RaidMount.CheckIcecrownLockout then
            RaidMount.CheckIcecrownLockout()
        else
            RaidMount.PrintAddonMessage("Icecrown lockout check function not available", true)
        end
    elseif command == "cleanup" then
        if RaidMount.CleanupDuplicateCharacters then
            RaidMount.CleanupDuplicateCharacters()
        end
        if RaidMount.CleanupDuplicateCharacterNames then
            RaidMount.CleanupDuplicateCharacterNames()
        end
        RaidMount.PrintAddonMessage("Character cleanup completed", false)
    else
        RaidMount.PrintAddonMessage(RaidMount.L("UNKNOWN_COMMAND", command), true)
    end
end

-- Show help commands
function RaidMount.ShowHelpCommands()
    RaidMount.PrintAddonMessage(RaidMount.L("HELP_TITLE"), false)
    print("|cFFFFFF00/rm|r - " .. RaidMount.L("HELP_OPEN"))
    print("|cFFFFFF00/rm help|r - " .. RaidMount.L("HELP_HELP"))
    print("|cFFFFFF00/rm stats|r - " .. RaidMount.L("HELP_STATS"))
    print("|cFFFFFF00/rm reset|r - " .. RaidMount.L("HELP_RESET"))
    print("|cFFFFFF00/rm refresh|r - " .. RaidMount.L("HELP_REFRESH"))
    print("|cFFFFFF00/rm verify|r - " .. RaidMount.L("HELP_VERIFY"))
    print("|cFFFFFF00/rm refreshchars|r - Refresh character mount data from Blizzard statistics")
    print("|cFFFFFF00/rm characters|r - Show character mount data status")
    print("|cFFFFFF00/rm refreshlockouts|r - Force refresh lockout data")
    print("|cFFFFFF00/rm refreshraidinfo|r - Force refresh raid info data")
    print("|cFFFFFF00/rm debug|r - Debug lockout detection issues")
    print("|cFFFFFF00/rm lockout <instance> [difficulty]|r - Check lockout status for any instance")
    print("|cFFFFFF00/rm icecrown|r - Check Icecrown Citadel 25H lockout status")
    print("|cFFFFFF00/rm cleanup|r - Clean up duplicate character entries")
    
    print("|cFFFFFF00/rm sound|r - Toggle mount drop sound notifications")
    print("|cFFFFFF00/rm testdropdowns|r - Test dropdown functionality")
end

-- Show stats command
function RaidMount.ShowStatsCommand()
    if not RaidMount.RaidMountFrame then
        RaidMount.CreateMainFrame()
    end

    RaidMount.RaidMountFrame:Show()
    RaidMount.isStatsView = true

    if RaidMount.ShowDetailedStatsView then
        RaidMount.ShowDetailedStatsView()
        RaidMount.PrintAddonMessage("Statistics view displayed.", false)
    else
        RaidMount.PrintAddonMessage("Statistics view not available.", true)
    end
end

-- Reset command with confirmation
function RaidMount.ResetCommand()
    if not RaidMount.resetConfirmationPending then
        RaidMount.resetConfirmationPending = true
        RaidMount.PrintAddonMessage(RaidMount.L("RESET_CONFIRMATION"), true)
        RaidMount.PrintAddonMessage(RaidMount.L("RESET_CONFIRM_AGAIN"), false)

        C_Timer.After(10, function()
            RaidMount.resetConfirmationPending = false
        end)
    else
        RaidMount.resetConfirmationPending = false
        RaidMount.ResetAttempts()
        RaidMount.PrintAddonMessage(RaidMount.L("RESET_COMPLETE"), false)

        -- Refresh UI if open
        if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
            if RaidMount.isStatsView then
                RaidMount.ShowDetailedStatsView()
            else
                RaidMount.PopulateUI()
            end
        end
    end
end

-- Refresh command
function RaidMount.RefreshCommand()
    print("|cFF33CCFFRaid|r|cFFFF0000Mount|r: Starting mount collection refresh...")

    if RaidMount.RefreshMountCollection then
        RaidMount.RefreshMountCollection()
        print("|cFF33CCFFRaid|r|cFFFF0000Mount|r: " .. RaidMount.L("REFRESH_COMPLETE"))

        -- Refresh UI if open
        if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
            if RaidMount.isStatsView then
                RaidMount.ShowDetailedStatsView()
            else
                RaidMount.PopulateUI()
            end
        end
    else
        print("|cFF33CCFFRaid|r|cFFFF0000Mount|r: Refresh function not available.")
    end
end

-- Verify command
function RaidMount.VerifyCommand()
    if RaidMount.VerifyStatistics then
        print("|cFF33CCFFRaid|r|cFFFF0000Mount|r: Starting verification against Blizzard statistics...")

        local results = RaidMount.VerifyStatistics()

        if results.verified == 0 then
            print("|cFF33CCFFRaid|r|cFFFF0000Mount|r: No mounts with Blizzard statistics found to verify.")
        else
            print(string.format("|cFF33CCFFRaid|r|cFFFF0000Mount|r: Verified %d mounts against Blizzard statistics.",
                results.verified))

            if results.corrected > 0 then
                print(string.format(
                    "|cFF33CCFFRaid|r|cFFFF0000Mount|r: Updated %d mount(s) with higher attempt counts from Blizzard data:",
                    results.corrected))
                for _, correction in ipairs(results.corrections) do
                    print(string.format("  |cFF00FF00%s|r: |cFFFF0000%d|r → |cFF00FF00%d|r attempts (Stat ID: %s)",
                        correction.mountName,
                        correction.oldTotal,
                        correction.newTotal,
                        correction.statId or "Unknown"))
                end
            else
                print("|cFF33CCFFRaid|r|cFFFF0000Mount|r: All mount attempt counts match Blizzard statistics.")
            end
        end

        -- Refresh UI if open
        if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
            if RaidMount.isStatsView then
                RaidMount.ShowDetailedStatsView()
            else
                RaidMount.PopulateUI()
            end
        end
    else
        RaidMount.PrintAddonMessage(RaidMount.L("VERIFY_COMPLETE"), false)
    end
end

 