-- TinyMeleeStats @project-version@ by @project-author@
-- Project revision: @project-revision@
--
-- TinyMeleeStats.lua:
-- File revision: @file-revision@
-- Last modified: @file-date-iso@
-- Author: @file-author@

local debug = false
--@debug@
debug = true
--@end-debug@

local AddonName = "TinyMeleeStats"
local AceAddon = LibStub("AceAddon-3.0")
local media = LibStub("LibSharedMedia-3.0")
TinyMeleeStats = AceAddon:NewAddon(AddonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local ldb = LibStub("LibDataBroker-1.1")
local TMSBroker = ldb:NewDataObject(AddonName, {
    type = "data source",
    label = AddonName,
    icon = "Interface\\Icons\\Ability_Racial_ShadowMeld",
    text = "--"
    })

local isInFight = false
local SpecChangedPause = GetTime()

local backdrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "",
    tile = false, tileSize = 16, edgeSize = 0,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

local function Debug(...)
    if debug then
        local text = ""
        for i = 1, select("#", ...) do
            if type(select(i, ...)) == "boolean" then
                text = text..(select(i, ...) and "true" or "false").." "
            else
                text = text..(select(i, ...) or "nil").." "
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFCCCC99"..AddonName..": |r"..text)
    end
end

TinyMeleeStats.fonts = {}

TinyMeleeStats.defaults = {
    char = {
        Font = "Vera",
        FontEffect = "none",
        Size = 12,
        FrameLocked = true,
        yPosition = 200,
        xPosition = 200,
        inCombatAlpha = 1,
        outOfCombatAlpha = .3,
        RecordMsg = true,
        RecordSound = false,
        RecordSoundFile = "Fanfare3",
        Spec1 = {
            HighestAp = 0,
            HighestCrit = "0.00",
            HighestHaste = 0,
            HighestHastePerc = "0.00",
            FastestMh = 500,
            FastestOh = 500,
            HighestMastery = "0.00",
            HighestVersatility = "0.00"
        },
        Spec2 = {
            HighestAp = 0,
            HighestCrit = "0.00",
            HighestHaste = 0,
            HighestHastePerc = "0.00",
            FastestMh = 500,
            FastestOh = 500,
            HighestMastery = "0.00",
            HighestVersatility = "0.00"
        },
        Style = {
            AP = {
                melee = true,
                tank = true
            },
            Crit = {
                melee = true,
                tank = true
            },
            Haste = {
                melee = true,
                tank = true
            },
            HastePerc = {},
            Speed = {
                melee = true,
                tank = true
            },
            Mastery = {
                melee = true,
                tank = true
            },
            Versatility = {
                melee = true,
                tank = true
            },
            showRecords = true,
            showRecordsLDB = true,
            vertical = false,
            labels = false
        },
        Color = {
            ap = {
                r = 1,
                g = 0.803921568627451,
                b = 0
            },
            crit = {
                r = 1.0,
                g = 0,
                b = 0.6549019607843137
            },
            haste = {
                r = 0,
                g = 0.611764705882353,
                b = 1.0
            },
            mastery = {
                r = 1.0,
                g = 1.0,
                b = 1.0
            },
            versatility = {
                r = 1,
                g = 0.72156862745098,
                b = 0.0313725490196078
            }
        },
        DBver = 3
    }
}

TinyMeleeStats.frame = CreateFrame("Frame",AddonName.."Frame",UIParent)
TinyMeleeStats.frame:SetWidth(100)
TinyMeleeStats.frame:SetHeight(15)
TinyMeleeStats.frame:SetFrameStrata("BACKGROUND")
TinyMeleeStats.frame:EnableMouse(true)
TinyMeleeStats.frame:RegisterForDrag("LeftButton")

TinyMeleeStats.string = TinyMeleeStats.frame:CreateFontString()

function TinyMeleeStats:SetDragScript()
    if self.db.char.FrameLocked then
        self.frame:SetMovable(false)
        fixed = "|cffFF0000"..L["Text is fixed. Uncheck Lock Frame in the options to move!"].."|r"
        self.frame:SetScript("OnDragStart", function() DEFAULT_CHAT_FRAME:AddMessage(fixed) end)
        self.frame:SetScript("OnEnter", nil)
        self.frame:SetScript("OnLeave", nil)
    else
        self.frame:SetMovable(true)
        self.frame:SetScript("OnDragStart", function() self.frame:StartMoving() end)
        self.frame:SetScript("OnDragStop", function() self.frame:StopMovingOrSizing() self.db.char.xPosition = self.frame:GetLeft() self.db.char.yPosition = self.frame:GetBottom() end)
        self.frame:SetScript("OnEnter", function() self.frame:SetBackdrop(backdrop) end)
        self.frame:SetScript("OnLeave", function() self.frame:SetBackdrop(nil) end)
    end
end

function TinyMeleeStats:SetFrameVisible()

    if self.db.char.FrameHide then
        self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -1000, -1000)
    else
        self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.char.xPosition, self.db.char.yPosition)
    end

