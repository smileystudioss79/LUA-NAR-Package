-- ============================================================
--  LUA-NAR  |  LPM Registry
--  lpm/lpm_registry.lua
--
--  This file is the authoritative format for an LPM package
--  registry.  A registry is just a Lua table returned by this
--  module.  Community members can host their own registries;
--  the LPM in-game UI fetches whichever URL the user sets.
--
--  HOW TO PUBLISH YOUR OWN PACKAGE
--  --------------------------------
--  1. Fork the official registry repo (see homepage).
--  2. Add an entry to the `packages` table below following the
--     template at the bottom of this file.
--  3. Open a Pull Request — that's it.
--
--  REGISTRY JSON FORMAT (for remote registries fetched by URL)
--  -----------------------------------------------------------
--  The same table structure can be served as JSON.  LPM will
--  detect Content-Type or a leading '{' and parse accordingly.
-- ============================================================

local registry = {}

-- ── Registry metadata ─────────────────────────────────────────
registry.meta = {
    name        = "LUA-NAR Official Registry",
    version     = "1",
    homepage    = "https://github.com/YOUR_USER/LUA-NAR",
    description = "Official package registry for LUA-NAR KSP scripts.",
    updated     = "2026-04-22",
}

-- ── Package list ──────────────────────────────────────────────
-- Each entry is a package descriptor.  Fields:
--
--   id          (string)  Unique snake_case identifier.
--   name        (string)  Human-readable display name.
--   version     (string)  Semver string, e.g. "1.2.0".
--   author      (string)  Author or maintainer name.
--   description (string)  One-line summary shown in LPM UI.
--   category    (string)  One of: "autopilot", "hud", "nav",
--                         "utility", "example", "other".
--   license     (string)  SPDX short name, e.g. "MIT".
--   url         (string)  Direct URL to the .lua file.
--                         Must be a raw file URL, not a GitHub
--                         HTML page.
--   sha256      (string)  Optional. SHA-256 hex of the file for
--                         integrity verification.
--   requires    (table)   Optional. List of LUA-NAR API namespaces
--                         this script needs, e.g.:
--                         {"flight", "nav", "autopilot", "ui"}
--                         Used by LPM to warn on API mismatches.
--   tags        (table)   Optional. Free-form string tags for
--                         search filtering.
--   ksp_min     (string)  Optional. Minimum KSP version, e.g. "1.8".
--   ksp_max     (string)  Optional. Maximum KSP version tested.

