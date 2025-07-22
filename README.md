# RaidMount - Comprehensive WoW Mount Tracking Addon

**RaidMount** is a powerful World of Warcraft addon that helps you track and manage your rare mount collection across all characters. From Classic to The War Within, RaidMount automatically logs mount attempts, displays real-time stats, and provides a clean, high-performance UI.

## Features

### Core Functionality
- **Automatic Attempt Tracking** – Logs attempts when you kill bosses with mount drops
- **Cross-Character Sync** – Tracks attempts across all your characters with realm and class data
- **Real-Time Collection Detection** – Automatically updates when you collect a mount
- **Blizzard Statistics Verification** – Syncs with official stats for accuracy
- **Session Management** – Tracks current session attempts with timeout handling

### User Interface
- **Professional Dark Theme** – Clean, performance-optimized design
- **8-Column Table View** – Mount name, raid, boss, drop rate, expansion, attempts, collection status, instance info
- **Advanced Filtering & Sorting** – Multi-select filters by expansion, type, difficulty, and collection status
- **Instant Search** – Live search with 0.02s debouncing for performance
- **Grid-Based Icon View** – Visual icon-based display with waypoint integration
- **Progress Bars** – Visual indicators of collection progress

### Interactive Features
- **Clickable Difficulty Buttons** – Shows lockout status and allows instant difficulty changes
- **Visual Status Indicators** – Button colors indicate lockouts (green = available, red = locked)
- **Smart Lockout Handling** – Combines 10/25 modes and supports all difficulty types

### Character Tracker
- **Per-Character Tracking** – Tracks individual attempts and last-seen dates
- **Class Color Coding** – Displays character names in their class colors
- **Data Verification** – Uses Blizzard achievement stats for backup and syncing
- **Realm Support** – Handles cross-realm characters properly

### Statistics & Analytics
- **Total Mounts Collected / Missing**
- **Attempts Overview** – Sortable by attempts, drop rate, or source
- **Expansion & Content Type Analysis** – Breakdowns by raid, dungeon, world boss, and event
- **Most Attempted Mounts** – Highlights unlucky streaks
- **Per-Character Attempt Rankings**

### Waypoint & Map Integration
- **TomTom Support** – Set waypoints directly from the interface
- **Built-in Map Integration** – Uses WoW's native waypoints if TomTom isn't installed

### Notifications
- **Zone-Based Popups** – Alerts for mounts available in current zone
- **Sound Alerts** – Optional drop sounds for new mounts
- **Draggable Windows** – UI elements can be repositioned freely

## Slash Commands

| Command             | Description                                 |
|---------------------|---------------------------------------------|
| `/rm`               | Open/close the main interface               |
| `/rm stats`         | Open the statistics view                    |
| `/rm characters`    | Show alt attempt tracking panel             |
| `/rm refresh`       | Refresh your mount collection status        |
| `/rm verify`        | Verify attempts with Blizzard statistics    |
| `/rm refreshchars`  | Refresh alt data from Blizzard stats        |
| `/rm sound`         | Toggle sound notifications                  |
| `/rm reset`         | Reset all stored attempt data (confirmation required) |

## Saved Variables

- `RaidMountAttempts` – Attempt data and character stats
- `RaidMountSettings` – User preferences and filter settings
- `RaidMountSaved` – Tooltip data and enhanced settings

## Localization

Supports the following languages:
- English (enUS)
- German (deDE)
- French (frFR)
- Spanish (esES/esMX)
- Russian (ruRU)
- Simplified Chinese (zhCN)
- Traditional Chinese (zhTW)

## Installation

1. Download the latest version from [CurseForge]([https://www.curseforge.com/wow/addons)](https://www.curseforge.com/wow/addons/raid-and-dungeon-mount-collection-tracker)
2. Extract to your `World of Warcraft/_retail_/Interface/AddOns/` directory
3. Restart WoW or reload the UI with `/reload`

## Developer Info

- Author: **knutballs** @ EU-Ravencrest
- Current Version: **21.07.25.35**
- Supported Interface: **110107, 110200**
- No external dependencies – pure Lua

## Contributing

Feel free to open issues or submit pull requests. When reporting bugs, please include:
- WoW version
- Interface version
- Steps to reproduce the issue
- Any error messages (Lua errors)

Pull requests should:
- Follow existing code style
- Include appropriate error handling
- Be tested in-game before submission

---



🍵 **Support the Developer**

If you enjoy this addon, consider supporting it:

- [Buy me a coffee](https://buymeacoffee.com/j0s0r)
- [Donate via PayPal](https://www.paypal.com/paypalme/johnfdavison)


---



---

*Last updated: July 21 2025*  
*Compatible with WoW 11.0+*
