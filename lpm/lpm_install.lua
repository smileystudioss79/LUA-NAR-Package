-- ============================================================
--  LUA-NAR  |  lpm/lpm_install.lua
--
--  Convenience wrapper — sources lpm.lua and runs an install.
--  Intended for use as a LuaRocks build step or a standalone
--  helper that third-party rock authors can call.
--
--  Usage from another Lua file:
--    local install = require("lua-nar.lpm_install")
--    install.run("orbital_autopilot",
--                { scripts_dir = "/path/to/GameData/LUA-NAR/Scripts" })
-- ============================================================

local lpm_install = {}

--- Run a single LPM install.
-- @param package_id  string  LPM package identifier
-- @param opts        table   { scripts_dir, registry_url, force }
-- @return boolean, string    (success, message)
function lpm_install.run(package_id, opts)
    opts = opts or {}

    local lpm = require("lua-nar.lpm")

    if opts.scripts_dir    then lpm.config.scripts_dir    = opts.scripts_dir    end
    if opts.registry_url   then lpm.config.registry_url   = opts.registry_url   end
    if opts.local_registry then lpm.config.local_registry = opts.local_registry end

    lpm.load_registry()

    local ok, err = lpm.install(package_id, { force = opts.force })
    if ok then
        return true, "Installed " .. package_id
    else
        return false, tostring(err)
    end
end

--- Install a list of packages.
-- @param ids   array of package id strings
-- @param opts  same as lpm_install.run opts
-- @return table of { id, ok, message }
function lpm_install.run_all(ids, opts)
    local results = {}
    for _, id in ipairs(ids) do
        local ok, msg = lpm_install.run(id, opts)
        results[#results+1] = { id = id, ok = ok, message = msg }
    end
    return results
end

return lpm_install
