# RaidMount - Raid & Dungeon Mount Collection Tracker

##  Overview

**RaidMount** is a comprehensive World of Warcraft addon that tracks your attempts at obtaining rare mounts from raids, dungeons, world bosses, and special events. Built with performance and accuracy in mind, it provides detailed statistics, real-time tracking, and a professional user interface to help you manage your mount collection journey.

**Current Version:** 06.07.25.11  
**Interface Support:** 110107  
**Author:** knutballs @EU Ravencrest

---

##  Features

###  Core Functionality
- **90+ Mounts Tracked** - Complete database from Classic WoW through The War Within
- **Automatic Attempt Tracking** - Records attempts when you kill bosses
- **Cross-Character Sync** - Tracks attempts across all your characters
- **Real-time Collection Detection** - Automatically updates when you obtain mounts
- **Statistics Verification** - Cross-checks with Blizzard's achievement statistics

###  User Interface
- **Professional Dark Theme** - Matches WoW's aesthetic
- **8-Column Display** - Mount, Raid, Boss, Drop Rate, Expansion, Attempts, Collected, Raid Available
- **Advanced Filtering** - Filter by status, expansion, content type, and live search
- **Sortable Columns** - Click any header to sort data
- **Enhanced Tooltips** - Detailed mount information with character breakdowns
- **Progress Tracking** - Visual progress bars and collection percentages

###  Statistics & Analytics
- **Overall Statistics** - Total mounts, collected count, missing count, total attempts
- **Expansion Breakdown** - Collection rates by expansion
- **Content Type Analysis** - Raid, dungeon, world boss, holiday event statistics
- **Most Attempted Mounts** - Identify your "unlucky" mounts
- **Character Breakdown** - See which characters have the most attempts

###  Performance Features
- **Smart Caching** - 50-tooltip cache system for instant display
- **Virtual Scrolling** - Only renders visible rows for smooth performance
- **Memory Optimization** - Object pooling and efficient data structures
- **Throttled Updates** - 300ms search throttling for smooth typing

##  Usage

### Basic Commands
- `/rm` - Open/close the main interface

### Interface Navigation

#### Main Window
- **Title Bar** - Drag to move the window
- **Close Button** - Top-right corner to close
- **Progress Bar** - Shows overall collection progress
- **View Toggle** - Switch between Mount List and Statistics views

#### Filtering System
- **Status Filter** - All, Collected, Uncollected
- **Expansion Filter** - All expansions from Classic to The War Within
- **Content Type Filter** - All, Raid, Dungeon, World, Holiday, Special
- **Search Box** - Real-time search with 300ms throttling

#### Mount List
- **Sortable Columns** - Click any header to sort
- **Color Coding**:
  - 🟢 Green: Collected mounts
  - ⚪ White: Uncollected mounts
  - 🟢 Green: Available raids
  - 🔴 Red: Locked raids with countdown
- **Hover Tooltips** - Detailed mount information


#### Statistics View
- **Overall Progress** - Visual progress bar with percentages
- **Expansion Breakdown** - Collection rates by expansion
- **Content Type Analysis** - Statistics by mount source
- **Most Attempted** - Ranked list of your most attempted mounts

---

##  Mount Database

### Content Types Covered
- **Raid Mounts** - All raid bosses from Classic through The War Within
- **Dungeon Mounts** - Heroic and Mythic dungeon drops
- **World Boss Mounts** - Rare world spawn mounts
- **Holiday Event Mounts** - Seasonal event rewards
- **Special Mounts** - Achievement and time-limited mounts

### Notable Mounts Included
- **Classic**: Onyxian Drake, Rivendare's Deathcharger
- **TBC**: Ashes of Al'ar, Fiery Warhorse, Raven Lord
- **WotLK**: Invincible, Mimiron's Head, Blue Proto-Drake
- **Cataclysm**: Pureblood Fire Hawk, Drake of the South Wind
- **MoP**: Astral Cloud Serpent, Kor'kron Juggernaut
- **WoD**: Ironhoof Destroyer, Felsteel Annihilator
- **Legion**: Felblaze Infernal, Antoran Charhound
- **BfA**: G.M.O.D., Glacial Tidestorm, Surf Jelly
- **Shadowlands**: Sanctum Gloomcharger, Vengeance
- **Dragonflight**: Anu'relos, Flame's Guidance
- **The War Within**: Sureki Skyrazor, Prototype A.S.M.R.

---

##  Settings & Customization

### Saved Variables
The addon automatically saves your data in three variables:
- `RaidMountAttempts` - Attempt tracking data
- `RaidMountSettings` - User preferences
- `RaidMountSaved` - Enhanced tooltip settings

### Data Management
- **Automatic Backup** - Data is verified against Blizzard statistics
- **Cross-Character Sync** - Attempts tracked across all characters
- **UK Date Format** - Timestamps in dd/mm/yy format
- **Class Information** - Character class data stored for tooltips

---

##  Technical Details

### Performance Optimizations
- **Tooltip Caching** - 50-tooltip cache with hit/miss tracking
- **Mount Detection** - Multiple fallback methods for accuracy
- **Statistics Verification** - Cross-checks with Blizzard API
- **Memory Management** - Object pooling and smart cleanup
- **Throttled Updates** - Prevents UI lag during rapid changes

### Data Integrity
- **Statistics Backup** - Uses Blizzard's achievement statistics as backup
- **Self-Correcting** - Automatically updates if statistics show higher counts
- **Character Tracking** - Per-character attempt data with class information
- **Collection Verification** - Multiple methods to verify mount ownership

### Architecture
- **Modular Design** - Separate files for different functionality
- **Clean Code Structure** - Professional development practices
- **Error Handling** - Extensive error handling and graceful degradation
- **No External Dependencies** - Pure Lua implementation

---




---

##  Contributing

### Reporting Issues
When reporting issues, please include:
- The RaidMount version you're using
- Steps to reproduce the issue
- Any error messages

### Feature Requests
We welcome feature requests! Please:
- Check existing issues first
- Provide detailed descriptions
- Explain the benefit to users



---
### ⚔️ Support the Quest!
---

🍵 **Support the Developer**

If you enjoy this addon, consider supporting it:

- [Buy me a coffee](https://buymeacoffee.com/j0s0r)
- [Donate via PayPal](https://www.paypal.com/paypalme/johnfdavison)

Your support helps keep the code flowing and the bugs away. 🧙‍♂️✨

---



---

*Last updated: July 06 2025*  
*Compatible with WoW 11.0+*
