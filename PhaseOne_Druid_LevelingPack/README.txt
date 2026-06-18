================================================================================
  PHASE ONE — HORDE FERAL DRUID LEVELING PACK (v1.0.0)
  Warmane Icecrown · WotLK 3.3.5a · Beginner install guide
================================================================================

WHAT YOU GET (lightweight — 8 addons)
  [Required]
    Questie-335     Quest helper (map icons, tracker)
    TomTom          Waypoint arrow (Questie integration)
    !Astrolabe      Map library (TomTom dependency)
    Leatrix_Plus    Auto-repair, auto-sell greys, faster loot
    WeakAuras       Aura framework (Bunny67 WotLK)
    PhaseOneLoader  Druid welcome + leveling presets

  [Optional]
    Bagnon          Combined bags
    Auctionator     Auction house helper

================================================================================
STEP 1 — FIND YOUR WARMANE FOLDER
================================================================================
  Folder must contain Wow.exe, e.g.:
    C:\Games\Warmane\
    C:\Program Files\Warmane\

================================================================================
STEP 2 — INSTALL (pick one method)
================================================================================

  METHOD A — INSTALL.bat (easiest)
    1. Double-click INSTALL.bat in this folder
    2. Paste full path to your Warmane folder when asked
    3. Wait for "Done!"

  METHOD B — Manual copy
    1. Open: PhaseOne_Druid_LevelingPack\Interface\AddOns
    2. Select ALL folders
    3. Copy into: YourWarmaneFolder\Interface\AddOns
    4. Merge/replace when prompted

  IMPORTANT: Folder names must match exactly (Questie-335, not Questie).

================================================================================
STEP 3 — ENABLE ADDONS (character select screen)
================================================================================
  1. Launch Warmane — stop at CHARACTER SELECT
  2. Click "AddOns"
  3. Check "Load out of date AddOns"  ← REQUIRED
  4. Enable: PhaseOneLoader, Questie-335, TomTom, !Astrolabe,
             Leatrix_Plus, WeakAuras, WeakAurasOptions
  5. Optional: Bagnon*, Auctionator
  6. OK → log in on your Druid

================================================================================
STEP 4 — RELOAD & VERIFY
================================================================================
  In chat:
    /reload

  You should see a welcome message from Phase One Druid Pack.
  Type /p1d anytime for Feral tips.

================================================================================
STEP 5 — PLAY (no extra setup required!)
================================================================================
  On first login the pack automatically configures:
    - Questie (±4 levels, sort by distance, hide completed)
    - Leatrix (auto repair, auto sell greys, faster loot)
    - P1 Feral HUD (energy bar, combo points, Rip/Rake/Mangle alerts)

  You will see a welcome message and the HUD near bottom-center.
  Drag the HUD to move it. /p1hud toggles it.

  OPTIONAL — extra WeakAuras (not required):
    /wa → WeakAuras\Feral_MANUAL_SETUP.txt

================================================================================
STEP 6 — QUESTING ON ICECROWN
================================================================================
  - Questie shows nearby quests (±4 levels, sorted by distance)
  - Ctrl + Left-click quest icon → TomTom arrow
  - /questie for settings
  - /ltp for Leatrix (auto repair/sell at vendors)

  Horde leveling route summary: Docs\HORDE_FERAL_DRUID_TIPS.txt

================================================================================
PERFORMANCE (Warmane Icecrown)
================================================================================
  /console scriptErrors 1
  /console maxfps 60

  Low FPS in Orgrimmar / Dalaran?
    - Video: Environment Low, Spell Effects Low
    - Disable Bagnon + Auctionator if not needed
    - WeakAuras: no animations, keep only Feral pack auras
    - Questie: lower icon limit in settings

================================================================================
TROUBLESHOOTING
================================================================================
  No addons?        → Wrong path or forgot "Load out of date"
  Questie broken?   → Options → Advanced → "Use WotLK map data"
  No arrow?         → Enable TomTom + !Astrolabe; Ctrl+click quest
  Wrong class tips? → Pack is for Feral Druid; /p1d still works

  GitHub: https://github.com/zakksu/Warmane-WoW

================================================================================
