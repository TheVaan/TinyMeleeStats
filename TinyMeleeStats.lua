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

local ldb = LibStub("LibDataBroker-1.1");
local TMSBroker = ldb:NewDataObject(AddonName, {
	type = "data source",
	label = AddonName,
	icon = "Interface\\Icons\\Ability_Racial_ShadowMeld",
	text = "--"
	})

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
			FastestMh = 500,
			FastestOh = 500
		},
		Spec2 = {
			HighestAp = 0,
			HighestCrit = "0.00",
			FastestMh = 500,
			FastestOh = 500
		},
		Style = {
			Ap = true,
			Crit = true,
			Speed = true,
			showRecords = true,
			vertical = false,
			labels = false,
			LDBtext = true
		},
		Color = {
			ap = {
				r = 1,
				g = 0.803921568627451,
				b = 0
			},
			crit = {
				r = 1,
				g = 0,
				b = 0.6549019607843137
			},
			speed = {
				r = 0,
				g = 0.611764705882353,
				b = 1
			}
		},
		DBver = 3
	}
}

TinyMeleeStats.tmsframe = CreateFrame("Frame",AddonName.."Frame",UIParent)
TinyMeleeStats.tmsframe:SetWidth(100)
TinyMeleeStats.tmsframe:SetHeight(15)
TinyMeleeStats.tmsframe:SetFrameStrata("BACKGROUND")
TinyMeleeStats.tmsframe:EnableMouse(true)
TinyMeleeStats.tmsframe:RegisterForDrag("LeftButton")

TinyMeleeStats.strings = {
	apString = TinyMeleeStats.tmsframe:CreateFontString(),
	critString = TinyMeleeStats.tmsframe:CreateFontString(),
	speedString = TinyMeleeStats.tmsframe:CreateFontString(),

	apRecordString = TinyMeleeStats.tmsframe:CreateFontString(),
	critRecordString = TinyMeleeStats.tmsframe:CreateFontString(),
	speedRecordString = TinyMeleeStats.tmsframe:CreateFontString(),
}

function TinyMeleeStats:SetStringColors()
	local c = self.db.char.Color
	self.strings.apString:SetTextColor(c.ap.r, c.ap.g, c.ap.b, 1.0)
	self.strings.critString:SetTextColor(c.crit.r, c.crit.g, c.crit.b, 1.0)
	self.strings.speedString:SetTextColor(c.speed.r, c.speed.g, c.speed.b, 1.0)

	self.strings.apRecordString:SetTextColor(c.ap.r, c.ap.g, c.ap.b, 1.0)
	self.strings.critRecordString:SetTextColor(c.crit.r, c.crit.g, c.crit.b, 1.0)
	self.strings.speedRecordString:SetTextColor(c.speed.r, c.speed.g, c.speed.b, 1.0)
end

function TinyMeleeStats:SetTextAnchors()
	local offsetX, offsetY = 3, 0
	if (not self.db.char.Style.vertical) then
		self.strings.apString:SetPoint("TOPLEFT", self.tmsframe,"TOPLEFT", offsetX, offsetY)
		self.strings.speedString:SetPoint("TOPLEFT", self.strings.apString, "TOPRIGHT", offsetX, offsetY)
		self.strings.critString:SetPoint("TOPLEFT", self.strings.speedString, "TOPRIGHT", offsetX, offsetY)

		self.strings.apRecordString:SetPoint("TOPLEFT", self.strings.apString, "BOTTOMLEFT")
		self.strings.speedRecordString:SetPoint("TOPLEFT", self.strings.apRecordString, "TOPRIGHT", offsetX, offsetY)
		self.strings.critRecordString:SetPoint("TOPLEFT", self.strings.speedRecordString, "TOPRIGHT", offsetX, offsetY)
	else
		self.strings.apString:SetPoint("TOPLEFT", self.tmsframe,"TOPLEFT", offsetX, offsetY)
		self.strings.speedString:SetPoint("TOPLEFT", self.strings.apString, "BOTTOMLEFT")
		self.strings.critString:SetPoint("TOPLEFT", self.strings.speedString, "BOTTOMLEFT")

		self.strings.apRecordString:SetPoint("TOPLEFT", self.strings.apString, "TOPRIGHT", offsetX, offsetY)
		self.strings.speedRecordString:SetPoint("TOPLEFT", self.strings.speedString, "TOPRIGHT", offsetX, offsetY)
		self.strings.critRecordString:SetPoint("TOPLEFT", self.strings.critString, "TOPRIGHT", offsetX, offsetY)
	end
