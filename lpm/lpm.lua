-- ============================================================
--  LUA-NAR  |  LPM Core  (lpm/lpm.lua)
--
--  Lua Package Manager for LUA-NAR.
--  Can run in two modes:
--
--    1. CLI (plain Lua 5.2+ or LuaJIT) — from the command line
--       to pre-populate your Scripts folder before launching KSP.
--
--    2. In-Game — loaded by LUA-NAR inside KSP.  In this mode the
--       network functions are stubbed out (KSP has no HTTP client
--       built in); use the companion lpm_ui.lua for the full GUI.
--
--  Quick CLI usage:
--    lua lpm.lua list
--    lua lpm.lua install orbital_autopilot
--    lua lpm.lua remove  telemetry
--    lua lpm.lua search  hud
--    lua lpm.lua info    live_hud
-- ============================================================

local lpm = {}
lpm._VERSION = "1.0.0"

-- ── Detect environment ────────────────────────────────────────
-- Inside KSP, `FlightGlobals` is a global; outside it's nil.
local IN_KSP = (FlightGlobals ~= nil)

-- ── Default configuration ─────────────────────────────────────
lpm.config = {
    -- Absolute path to your KSP GameData/LUA-NAR/Scripts/ folder.
    -- Override this before calling any install/remove functions.
    scripts_dir    = "GameData/LUA-NAR/Scripts",

    -- URL of the registry file (JSON or Lua table).
    registry_url   = "https://raw.githubusercontent.com/YOUR_USER/LUA-NAR/main/lpm/lpm_registry.lua",

    -- Path to a local registry file (used when offline or in-game).
    local_registry = "lpm/lpm_registry.lua",

    -- Path to the installed-packages manifest.
    manifest_path  = "GameData/LUA-NAR/lpm_manifest.lua",

    -- Whether to verify sha256 checksums (requires a sha256 library).
    verify_checksums = false,
}

-- ── Manifest (tracks what is installed) ──────────────────────
-- Format:  { [id] = { version, installed_at, path } }
local _manifest = nil

local function manifest_path()
    return lpm.config.manifest_path
end

local function load_manifest()
    if _manifest then return _manifest end
    local f = io.open(manifest_path(), "r")
    if f then
        local src = f:read("*a")
        f:close()
        local fn, err = load("return " .. src)
        if fn then
            _manifest = fn() or {}
        else
            io.stderr:write("[LPM] Warning: corrupt manifest — " .. tostring(err) .. "\n")
            _manifest = {}
        end
    else
        _manifest = {}
    end
    return _manifest
end

