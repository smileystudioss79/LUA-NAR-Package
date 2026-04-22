-- ============================================================
--  LUA-NAR  |  LuaRocks Rockspec
-- ============================================================

rockspec_format = "3.0"

package = "lua-nar"
version = "1.0.1-1"

description = {
    summary    = "Lua scripting runtime for Kerbal Space Program (KSP 1.8+)",
    detailed   = [[
LUA-NAR embeds the MoonSharp Lua 5.2-compatible interpreter into KSP,
exposing a full flight/autopilot/navigation/UI API to user scripts.
Drop any .lua file into GameData/LUA-NAR/Scripts/ and it loads
automatically when you enter the flight scene - no restart required.

This rock distributes the Lua-side helper libraries and example
scripts. The C# DLL (LUA-NAR.dll) must be installed separately
from the mod's GameData release.
    ]],
    license    = "All Rights Reserved",
    homepage   = "https://github.com/smileystudioss79/LUA-NAR",
    issues_url = "https://github.com/smileystudioss79/LUA-NAR/issues",
    maintainer = "smileystudioss79 <>",
    labels     = {
        "ksp", "kerbal-space-program", "scripting",
        "autopilot", "flight", "simulation", "moonsharp"
    },
}

dependencies = {
    "lua >= 5.2, < 5.5",
}

source = {
    url = "git+https://github.com/smileystudioss79/LUA-NAR.git",
    tag = "v1.0.1",
}

build = {
    type = "builtin",
    modules = {
        ["lua-nar.lpm"]          = "lpm/lpm.lua",
        ["lua-nar.lpm_registry"] = "lpm/lpm_registry.lua",
        ["lua-nar.lpm_install"]  = "lpm/lpm_install.lua",
    },
    install = {
        lua = {
            ["lua-nar.scripts.hello_world"]       = "GameData/LUA-NAR/Scripts/hello_world.lua",
            ["lua-nar.scripts.telemetry"]         = "GameData/LUA-NAR/Scripts/telemetry.lua",
            ["lua-nar.scripts.auto_throttle"]     = "GameData/LUA-NAR/Scripts/auto_throttle.lua",
            ["lua-nar.scripts.orbit_report"]      = "GameData/LUA-NAR/Scripts/orbit_report.lua",
            ["lua-nar.scripts.orbital_autopilot"] = "GameData/LUA-NAR/Scripts/orbital_autopilot.lua",
            ["lua-nar.scripts.live_hud"]          = "GameData/LUA-NAR/Scripts/live_hud.lua",
            ["lua-nar.scripts.stage_monitor"]     = "GameData/LUA-NAR/Scripts/stage_monitor.lua",
            ["lua-nar.scripts.api_explorer"]      = "GameData/LUA-NAR/Scripts/api_explorer.lua",
            ["lua-nar.scripts.lpm_ui"]            = "GameData/LUA-NAR/Scripts/lpm_ui.lua",
        },
    },
}
