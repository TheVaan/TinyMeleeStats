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
    -- WOW_PROJECT_MOP_CLASSIC = 16 (MoP Classic)
    
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
    elseif projectID == 16 then
        return "MOP_CLASSIC"
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
        elseif tocVersion >= 10000 then
            return "CLASSIC"
        else
            return "UNKNOWN"
        end
    end
end

local WoWVersion = GetWoWVersion()
Compat.WoWVersion = WoWVersion

-- Helper function to safely call APIs
local function SafeCall(func, ...)
    if func then
        local success, result = pcall(func, ...)
        if success then
            return result
        end
    end
    return nil
end

-- Attack Power
function Compat.GetAttackPower(isRanged)
    if isRanged then
        local base, buff, debuff = UnitRangedAttackPower("player")
        return (base or 0) + (buff or 0) + (debuff or 0)
    else
        local base, buff, debuff = UnitAttackPower("player")
        return (base or 0) + (buff or 0) + (debuff or 0)
    end
end

-- Crit Chance (melee)
function Compat.GetCritChance(isSpell)
    if isSpell then
        return 0
    else
        -- Melee crit
        local crit = SafeCall(GetCritChance, "player")
        return crit or 0
    end
end

-- Haste
function Compat.GetHaste()
    if WoWVersion == "RETAIL" or WoWVersion == "MOP_CLASSIC" then
        -- Retail/MoP: Use UnitSpellHaste directly (returns percentage as decimal, e.g. 0.15 for 15%)
        local hasteperc = UnitSpellHaste("player") or 0
        -- Calculate rating from percentage if needed
        local CR = SafeCall(GetCombatRating, CR_HASTE_SPELL) or 0
        local CRB = SafeCall(GetCombatRatingBonus, CR_HASTE_SPELL) or 0
        local haste = 0
        if CRB > 0 and CR > 0 and hasteperc > 0 then
            haste = CR / CRB * hasteperc
        end
        return math.floor(haste + 0.5), string.format("%.2f", hasteperc * 100)
    else
        -- Classic/TBC/Wrath: Use Combat Rating
        local CR = SafeCall(GetCombatRating, CR_HASTE_SPELL) or 0
        local CRB = SafeCall(GetCombatRatingBonus, CR_HASTE_SPELL) or 0
        local hasteperc = SafeCall(UnitSpellHaste, "player") or 0
        local haste = 0
        
        if CRB > 0 and CR > 0 and hasteperc > 0 then
            haste = CR / CRB * hasteperc
        end
        
        return math.floor(haste + 0.5), string.format("%.2f", hasteperc * 100)
    end
end

-- Weapon Speed
function Compat.GetWeaponSpeed()
    local mainSpeed, offSpeed = UnitAttackSpeed("player")
    return mainSpeed, offSpeed
end

-- Specialization
function Compat.GetSpecialization()
    if WoWVersion == "RETAIL" or WoWVersion == "MOP_CLASSIC" then
        return SafeCall(GetSpecialization)
    else
        return nil
    end
end

function Compat.GetSpecializationRole(spec)
    if WoWVersion == "RETAIL" or WoWVersion == "MOP_CLASSIC" then
        if spec then
            return SafeCall(GetSpecializationRole, spec, false, false)
        end
    end
    return nil
end

function Compat.GetActiveSpecGroup()
    if WoWVersion == "RETAIL" or WoWVersion == "MOP_CLASSIC" then
        return SafeCall(GetActiveSpecGroup) or 1
    else
        -- Classic: Always return 1 (no dual spec)
        return 1
    end
end

-- Mastery
function Compat.GetMastery()
    if WoWVersion == "RETAIL" or WoWVersion == "MOP_CLASSIC" then
        local mastery = SafeCall(GetMasteryEffect)
        if mastery then
            return string.format("%.2f", mastery)
        end
    end
    return nil
end

-- Versatility
function Compat.GetVersatility()
    if WoWVersion == "RETAIL" then
        -- Retail: Use GetCombatRating with versatility ID
        local rating = SafeCall(GetCombatRating, 29) or 0
        return string.format("%.2f", rating / 130)
    else
        return nil
    end
end

-- Check if API is available
function Compat.HasMastery()
    return WoWVersion == "RETAIL" or WoWVersion == "MOP_CLASSIC"
end

function Compat.HasVersatility()
    return WoWVersion == "RETAIL"
end

return Compat