end

function TinyMeleeStats:SetDragScript()
	if self.db.char.FrameLocked then
		self.tmsframe:SetMovable(false)
		fixed = "|cffFF0000"..L["Text is fixed. Uncheck Lock Frame in the options to move!"].."|r"
		self.tmsframe:SetScript("OnDragStart", function() DEFAULT_CHAT_FRAME:AddMessage(fixed) end)
		self.tmsframe:SetScript("OnEnter", nil)
		self.tmsframe:SetScript("OnLeave", nil)
	else
		self.tmsframe:SetMovable(true)
		self.tmsframe:SetScript("OnDragStart", function() self.tmsframe:StartMoving() end)
		self.tmsframe:SetScript("OnDragStop", function() self.tmsframe:StopMovingOrSizing() self.db.char.xPosition = self.tmsframe:GetLeft() self.db.char.yPosition = self.tmsframe:GetBottom()	end)
		self.tmsframe:SetScript("OnEnter", function() self.tmsframe:SetBackdrop(backdrop) end)
		self.tmsframe:SetScript("OnLeave", function() self.tmsframe:SetBackdrop(nil) end)
	end
end

function TinyMeleeStats:SetFrameVisible()

	if self.db.char.FrameHide then
		self.tmsframe:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -1000, -1000)
	else
		self.tmsframe:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.char.xPosition, self.db.char.yPosition)
	end

end

function TinyMeleeStats:SetBroker()

	if self.db.char.Style.LDBtext then
		TMSBroker.label = ""
	else
		TMSBroker.label = AddonName
	end

end

function TinyMeleeStats:InitializeFrame()
	self.tmsframe:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.char.xPosition, self.db.char.yPosition)
	local font = media:Fetch("font", self.db.char.Font)
	for k, fontObject in pairs(self.strings) do
		fontObject:SetFontObject(GameFontNormal)
		if not fontObject:SetFont(font, self.db.char.Size, self.db.char.FontEffect) then
			fontObject:SetFont("Fonts\\FRIZQT__.TTF", self.db.char.Size, self.db.char.FontEffect)
		end
		fontObject:SetJustifyH("LEFT")
		fontObject:SetJustifyV("MIDDLE")
	end
	self.strings.apString:SetText(" ")
	self.strings.apString:SetHeight(self.strings.apString:GetStringHeight())
	self.strings.apString:SetText("")
	self:SetTextAnchors()
	self:SetStringColors()
	self:SetDragScript()
	self:SetFrameVisible()
	self:SetBroker()
	self:Stats()
end

function TinyMeleeStats:OnInitialize()
	local AceConfigReg = LibStub("AceConfigRegistry-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")

	self.db = LibStub("AceDB-3.0"):New(AddonName.."DB", TinyMeleeStats.defaults, "char")
	LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, self:Options(), "tmscmd")
	media.RegisterCallback(self, "LibSharedMedia_Registered")

	self:RegisterChatCommand("tms", function() AceConfigDialog:Open(AddonName) end)
	self:RegisterChatCommand(AddonName, function() AceConfigDialog:Open(AddonName) end)
	self.optionsFrame = AceConfigDialog:AddToBlizOptions(AddonName, AddonName)
	self.db:RegisterDefaults(self.defaults)
	local version = GetAddOnMetadata(AddonName,"Version")
	local loaded = L["Open the configuration menu with /tms or /tinymeleestats"].."|r"
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
	self:RegisterEvent("UNIT_ATTACK_POWER", "OnEvent")
	self:RegisterEvent("UNIT_ATTACK_SPEED", "OnEvent")
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

local orgSetActiveSpecGroup = SetActiveSpecGroup;
function SetActiveSpecGroup(...)
	SpecChangedPause = GetTime() + 60
	Debug("Set SpecChangedPause")
	return orgSetActiveSpecGroup(...)
end

