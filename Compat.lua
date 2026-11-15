-- TinyMeleeStats Compatibility Layer
-- Provides version-specific API wrappers for different WoW versions
-- Only contains functions used by TinyMeleeStats (melee-related stats)

local Compat = {}
TinyMeleeStats = TinyMeleeStats or {}
TinyMeleeStats.Compat = Compat

-- Version detection
local function GetWoWVersion()
    local version, build, date, tocVersion = GetBuildInfo()
    local projectID = WOW_PROJECT_ID or 0

    -- WOW_PROJECT_ID constants:
    -- WOW_PROJECT_MAINLINE = 1 (Retail)
    -- WOW_PROJECT_CLASSIC = 2 (Classic)
    -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5 (TBC Classic)
    -- WOW_PROJECT_WRATH_CLASSIC = 11 (Wrath Classic)
    -- WOW_PROJECT_CATACLYSM_CLASSIC = 14 (Cata Classic)
    -- WOW_PROJECT_MOP_CLASSIC = 16 (MoP Classic, older clients)
    -- WOW_PROJECT_CAMELOT = 18 (WoW Forever)
    -- WOW_PROJECT_MISTS_CLASSIC = 19 (MoP Classic)

    if projectID == 1 then
        return "RETAIL"
    elseif projectID == 2 then
        return "CLASSIC"
    elseif projectID == 5 then
        return "TBC_CLASSIC"
    elseif projectID == 11 then
        return "WRATH_CLASSIC"
    elseif projectID == 14 then
        return "CATA_CLASSIC"
    elseif projectID == 16 or projectID == 19 then
        return "MOP_CLASSIC"
    elseif projectID == 18 then
        return "FOREVER"
    else
        -- Fallback: try to detect from tocVersion
        if tocVersion >= 120000 then
            return "RETAIL"
        elseif tocVersion >= 50000 then
            return "MOP_CLASSIC"
        elseif tocVersion >= 40000 then
            return "CATA_CLASSIC"
        elseif tocVersion >= 30000 then
            return "WRATH_CLASSIC"
        elseif tocVersion >= 20000 then
            return "TBC_CLASSIC"
        elseif tocVersion >= 16000 then
            return "FOREVER"
        elseif tocVersion >= 10000 then
            return "CLASSIC"
        else
            return "UNKNOWN"
        end
    end
end

local WoWVersion = GetWoWVersion()
Compat.WoWVersion = WoWVersion

-- Specializations exist on these clients only
local HAS_SPEC = WoWVersion == "RETAIL" or WoWVersion == "MOP_CLASSIC" or WoWVersion == "FOREVER"

-- Secret values (Midnight and WoW Forever): stat getters can return values
-- that addons must not compare or calculate with. issecretvalue does not
-- exist on older clients.
local issecretvalue = issecretvalue or function() return false end

-- Returns nil if the arguments of pcall failed or any result is secret
local function CheckResults(ok, ...)
    if not ok then
        return nil
    end
    for i = 1, select("#", ...) do
        if issecretvalue((select(i, ...))) then
            return nil
        end
    end
    return ...
end

-- Helper function to safely call APIs, returns the first result
-- (nil if the function is missing, errors or returns a secret value)
local function SafeCall(func, ...)
    if func then
        return (CheckResults(pcall(func, ...)))
    end
    return nil
end

-- Same as SafeCall, but returns all results
local function SafeCallMulti(func, ...)
    if func then
        return CheckResults(pcall(func, ...))
    end
    return nil
end

-- Remembers the last readable results per key. While a stat is unreadable
-- (secret in combat) the last known values are returned instead.
local lastKnown = {}
local function Keep(key, ...)
    if (...) ~= nil then
        lastKnown[key] = { n = select("#", ...), ... }
        return ...
    end
    local last = lastKnown[key]
    if last then
        return unpack(last, 1, last.n)
    end
    return ...
end

-- True while unit stats are returned as secret values
function Compat.StatsAreSecret()
    local func = C_Secrets and C_Secrets.ShouldUnitStatsBeSecret
    return func and SafeCall(func) or false
end