end

function TinyMeleeStats:InitializeFrame()
    local font = media:Fetch("font", self.db.char.Font)
    self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.char.xPosition, self.db.char.yPosition)
    self.string:SetPoint("TOPLEFT", self.frame,"TOPLEFT", 0, 0)
    self.string:SetFontObject(GameFontNormal)
    if not self.string:SetFont(font, self.db.char.Size, self.db.char.FontEffect) then
        self.string:SetFont("Fonts\\FRIZQT__.TTF", self.db.char.Size, self.db.char.FontEffect)
    end
    self.string:SetJustifyH("LEFT")
    self.string:SetJustifyV("MIDDLE")

    self:SetDragScript()
    self:SetFrameVisible()
    self:Stats()
end

function TinyMeleeStats:OnInitialize()
    local AceConfigReg = LibStub("AceConfigRegistry-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")

    local GetAddOnMetadata = GetAddOnMetadata or (C_AddOns and C_AddOns.GetAddOnMetadata)
    
    self.db = LibStub("AceDB-3.0"):New(AddonName.."DB", TinyMeleeStats.defaults, "char")
    LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, self:Options(), "tmscmd")
    media.RegisterCallback(self, "LibSharedMedia_Registered")

    self:RegisterChatCommand("tms", function() AceConfigDialog:Open(AddonName) end)
    self:RegisterChatCommand(AddonName, function() AceConfigDialog:Open(AddonName) end)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(AddonName, AddonName)
    self.db:RegisterDefaults(self.defaults)

    local version = GetAddOnMetadata(AddonName,"Version")
    local loaded = L["Open the configuration menu with /tms or /TinyMeleeStats"].."|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd700"..AddonName.." |cff00ff00~v"..version.."~|cffffd700: "..loaded)

    TMSBroker.OnClick = function(frame, button)	AceConfigDialog:Open(AddonName)	end
    TMSBroker.OnTooltipShow = function(tt) tt:AddLine(AddonName) end

    TinyMStatsDB = TinyMStatsDB or {}
    self.Globaldb = TinyMStatsDB
end

function TinyMeleeStats:OnEnable()
    self:LibSharedMedia_Registered()
    self:InitializeFrame()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
    self:RegisterEvent("UNIT_AURA", "OnEvent")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnEvent")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED", "OnEvent")
    self:RegisterEvent("UNIT_LEVEL", "OnEvent")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
    self:RegisterEvent("PLAYER_TALENT_UPDATE", "OnEvent")
end

function TinyMeleeStats:LibSharedMedia_Registered()
    media:Register("font", "BaarSophia", [[Interface\Addons\TinyMeleeStats\Fonts\BaarSophia.ttf]])
    media:Register("font", "LucidaSD", [[Interface\Addons\TinyMeleeStats\Fonts\LucidaSD.ttf]])
    media:Register("font", "Teen", [[Interface\Addons\TinyMeleeStats\Fonts\Teen.ttf]])
    media:Register("font", "Vera", [[Interface\Addons\TinyMeleeStats\Fonts\Vera.ttf]])
    media:Register("sound", "Fanfare1", [[Interface\Addons\TinyMeleeStats\Sound\Fanfare.ogg]])
    media:Register("sound", "Fanfare2", [[Interface\Addons\TinyMeleeStats\Sound\Fanfare2.ogg]])
    media:Register("sound", "Fanfare3", [[Interface\Addons\TinyMeleeStats\Sound\Fanfare3.ogg]])

    for k, v in pairs(media:List("font")) do
        self.fonts[v] = v
    end