registry.packages = {

    -- ── Built-in example scripts (shipped with the mod) ──────
    {
        id          = "hello_world",
        name        = "Hello World",
        version     = "1.0.0",
        author      = "LUA-NAR Team",
        description = "Minimal example: displays a draggable GUI window.",
        category    = "example",
        license     = "LicenseRef-LUA-NAR",
        url         = "https://raw.githubusercontent.com/YOUR_USER/LUA-NAR/main/GameData/LUA-NAR/Scripts/hello_world.lua",
        requires    = {"ui"},
        tags        = {"example", "beginner"},
        builtin     = true,   -- ships with the mod, never needs downloading
    },
    {
        id          = "telemetry",
        name        = "Telemetry Logger",
        version     = "1.0.0",
        author      = "LUA-NAR Team",
        description = "Logs altitude, speed and G-force to Lua-Nar.log every second.",
        category    = "utility",
        license     = "LicenseRef-LUA-NAR",
        url         = "https://raw.githubusercontent.com/YOUR_USER/LUA-NAR/main/GameData/LUA-NAR/Scripts/telemetry.lua",
        requires    = {"vessel"},
        tags        = {"telemetry", "logging", "beginner"},
        builtin     = true,
    },
    {
        id          = "auto_throttle",
        name        = "Auto Throttle",
        version     = "1.0.0",
        author      = "LUA-NAR Team",
        description = "Reduces throttle automatically above 20 km to limit heating.",
        category    = "autopilot",
        license     = "LicenseRef-LUA-NAR",
        url         = "https://raw.githubusercontent.com/YOUR_USER/LUA-NAR/main/GameData/LUA-NAR/Scripts/auto_throttle.lua",
        requires    = {"vessel", "flight"},
        tags        = {"throttle", "atmosphere", "beginner"},
        builtin     = true,
    },
    {
        id          = "orbit_report",
        name        = "Orbit Report",
        version     = "1.0.0",
        author      = "LUA-NAR Team",
        description = "Prints a full orbital parameter summary to the log.",
        category    = "nav",
        license     = "LicenseRef-LUA-NAR",
        url         = "https://raw.githubusercontent.com/YOUR_USER/LUA-NAR/main/GameData/LUA-NAR/Scripts/orbit_report.lua",
        requires    = {"vessel", "nav"},
        tags        = {"orbit", "report", "beginner"},
        builtin     = true,
    },
    {
        id          = "orbital_autopilot",
        name        = "Orbital Autopilot",
        version     = "1.0.1",
        author      = "LUA-NAR Team",
        description = "Full GUI ascent + circularisation autopilot with preset orbit selection.",
        category    = "autopilot",
        license     = "LicenseRef-LUA-NAR",
        url         = "https://raw.githubusercontent.com/YOUR_USER/LUA-NAR/main/GameData/LUA-NAR/Scripts/orbital_autopilot.lua",
        requires    = {"vessel", "flight", "nav", "autopilot", "ui"},
        tags        = {"autopilot", "ascent", "orbit", "gui", "advanced"},
        ksp_min     = "1.8",
        builtin     = true,
    },
    {
        id          = "live_hud",
        name        = "Live HUD",
        version     = "1.0.0",
        author      = "LUA-NAR Team",
        description = "Always-on telemetry overlay with altitude, speed, orbit and fuel.",
        category    = "hud",
        license     = "LicenseRef-LUA-NAR",
        url         = "https://raw.githubusercontent.com/YOUR_USER/LUA-NAR/main/GameData/LUA-NAR/Scripts/live_hud.lua",
        requires    = {"vessel", "nav", "ui"},
        tags        = {"hud", "telemetry", "gui"},
        builtin     = true,
    },
    {
        id          = "stage_monitor",
        name        = "Stage Monitor",
        version     = "1.0.0",
        author      = "LUA-NAR Team",
        description = "Watches stage transitions and logs resource levels per stage.",
        category    = "utility",
        license     = "LicenseRef-LUA-NAR",
        url         = "https://raw.githubusercontent.com/YOUR_USER/LUA-NAR/main/GameData/LUA-NAR/Scripts/stage_monitor.lua",
        requires    = {"vessel", "flight"},
        tags        = {"staging", "resources", "utility"},
        builtin     = true,
    },
    {
        id          = "api_explorer",
        name        = "API Explorer",
        version     = "1.0.0",
        author      = "LUA-NAR Team",
        description = "Interactive GUI browser for every LUA-NAR API function.",
        category    = "utility",
        license     = "LicenseRef-LUA-NAR",
        url         = "https://raw.githubusercontent.com/YOUR_USER/LUA-NAR/main/GameData/LUA-NAR/Scripts/api_explorer.lua",
        requires    = {"vessel", "flight", "nav", "autopilot", "ui"},
        tags        = {"debug", "explorer", "reference", "advanced"},
        builtin     = true,
    },

    -- ── Template: copy this block to add a community package ─
    --[[
    {
        id          = "my_cool_script",
        name        = "My Cool Script",
        version     = "1.0.0",
        author      = "YourName",
        description = "Does something amazing in KSP via LUA-NAR.",
        category    = "utility",     -- autopilot|hud|nav|utility|example|other
        license     = "MIT",
        url         = "https://raw.githubusercontent.com/YOU/REPO/main/my_cool_script.lua",
        sha256      = "abc123...",   -- optional but recommended
        requires    = {"vessel"},    -- vessel|flight|nav|autopilot|ui
        tags        = {"cool", "useful"},
        ksp_min     = "1.8",
    },
    --]]
}

return registry