-- Looks up an API in C_SpecializationInfo first, then as a legacy global
local function GetSpecAPI(name)
    local info = C_SpecializationInfo
    return (info and info[name]) or _G[name]
end

-- Attack Power
function Compat.GetAttackPower(isRanged)
    local func = isRanged and UnitRangedAttackPower or UnitAttackPower
    local base, buff, debuff = Keep(isRanged and "rangedap" or "ap", SafeCallMulti(func, "player"))
    return (base or 0) + (buff or 0) + (debuff or 0)
end

-- Crit Chance (melee)
function Compat.GetCritChance(isSpell)
    if isSpell then
        return 0
    else
        -- Melee crit
        return Keep("meleecrit", SafeCall(GetCritChance, "player")) or 0
    end
end

-- Haste
function Compat.GetHaste()
    -- UnitSpellHaste returns a percentage, e.g. 15.5 for 15.5% haste
    local hasteperc = Keep("hasteperc", SafeCall(UnitSpellHaste, "player")) or 0
    -- Haste rating that corresponds to the total haste percentage
    local CR = Keep("hasterating", SafeCall(GetCombatRating, CR_HASTE_SPELL)) or 0
    local CRB = Keep("hastebonus", SafeCall(GetCombatRatingBonus, CR_HASTE_SPELL)) or 0
    local haste = 0
    if CRB > 0 and CR > 0 and hasteperc > 0 then
        haste = CR / CRB * hasteperc
    end
    return math.floor(haste + 0.5), string.format("%.2f", hasteperc)
end

-- Weapon Speed
function Compat.GetWeaponSpeed()
    local mainSpeed, offSpeed = Keep("weaponspeed", SafeCallMulti(UnitAttackSpeed, "player"))
    return mainSpeed, offSpeed
end

-- Specialization
function Compat.GetSpecialization()
    if HAS_SPEC then
        return SafeCall(GetSpecAPI("GetSpecialization"))
    else
        return nil
    end
end

-- Enum.LFGRole values as returned by GetSpecializationRoleEnum
local ROLE_BY_ENUM = { [0] = "TANK", [1] = "HEALER", [2] = "DAMAGER" }
if Enum and Enum.LFGRole then
    ROLE_BY_ENUM = {
        [Enum.LFGRole.Tank] = "TANK",
        [Enum.LFGRole.Healer] = "HEALER",
        [Enum.LFGRole.Damage] = "DAMAGER",
    }
end

function Compat.GetSpecializationRole(spec)
    if HAS_SPEC and spec then
        local role = SafeCall(GetSpecAPI("GetSpecializationRole"), spec, false, false)
        if role then
            return role
        end
        role = ROLE_BY_ENUM[SafeCall(GetSpecAPI("GetSpecializationRoleEnum"), spec)]
        if role then
            return role
        end
        -- 5th result of GetSpecializationInfo is the role
        return (select(5, SafeCallMulti(GetSpecAPI("GetSpecializationInfo"), spec)))
    end
    return nil
end

function Compat.GetActiveSpecGroup()
    if HAS_SPEC then
        local group = SafeCall(GetSpecAPI("GetActiveSpecGroup"))
        if group == 1 or group == 2 then
            return group
        end
    end
    -- Classic: Always return 1 (no dual spec)
    return 1
end

-- Mastery
function Compat.GetMastery()
    if Compat.HasMastery() then
        local mastery = Keep("mastery", SafeCall(GetMasteryEffect))
        if mastery then
            return string.format("%.2f", mastery)
        end
    end
    return nil
end

-- Versatility
function Compat.GetVersatility()
    if Compat.HasVersatility() then
        -- Retail: Use GetCombatRating with versatility ID
        local rating = Keep("versatility", SafeCall(GetCombatRating, 29)) or 0
        return string.format("%.2f", rating / 130)
    else
        return nil
    end
end

-- Check if API is available
function Compat.HasMastery()
    -- WoW Forever has no mastery
    return WoWVersion == "RETAIL" or WoWVersion == "MOP_CLASSIC"
end

function Compat.HasVersatility()
    -- WoW Forever has no versatility
    return WoWVersion == "RETAIL"
end

return Compat