end

-- Hook SetActiveSpecGroup if it exists
if SetActiveSpecGroup then
    local orgSetActiveSpecGroup = SetActiveSpecGroup
    function SetActiveSpecGroup(...)
        SpecChangedPause = GetTime() + 60
        TinyMeleeStats:ScheduleTimer("Stats", 62)
        Debug("Set SpecChangedPause")
        return orgSetActiveSpecGroup(...)
    end
end

function TinyMeleeStats:OnEvent(event, arg1)
    if (event == "PLAYER_ENTERING_WORLD") then
        self:UseTinyXStats()
    end
    if ((event == "PLAYER_REGEN_ENABLED") or (event == "PLAYER_ENTERING_WORLD")) then
        self.frame:SetAlpha(self.db.char.outOfCombatAlpha)
        isInFight = false
    end
    if (event == "PLAYER_REGEN_DISABLED") then
        self.frame:SetAlpha(self.db.char.inCombatAlpha)
        isInFight = true
    end
    if (event == "UNIT_AURA" and arg1 == "player") then
        self:ScheduleTimer("Stats", .8)
    end
    if (event ~= "UNIT_AURA") then
        self:Stats()
    end

end

function TinyMeleeStats:UseTinyXStats()

    if self.Globaldb.NoXStatsPrint then return end

    local text = {}
    text[1] = "|cFF00ff00"..L["Please use TinyXStats, it's an all in one Stats Addon."].."|r"
    text[2] = "https://curseforge.com/wow/addons/tinystats"
    text[3] = "|cFF00ff00"..L["In future this will be updated first."].."|r"
    for i = 1, 3 do
        DEFAULT_CHAT_FRAME:AddMessage("|cFFCCCC99"..AddonName..": |r"..text[i])
    end

end

local function HexColor(stat)

    local c = TinyMeleeStats.db.char.Color[stat]
    local hexColor = string.format("|cff%2X%2X%2X", 255*c.r, 255*c.g, 255*c.b)
    return hexColor

end

local function MsgRecord(name,value)
    if (TinyMeleeStats.db.char.RecordMsg == true) then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000"..L["Record broken!"]..": "..name..": |c00ffef00"..value.."|r")
        return true
    end
end

local function SetRecordLabel(label)
    if not TinyMeleeStats.db.char.Style.labels or TinyMeleeStats.db.char.Style.vertical then
        label = ""
    end
    return label
end

local function SetLabel(color,label)
    local style = TinyMeleeStats.db.char.Style
    TinyMeleeStats.CString = TinyMeleeStats.CString..HexColor(color)..(style.labels and label or "")
    TinyMeleeStats.RString = TinyMeleeStats.RString..HexColor(color)..SetRecordLabel(label)
    TinyMeleeStats.ldbString = TinyMeleeStats.ldbString..HexColor(color)..(style.labels and label or "")
    TinyMeleeStats.ldbRecord = TinyMeleeStats.ldbRecord..HexColor(color)..(style.labels and label or "")
end

local function SetValues(Value,Highest)
    TinyMeleeStats.CString = TinyMeleeStats.CString..Value
    TinyMeleeStats.RString = TinyMeleeStats.RString..Highest
    TinyMeleeStats.ldbString = TinyMeleeStats.ldbString..Value.." "
    TinyMeleeStats.ldbRecord = TinyMeleeStats.ldbRecord..Highest.." "
end

local function FormatRString()
    if TinyMeleeStats.db.char.Style.vertical then
        if TinyMeleeStats.db.char.Style.showRecords then
            TinyMeleeStats.CString = TinyMeleeStats.CString.." ("..TinyMeleeStats.RString..")|n"
            TinyMeleeStats.RString = ""
        else
            TinyMeleeStats.CString = TinyMeleeStats.CString.."|n"
            TinyMeleeStats.RString = ""
        end
    else
        TinyMeleeStats.CString = TinyMeleeStats.CString.." "
        TinyMeleeStats.RString = TinyMeleeStats.RString.." "
    end
end

