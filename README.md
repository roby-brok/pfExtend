# pfExtend

> ### About this fork
>
> **This fork is maintained for [OctoWoW](https://octowow.st)** — that is where the fixes below
> were found and tested. They are not OctoWoW-specific and apply to any 1.12 client. Where the
> documentation below refers to Turtle WoW, that is the original authors' text.
>
> All credit goes to **[Cliencer](https://github.com/Cliencer/pfExtend)** and **TinyStick**, who
> wrote and maintain pfExtend, and to **[shagu](https://github.com/shagu/pfQuest)** for pfQuest
> which it builds on. This fork only adds the six QuestHelper fixes below — everything else is
> their work, unchanged. Please use
> [the original repository](https://github.com/Cliencer/pfExtend) unless you specifically need
> these.
>
> **`modules/QuestHelper/main.lua`**
>
> 1. **Failed profession requirements were reported as a class mismatch.** The skill check set
>    `ret.WRONGCLASS` instead of `ret.WRONGSKILL`, so a quest you couldn't take because of a
>    profession showed up as wrong-class. (`WRONG_SKILL` already exists in the priority table, so
>    the flag was simply the wrong one.)
> 2. **The object faction test was inverted.** It set `WRONGFACTION` when the quest object's
>    faction *matched* yours. The unit branch a few lines above uses `not strfind(...)`, which
>    confirms the intended sense.
> 3. **Quest-chain priority bits contradicted their own comments.** `HAS_PRE` and `FINISHED` were
>    `2` and `0` while documented as `00000001` and `00000010`; corrected to `1` and `2`.
> 4. **`OnMapChange` ignored the loop variable.** Inside `for _, location in pairs(locations)` the
>    guard tested `z2q[location]` but the body always read `z2q[PFEXQuestHelper.zone]`, so only the
>    current zone's quests were ever collected.
> 5. **Missing quest IDs caused a nil index.** `QuestFilter` now flags an unknown id and returns
>    early instead of indexing `quests[id]`, which matters when a quest database pack is removed.
>
> **`modules/QuestHelper/browser.lua`**
>
> 6. Two nil guards on the same missing-id path in `AddMapNode` — the quest title concat, and
>    `quests[id]` itself.
> 7. **Quests with a turn-in NPC but no quest-giver crashed the browser.** The quest-ender block in
>    `AddMapNode` reached into `quests[id]["start"]` without the guard its sibling quest-starter
>    block already had, throwing `attempt to index field 'start' (a nil value)`. Around 40 quests
>    in the Turtle database trip this — Baron Aquanis, Samophlange, Rizzle's Schematics and the
>    WANTED series among them. Both the unit and the object branch are now guarded. Reported by
>    **CakiL**.
>
> All of the above first shipped in **1.0.6**; see
> [Releases](https://github.com/roby-brok/pfExtend/releases) for per-version notes.
>
> **`modules/ShowLoots/` — 1.0.7**
>
> 8. **The three sort buttons emptied the window.** Clicking *Chance*, *ID* or *Quality* in the
>    ShowLoots browser blanked every row. The list the window draws is rebuilt from the live
>    mouseover: `UPDATE_MOUSEOVER_UNIT` clears `LootListShown` and only refills it when a unit is
>    actually under the cursor. Moving the cursor off the mob is exactly what you do to reach the
>    window, so the list was already empty by the time you clicked — and the sort handler refreshed
>    by calling `Hide()` then `Show()`, which re-ran `OnShow` and re-read that empty list. All three
>    buttons, every time.
>
>    The window now snapshots the list when it opens and sorts the snapshot, the mouseover handler
>    leaves the list alone while the window is open, and sorting repopulates in place instead of
>    cycling the frame. `ModifyTooltip()` returning nil is also guarded — it returns nil for a focus
>    it declines to describe, which made the next `ipairs()` over the list an error.
>
>    Worth noting for other 1.12 addons: this got more reliable to hit on ClassicAPI, which fires
>    `UPDATE_MOUSEOVER_UNIT` on *leaving* a unit. ClassicAPI ships its own
>    `CAPI_MouseoverClearedCompat` shim for exactly this pattern; pfExtend's handler had no such
>    guard.
>
> **`modules/ShowLoots/main.lua` — 1.0.8**
>
> 10. **"No loots" stamped under the loot list when the cursor left the mob.** The same loss-fire
>     as above reached the tooltip path: it cleared the list and flagged a redraw while the old
>     unit's tooltip was still fading on screen, so the ticker appended *No loots* right under the
>     loot lines it had just written. SuperAPI recently joined ClassicAPI in firing
>     `UPDATE_MOUSEOVER_UNIT` on unit loss, which is why this started showing up on both stacks.
>     The handler now returns before touching any state when nothing is under the cursor — which
>     also keeps the last list alive for the browser, the same flow fix 8 wanted. Reported by
>     **etherform**.
>
> **`modules/About/config.lua`, both `main.lua` — 1.0.7**
>
> 9. **Both loot databases were rebuilt on every login.** The guard reads
>    `PfExtend_Database[mod]["version"] ~= PfExtend_Config_Template["About"].Version()`, but
>    `Version()` constructs a fresh `{text="..."}` table on each call, so the comparison was
>    between two different tables and never equal. `UpdateDatabase()` therefore ran every time you
>    logged in — for ShowLoots that is a walk over every item in the pfQuest database with refloot
>    expansion, written straight back into SavedVariables. Both call sites now compare `.text`. The
>    stored value corrects itself on the first login after updating.

> 10. **A database-pack update now invalidates the cached databases.** Both caches are built
>    from `pfQuest-octo`'s data but were keyed only to pfExtend's own version, so a corrected
>    pack left every existing install serving the old data until pfExtend itself changed.
>    The cache key now includes the pack's version.
>
>    The version itself now comes from `GetAddOnMetadata`, so it lives only in the `.toc` instead
>    of being hardcoded in `About/config.lua` as well, where it had already drifted.
>
> Fork maintained by **Roby_Brok**.

English | [简体中文](README-zhCN.md)

pfExtend is an extension addon for [pfQuest](https://github.com/shagu/pfQuest), enhancing the gameplay experience by providing monster loot display and quest chain visualization functionalities. Compatible with **Turtle WoW** (1.12.0 client).

## Features

### ShowLoots - Monster Loot Display

When hovering over a monster, automatically displays its full loot table in the tooltip.
![ShowLoots Browser](img/Snipaste_2026-02-10_17-51-52.jpg)
**Key Features:**
- **Real-time Loot Preview**: Hover over any monster to see its complete drop list directly in the game tooltip
- **Drop Rate Visualization**: Shows exact drop percentages with color-coded indicators (green = common, red = rare)
- **Smart Filtering**: Filter loot by item quality (Poor, Common, Uncommon, Rare, Epic, Legendary)
- **Favorites System**: Mark items as favorites to highlight them in the loot list (favorited items appear at top)
- **Detailed Browser**: Press `Alt+Ctrl` while hovering to open a full loot browser window showing:
  - Item links with quality colors
  - Exact drop rates with percentage coloring
  - Item sources (NPCs, Objects, Vendors)
  - Zone locations for each source
  - Reference loot tables support (indirect drops)
  - Clickable item links for detailed inspection

**Supported Loot Types:**
- **Unit (NPC) Drops**: Direct monster loot
- **Object Loot**: Chests, containers, mining nodes, herbs, etc.
- **Reference Tables**: Complex loot tables linking multiple sources (e.g., "World Drop" tables)

**Configuration Options:**
- Enable/disable the feature
- Set maximum number of items displayed in tooltip
- Filter by minimum item quality (hide junk items)
- Toggle item ID display in browser

---

### QuestHelper - Quest Chain Browser

A powerful quest chain visualization tool integrated into the World Map.
![QuestHelper Browser](img/Snipaste_2026-02-10_17-50-45.jpg)

**Key Features:**
- **Interactive Quest Tree**: Displays all available quests in current zone as an expandable tree structure
- **Quest Chain Visualization**: Automatically builds and displays complete quest chains (prerequisites → follow-ups)
- **Smart Quest Filtering**: Automatically filters quests by:
  - Race compatibility
  - Class requirements
  - Profession requirements
  - Level requirements
  - Event quests
  - Prerequisite completion status

**Quest Status Indicators:**

| Color | Tag | Meaning |
|-------|-----|---------|
| <span style="color:#3eff2b">●</span> Green | Active | Currently in quest log |
| <span style="color:#ffff2b">●</span> Yellow | Available | Can be accepted now |
| <span style="color:#ff2b2b">●</span> Red | Prereq | Missing prerequisite quests |
| <span style="color:#ff2b2b">●</span> Red | High-Level | Level requirement not met |
| <span style="color:#5a5a5a">●</span> Gray | Finished | Completed (dimmed if all follow-ups done) |
| <span style="color:#5a5a5a">●</span> Gray | Race/Class/Skill | Requirements not met |
| <span style="color:#2b3eff">●</span> Blue | Event | Seasonal or event quest |
| <span style="color:#ffff2b">●</span> Yellow | Hidden | Starts from item drop |

**Interactive Map Integration:**
- **Map Toggle Button**: Quick access button on World Map (`QH` button)
- **Quest Pinning**: Click any quest to pin it on the world map
- **Automatic Map Markers**: Shows quest giver locations (NPCs, Objects, Items)
- **Smart Clustering**: Groups nearby quest markers to reduce clutter
- **Cross-Zone Tracking**: 
  - Click to track quests from other zones (auto-switch map)
  - Ctrl+Click to find and track prerequisite quests in their respective zones

**Quest Chain Navigation:**
- **Expandable Tree**: Click `+`/`-` to expand or collapse quest chains
- **Double-Click**: Expand/collapse entire subtree at once
- **Auto-Scroll**: Automatically scrolls to relevant quest when switching zones
- **Persistent Pins**: Quest pins remain on map until manually removed

**Advanced Features:**
- **Prerequisite Finder**: Automatically locates prerequisite quests when current quest is unavailable
- **Multi-Zone Support**: Handles quests available in multiple zones or locations
- **Item-Start Quests**: Tracks quests that begin from item drops (with drop source locations)
- **Unified Cache**: Optimized database for fast quest zone lookups

---

## Dependencies

- **[pfQuest](https://github.com/shagu/pfQuest)** - Required database provider
- **[pfQuest-turtle](https://github.com/shagu/pfQuest-turtle)** - Additional database for Turtle WoW (required only for Turtle WoW)
- **[pfUI](https://github.com/shagu/pfUI)** - Recommended UI framework (optional)

## Installation

1. **[Download the latest release](https://github.com/roby-brok/pfExtend/releases/latest)** and take
   `pfExtend-X.X.X.zip` — *not* the *Source code (zip)* link
2. Extract it into your WoW addons folder: `Interface\AddOns\`
3. Restart the game or reload the UI (`/reload`)

The release zip already contains a correctly named `pfExtend` folder, so there is nothing to
rename. *Source code (zip)* is the one to avoid: it unpacks to `pfExtend-X.X.X`, and WoW skips a
folder whose name does not match the `.toc` inside it — in silence, with no error and no entry in
the addon list.

## Commands

| Command | Description |
|---------|-------------|
| `/pfex` | Open pfExtend configuration window |

## Configuration

Access settings via:
- Slash command: `/pfex`
- Browser window settings button (gear icon)
![Configuration Panel](img/Snipaste_2026-02-10_17-52-11.jpg)


## Database Update

Both features require a one-time database initialization:
- Automatically updates on first login after installation
- Manual update available via settings
- Update required when pfQuest database changes

## Compatibility

- **Client**: World of Warcraft 1.12.0 (Vanilla), compatible with **Turtle WoW**
- **Dependencies**: pfQuest (and pfQuest-turtle for Turtle WoW), pfUI(optional)
- **Conflicts**: None known

## Credits

- **Author**: Cliencer
- **Base Framework**: pfQuest by Shagu
- **UI Framework**: pfUI by Shagu

