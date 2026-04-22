-- ============================================================
--  LUA-NAR  |  LPM In-Game UI
--  GameData/LUA-NAR/Scripts/lpm_ui.lua
--
--  A full in-game GUI package manager for LUA-NAR.
--  Drop this into your Scripts/ folder and it loads
--  automatically when you enter a Flight scene.
--
--  Features:
--    • Browse all packages in the bundled registry
--    • See which are already installed (present in Scripts/)
--    • One-click "info" view per package
--    • Category filter tabs
--    • Reload registry from disk on demand
--
--  NOTE: In-game installs cannot download from the internet
--  (KSP has no HTTP client).  LPM in-game shows you WHAT to
--  install; use the CLI tool (lua lpm.lua install <id>) while
--  KSP is closed to actually grab scripts.
-- ============================================================

print("[LPM-UI] lpm_ui.lua loading...")

-- ── Load the registry ─────────────────────────────────────────
-- The registry lives at GameData/LUA-NAR/lpm_registry.lua
-- LuaManager sets the working directory to GameData/LUA-NAR/
-- so a relative path works.
local registry_path = "lpm_registry.lua"
local registry      = nil

local function load_registry()
    local f = io.open(registry_path, "r")
    if not f then
        logToFile("[LPM-UI] Registry file not found: " .. registry_path)
        return nil
    end
    local src = f:read("*a")
    f:close()
    local fn, err = load(src)
    if not fn then
        logToFile("[LPM-UI] Registry parse error: " .. tostring(err))
        return nil
    end
    local ok, result = pcall(fn)
    if not ok then
        logToFile("[LPM-UI] Registry runtime error: " .. tostring(result))
        return nil
    end
    return result
end

-- ── Check which scripts are installed ────────────────────────
-- "Installed" = a file with the package id exists in Scripts/
local scripts_path = "Scripts/"

local function is_installed(pkg)
    local f = io.open(scripts_path .. pkg.id .. ".lua", "r")
    if f then f:close(); return true end
    return false
end

-- ── State ─────────────────────────────────────────────────────
local WIN_MAIN   = "lpm_main"
local WIN_INFO   = "lpm_info"
local WIN_STATUS = "lpm_status"

local CATEGORIES = { "all", "autopilot", "hud", "nav", "utility", "example", "other" }
local current_cat = "all"
local selected_pkg = nil
local status_msg   = ""
local status_ok    = true

-- ── Build helpers ─────────────────────────────────────────────
local function set_status(msg, is_ok)
    status_msg = msg
    status_ok  = is_ok ~= false
    guiClear(WIN_STATUS)
    guiLabel(WIN_STATUS, is_ok and "✔  " .. msg or "✖  " .. msg)
    guiShow(WIN_STATUS)
end

local function category_icon(cat)
    local icons = {
        autopilot = "🚀",
        hud       = "🖥",
        nav       = "🧭",
        utility   = "🔧",
        example   = "📄",
        other     = "📦",
    }
    return icons[cat] or "📦"
end

-- ── Info window ───────────────────────────────────────────────
local function build_info_window(pkg)
    guiClear(WIN_INFO)
    guiLabel(WIN_INFO, "── PACKAGE INFO ──")
    guiSeparator(WIN_INFO)
    guiLabel(WIN_INFO, "Name    : " .. pkg.name)
    guiLabel(WIN_INFO, "ID      : " .. pkg.id)
    guiLabel(WIN_INFO, "Version : " .. pkg.version)
    guiLabel(WIN_INFO, "Author  : " .. pkg.author)
    guiLabel(WIN_INFO, "Category: " .. pkg.category)
    guiLabel(WIN_INFO, "License : " .. pkg.license)
    guiSeparator(WIN_INFO)
    guiLabel(WIN_INFO, pkg.description)
    guiSeparator(WIN_INFO)

    if pkg.requires and #pkg.requires > 0 then
        guiLabel(WIN_INFO, "Requires APIs:")
        guiLabel(WIN_INFO, "  " .. table.concat(pkg.requires, ", "))
        guiSpace(WIN_INFO, 2)
    end

    if pkg.tags and #pkg.tags > 0 then
        guiLabel(WIN_INFO, "Tags: " .. table.concat(pkg.tags, ", "))
        guiSpace(WIN_INFO, 2)
    end

    guiSeparator(WIN_INFO)
    guiLabel(WIN_INFO, "File URL:")
    guiLabel(WIN_INFO, pkg.url)
    guiSpace(WIN_INFO, 4)

    if is_installed(pkg) then
        guiLabel(WIN_INFO, "✔ Already in Scripts/")
    else
        guiLabel(WIN_INFO, "⬇  To install, run in CLI:")
        guiLabel(WIN_INFO, "  lua lpm.lua install " .. pkg.id)
    end

    guiSpace(WIN_INFO, 4)
    guiButton(WIN_INFO, "✕ Close", function()
        guiHide(WIN_INFO)
        selected_pkg = nil
    end)