local function GetAttackPower()
    return TinyMeleeStats.Compat.GetAttackPower(false)
end

local function GetCrit()
    return TinyMeleeStats.Compat.GetCritChance(false)
end

local function GetHaste()
    local haste, hasteperc = TinyMeleeStats.Compat.GetHaste()
    return string.format("%.0f", haste), hasteperc
end

local function GetWeaponSpeed(spec)
    local speed, fastestSpeed = 500, 500
    local mainSpeed, offSpeed = TinyMeleeStats.Compat.GetWeaponSpeed()
    if (offSpeed == nil) then
        if (mainSpeed and mainSpeed > 0) then
            mainSpeed = string.format("%.2f", mainSpeed)
            speed = mainSpeed
            fastestSpeed = TinyMeleeStats.db.char[spec].FastestMh
        else
            speed = 500
            mainSpeed = 500
        end
    else
        if (mainSpeed and mainSpeed > 0) then
            mainSpeed = string.format("%.2f", mainSpeed)
            offSpeed = string.format("%.2f", offSpeed)
            speed = mainSpeed.."s "..offSpeed
        else
            speed = 500
            mainSpeed = 500
            offSpeed = nil
            fastestSpeed = 500
        end
        fastestSpeed = TinyMeleeStats.db.char[spec].FastestMh.."s "..TinyMeleeStats.db.char[spec].FastestOh
    end
    return mainSpeed, offSpeed, speed, fastestSpeed
end

local function GetMastery()
    local mastery = TinyMeleeStats.Compat.GetMastery()
    return mastery
end

function TinyMeleeStats:GetUnitRole()
    self.class = select(2, UnitClass("player"))
    local role
    local Talent = TinyMeleeStats.Compat.GetSpecialization()
    if Talent then
        role = TinyMeleeStats.Compat.GetSpecializationRole(Talent)
    end
    if not role then
        local ap = GetAttackPower()
        local spelldmg = 0
        if ap > spelldmg then
            role = "melee"
        else
            role = "caster"
        end
    else
        if role == "HEALER" then
            role = "healer"
        elseif role == "TANK" then
            role = "tank"
        elseif role == "DAMAGER" then
            if (self.class == "MAGE" or self.class == "WARLOCK" or self.class == "PRIEST") then
                role = "caster"
            elseif (self.class == "SHAMAN" and Talent == 1) then
                role = "caster"
            elseif (self.class == "DRUID" and Talent == 1) then
                role = "caster"
            else
                role = "melee"
            end
        end
    end
    if (not self.PlayerRole or self.PlayerRole ~= role) then
        self.PlayerRole = role
        self:Stats()
    end

    Debug("you are:", role)
    return role
end

