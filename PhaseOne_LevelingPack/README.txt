================================================================================
  PHASE ONE — WARMANE WOTLK HORDE WARLOCK LEVELING PACK (v1.1.0)
  Beginner install guide (plain text)
================================================================================

WHAT YOU GET (lightweight — 8 addons)
  [Required]
    Questie-335     Quest helper (map icons, tracker)
    TomTom          Waypoint arrow (works with Questie)
    !Astrolabe      Map library (required by TomTom)
    Leatrix_Plus    QoL: auto-repair, auto-sell greys, faster loot
    WeakAuras       Aura framework (Bunny67 WotLK build)
    PhaseOneLoader  Welcome + presets on first login
    P1WarlockHUD    DoT tracker (Corruption/Immolate/CoA) — no import!

  [Optional — enable only if you want them]
    Bagnon          Combined bags (search/sort)
    Auctionator     Simple auction house helper

================================================================================
STEP 1 — FIND YOUR WARMANE FOLDER
================================================================================
  Typical path:
    C:\Games\Warmane\Interface\AddOns
    or wherever your Warmane 3.3.5a client is installed.

  You need the folder:
    ...\World of Warcraft\Interface\AddOns

================================================================================
STEP 2 — COPY ADDONS (2 minutes)
================================================================================
  1. Open this pack folder: PhaseOne_LevelingPack
  2. Open: PhaseOne_LevelingPack\Interface\AddOns
  3. Select ALL folders inside AddOns
  4. Copy them into your game's Interface\AddOns folder
  5. When asked to merge/replace folders, choose YES

  IMPORTANT folder names (must match exactly):
    Questie-335
    TomTom
    !Astrolabe
    Leatrix_Plus
    WeakAuras
    PhaseOneLoader
    Bagnon          (optional)
    Auctionator     (optional)

  Do NOT nest an extra AddOns folder inside AddOns.

================================================================================
STEP 3 — ENABLE ADDONS AT LOGIN
================================================================================
  1. Start Warmane / WoW 3.3.5a
  2. At the CHARACTER SELECT screen, click "AddOns" (bottom-left)
  3. Check: "Load out of date AddOns"  <-- REQUIRED
  4. Enable these (check each box):
       PhaseOneLoader
       Questie-335
       TomTom
       !Astrolabe
       Leatrix_Plus
       WeakAuras
       Bagnon          (optional)
       Auctionator     (optional)
  5. Click OK and log in

  TIP: Click "Enable All" then disable anything you don't want.

================================================================================
STEP 4 — RELOAD UI
================================================================================
  In-game chat:
    /reload

  You should see a welcome message from Phase One Pack.

================================================================================
STEP 5 — IMPORT WEAKAURAS (Warlock helpers)
================================================================================
  1. Type: /wa
  2. Click "Import"
  3. Open file: WeakAuras\Warlock_Leveling_Starter_Pack.txt
  4. Copy the long !WA:2! string and paste into import box
  5. Click Import → Accept

  If import fails, use the manual guide:
    WeakAuras\Warlock_MANUAL_SETUP.txt

  Also import (optional):
    WeakAuras\Warlock_Pet_Focus.txt
    WeakAuras\Warlock_Rotation_Helper.txt

================================================================================
STEP 6 — QUESTIE + TOMTOM QUICK USE
================================================================================
  - Quest icons appear on map/minimap
  - Ctrl + Left-click a quest icon → TomTom arrow points there
  - Type /questie for options
  - Type /tomtom to toggle arrow info

  Questie presets applied on first login:
    - Show quests within ±4 levels
    - Tracker sorted by distance
    - Completed quests hidden in tracker

================================================================================
STEP 7 — LEATRIX PLUS
================================================================================
  Type: /ltp

  Presets enabled on first login:
    - Auto repair gear
    - Auto sell grey items at vendors
    - Faster looting
    - Hide spammy error messages (performance)

================================================================================
PERFORMANCE TIPS (Warmane / low FPS)
================================================================================
  In-game console (paste in chat):
    /console scriptErrors 1
    /console maxfps 60

  Check FPS: enable FPS counter in Video options, or use Leatrix Plus.

  If FPS drops in cities:
    - Video → Environment Detail: Low
    - Video → Spell Effects: Low
    - WeakAuras → disable animations (see WeakAuras\PERFORMANCE.txt)
    - Disable optional addons (Bagnon, Auctionator) if not needed
    - Questie: reduce icon limit in Questie settings

  Target: < 5-6 active addons for Phase One (excluding libraries).

================================================================================
HORDE WARLOCK TIPS
================================================================================
  See: Docs\HORDE_WARLOCK_TIPS.txt
  In-game: /p1

================================================================================
TROUBLESHOOTING
================================================================================
  Addons not showing?
    - Wrong folder (must be Interface\AddOns\Questie-335 not nested)
    - Forgot "Load out of date AddOns"

  Questie errors on Warmane?
    - Questie-335 → Options → Advanced → enable "Use WotLK map data" if needed

  No quest arrow?
    - Enable TomTom + !Astrolabe
    - Ctrl+click quest icon on map

  Lua errors?
    /console scriptErrors 1
    Screenshot error and check GitHub issues

================================================================================
GITHUB: https://github.com/zakksu/Warmane-WoW
================================================================================