function TinyMeleeStats:OnEvent(event, arg1)
	if ((event == "PLAYER_REGEN_ENABLED") or (event == "PLAYER_ENTERING_WORLD")) then
		self.tmsframe:SetAlpha(self.db.char.outOfCombatAlpha)
		--[[local weekday, month, day, year = CalendarGetDate()
		if self.db.char.PostXStatsDay ~= day then
			self.db.char.PostXStatsDay = day
			self:UseTinyXStats()
		end]]--
	end
	if (event == "PLAYER_REGEN_DISABLED") then
		self.tmsframe:SetAlpha(self.db.char.inCombatAlpha)
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
	text[1] = "|cFF00ff00You can use TinyXStats, (all in one Stats Addon).|r"
	text[2] = "http://www.curse.com/addons/wow/tinystats"
	text[3] = "|cFF00ff00This will always be updated as the first.|r"
	for i = 1, 3 do
		DEFAULT_CHAT_FRAME:AddMessage("|cFFCCCC99"..AddonName..": |r"..text[i])
	end

end

local function HexColor(stat)

	local c = TinyMeleeStats.db.char.Color[stat]
	local hexColor = string.format("|cff%2X%2X%2X", 255*c.r, 255*c.g, 255*c.b)
	return hexColor

end

local function GetSpeed(spec)
	local speed, fastestSpeed = 0, 0
	local mainSpeed, offSpeed = UnitAttackSpeed("player")
	if (offSpeed == nil) then
		if (mainSpeed > 0) then
			mainSpeed = string.format("%.2f", mainSpeed)
			speed = mainSpeed
			fastestSpeed = TinyMeleeStats.db.char[spec].FastestMh
		else
			speed = 500
			mainSpeed = 500
		end
	else
		if (mainSpeed > 0) then
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