local function save_manifest()
    local m = load_manifest()
    local lines = { "-- LUA-NAR LPM manifest  (auto-generated, do not edit)\n{" }
    for id, info in pairs(m) do
        lines[#lines+1] = string.format(
            "  [%q] = { version = %q, installed_at = %q, path = %q },",
            id, info.version, info.installed_at, info.path
        )
    end
    lines[#lines+1] = "}"
    local f, err = io.open(manifest_path(), "w")
    if not f then
        io.stderr:write("[LPM] Cannot write manifest: " .. tostring(err) .. "\n")
        return false
    end
    f:write(table.concat(lines, "\n"))
    f:close()
    return true
end

-- ── Registry loading ──────────────────────────────────────────
local _registry = nil

function lpm.load_registry(force_remote)
    if _registry and not force_remote then return _registry end

    -- Try local registry first (always works in-game and offline)
    local f = io.open(lpm.config.local_registry, "r")
    if f then
        local src = f:read("*a")
        f:close()
        local fn, err = load(src)
        if fn then
            _registry = fn()
            return _registry
        else
            io.stderr:write("[LPM] Local registry parse error: " .. tostring(err) .. "\n")
        end
    end

    -- Fallback: fetch remote (CLI only — needs luasocket or wget)
    if not IN_KSP then
        local ok, http = pcall(require, "socket.http")
        if ok then
            local body, code = http.request(lpm.config.registry_url)
            if body and code == 200 then
                local fn, err = load(body)
                if fn then
                    _registry = fn()
                    -- Cache it locally
                    local wf = io.open(lpm.config.local_registry, "w")
                    if wf then wf:write(body); wf:close() end
                    return _registry
                else
                    io.stderr:write("[LPM] Remote registry parse error: " .. tostring(err) .. "\n")
                end
            else
                io.stderr:write("[LPM] Failed to fetch registry (HTTP " .. tostring(code) .. ")\n")
            end
        else
            io.stderr:write("[LPM] No HTTP client available. Place lpm_registry.lua locally.\n")
        end
    end

    error("[LPM] Could not load registry. Ensure lpm/lpm_registry.lua exists.")
end

-- ── Helpers ───────────────────────────────────────────────────
local function find_package(id)
    local reg = lpm.load_registry()
    for _, pkg in ipairs(reg.packages) do
        if pkg.id == id then return pkg end
    end
    return nil
end

local function timestamp()
    return os.date and os.date("!%Y-%m-%dT%H:%M:%SZ") or "unknown"
end

local function ensure_dir(path)
    -- Portable mkdir -p equivalent (best-effort)
    local sep = package.config:sub(1,1)
    local parts = {}
    for p in path:gmatch("[^/\\]+") do parts[#parts+1] = p end
    local cur = ""
    for _, p in ipairs(parts) do
        cur = cur == "" and p or (cur .. sep .. p)
        os.execute("mkdir" .. (sep == "/" and " -p " or " ") .. '"' .. cur .. '"')
    end
end

-- Download a URL to a local path.
-- Returns true on success, false + error string on failure.
local function download(url, dest_path)
    -- Try LuaSocket first
    local ok, http = pcall(require, "socket.http")
    if ok then
        local ltn12 = require("ltn12")
        local f, err = io.open(dest_path, "wb")
        if not f then return false, "Cannot open " .. dest_path .. ": " .. tostring(err) end
        local _, code = http.request {
            url    = url,
            sink   = ltn12.sink.file(f),
        }
        if code == 200 then return true end
        os.remove(dest_path)
        return false, "HTTP " .. tostring(code)
    end

    -- Try curl / wget as fallback
    local cmd
    if os.execute("curl --version > /dev/null 2>&1") == 0 then
        cmd = string.format('curl -fsSL -o "%s" "%s"', dest_path, url)
    elseif os.execute("wget --version > /dev/null 2>&1") == 0 then
        cmd = string.format('wget -q -O "%s" "%s"', dest_path, url)
    else
        return false, "No HTTP client found. Install luasocket, curl, or wget."
    end

    local rc = os.execute(cmd)
    if rc == 0 then return true end
    return false, "Download command failed (exit " .. tostring(rc) .. ")"
end

-- ── Public API ────────────────────────────────────────────────

--- List all packages in the registry.
-- @param filter  optional category or tag string to filter by
-- @return array of package descriptors
function lpm.list(filter)
    local reg = lpm.load_registry()
    local m   = load_manifest()
    local out = {}
    for _, pkg in ipairs(reg.packages) do
        local match = true
        if filter and filter ~= "" then
            match = (pkg.category == filter) or
                    (pkg.id:find(filter, 1, true) ~= nil) or
                    (pkg.name:lower():find(filter:lower(), 1, true) ~= nil)
            if not match and pkg.tags then
                for _, t in ipairs(pkg.tags) do
                    if t == filter then match = true; break end
                end
            end
        end
        if match then
            local entry = {}
            for k, v in pairs(pkg) do entry[k] = v end
            entry.installed = (m[pkg.id] ~= nil)
            entry.installed_version = m[pkg.id] and m[pkg.id].version
            out[#out+1] = entry
        end
    end
    return out
end

--- Search packages by keyword.
function lpm.search(keyword)
    return lpm.list(keyword)
end

--- Return full info for one package.
function lpm.info(id)
    local pkg = find_package(id)
    if not pkg then return nil, "Package '" .. id .. "' not found in registry." end
    local m = load_manifest()
    pkg.installed         = (m[id] ~= nil)
    pkg.installed_version = m[id] and m[id].version
    return pkg
end

--- Install a package by id.
-- @param id        package identifier
-- @param opts      optional table: { force = true } to reinstall
-- @return true on success; false, error_string on failure
function lpm.install(id, opts)
    opts = opts or {}
    local pkg, err = lpm.info(id)
    if not pkg then return false, err end

    local m = load_manifest()
    if m[id] and not opts.force then
        return false, "Package '" .. id .. "' is already installed (v" .. m[id].version .. "). Use force=true to reinstall."
    end

    if pkg.builtin and not opts.force then
        return false, "'" .. id .. "' is a built-in script and ships with LUA-NAR already."
    end

    local dest_dir  = lpm.config.scripts_dir
    local dest_file = dest_dir .. "/" .. id .. ".lua"

    ensure_dir(dest_dir)

    local ok, dl_err = download(pkg.url, dest_file)
    if not ok then
        return false, "Download failed: " .. tostring(dl_err)
    end

    m[id] = {
        version      = pkg.version,
        installed_at = timestamp(),
        path         = dest_file,
    }
    save_manifest()

    return true
end

--- Remove an installed package.
function lpm.remove(id)
    local m = load_manifest()
    if not m[id] then
        return false, "Package '" .. id .. "' is not installed."
    end

    local path = m[id].path
    local ok, err = os.remove(path)
    if not ok then
        return false, "Could not delete " .. path .. ": " .. tostring(err)
    end

    m[id] = nil
    save_manifest()
    return true
end

--- Update all installed packages to the latest registry version.
-- @return table of { id, from_version, to_version, ok, err }
function lpm.update_all()
    local m = load_manifest()
    lpm.load_registry(true)   -- force-refresh from remote
    local results = {}
    for id, info in pairs(m) do
        local pkg = find_package(id)
        if pkg and pkg.version ~= info.version then
            local ok, err = lpm.install(id, { force = true })
            results[#results+1] = {
                id           = id,
                from_version = info.version,
                to_version   = pkg.version,
                ok           = ok,
                err          = err,
            }
        end
    end
    return results
end

-- ── CLI entry-point ───────────────────────────────────────────
-- Only runs when this file is executed directly (not require'd).
if arg and arg[0] and arg[0]:find("lpm%.lua$") then
    local cmd = arg[1] or "help"

    local function printf(fmt, ...) io.write(string.format(fmt, ...)) end

    if cmd == "list" then
        local filter = arg[2]
        local pkgs   = lpm.list(filter)
        printf("%-22s  %-10s  %-12s  %s\n", "ID", "VERSION", "CATEGORY", "DESCRIPTION")
        printf(string.rep("-", 80) .. "\n")
        for _, p in ipairs(pkgs) do
            local inst = p.installed and ("  [installed v" .. tostring(p.installed_version) .. "]") or ""
            printf("%-22s  %-10s  %-12s  %s%s\n",
                p.id, p.version, p.category, p.description, inst)
        end

    elseif cmd == "search" then
        local keyword = arg[2] or ""
        local pkgs = lpm.search(keyword)
        for _, p in ipairs(pkgs) do
            printf("  %s  —  %s\n", p.id, p.description)
        end

    elseif cmd == "info" then
        local id = arg[2]
        if not id then print("Usage: lua lpm.lua info <id>"); os.exit(1) end
        local p, err = lpm.info(id)
        if not p then print(err); os.exit(1) end
        printf("Name        : %s\n", p.name)
        printf("ID          : %s\n", p.id)
        printf("Version     : %s\n", p.version)
        printf("Author      : %s\n", p.author)
        printf("Category    : %s\n", p.category)
        printf("License     : %s\n", p.license)
        printf("Description : %s\n", p.description)
        printf("URL         : %s\n", p.url)
        printf("Installed   : %s\n", tostring(p.installed))
        if p.requires then printf("Requires    : %s\n", table.concat(p.requires, ", ")) end
        if p.tags     then printf("Tags        : %s\n", table.concat(p.tags, ", ")) end

    elseif cmd == "install" then
        local id = arg[2]
        if not id then print("Usage: lua lpm.lua install <id>"); os.exit(1) end
        local ok, err = lpm.install(id, { force = arg[3] == "--force" })
        if ok then
            print("[LPM] Installed: " .. id)
        else
            print("[LPM] Error: " .. tostring(err))
            os.exit(1)
        end

    elseif cmd == "remove" then
        local id = arg[2]
        if not id then print("Usage: lua lpm.lua remove <id>"); os.exit(1) end
        local ok, err = lpm.remove(id)
        if ok then
            print("[LPM] Removed: " .. id)
        else
            print("[LPM] Error: " .. tostring(err))
            os.exit(1)
        end

    elseif cmd == "update" then
        local results = lpm.update_all()
        if #results == 0 then
            print("[LPM] All packages are up to date.")
        else
            for _, r in ipairs(results) do
                if r.ok then
                    printf("[LPM] Updated %s: %s → %s\n", r.id, r.from_version, r.to_version)
                else
                    printf("[LPM] Failed  %s: %s\n", r.id, tostring(r.err))
                end
            end
        end

    else
        print("LUA-NAR LPM v" .. lpm._VERSION)
        print("")
        print("Usage:")
        print("  lua lpm.lua list    [category/tag]  — list all / filtered packages")
        print("  lua lpm.lua search  <keyword>       — search by keyword")
        print("  lua lpm.lua info    <id>             — show package details")
        print("  lua lpm.lua install <id> [--force]  — install a package")
        print("  lua lpm.lua remove  <id>             — remove an installed package")
        print("  lua lpm.lua update                  — update all installed packages")
        print("")
        print("Examples:")
        print("  lua lpm.lua list autopilot")
        print("  lua lpm.lua install orbital_autopilot")
        print("  lua lpm.lua info live_hud")
    end
end

return lpm
