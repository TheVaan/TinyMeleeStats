-- TinyMeleeStats @project-version@ by @project-author@
-- Project revision: @project-revision@
--
-- Options.lua:
-- File revision: @file-revision@
-- Last modified: @file-date-iso@
-- Author: @file-author@

if not TinyMeleeStats then return end

local AddonName = "TinyMeleeStats"
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)
local media = LibStub("LibSharedMedia-3.0")
local Compat = TinyMeleeStats.Compat

TinyMeleeStats.fonteffects = {
    ["none"] = L["NONE"],
    ["OUTLINE"] = L["OUTLINE"],
    ["THICKOUTLINE"] = L["THICKOUTLINE"]
}
TinyMeleeStats.RoleLocale = {
    melee = PLAYERSTAT_MELEE_COMBAT,
    tank = PLAYERSTAT_DEFENSES
}

function TinyMeleeStats:Options()
    local GetAddOnMetadata = GetAddOnMetadata or (C_AddOns and C_AddOns.GetAddOnMetadata)
    local show = string.lower(SHOW)
    local hide = string.lower(HIDE)
    local options = {
        name = AddonName.." "..GetAddOnMetadata(AddonName,"Version"),
        handler = TinyMeleeStats,
        type = 'group',
        args = {
            reset = {
                name = L["Reset position"],
                desc = L["Resets the frame's position"],
                type = "execute",
                func = function()
                        self.db.char.FrameHide = false
                        self.frame:ClearAllPoints() self.frame:SetPoint("CENTER", UIParent, "CENTER")
                    end,
                disabled = function() return InCombatLockdown() end,
                order = 1
            },
            lock = {
                name = L["Lock Frame"],
                desc = L["Locks the position of the text frame"],
                type = 'toggle',
                get = function() return self.db.char.FrameLocked end,
                set = function(info, value)
                    if(value) then
                        self.db.char.FrameLocked = true
                    else
                        self.db.char.FrameLocked = false
                    end
                    self:SetDragScript()
                end,
                disabled = function() return InCombatLockdown() end,
                order = 2
            },
            style = {
                name = STAT_CATEGORY_ATTRIBUTES,
                desc = L["Select which stats to show"],
                type = 'group',
                order = 10,
                args = {
                    hader = {
                        name = function() return TinyMeleeStats.RoleLocale[TinyMeleeStats.PlayerRole] or STAT_CATEGORY_ATTRIBUTES end,
                        type = 'header',
                        order = 1,
                    },
                    ap = {
                        hidden = function() return not self.defaults.char.Style.AP[TinyMeleeStats.PlayerRole] end,
                        name = STAT_ATTACK_POWER,
                        desc = STAT_ATTACK_POWER.." "..show.."/"..hide,
                        width = 'double',
                        type = 'toggle',
                        get = function() return self.db.char.Style.AP[TinyMeleeStats.PlayerRole] end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.Style.AP[TinyMeleeStats.PlayerRole] = true
                            else
                                self.db.char.Style.AP[TinyMeleeStats.PlayerRole] = false
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 4,
                    },
                    apcolor = {
                        hidden = function() return not self.defaults.char.Style.AP[TinyMeleeStats.PlayerRole] end,
                        name = "",
                        desc = "",
                        width = 'half',
                        type = 'color',
                        get = function()
                            local c = self.db.char.Color.ap
                            return c.r, c.g, c.b
                        end,
                        set = function(info, r, g, b)
                            local c = self.db.char.Color.ap
                            c.r, c.g, c.b = r, g, b
                            self:Stats()
                        end,
                        order = 5,
                    },
                    haste = {
                        hidden = function() return not self.defaults.char.Style.Haste[TinyMeleeStats.PlayerRole] end,
                        name = SPELL_HASTE,
                        desc = SPELL_HASTE.." "..show.."/"..hide.."\n"..L["(Only rating or percentage display possible!)"],
                        width = 'double',
                        type = 'toggle',
                        get = function() return self.db.char.Style.Haste[TinyMeleeStats.PlayerRole] end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.Style.Haste[TinyMeleeStats.PlayerRole] = true
                                self.db.char.Style.HastePerc[TinyMeleeStats.PlayerRole] = false
                            else
                                self.db.char.Style.Haste[TinyMeleeStats.PlayerRole] = false
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 6,
                    },
                    hastecolor = {
                        hidden = function() return not self.defaults.char.Style.Haste[TinyMeleeStats.PlayerRole] end,
                        name = "",
                        desc = "",
                        width = 'half',
                        type = 'color',
                        get = function()
                            local c = self.db.char.Color.haste
                            return c.r, c.g, c.b
                        end,
                        set = function(info, r, g, b)
                            local c = self.db.char.Color.haste
                            c.r, c.g, c.b = r, g, b
                            self:Stats()
                        end,
                        order = 7,
                    },
                    hasteperc = {
                        hidden = function() return not self.defaults.char.Style.Haste[TinyMeleeStats.PlayerRole] end,
                        name = L["Percent Haste"],
                        desc = L["Percent Haste"].." "..show.."/"..hide.."\n"..L["(Only rating or percentage display possible!)"],
                        width = 'full',
                        type = 'toggle',
                        get = function() return self.db.char.Style.HastePerc[TinyMeleeStats.PlayerRole] end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.Style.HastePerc[TinyMeleeStats.PlayerRole] = true
                                self.db.char.Style.Haste[TinyMeleeStats.PlayerRole] = false
                            else
                                self.db.char.Style.HastePerc[TinyMeleeStats.PlayerRole] = false
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 8,
                    },
                    speed = {
                        hidden = function() return not self.defaults.char.Style.Speed[TinyMeleeStats.PlayerRole] end,
                        name = WEAPON_SPEED,
                        desc = WEAPON_SPEED.." "..show.."/"..hide,
                        width = 'double',
                        type = 'toggle',
                        get = function() return self.db.char.Style.Speed[TinyMeleeStats.PlayerRole] end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.Style.Speed[TinyMeleeStats.PlayerRole] = true
                            else
                                self.db.char.Style.Speed[TinyMeleeStats.PlayerRole] = false
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 9,
                    },
                    speedcolor = {
                        hidden = function() return not self.defaults.char.Style.Speed[TinyMeleeStats.PlayerRole] end,
                        name = "",
                        desc = "",
                        width = 'half',
                        type = 'color',
                        get = function()
                            local c = self.db.char.Color.haste
                            return c.r, c.g, c.b
                        end,
                        set = function(info, r, g, b)
                            local c = self.db.char.Color.haste
                            c.r, c.g, c.b = r, g, b
                            self:Stats()
                        end,
                        order = 10,
                    },
                    crit = {
                        hidden = function() return not self.defaults.char.Style.Crit[TinyMeleeStats.PlayerRole] end,
                        name = CRIT_CHANCE,
                        desc = CRIT_CHANCE.." "..show.."/"..hide,
                        width = 'double',
                        type = 'toggle',
                        get = function() return self.db.char.Style.Crit[TinyMeleeStats.PlayerRole] end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.Style.Crit[TinyMeleeStats.PlayerRole] = true
                            else
                                self.db.char.Style.Crit[TinyMeleeStats.PlayerRole] = false
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 17,
                    },
                    critcolor = {
                        hidden = function() return not self.defaults.char.Style.Crit[TinyMeleeStats.PlayerRole] end,
                        name = "",
                        desc = "",
                        width = 'half',
                        type = 'color',
                        get = function()
                            local c = self.db.char.Color.crit
                            return c.r, c.g, c.b
                        end,
                        set = function(info, r, g, b)
                            local c = self.db.char.Color.crit
                            c.r, c.g, c.b = r, g, b
                            self:Stats()
                        end,
                        order = 18,
                    },
                    mastery = {
                        hidden = function() return not Compat.HasMastery() or not self.defaults.char.Style.Mastery[TinyMeleeStats.PlayerRole] end,
                        name = STAT_MASTERY,
                        desc = STAT_MASTERY.." "..show.."/"..hide,
                        width = 'double',
                        type = 'toggle',
                        get = function() return self.db.char.Style.Mastery[TinyMeleeStats.PlayerRole] end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.Style.Mastery[TinyMeleeStats.PlayerRole] = true
                            else
                                self.db.char.Style.Mastery[TinyMeleeStats.PlayerRole] = false
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 19,
                    },
                    masterycolor = {
                        hidden = function() return not Compat.HasMastery() or not self.defaults.char.Style.Mastery[TinyMeleeStats.PlayerRole] end,
                        name = "",
                        desc = "",
                        width = 'half',
                        type = 'color',
                        get = function()
                            local c = self.db.char.Color.mastery
                            return c.r, c.g, c.b
                        end,
                        set = function(info, r, g, b)
                            local c = self.db.char.Color.mastery
                            c.r, c.g, c.b = r, g, b
                            self:Stats()
                        end,
                        order = 20,
                    },
                    versatility = {
                        hidden = function() return not Compat.HasVersatility() end,
                        name = STAT_VERSATILITY,
                        desc = STAT_VERSATILITY.." "..show.."/"..hide,
                        width = 'double',
                        type = 'toggle',
                        get = function() return self.db.char.Style.Versatility[TinyMeleeStats.PlayerRole] end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.Style.Versatility[TinyMeleeStats.PlayerRole] = true
                            else
                                self.db.char.Style.Versatility[TinyMeleeStats.PlayerRole] = false
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 21,
                    },
                    versatilitycolor = {
                        hidden = function() return not Compat.HasVersatility() or not self.defaults.char.Style.Versatility[TinyMeleeStats.PlayerRole] end,
                        name = "",
                        desc = "",
                        width = 'half',
                        type = 'color',
                        get = function()
                            local c = self.db.char.Color.versatility
                            return c.r, c.g, c.b
                        end,
                        set = function(info, r, g, b)
                            local c = self.db.char.Color.versatility
                            c.r, c.g, c.b = r, g, b
                            self:Stats()
                        end,
                        order = 22,
                    },
                    header1 = {
                        name = "",
                        type = 'header',
                        order = 31,
                    },
                    showrecords = {
                        name = L["Show records"],
                        desc = L["Whether or not to show record values"],
                        width = 'full',
                        type = 'toggle',
                        get = function() return self.db.char.Style.showRecords end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.Style.showRecords = true
                            else
                                self.db.char.Style.showRecords = false
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 32,
                    },
                    showrecordsldb = {
                        name = L["Show records on Broker"],
                        desc = L["Whether or not to show record values on Broker"],
                        width = 'full',
                        type = 'toggle',
                        get = function() return self.db.char.Style.showRecordsLDB end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.Style.showRecordsLDB = true
                            else
                                self.db.char.Style.showRecordsLDB = false
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 33,
                    },
                    resetrecords = {
                        name = L["Reset records"],
                        desc = L["Clears your current records"],
                        type = 'execute',
                        func = function()
                            local spec = "Spec"..TinyMeleeStats.Compat.GetActiveSpecGroup()
                            for stat, num in pairs(self.defaults.char[spec]) do
                                self.db.char[spec][stat] = num
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 34,
                    },
                    resetcolor = {
                        name = L["Reset colors"],
                        desc = L["Clears your current color settings"],
                        type = 'execute',
                        func = function()
                            for stat, c in pairs(self.defaults.char.Color) do
                                self.db.char.Color[stat].r = c.r
                                self.db.char.Color[stat].g = c.g
                                self.db.char.Color[stat].b = c.b
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 35,
                    }
                }
            },
            text = {
                name = L["Text"],
                desc = L["Text settings"],
                type = 'group',
                order = 11,
                args = {
                    oocalpha = {
                        name = L["Text Alpha"].." "..L["out of combat"],
                        desc = L["Alpha of the text"].." ("..L["out of combat"]..")",
                        width = 'full',
                        type = 'range',
                        min = 0,
                        max = 1,
                        step = 0.01,
                        isPercent = true,
                        get = function() return self.db.char.outOfCombatAlpha end,
                        set = function(info, newValue)
                            self.db.char.outOfCombatAlpha = newValue
                            self.frame:SetAlpha(self.db.char.outOfCombatAlpha)
                        end,
                        disabled = function() return InCombatLockdown() or self.db.char.FrameHide end,
                        order = 1,
                    },
                    icalpha = {
                        name = L["Text Alpha"].." "..L["in combat"],
                        desc = L["Alpha of the text"].." ("..L["in combat"]..")",
                        width = 'full',
                        type = 'range',
                        min = 0,
                        max = 1,
                        step = 0.01,
                        isPercent = true,
                        get = function() return self.db.char.inCombatAlpha end,
                        set = function(info, newValue)
                            self.db.char.inCombatAlpha = newValue
                            self.frame:SetAlpha(self.db.char.inCombatAlpha)
                        end,
                        disabled = function() return InCombatLockdown() or self.db.char.FrameHide end,
                        order = 2,
                    },
                    barfontsize = {
                        name = FONT_SIZE,
                        width = 'full',
                        type = 'range',
                        min = 6,
                        max = 32,
                        step = 1,
                        get = function() return self.db.char.Size end,
                        set = function(info, newValue)
                            self.db.char.Size = newValue
                            local font = media:Fetch("font", self.db.char.Font)
                            self.string:SetFont(font, self.db.char.Size, self.db.char.FontEffect)
                            self:InitializeFrame()
                        end,
                        disabled = function() return InCombatLockdown() or self.db.char.FrameHide end,
                        order = 3,
                    },
                    font = {
                        name = L["Font"],
                        type = 'select',
                        get = function() return self.db.char.Font end,
                        set = function(info, newValue)
                            self.db.char.Font = newValue
                            local font = media:Fetch("font", self.db.char.Font)
                            self.string:SetFont(font, self.db.char.Size, self.db.char.FontEffect)
                        end,
                        values = self.fonts,
                        disabled = function() return InCombatLockdown() or self.db.char.FrameHide end,
                        order = 4,
                    },
                    fonteffect = {
                        name = L["Font border"],
                        type = 'select',
                        get = function() return self.db.char.FontEffect end,
                        set = function(info, newValue)
                            self.db.char.FontEffect = newValue
                            local font = media:Fetch("font", self.db.char.Font)
                            self.string:SetFont(font, self.db.char.Size, self.db.char.FontEffect)
                        end,
                        values = self.fonteffects,
                        disabled = function() return InCombatLockdown() or self.db.char.FrameHide end,
                        order = 5,
                    },
                    vertical = {
                        name = L["Display stats vertically"],
                        desc = L["Whether or not to show stats vertically"],
                        width = 'full',
                        type = 'toggle',
                        get = function() return self.db.char.Style.vertical end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.Style.vertical = true
                            else
                                self.db.char.Style.vertical = false
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() or self.db.char.FrameHide end,
                        order = 6,
                    },
                    labels = {
                        name = L["Show labels"],
                        desc = L["Whether or not to show labels for each stat"],
                        width = 'full',
                        type = 'toggle',
                        get = function() return self.db.char.Style.labels end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.Style.labels = true
                            else
                                self.db.char.Style.labels = false
                            end
                            self:Stats()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 7,
                    },
                    hide = {
                        name = L["Hide Frame"],
                        desc = L["Hide the text frame (to show stats only in the LDB text field)"],
                        type = 'toggle',
                        get = function() return self.db.char.FrameHide end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.FrameHide = true
                            else
                                self.db.char.FrameHide = false
                            end
                            self:SetFrameVisible()
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 8,
                    },
                    spaceline4 = {
                        name = " ",
                        type = 'description',
                        order = 20,
                    },
                    record = {
                        name = L["Announce records"],
                        desc = L["Whether or not to display a message when a record is broken"],
                        type = 'toggle',
                        get = function() return self.db.char.RecordMsg end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.RecordMsg = true
                            else
                                self.db.char.RecordMsg = false
                            end
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 21,
                    },
                    recordSound = {
                        name = L["Play sound on record"],
                        desc = L["Whether or not to play a sound when a record is broken"],
                        type = 'toggle',
                        get = function() return self.db.char.RecordSound end,
                        set = function(info, value)
                            if(value) then
                                self.db.char.RecordSound = true
                            else
                                self.db.char.RecordSound = false
                            end
                        end,
                        disabled = function() return InCombatLockdown() end,
                        order = 22,
                    },
                    spaceline5 = {
                        name = " ",
                        type = 'description',
                        order = 30,
                    },
                    selectSound = {
                        name = L["Sound"],
                        type = 'select',
                        dialogControl = "LSM30_Sound",
                        get = function() return self.db.char.RecordSoundFile end,
                        set = function(info, value) self.db.char.RecordSoundFile = value end,
                        values = AceGUIWidgetLSMlists.sound,
                        disabled = function() return InCombatLockdown() end,
                        order = 31,
                    },
                }
            },
            XStats = {
                name = "TinyXStats",
                desc = "TinyXStats settings",
                type = 'group',
                order = 12,
                args = {
                    des1 = {
                        name = "|cFF00ff00"..L["Please use TinyXStats, it's an all in one Stats Addon."].."|r",
                        type = 'description',
                        order = 1,
                    },
                    spaceline1 = {
                        name = " ",
                        type = 'description',
                        order = 2,
                    },
                    des2 = {
                        name = "",
                        desc = "",
                        type = 'input',
                        width = "full",
                        get = function() return "https://curseforge.com/wow/addons/tinystats" end,
                        set = function(_,val) end,
                        order = 3,
                    },
                    spaceline2 = {
                        name = " ",
                        type = 'description',
                        order = 4,
                    },
                    des3 = {
                        name = "|cFF00ff00"..L["In future this will be updated first."].."|r",
                        type = 'description',
                        order = 5,
                    },
                    spaceline3 = {
                        name = " ",
                        type = 'description',
                        order = 6,
                    },
                    XHide = {
                        name = "Hide Message",
                        desc = "Hide Message",
                        width = 'full',
                        type = 'toggle',
                        get = function() return self.Globaldb.NoXStatsPrint end,
                        set = function() self.Globaldb.NoXStatsPrint = not self.Globaldb.NoXStatsPrint end,
                        order = 7,
                    },
                }
            },
        }
    }

    return options
end