function TinyMeleeStats:Stats()
	Debug("Stats()")
	local style = self.db.char.Style
	local base, buff, debuff = UnitAttackPower("player")
	local ap = base + buff + debuff
	local crit = string.format("%.2f", GetCritChance("player"))
	local spec = "Spec"..GetActiveSpecGroup()
	local mainSpeed, offSpeed, speed, fastestSpeed = GetSpeed(spec)

	local recordBroken = "|cffFF0000"..L["Record broken!"]..": "
	local recordIsBroken = false

	if SpecChangedPause <= GetTime() then
		if (tonumber(mainSpeed) < tonumber(self.db.char[spec].FastestMh)) then
			self.db.char[spec].FastestMh = mainSpeed
			if (self.db.char.RecordMsg == true) then
				DEFAULT_CHAT_FRAME:AddMessage(recordBroken..WEAPON_SPEED..(offSpeed and " (MainHand)" or "")..": |c00ffef00"..self.db.char[spec].FastestMh.."|r")
				recordIsBroken = true
			end
			fastestSpeed = TinyMeleeStats.db.char[spec].FastestMh
		end
		if (offSpeed and (tonumber(offSpeed) < tonumber(self.db.char[spec].FastestOh))) then
			self.db.char[spec].FastestOh = offSpeed
			if (self.db.char.RecordMsg == true) then
				DEFAULT_CHAT_FRAME:AddMessage(recordBroken..WEAPON_SPEED.." (OffHand): |c00ffef00"..self.db.char[spec].FastestOh.."|r")
				recordIsBroken = true
			end
			fastestSpeed = TinyMeleeStats.db.char[spec].FastestMh.."s "..TinyMeleeStats.db.char[spec].FastestOh
		end
		if (tonumber(ap) > tonumber(self.db.char[spec].HighestAp)) then
			self.db.char[spec].HighestAp = ap
			if (self.db.char.RecordMsg == true) then
				DEFAULT_CHAT_FRAME:AddMessage(recordBroken..STAT_ATTACK_POWER..": |c00ffef00"..self.db.char[spec].HighestAp.."|r")
				recordIsBroken = true
			end
		end
		if (tonumber(crit) > tonumber(self.db.char[spec].HighestCrit)) then
			self.db.char[spec].HighestCrit = crit
			if (self.db.char.RecordMsg == true) then
				DEFAULT_CHAT_FRAME:AddMessage(recordBroken..MELEE_CRIT_CHANCE..": |c00ffef00"..self.db.char[spec].HighestCrit.."|r")
				recordIsBroken = true
			end
		end
	end

	if ((recordIsBroken == true) and (self.db.char.RecordSound == true)) then
		PlaySoundFile(media:Fetch("sound", self.db.char.RecordSoundFile),"Master")
	end

	local ldbString = ""
	local ldbRecord = ""

	if (style.showRecords) then ldbRecord = "|n" end

	if (style.Ap == true) then
		local apTempString = ""
		local apRecordTempString = ""
		ldbString = ldbString..HexColor("ap")
		if (style.labels) then
			apTempString = apTempString..L["Ap:"].." "
			ldbString = ldbString..L["Ap:"].." "
		end
		apTempString = apTempString..ap
		ldbString = ldbString..ap.." "
		if (style.showRecords) then
			ldbRecord = ldbRecord..HexColor("ap")
			if (style.vertical) then
				apRecordTempString = apRecordTempString.."("..self.db.char[spec].HighestAp..")"
				if (style.labels) then
					ldbRecord = ldbRecord..L["Ap:"].." "
				end
				ldbRecord = ldbRecord..self.db.char[spec].HighestAp.." "
			else
				if (style.labels) then
					apRecordTempString = apRecordTempString..L["Ap:"].." "
					ldbRecord = ldbRecord..L["Ap:"].." "
				end
				apRecordTempString = apRecordTempString..self.db.char[spec].HighestAp
				ldbRecord = ldbRecord..self.db.char[spec].HighestAp.." "
			end
		end
		self.strings.apString:SetText(apTempString)
		self.strings.apRecordString:SetText(apRecordTempString)
	else
		self.strings.apString:SetText("")
		self.strings.apRecordString:SetText("")
	end
	if (style.Speed == true) then
		local speedTempString = ""
		local speedRecordTempString = ""
		ldbString = ldbString..HexColor("speed")
		if (style.labels) then
			speedTempString = speedTempString..L["Speed:"].." "
			ldbString = ldbString..L["Speed:"].." "
		end
		speedTempString = speedTempString..speed.."s"
		ldbString = ldbString..speed.."s "
		if (style.showRecords) then
			ldbRecord = ldbRecord..HexColor("speed")
			if (style.vertical) then
				if (style.labels) then
					ldbRecord = ldbRecord..L["Speed:"].." "
				end
				speedRecordTempString = speedRecordTempString.."("..fastestSpeed.."s)"
				ldbRecord = ldbRecord..fastestSpeed.."s "
			else
				if (style.labels) then
					speedRecordTempString = speedRecordTempString..L["Speed:"].." "
					ldbRecord = ldbRecord..L["Speed:"].." "
				end
				speedRecordTempString = speedRecordTempString..fastestSpeed.."s"
				ldbRecord = ldbRecord..fastestSpeed.."s "
			end
		end
		self.strings.speedString:SetText(speedTempString)
		self.strings.speedRecordString:SetText(speedRecordTempString)
	else
		self.strings.speedString:SetText("")
		self.strings.speedRecordString:SetText("")
	end
	if (style.Crit == true) then
		local critTempString = ""
		local critRecordTempString = ""
		ldbString = ldbString..HexColor("crit")
		if (style.labels) then
			critTempString = critTempString..L["Crit:"].." "
			ldbString = ldbString..L["Crit:"].." "
		end
		critTempString = critTempString..crit.."%"
		ldbString = ldbString..crit.."% "
		if (style.showRecords) then
			ldbRecord = ldbRecord..HexColor("crit")
			if (style.vertical) then
				if (style.labels) then
					ldbRecord = ldbRecord..L["Crit:"].." "
				end
				critRecordTempString = critRecordTempString.."("..self.db.char[spec].HighestCrit.."%)"
				ldbRecord = ldbRecord..self.db.char[spec].HighestCrit.."% "
			else
				if (style.labels) then
					critRecordTempString = critRecordTempString..L["Crit:"].." "
					ldbRecord = ldbRecord..L["Crit:"].." "
				end
				critRecordTempString = critRecordTempString..self.db.char[spec].HighestCrit.."%"
				ldbRecord = ldbRecord..self.db.char[spec].HighestCrit.."% "
			end
		end
		self.strings.critString:SetText(critTempString)
		self.strings.critRecordString:SetText(critRecordTempString)
	else
		self.strings.critString:SetText("")
		self.strings.critRecordString:SetText("")
	end

	if (style.LDBtext) then
		TMSBroker.text = ldbString..ldbRecord.."|r"
	else
		TMSBroker.text = ""
	end
end