end

-- ── Main package list window ──────────────────────────────────
local function build_main_window()
    if not registry then
        guiClear(WIN_MAIN)
        guiLabel(WIN_MAIN, "LUA-NAR Package Manager")
        guiSeparator(WIN_MAIN)
        guiLabel(WIN_MAIN, "⚠  Registry not loaded.")
        guiLabel(WIN_MAIN, "Ensure lpm_registry.lua is in")
        guiLabel(WIN_MAIN, "GameData/LUA-NAR/")
        guiSpace(WIN_MAIN, 4)
        guiButton(WIN_MAIN, "↺ Retry load", function()
            registry = load_registry()
            build_main_window()
        end)
        guiButton(WIN_MAIN, "✕ Close", function() guiHide(WIN_MAIN) end)
        return
    end

    guiClear(WIN_MAIN)
    guiLabel(WIN_MAIN, "LUA-NAR Package Manager  v" ..
        (registry.meta and registry.meta.version or "?"))
    guiSeparator(WIN_MAIN)

    -- Category filter tabs (as buttons)
    guiLabel(WIN_MAIN, "Filter:")
    for _, cat in ipairs(CATEGORIES) do
        local marker = (cat == current_cat) and "► " or "  "
        guiButton(WIN_MAIN, marker .. cat, function()
            current_cat = cat
            build_main_window()
        end)
    end

    guiSeparator(WIN_MAIN)
    guiLabel(WIN_MAIN, "Packages:")
    guiSpace(WIN_MAIN, 2)

    local count = 0
    for _, pkg in ipairs(registry.packages) do
        if current_cat == "all" or pkg.category == current_cat then
            local inst  = is_installed(pkg) and " ✔" or ""
            local label = string.format("%s %s  v%s%s",
                category_icon(pkg.category), pkg.name, pkg.version, inst)
            guiButton(WIN_MAIN, label, function()
                selected_pkg = pkg
                build_info_window(pkg)
                guiShow(WIN_INFO)
            end)
            count = count + 1
        end
    end

    if count == 0 then
        guiLabel(WIN_MAIN, "  (no packages in this category)")
    end

    guiSeparator(WIN_MAIN)
    guiButton(WIN_MAIN, "↺ Reload registry", function()
        registry = load_registry()
        if registry then
            set_status("Registry reloaded — " ..
                #registry.packages .. " packages.", true)
        else
            set_status("Registry reload failed.", false)
        end
        build_main_window()
    end)

    guiButton(WIN_MAIN, "✕ Close", function()
        guiHide(WIN_MAIN)
        guiHide(WIN_INFO)
        guiHide(WIN_STATUS)
    end)
end

-- ── Initialise ────────────────────────────────────────────────
guiCreate(WIN_MAIN,   "LPM — Package Manager",  20,  60, 280, 560)
guiCreate(WIN_INFO,   "Package Info",          320,  60, 320, 460)
guiCreate(WIN_STATUS, "LPM Status",            20,  640, 500, 50)

registry = load_registry()

if registry then
    logToFile("[LPM-UI] Registry loaded — " .. #registry.packages .. " packages.")
    set_status("Registry loaded — " .. #registry.packages .. " packages.", true)
else
    logToFile("[LPM-UI] Registry missing. Showing empty browser.")
    set_status("Registry not found. Check GameData/LUA-NAR/lpm_registry.lua", false)
end

build_main_window()
guiShow(WIN_MAIN)

print("[LPM-UI] Package manager ready.")