function TinyMeleeStats:Stats()
    Debug("Stats()")
    local style = self.db.char.Style
    local mastery = GetMastery()
    local versatility = TinyMeleeStats.Compat.GetVersatility()
    if not versatility then
        versatility = "0.00"
    end
    local spec = "Spec"..TinyMeleeStats.Compat.GetActiveSpecGroup()
    local pow = GetAttackPower()
    local crit = string.format("%.2f",GetCrit())
    local haste, hasteperc = GetHaste()
    local mainSpeed, offSpeed, speed, fastestSpeed = 500, nil, 500, 500
    if style.Speed[self.PlayerRole] then
        mainSpeed, offSpeed, speed, fastestSpeed = GetWeaponSpeed(spec)
    end

    local recordIsBroken = false

    if SpecChangedPause <= GetTime() then
        if (style.AP[self.PlayerRole] and tonumber(pow) > tonumber(self.db.char[spec].HighestAp)) then
            self.db.char[spec].HighestAp = pow
            recordIsBroken = MsgRecord(STAT_ATTACK_POWER,pow) or recordIsBroken
        end
        if (style.Haste[self.PlayerRole] or style.HastePerc[self.PlayerRole]) then
            if (tonumber(haste) > tonumber(self.db.char[spec].HighestHaste) or tonumber(hasteperc) > tonumber(self.db.char[spec].HighestHastePerc)) then
                self.db.char[spec].HighestHaste = haste
                self.db.char[spec].HighestHastePerc = hasteperc
                recordIsBroken = MsgRecord(SPELL_HASTE,haste) or recordIsBroken
                recordIsBroken = MsgRecord(L["Percent Haste"],hasteperc) or recordIsBroken
            end
        end
        if (style.Speed[self.PlayerRole]) then
            if (tonumber(mainSpeed) < tonumber(self.db.char[spec].FastestMh)) then
                self.db.char[spec].FastestMh = mainSpeed
                recordIsBroken = MsgRecord(WEAPON_SPEED..(offSpeed and " (MainHand)" or ""),mainSpeed) or recordIsBroken
                fastestSpeed = self.db.char[spec].FastestMh
            end
            if (offSpeed and (tonumber(offSpeed) < tonumber(self.db.char[spec].FastestOh))) then
                self.db.char[spec].FastestOh = offSpeed
                recordIsBroken = MsgRecord(WEAPON_SPEED.." (OffHand)",offSpeed) or recordIsBroken
                fastestSpeed = self.db.char[spec].FastestMh.."s "..self.db.char[spec].FastestOh
            end
        end
        if (style.Crit[self.PlayerRole] and tonumber(crit) > tonumber(self.db.char[spec].HighestCrit)) then
            self.db.char[spec].HighestCrit = crit
            recordIsBroken = MsgRecord(MELEE_CRIT_CHANCE,crit) or recordIsBroken
        end
        if (style.Mastery[self.PlayerRole] and mastery) and (tonumber(mastery) > tonumber(self.db.char[spec].HighestMastery)) then
            self.db.char[spec].HighestMastery = mastery
            recordIsBroken = MsgRecord(STAT_MASTERY,mastery) or recordIsBroken
        end
        if (style.Versatility[self.PlayerRole] and TinyMeleeStats.Compat.HasVersatility() and tonumber(versatility) > tonumber(self.db.char[spec].HighestVersatility)) then
            self.db.char[spec].HighestVersatility = versatility
            recordIsBroken = MsgRecord(STAT_VERSATILITY,versatility) or recordIsBroken
        end
    else
        Debug("rekords skipped SpecChangedPause")
    end

    if ((recordIsBroken == true) and (self.db.char.RecordSound == true)) then
        PlaySoundFile(media:Fetch("sound", self.db.char.RecordSoundFile),"Master")
    end

    self.ldbString = ""
    self.ldbRecord = ""
    self.CString = ""
    self.RString = ""

    if (style.AP[self.PlayerRole]) then
        SetLabel("ap",L["Ap:"])
        SetValues(pow,self.db.char[spec].HighestAp)
        FormatRString()
    end
    if (style.Haste[self.PlayerRole]) then
        SetLabel("haste",L["Haste:"])
        SetValues(haste,self.db.char[spec].HighestHaste)
        FormatRString()
    elseif (style.HastePerc[self.PlayerRole]) then
        SetLabel("haste",SPELL_HASTE_ABBR..":")
        SetValues(hasteperc.."%",self.db.char[spec].HighestHastePerc.."%")
        FormatRString()
    elseif (style.Speed[self.PlayerRole]) then
        SetLabel("haste",L["Speed:"])
        SetValues(speed.."s",fastestSpeed.."s")
        FormatRString()
    end
    if (style.Crit[self.PlayerRole]) then
        SetLabel("crit",L["Crit:"])
        SetValues(crit.."%",self.db.char[spec].HighestCrit.."%")
        FormatRString()
    end
    if (style.Mastery[self.PlayerRole] and mastery) then
        SetLabel("mastery",L["Mas:"])
        SetValues(mastery.."%",self.db.char[spec].HighestMastery.."%")
        FormatRString()
    end
    if (style.Versatility[self.PlayerRole] and TinyMeleeStats.Compat.HasVersatility()) then
        SetLabel("versatility",L["Vers:"])
        SetValues(versatility.."%",self.db.char[spec].HighestVersatility.."%")
        FormatRString()
    end

    if style.showRecords then
        if not style.vertical then
            self.CString = self.CString.."|n"..self.RString
        end
    end

    if style.showRecordsLDB then
        self.ldbString = self.ldbString.."|n"..self.ldbRecord
    end

    self.string:SetText(self.CString)

    TMSBroker.text = self.ldbString.."|r"
    
end
