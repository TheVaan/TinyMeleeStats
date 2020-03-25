-- TinyMeleeStats @project-version@ by @project-author@
-- Project revision: @project-revision@
--
-- Options.lua:
-- File revision: @file-revision@
-- Last modified: @file-date-iso@
-- Author: @file-author@

local debug = false
--@debug@
debug = true
--@end-debug@

if not TinyMeleeStats then return end

local AddonName = "TinyMeleeStats"
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)
local media = LibStub("LibSharedMedia-3.0")

TinyMeleeStats.fonteffects = {
	["none"] = L["NONE"],
	["OUTLINE"] = L["OUTLINE"],
	["THICKOUTLINE"] = L["THICKOUTLINE"]
}

function TinyMeleeStats:Options()
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
				type = 'execute',
				func = function()
						self.tmsframe:ClearAllPoints() self.tmsframe:SetPoint("CENTER", UIParent, "CENTER")
					end,
				disabled = function() return InCombatLockdown() end,
				order = 1,
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
				order = 2,
			},
			style = {
				name = STAT_CATEGORY_ATTRIBUTES,
				desc = L["Select which stats to show"],
				type = 'group',
				order = 2,
				args = {
					hader = {
						name = STAT_CATEGORY_ATTRIBUTES,
						type = 'header',
						order = 1,
					},
					spaceline3 = {
						name = "\n",
						type = 'description',
						order = 2,
					},
					ap = {
						name = STAT_ATTACK_POWER,
						desc = STAT_ATTACK_POWER.." "..show.."/"..hide,
						width = 'double',
						type = 'toggle',
						get = function() return self.db.char.Style.Ap end,
						set = function(info, value)
							if(value) then
								self.db.char.Style.Ap = true
							else
								self.db.char.Style.Ap = false
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 3,
					},
					apcolor = {
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
							self:SetStringColors()
							self:Stats()
						end,
						order = 4,
					},
					speed = {
						name = WEAPON_SPEED,
						desc = WEAPON_SPEED.." "..show.."/"..hide,
						width = 'double',
						type = 'toggle',
						get = function() return self.db.char.Style.Speed end,
						set = function(info, value)
							if(value) then
								self.db.char.Style.Speed = true
							else
								self.db.char.Style.Speed = false
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 5,
					},
					speedcolor = {
						name = "",
						desc = "",
						width = 'half',
						type = 'color',
						get = function()
							local c = self.db.char.Color.speed
							return c.r, c.g, c.b
						end,
						set = function(info, r, g, b)
							local c = self.db.char.Color.speed
							c.r, c.g, c.b = r, g, b
							self:SetStringColors()
							self:Stats()
						end,
						order = 6,
					},
					crit = {
						name = CRIT_CHANCE,
						desc = CRIT_CHANCE.." "..show.."/"..hide,
						width = 'double',
						type = 'toggle',
						get = function() return self.db.char.Style.Crit end,
						set = function(info, value)
							if(value) then
								self.db.char.Style.Crit = true
							else
								self.db.char.Style.Crit = false
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 7,
					},
					critcolor = {
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
							self:SetStringColors()
							self:Stats()
						end,
						order = 8,
					},
					header1 = {
						name = "",
						type = 'header',
						order = 11,
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
						order = 12,
					},
					resetrecords = {
						name = L["Reset records"],
						desc = L["Clears your current records"],
						width = 'normal',
						type = 'execute',
						func = function()
							local spec = "Spec"..GetActiveSpecGroup()
							for stat, num in pairs(self.defaults.char[spec]) do
								if string.find(stat,"Highest") or string.find(stat,"Fastest") then
									self.db.char[spec][stat] = num
								end
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 13,
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
							self:SetStringColors()
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 14,
					}
				}
			},
			text = {
				name = L["Text"],
				desc = L["Text settings"],
				type = 'group',
				order = 3,
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
							self.tmsframe:SetAlpha(self.db.char.outOfCombatAlpha)
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
							self.tmsframe:SetAlpha(self.db.char.inCombatAlpha)
						end,
						disabled = function() return InCombatLockdown() or self.db.char.FrameHide end,
						order = 2,
					},
					barfontsize = {
						name = L["Font size"],
						width = 'full',
						type = 'range',
						min = 6,
						max = 32,
						step = 1,
						get = function() return self.db.char.Size end,
						set = function(info, newValue)
							self.db.char.Size = newValue
							local font = media:Fetch("font", self.db.char.Font)
							for k, fontObject in pairs(self.strings) do
								fontObject:SetFont(font, self.db.char.Size, self.db.char.FontEffect)
							end
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
							for k, fontObject in pairs(self.strings) do
								fontObject:SetFont(font, self.db.char.Size, self.db.char.FontEffect)
							end
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
							for k, fontObject in pairs(self.strings) do
								fontObject:SetFont(font, self.db.char.Size, self.db.char.FontEffect)
							end
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
							self:SetTextAnchors()
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
						order = 8
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
						name = SOUND_LABEL,
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
				order = 3,
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
