local unitscan = CreateFrame'Frame'
local forbidden
local is_resting
local deadscan = false
unitscan:SetScript('OnUpdate', function() unitscan.UPDATE() end)
unitscan:SetScript('OnEvent', function(_, event, arg1)
	if event == 'ADDON_LOADED' and arg1 == 'unitscan' then
		unitscan.LOAD()
	elseif event == 'ADDON_ACTION_FORBIDDEN' and arg1 == 'unitscan' then
		forbidden = true
	elseif event == 'PLAYER_TARGET_CHANGED' then
		if UnitName'target' and strupper(UnitName'target') == unitscan.button:GetText() and not GetRaidTargetIndex'target' and (not UnitInRaid'player' or IsRaidOfficer() or IsRaidLeader()) then
			SetRaidTarget('target', 2)
		end
	elseif event == 'ZONE_CHANGED_NEW_AREA' or 'PLAYER_LOGIN' or 'PLAYER_UPDATE_RESTING' then
		local loc = GetRealZoneText()
		local _, instance_type = IsInInstance()
		is_resting = IsResting()
		nearby_targets = {}

		if instance_type == "raid" or instance_type == "pvp" then return end
		if loc == nil then return end

		for name, zone in pairs(rare_spawns) do
			if not unitscan_ignored[name] then
				local reaction = UnitReaction("player", name)
				if not reaction or reaction < 4 then reaction = true else reaction = false end
				if reaction and (loc == zone or string.match(loc, zone) or zone == "A H") then 
					table.insert(nearby_targets, name)
				end
			end
		end
		-- print("nearby_targets:", table.concat(nearby_targets, ", ")) -- Don't delete, it's a useful debug code to print what was added to the rare list scanning.
	end
end)


function unitscan.refresh_nearby_targets()
	-- print("Refreshed nearby rare list.")
    local loc = GetRealZoneText()
    local _, instance_type = IsInInstance()
    is_resting = IsResting()
    nearby_targets = {}
    
    if instance_type == "raid" or instance_type == "pvp" then return end
    if loc == nil then return end
    
    for name, zone in pairs(rare_spawns) do
        if not unitscan_ignored[name] then
            local reaction = UnitReaction("player", name)
            if not reaction or reaction < 4 then reaction = true else reaction = false end
            if reaction and (loc == zone or string.match(loc, zone) or zone == "A H") then 
                table.insert(nearby_targets, name)
            end
        end
    end

    -- print("nearby_targets:", table.concat(nearby_targets, ", "))
end



unitscan:RegisterEvent'ADDON_LOADED'
unitscan:RegisterEvent'ADDON_ACTION_FORBIDDEN'
unitscan:RegisterEvent'PLAYER_TARGET_CHANGED'
unitscan:RegisterEvent'ZONE_CHANGED_NEW_AREA'
unitscan:RegisterEvent'PLAYER_LOGIN'
unitscan:RegisterEvent'PLAYER_UPDATE_RESTING'

local BROWN = {.7, .15, .05}
local YELLOW = {1, 1, .15}
unitscan_targets = {}
unitscan_ignored = {}
unitscan_defaults = {
	CHECK_INTERVAL = .3,
}
local found = {}

-- Check the current locale of the WoW client
local currentLocale = GetLocale()

-- Define the rare spawns table based on the current locale
rare_spawns = {}
if currentLocale == "enUS" or currentLocale == "enGB" then
    rare_spawns = {
	["AZUROUS"] = "Winterspring",
	["GENERAL COLBATANN"] = "Winterspring",
	["KASHOCH THE REAVER"] = "Winterspring",
	["LADY HEDERINE"] = "Winterspring",
	["ALSHIRR BANEBREATH"] = "Felwood",
	["DESSECUS"] = "Felwood",
	["IMMOLATUS"] = "Felwood",
	["MONNOS THE ELDER"] = "Azshara",
	["SCALEBEARD"] = "Azshara",
	["BROTHER RAVENOAK"] = "Stonetalon Mountains",
	["FOREMAN RIGGER"] = "Stonetalon Mountains",
	["SISTER RIVEN"] = "Stonetalon Mountains",
	["SORROW WING"] = "Stonetalon Mountains",
	["TASKMASTER WHIPFANG"] = "Stonetalon Mountains",
	["AEAN SWIFTRIVER"] = "The Barrens",
	["AMBASSADOR BLOODRAGE"] = "The Barrens",
	["BRONTUS"] = "The Barrens",
	["CAPTAIN GEROGG HAMMERTOE"] = "The Barrens",
	["ELDER MYSTIC RAZORSNOUT"] = "The Barrens",
	["GESHARAHAN"] = "The Barrens",
	["HAGG TAURENBANE"] = "The Barrens",
	["HANNAH BLADELEAF"] = "The Barrens",
	["MARCUS BEL"] = "The Barrens",
	["ROCKLANCE"] = "The Barrens",
	["SISTER RATHTALON"] = "The Barrens",
	["SWIFTMANE"] = "The Barrens",
	["SWINEGART SPEARHIDE"] = "The Barrens",
	["TAKK THE LEAPER"] = "The Barrens",
	["THORA FEATHERMOON"] = "The Barrens",
	["CAPTAIN FLAT TUSK"] = "Durotar",
	["FELWEAVER SCORNN"] = "Durotar",
	["BRIMGORE"] = "Dustwallow Marsh",
	["SISTER HATELASH"] = "Mulgore",
	["HEARTRAZOR"] = "Thousand Needles",
	["IRONEYE THE INVINCIBLE"] = "Thousand Needles",
	["VILE STING"] = "Thousand Needles",
	["JIN'ZALLAH THE SANDBRINGER"] = "Tanaris",
	["WARLEADER KRAZZILAK"] = "Tanaris",
	["GRUFF"] = "Un'Goro Crater",
	["KING MOSH"] = "Un'Goro Crater",
	["REX ASHIL"] = "Silithus",
	["SCARLET EXECUTIONER"] = "Western Plaguelands",
	["SCARLET HIGH CLERIST"] = "Western Plaguelands",
	["TAMRA STORMPIKE"] = "Hillsbrad Foothills",
	["NARILLASANZ"] = "Alterac Mountains",
	["GRIMUNGOUS"] = "The Hinterlands",
	["MITH'RETHIS THE ENCHANTER"] = "The Hinterlands",
	["DARBEL MONTROSE"] = "Arathi Highlands",
	["FOULBELLY"] = "Arathi Highlands",
	["RUUL ONESTONE"] = "Arathi Highlands",
	["EMOGG THE CRUSHER"] = "Loch Modan",
	["SIEGE GOLEM"] = "Badlands",
	["HIGHLORD MASTROGONDE"] = "Searing Gorge",
	["HEMATOS"] = "Burning Steppes",
	["LORD CAPTAIN WYRMAK"] = "Swamp of Sorrows",
	["JADE"] = "Swamp of Sorrows",
	["HIGH PRIESTESS HAI'WATNA"] = "Stranglethorn Vale",
	["MOSH'OGG BUTCHER"] = "Stranglethorn Vale",
	["ANATHEMUS"] = "Badlands",
	["ZARICOTL"] = "Badlands",
	["DEVIATE FAERIE DRAGON"] = "Wailing Caverns",
	["MESHLOK THE HARVESTER"] = "Maraudon",
	["BLIND HUNTER"] = "Razorfen Kraul",
	["EARTHCALLER HALMGAR"] = "Razorfen Kraul",
	["RAZORFEN SPEARHIDE"] = "Razorfen Kraul",
	["ZERILLIS"] = "Zul'Farrak",
	["AZSHIR THE SLEEPLESS"] = "Scarlet Monastery",
	["HEARTHSINGER FORRESTEN"] = "Stratholme",
	["SKUL"] = "Stratholme",
	["STONESPINE"] = "Stratholme",
	["DEATHSWORN CAPTAIN"] = "Shadowfang Keep",
	["DARK IRON AMBASSADOR"] = "Gnomeregan",
	["LORD ROCCOR"] = "Blackrock Depths",
	["PANZOR THE INVINCIBLE"] = "Blackrock Depths",
	["PYROMANCER LOREGRAIN"] = "Blackrock Depths",
	["VEREK"] = "Blackrock Depths",
	["WARDER STILGISS"] = "Blackrock Depths",
	["BANNOK GRIMAXE"] = "Blackrock Spire",
	["BURNING FELGUARD"] = "Blackrock Spire",
	["CRYSTAL FANG"] = "Blackrock Spire",
	["GHOK BASHGUUD"] = "Blackrock Spire",
	["SPIRESTONE BATTLE LORD"] = "Blackrock Spire",
	["SPIRESTONE BUTCHER"] = "Blackrock Spire",
	["SPIRESTONE LORD MAGUS"] = "Blackrock Spire",
	["JED RUNEWATCHER"] = "Blackrock Spire",
	["BRUEGAL IRONKNUCKLE"] = "The Stockade",
	["MINER JOHNSON"] = "The Deadmines",
	["SKARR THE UNBREAKABLE"] = "Dire Maul",
	["MUSHGOG"] = "Dire Maul",
	["7:XT"] = "Badlands",
	["ACCURSED SLITHERBLADE"] = "Desolace",
	["ACHELLIOS THE BANISHED"] = "Thousand Needles",
	["AKKRILUS"] = "Ashenvale",
	["AKUBAR THE SEER"] = "Blasted Lands",
	["ALSHIRR BANEBREATH"] = "Felwood",
	["ANTILOS"] = "Azshara",
	["ANTILUS THE SOARER"] = "Feralas",
	["APOTHECARY FALTHIS"] = "Ashenvale",
	["ARAGA"] = "Alterac Mountains",
	["ARASH-ETHIS"] = "Feralas",
	["AZZERE THE SKYBLADE"] = "The Barrens",
	["BARNABUS"] = "Badlands",
	["BAYNE"] = "Tirisfal Glades",
	["BIG SAMRAS"] = "Hillsbrad Foothills",
	["BJARN"] = "Dun Morogh",
	["BLACKMOSS THE FETID"] = "Teldrassil",
	["BLOODROAR THE STALKER"] = "Feralas",
	["BOSS GALGOSH"] = "Loch Modan",
	["BOULDERHEART"] = "Redridge Mountains",
	["BRACK"] = "Westfall",
	["MARISA DU'PAIGE"] = "Westfall",
	["BRANCH SNAPPER"] = "Ashenvale",
	["BROKEN TOOTH"] = "Badlands",
	["BROKESPEAR"] = "The Barrens",
	["BURGLE EYE"] = "Dustwallow Marsh",
	["CARNIVOUS THE BREAKER"] = "Darkshore",
	["CHATTER"] = "Redridge Mountains",
	["CLACK THE REAVER"] = "Blasted Lands",
	["CLUTCHMOTHER ZAVAS"] = "Un'Goro Crater",
	["COMMANDER FELSTROM"] = "Duskwood",
	["CRANKY BENJ"] = "Alterac Mountains",
	["CREEPTHESS"] = "Hillsbrad Foothills",
	["CRIMSON ELITE"] = "Western Plaguelands",
	["CURSED CENTAUR"] = "Desolace",
	["CYCLOK THE MAD"] = "Tanaris",
	["DALARAN SPELLSCRIBE"] = "Silverpine Forest",
	["DARKMIST WIDOW"] = "Dustwallow Marsh",
	["DART"] = "Dustwallow Marsh",
	["DEATH FLAYER"] = "Durotar",
	["DEATH HOWL"] = "Felwood",
	["DEATHEYE"] = "Blasted Lands",
	["DEATHMAW"] = "Burning Steppes",
	["DEATHSPEAKER SELENDRE"] = "Eastern Plaguelands",
	["DEEB"] = "Tirisfal Glades",
	["DIAMOND HEAD"] = "Feralas",
	["DIGGER FLAMEFORGE"] = "The Barrens",
	["DISHU"] = "The Barrens",
	["DRAGONMAW BATTLEMASTER"] = "Wetlands",
	["DREADSCORN"] = "Blasted Lands",
	["DROGOTH THE ROAMER"] = "Dustwallow Marsh",
	["DUGGAN WILDHAMMER"] = "Eastern Plaguelands",
	["DUSKSTALKER"] = "Teldrassil",
	["DUSTWRAITH"] = "Zul'Farrak",
	["ECK'ALOM"] = "Ashenvale",
	["EDAN THE HOWLER"] = "Dun Morogh",
	["ENFORCER EMILGUND"] = "Mulgore",
	["ENGINEER WHIRLEYGIG"] = "The Barrens",
	["FALLEN CHAMPION"] = "Scarlet Monastery",
	["FARMER SOLLIDEN"] = "Tirisfal Glades",
	["FAULTY WAR GOLEM"] = "Searing Gorge",
	["FEDFENNEL"] = "Elwynn Forest",
	["FELLICENT'S SHADE"] = "Tirisfal Glades",
	["FENROS"] = "Duskwood",
	["FINGAT"] = "Swamp of Sorrows",
	["FIRECALLER RADISON"] = "Darkshore",
	["FLAGGLEMURK THE CRUEL"] = "Darkshore",
	["FOE REAPER 4000"] = "Westfall",
	["FOREMAN GRILLS"] = "The Barrens",
	["FOREMAN JERRIS"] = "Western Plaguelands",
	["FOREMAN MARCRID"] = "Western Plaguelands",
	["FOULMANE"] = "Western Plaguelands",
	["FURY SHELDA"] = "Teldrassil",
	["GARNEG CHARSKULL"] = "Wetlands",
	["GATEKEEPER RAGEROAR"] = "Azshara",
	["GENERAL FANGFERROR"] = "Azshara",
	["GEOLORD MOTTLE"] = "Durotar",
	["GEOMANCER FLINTDAGGER"] = "Arathi Highlands",
	["GEOPRIEST GUKK'ROK"] = "The Barrens",
	["GHOST HOWL"] = "Mulgore",
	["GIBBLESNIK"] = "Thousand Needles",
	["GIBBLEWILT"] = "Dun Morogh",
	["GIGGLER"] = "Desolace",
	["GILMORIAN"] = "Swamp of Sorrows",
	["GISH THE UNMOVING"] = "Eastern Plaguelands",
	["GLUGGLE"] = "Stranglethorn Vale",
	["GNARL LEAFBROTHER"] = "Feralas",
	["GNAWBONE"] = "Wetlands",
	["GOREFANG"] = "Silverpine Forest",
	["GORGON'OCH"] = "Burning Steppes",
	["GRAVIS SLIPKNOT"] = "Alterac Mountains",
	["GREAT FATHER ARCTIKUS"] = "Dun Morogh",
	["GREATER FIREBIRD"] = "Tanaris",
	["GRETHEER"] = "Silithus",
	["GRIMMAW"] = "Teldrassil",
	["GRIMTOOTH"] = "Alterac Valley",
	["GRIZLAK"] = "Loch Modan",
	["GRIZZLE SNOWPAW"] = "Winterspring",
	["GRUBTHOR"] = "Silithus",
	["GRUFF SWIFTBITE"] = "Elwynn Forest",
	["GRUKLASH"] = "Burning Steppes",
	["GRUNTER"] = "Blasted Lands",
	["HAARKA THE RAVENOUS"] = "Tanaris",
	["HAHK'ZOR"] = "Burning Steppes",
	["HAMMERSPINE"] = "Dun Morogh",
	["HARB FOULMOUNTAIN"] = "Thousand Needles",
	["HAYOC"] = "Dustwallow Marsh",
	["HED'MUSH THE ROTTING"] = "Eastern Plaguelands",
	["HEGGIN STONEWHISKER"] = "The Barrens",
	["HIGH GENERAL ABBENDIS"] = "Eastern Plaguelands",
	["HISSPERAK"] = "Desolace",
	["HUMAR THE PRIDELORD"] = "The Barrens",
	["HURICANIAN"] = "Silithus",
	["IRONBACK"] = "The Hinterlands",
	["IRONSPINE"] = "Scarlet Monastery",
	["JALINDE SUMMERDRAKE"] = "The Hinterlands",
	["JIMMY THE BLEEDER"] = "Alterac Mountains",
	["KASKK"] = "Desolace",
	["KAZON"] = "Redridge Mountains",
	["KOVORK"] = "Arathi Highlands",
	["KREGG KEELHAUL"] = "Tanaris",
	["KRELLACK"] = "Silithus",
	["KRETHIS SHADOWSPINNER"] = "Silverpine Forest",
	["KURMOKK"] = "Stranglethorn Vale",
	["LADY HEDERINE"] = "Winterspring",
	["LADY MOONGAZER"] = "Darkshore",
	["LADY SESSPIRA"] = "Azshara",
	["LADY SZALLAH"] = "Feralas",
	["LADY VESPIA"] = "Ashenvale",
	["LADY VESPIRA"] = "Darkshore",
	["LADY ZEPHRIS"] = "Hillsbrad Foothills",
	["LAPRESS"] = "Silithus",
	["LARGE LOCH CROCOLISK"] = "Loch Modan",
	["LEECH WIDOW"] = "Wetlands",
	["LEPRITHUS"] = "Westfall",
	["LICILLIN"] = "Darkshore",
	["LO'GROSH"] = "Alterac Mountains",
	["LORD ANGLER"] = "Dustwallow Marsh",
	["LORD CONDAR"] = "Loch Modan",
	["LORD DARKSCYTHE"] = "Eastern Plaguelands",
	["LORD MALATHROM"] = "Duskwood",
	["LORD MALDAZZAR"] = "Western Plaguelands",
	["LORD SAKRASIS"] = "Stranglethorn Vale",
	["LORD SINSLAYER"] = "Darkshore",
	["LOST ONE CHIEFTAIN"] = "Swamp of Sorrows",
	["LOST ONE COOK"] = "Swamp of Sorrows",
	["LOST SOUL"] = "Tirisfal Glades",
	["LUPOS"] = "Duskwood",
	["MA'RUK WYRMSCALE"] = "Wetlands",
	["MAGISTER HAWKHELM"] = "Azshara",
	["MAGOSH"] = "Loch Modan",
	["MAGRONOS THE UNYIELDING"] = "Blasted Lands",
	["MALFUNCTIONING REAVER"] = "Burning Steppes",
	["MALGIN BARLEYBREW"] = "The Barrens",
	["MASTER DIGGER"] = "Westfall",
	["MASTER FEARDRED"] = "Azshara",
	["MAZZRANACHE"] = "Mulgore",
	["MEZZIR THE HOWLER"] = "Winterspring",
	["MIRELOW"] = "Wetlands",
	["MIST HOWLER"] = "Ashenvale",
	["MOJO THE TWISTED"] = "Blasted Lands",
	["MOLOK THE CRUSHER"] = "Arathi Highlands",
	["MOLT THORN"] = "Swamp of Sorrows",
	["MONGRESS"] = "Felwood",
	["MORGAINE THE SLY"] = "Elwynn Forest",
	["MOTHER FANG"] = "Elwynn Forest",
	["MUAD"] = "Tirisfal Glades",
	["MUGGLEFIN"] = "Ashenvale",
	["MURDEROUS BLISTERPAW"] = "Tanaris",
	["NAL'TASZAR"] = "Stonetalon Mountains",
	["NARAXIS"] = "Duskwood",
	["NARG THE TASKMASTER"] = "Elwynn Forest",
	["NEFARU"] = "Duskwood",
	["NIMAR THE SLAYER"] = "Arathi Highlands",
	["OAKPAW"] = "Ashenvale",
	["OLD CLIFF JUMPER"] = "The Hinterlands",
	["OLD GRIZZLEGUT"] = "Feralas",
	["OLD VICEJAW"] = "Silverpine Forest",
	["OLM THE WISE"] = "Felwood",
	["OMGORN THE LOST"] = "Tanaris",
	["OOZEWORM"] = "Dustwallow Marsh",
	["PRIDEWING PATRIARCH"] = "Stonetalon Mountains",
	["PRINCE KELLEN"] = "Desolace",
	["PRINCE NAZJAK"] = "Arathi Highlands",
    ["PRINCE RAZE"] = "Ashenvale",
    ["PUTRIDIUS"] = "Western Plaguelands",
    ["QIROT"] = "Feralas",
    ["RAGEPAW"] = "Felwood",
    ["RAK'SHIRI"] = "Winterspring",
    ["RANGER LORD HAWKSPEAR"] = "Eastern Plaguelands",
    ["RATHORIAN"] = "The Barrens",
    ["RAVAGE"] = "Blasted Lands",
    ["RAVASAUR MATRIARCH"] = "Un'Goro Crater",
    ["RAVENCLAW REGENT"] = "Silverpine Forest",
    ["RAZORMAW MATRIARCH"] = "Wetlands",
    ["RAZORTALON"] = "The Hinterlands",
    ["REKK'TILAC"] = "Searing Gorge",
    ["RESSAN THE NEEDLER"] = "Tirisfal Glades",
    ["RETHEROKK THE BERSERKER"] = "The Hinterlands",
    ["RIBCHASER"] = "Redridge Mountains",
    ["RIPPA"] = "Stranglethorn Vale",
    ["RIPSCALE"] = "Dustwallow Marsh",
    ["RO'BARK"] = "Hillsbrad Foothills",
    ["ROHH THE SILENT"] = "Redridge Mountains",
    ["ROLOCH"] = "Stranglethorn Vale",
    ["RORGISH JOWL"] = "Ashenvale",
    ["ROT HIDE BRUISER"] = "Silverpine Forest",
    ["RUMBLER"] = "Badlands",
    ["SANDARR DUNEREAVER"] = "Zul'farrak",
    ["SCALD"] = "Searing Gorge",
    ["SCALE BELLY"] = "Stranglethorn Vale",
    ["SCARGIL"] = "Hillsbrad Foothills",
    ["SCARLET INTERROGATOR"] = "Western Plaguelands",
    ["SCARLET JUDGE"] = "Western Plaguelands",
    ["SCARLET SMITH"] = "Western Plaguelands",
    ["SEEKER AQUALON"] = "Redridge Mountains",
    ["SENTINEL AMARASSAN"] = "Stonetalon Mountains",
    ["SERGEANT BRASHCLAW"] = "Westfall",
    ["SETIS"] = "Silithus",
    ["SEWER BEAST"] = "Stormwind City",
    ["SHADOWCLAW"] = "Darkshore",
    ["SHADOWFORGE COMMANDER"] = "Badlands",
    ["SHANDA THE SPINNER"] = "Loch Modan",
    ["SHLEIPNARR"] = "Searing Gorge",
    ["SILITHID HARVESTER"] = "The Barrens",
    ["SILITHID RAVAGER"] = "Thousand Needles",
    ["SINGER"] = "Arathi Highlands",
    ["SKHOWL"] = "Alterac Mountains",
    ["SLARK"] = "Westfall",
    -- ["SLAVE MASTER BLACKHEART"] = "Searing Gorge", -- underground mob, may wanna disable
    ["SLUDGE BEAST"] = "The Barrens",
    ["SLUDGINN"] = "Wetlands",
    ["SMOLDAR"] = "Searing Gorge",
    ["SNAGGLESPEAR"] = "Mulgore",
    ["SNARLER"] = "Feralas",
    ["SNARLFLARE"] = "Redridge Mountains",
    ["SNARLMANE"] = "Silverpine Forest",
    ["SNORT THE HECKLER"] = "The Barrens",
    ["SORIID THE DEVOURER"] = "Tanaris",
    ["SPITEFLAYER"] = "Blasted Lands",
    ["SQUIDDIC"] = "Redridge Mountains",
    ["SRI'SKULK"] = "Tirisfal Glades",
    ["STONE FURY"] = "Alterac Mountains",
    ["STONEARM"] = "The Barrens",
    ["STRIDER CLUTCHMOTHER"] = "Darkshore",
    ["TERRORSPARK"] = "Burning Steppes",
    ["TERROWULF PACKLORD"] = "Ashenvale",
    ["THAURIS BALGARR"] = "Burning Steppes",
    -- ["THE CLEANER"] = "Eastern Plaguelands", -- doesnt drop anything and too much hp.
    ["THE EVALCHARR"] = "Azshara",
    ["THE HUSK"] = "Western Plaguelands",
    ["THE ONGAR"] = "Felwood",
    ["THE RAKE"] = "Mulgore",
    ["THE RAZZA"] = "Dire Maul",
    ["THE REAK"] = "The Hinterlands",
    ["THE ROT"] = "Dustwallow Marsh",
    ["THREGGIL"] = "Teldrassil",
    ["THUNDERSTOMP"] = "The Barrens",
    ["THUROS LIGHTFINGERS"] = "Elwynn Forest",
    ["TIMBER"] = "Dun Morogh",
    ["TORMENTED SPIRIT"] = "Tirisfal Glades",
    ["TWILIGHT LORD EVERUN"] = "Silithus",
    ["UHK'LOC"] = "Un'Goro Crater",
    ["URSOL'LOK"] = "Ashenvale",
    ["URUSON"] = "Teldrassil",
    ["VARO'THEN'S GHOST"] = "Azshara",
    ["VENGEFUL ANCIENT"] = "Stonetalon Mountains",
    ["VERIFONIX"] = "Stranglethorn Vale",
    ["VOLCHAN"] = "Burning Steppes",
    ["VULTROS"] = "Westfall",
    ["WAR GOLEM"] = "Badlands",
    ["WARLORD KOLKANIS"] = "Durotar",
    ["WARLORD THRESH'JIN"] = "Eastern Plaguelands",
    ["WATCH COMMANDER ZALAPHIL"] = "Durotar",
    ["WITHERHEART THE STALKER"] = "The Hinterlands",
    ["ZALAS WITHERBARK"] = "Arathi Highlands",
    ["ZORA"] = "Silithus",
    ["ZUL'BRIN WARPBRANCH"] = "Eastern Plaguelands",
    ["ZUL'AREK HATEFOWLER"] = "The Hinterlands",
    -- Thanks to Macumba for finding these rares
    -- ["NERUBIAN OVERSEER"] = "Eastern Plaguelands", -- doesnt drop anything worth and too much hp.
	["DIGMASTER SHOVELPHLANGE"] = "Badlands",
	-- ["SCARSHIELD QUARTERMASTER"] = "Blackrock Mountain", -- doesnt drop anything worth
	["THE BEHEMOTH"] = "Blackrock Mountain",
	["TREGLA"] = "Eversong Woods",
	["BRAINWASHED NOBLE"] = "The Deadmines",
	["TRIGORE THE LASHER"] = "Wailing Caverns",
	["BOAHN"] = "Wailing Caverns",
	["CRUSTY"] = "Desolace",
	["ZEKKIS"] = "Temple of Atal'Hakkar",
	["VEYZHAK THE CANNIBAL"] = "Temple of Atal'Hakkar",
	-- TBC
    ["SHADIKITH THE GLIDER"] = "Karazhan",
    ["HYAKISS THE LURKER"] = "Karazhan",
    ["ROKAD THE RAVAGER"] = "Karazhan",
    ["GORETOOTH"] = "Nagrand",
    ["VOIDHUNTER YAR"] = "Nagrand",
    ["BRO'GAZ THE CLANLESS"] = "Nagrand",
    ["MARTICAR"] = "Zangarmarsh",
    ["BOG LURKER"] = "Zangarmarsh",
    ["COILFANG EMISSARY"] = "Zangarmarsh",
    ["NURAMOC"] = "Netherstorm",
    ["EVER-CORE THE PUNISHER"] = "Netherstorm",
    ["CHIEF ENGINEER LORTHANDER"] = "Netherstorm",
    ["AMBASSADOR JERRIKAR"] = "Shadowmoon Valley",
    ["COLLIDUS THE WARP-WATCHER"] = "Shadowmoon Valley",
    ["KRAATOR"] = "Shadowmoon Valley",
    ["VORAKEM DOOMSPEAKER"] = "Hellfire Peninsula",
    ["FULGORGE"] = "Hellfire Peninsula",
    ["MEKTHORG THE WILD"] = "Hellfire Peninsula",
    ["HEMATHION"] = "Blade's Edge Mountains",
    ["MORCRUSH"] = "Blade's Edge Mountains",
    ["SPEAKER MAR'GROM"] = "Blade's Edge Mountains",
    ["ELDINARCUS"] = "Eversong Woods",
    ["DR. WHITHERLIMB"] = "Ghostlands",
    ["CRIPPLER"] = "Terokkar Forest",
    ["DOOMSAYER JURIM"] = "Terokkar Forest",
    ["OKREK"] = "Terokkar Forest",
    ["FENISSA THE ASSASSIN"] = "Bloodmyst Isle",
    -- ["DOOMWALKER"] = "Shadowmoon Valley", -- disabled world boss
    -- ["DOOM LORD KAZZAK"] = "Hellfire Peninsula", -- disabled world boss
    -- WoTLK
    ["FUMBLUB GEARWIND"] = "Borean Tundra",
    ["ICEHORN"] = "Borean Tundra",
    ["OLD CRYSTALBARK"] = "Borean Tundra",
    ["CRAZED INDU'LE SURVIVOR"] = "Dragonblight",
    ["SCARLET HIGHLORD DAION"] = "Dragonblight",
    ["TUKEMUTH"] = "Dragonblight",
    ["ARCTURIS"] = "Grizzly Hills",
    ["GROCKLAR"] = "Grizzly Hills",
    ["SEETHING HATE"] = "Grizzly Hills",
    ["SYREIAN THE BONECARVER"] = "Grizzly Hills",
    ["KING PING"] = "Howling Fjord",
    ["PEROBAS THE BLOODTHIRSTER"] = "Howling Fjord",
    ["VIGDIS THE WAR MAIDEN"] = "Howling Fjord",
    ["HIGH THANE JORFUS"] = "Icecrown",
    ["HILDANA DEATHSTEALER"] = "Icecrown",
    ["PUTRIDUS THE ANCIENT"] = "Icecrown",
    ["AOTONA"] = "Sholazar Basin",
    ["KING KRUSH"] = "Sholazar Basin",
    ["LOQUE'NAHAK"] = "Sholazar Basin",
    ["DIRKEE"] = "The Storm Peaks",
    ["SKOLL"] = "The Storm Peaks",
    ["TIME-LOST PROTO DRAKE"] = "The Storm Peaks",
    ["VYRAGOSA"] = "The Storm Peaks",
    ["GONDRIA"] = "Zul'Drak",
    ["GRIEGEN"] = "Zul'Drak",
    ["TERROR SPINNER"] = "Zul'Drak",
    ["ZUL'DRAK SENTINEL"] = "Zul'Drak",
    }
elseif currentLocale == "ruRU" then
    rare_spawns = {
	["ЛАЗУРИС"] = "Зимние Ключи",
	["ГЕНЕРАЛ КОЛБАТАНН"] = "Зимние Ключи",
	["КАШОХ РАЗОРИТЕЛЬ"] = "Зимние Ключи",
	["ЛЕДИ ХЕДЕРИНА"] = "Зимние Ключи",
	["АЛШИР ГИБЛОДЫХ"] = "Оскверненный лес",
	["ДЕССЕКУС"] = "Оскверненный лес",
	["ИСПЕПЕЛИТЕЛЬ"] = "Оскверненный лес",
	["МОННОС ДРЕВНИЙ"] = "Азшара",
	["ЧЕШУЕБОРОД"] = "Азшара",
	["БРАТ ВОРОНИЙ ДУБ"] = "Когтистые горы",
	["ШТЕЙГЕР РИГГЕР"] = "Когтистые горы",
	["СЕСТРА ТЕРЗАЮЩАЯ"] = "Когтистые горы",
	["КРЫЛО СКОРБИ"] = "Когтистые горы",
	["НАДСМОТРЩИК ХЛЕСТОКЛЫК"] = "Когтистые горы",
	["ЭАН БЫСТРАЯ РЕКА"] = "Степи",
	["ПОСОЛ КРОВОПУСК"] = "Степи",
	["БРОНТУС"] = "Степи",
	["КАПИТАН ГЕРОГГ ТЯЖЕЛОСТУП"] = "Степи",
	["СТАРЫЙ МИСТИК ОСТРОМОРД"] = "Степи",
	["ГЕШАРАХАН"] = "Степи",
	["ХАГГ ТАУРЕБОЙ"] = "Степи",
	["ХАННА ОСТРОЛИСТ"] = "Степи",
	["МАРКУС БЕЛ"] = "Степи",
	["КАМЕННОЕ КОПЬЕ"] = "Степи",
	["СЕСТРА КОГОТЬ КУРГАНА"] = "Степи",
	["БЫСТРОГРИВ"] = "Степи",
	["СВИНЕАР КОПЬЕШКУР"] = "Степи",
	["ТАКК ПРЫГУН"] = "Степи",
	["ТОРА ОПЕРЕННАЯ ЛУНА"] = "Степи",
	["КАПИТАН ТУПОЙ КЛЫК"] = "Дуротар",
	["СКОРНН ТКАЧ СКВЕРНЫ"] = "Дуротар",
	["КРАЕГОР"] = "Пылевые топи",
	["СЕСТРА ПЛЕТЬ НЕНАВИСТИ"] = "Мулгор",
	["СЕРДЦЕРЕЗ"] = "Тысяча Игл",
	["ЖЕЛЕЗНОГЛАЗ НЕУЯЗВИМЫЙ"] = "Тысяча Игл",
	["КОВАРНОЕ ЖАЛО"] = "Тысяча Игл",
	["ДЖИН'ЗАЛЛАХ ХОЗЯИН БАРХАНОВ"] = "Танарис",
	["ВОЕННЫЙ ВОЖДЬ КРАЗЗИЛАК"] = "Танарис",
	["ГРАФФ"] = "Кратер Ун'Горо",
	["КОРОЛЬ МОШ"] = "Кратер Ун'Горо",
	["РЕКС АШИЛ"] = "Силитус",
	["ПАЛАЧ ИЗ АЛОГО ОРДЕНА"] = "Западные Чумные земли",
	["ВЕРХОВНЫЙ СВЯЩЕННИК ИЗ АЛОГО ОРДЕНА"] = "Западные Чумные земли",
	["ТАМРАН ГРОЗОВАЯ ВЕРШИНА"] = "Предгорья Хилсбрада",
	["НАРИЛЛАСАНЗ"] = "Альтеракские горы",
	["МРАЧНОУС"] = "Внутренние земли",
	["МИТ'РЕТИС ЗАЧАРОВЫВАТЕЛЬ"] = "Внутренние земли",
	["ДАРБЕЛЛА МОНТРОУЗ"] = "Нагорье Арати",
	["ГНИЛОБРЮХ"] = "Нагорье Арати",
	["РУУЛ ОДИНОКИЙ КАМЕНЬ"] = "Нагорье Арати",
	["АМОГГ СОКРУШИТЕЛЬ"] = "Лок Модан",
	["ОСАДНЫЙ ГОЛЕМ"] = "Бесплодные земли",
	["ВЕРХОВНЫЙ ЛОРД МАСТРОГОНД"] = "Тлеющее ущелье",
	["ГЕМАТОС"] = "Пылающие степи",
	["ЛОРД-КАПИТАН ЗМЕЮК"] = "Болото Печали",
	["НЕФРИТ"] = "Болото Печали",
	["ВЕРХОВНАЯ ЖРИЦА ХАЙ'ВАТНА"] = "Тернистая долина",
	["ПАЛАЧ МОШ'ОГГ"] = "Тернистая долина",
	["АНАТЕМУС"] = "Бесплодные земли",
	["ЗАРИКОТЛЬ"] = "Бесплодные земли",
	["ЗАГАДОЧНЫЙ ВОЛШЕБНЫЙ ДРАКОН"] = "Пещеры Стенаний",
	["МЕШЛОК ЖНЕЦ"] = "Мародон",
	["СЛЕПОЙ ОХОТНИК"] = "Лабиринты Иглошкурых",
	["ЗАКЛИНАТЕЛЬНИЦА ЗЕМЛИ ХАЛМГАР"] = "Лабиринты Иглошкурых",
	["КОПЬЕШКУР ИЗ ПЛЕМЕНИ ИГЛОШКУРЫХ"] = "Лабиринты Иглошкурых",
	["ЗЕРИЛЛИС"] = "Зул'Фаррак",
	["АЗШИР НЕСПЯЩИЙ"] = "Монастырь Алого ордена",
	["ПЕВЧИЙ ФОРРЕСТЕН"] = "Стратхольм",
	["ЧЕРЕП"] = "Стратхольм",
	["КАМЕННЫЙ ГРЕБЕНЬ"] = "Стратхольм",
	["КАПИТАН СЛУЖИТЕЛЕЙ СМЕРТИ"] = "Крепость Темного Клыка",
	["ПОСОЛ ИЗ КЛАНА ЧЕРНОГО ЖЕЛЕЗА"] = "Гномреган",
	["ЛОРД РОККОР"] = "Глубины Черной горы",
	["ПАНЦЕР НЕПОБЕДИМЫЙ"] = "Глубины Черной горы",
	["ПИРОМАН ЗЕРНО МУДРОСТИ"] = "Глубины Черной горы",
	["ВЕРЕК"] = "Глубины Черной горы",
	["ТЮРЕМЩИК СТИЛГИСС"] = "Глубины Черной горы",
	["БАННОК ЛЮТОРЕЗ"] = "Вершина Черной горы",
	["ПЫЛАЮЩИЙ СТРАЖ СКВЕРНЫ"] = "Вершина Черной горы",
	["ХРУСТАЛЬНЫЙ КЛЫК"] = "Вершина Черной горы",
	["ГОК КРЕПКОБИВ"] = "Вершина Черной горы",
	["ПОЛКОВОДЕЦ ИЗ КЛАНА ЧЕРНОЙ ВЕРШИНЫ"] = "Вершина Черной горы",
	["МЯСНИК ИЗ КЛАНА ЧЕРНОЙ ВЕРШИНЫ"] = "Вершина Черной горы",
	["ЛОРД-ВОЛХВ ИЗ КЛАНА ЧЕРНОЙ ВЕРШИНЫ"] = "Вершина Черной горы",
	["ДЖЕД РУНОВЕД"] = "Вершина Черной горы",
	["БРУГАЛ ЖЕЛЕЗНЫЙ КУЛАК"] = "Тюрьма",
	["ШАХТЕР ДЖОНСОН"] = "Мертвые копи",
	["СКАРР НЕПРЕКЛОННЫЙ"] = "Забытый Город",
	["МУШГОГ"] = "Забытый Город",
	["7:XT"] = "Бесплодные земли",
	["ПРОКЛЯТЫЙ СКОЛЬЗЯЩИЙ ПЛАВНИК"] = "Пустоши",
	["АКЕЛЛИОС-ИЗГНАННИК"] = "Тысяча Игл",
	["АККРИЛУС"] = "Ясеневый лес",
	["ПРОВИДЕЦ АКУБАР"] = "Выжженные земли",
	["АЛШИР ГИБЛОДЫХ"] = "Оскверненный лес",
	["АНТИЛОС"] = "Азшара",
	["АНТИЛУС ПАРЯЩИЙ"] = "Фералас",
	["АПТЕКАРЬ ФАЛТИС"] = "Ясеневый лес",
	["АРАГА"] = "Альтеракские горы",
	["АРАШ-ЕТИС"] = "Фералас",
	["АЗЗИРА КЛИНОК НЕБЕС"] = "Степи",
	["БАРНАБУС"] = "Бесплодные земли",
	["ЗВЕРР"] = "Тирисфальские леса",
	["БОЛЬШОЙ САМРАС"] = "Предгорья Хилсбрада",
	["ПАРШИВЫЙ КОГОТЬ"] = "Дун Морог",
	["ЧЕРНОМШЕЦ ЗЛОСМРАДНЫЙ"] = "Тельдрассил",
	["РОКОТУН ЛОВЕЦ"] = "Фералас",
	["ГЛАВАРЬ ГАЛГОШ"] = "Лок Модан",
	["КАМНЕСЕРД"] = "Красногорье",
	["БРАКК"] = "Западный Край",
	["МАРИСА ДЮ ПЭЖ"] = "Западный Край",
	["ВЕТКОХВАТ"] = "Ясеневый лес",
	["СЛОМАННЫЙ КЛЫК"] = "Бесплодные земли",
	["КОПЬЕЛОМ"] = "Степи",
	["ВОРОВСКОЙ ГЛАЗ"] = "Пылевые топи",
	["КАРНИВУС РАЗРУШИТЕЛЬ"] = "Темные берега",
	["ТРЕЩУНЬЯ"] = "Красногорье",
	["ЩЕЛКУН РАЗОРИТЕЛЬ"] = "Выжженные земли",
	["МАТКА ЗАВАС"] = "Кратер Ун'Горо",
	["КОМАНДОР СКВЕРНСТРОМ"] = "Сумеречный лес",
	["ЗЛОБНЫЙ БЕНДЖИ"] = "Альтеракские горы",
	["ПОЛЗУХ"] = "Предгорья Хилсбрада",
	["ГВАРДЕЕЦ ИЗ БАГРОВОГО ЛЕГИОНА"] = "Западные Чумные земли",
	["ПРОКЛЯТЫЙ КЕНТАВР"] = "Пустоши",
	["ЦИКЛОК БЕЗУМНЫЙ"] = "Танарис",
	["ДАЛАРАНСКИЙ ЧАРОКНИЖНИК"] = "Серебряный бор",
	["ЧЕРНАЯ ВДОВА МГЛИСТОЙ ПЕЩЕРЫ"] = "Пылевые топи",
	["ДАРТ"] = "Пылевые топи",
	["СМЕРТОНОСНЫЙ ЖИВОДЕР"] = "Дуротар",
	["СМЕРТНЫЙ ВОЙ"] = "Оскверненный лес",
	["СМЕРТЕГЛАЗ"] = "Выжженные земли",
	["ГИБЛОПАСТЬ"] = "Пылающие степи",
	["ВЕСТНИЦА СМЕРТИ СЕЛЕНДРА"] = "Восточные Чумные земли",
	["ДИБ"] = "Тирисфальские леса",
	["РОМБОГОЛОВ"] = "Фералас",
	["ЗЕМЛЕКОП ОГНЕПЛАВ"] = "Степи",
	["ДИШУ"] = "Степи",
	["ВОЕНАЧАЛЬНИК ИЗ КЛАНА ДРАКОНЬЕЙ ПАСТИ"] = "Болотина",
	["БЕССТРАШНЫЙ"] = "Выжженные земли",
	["ДРОГОТ БРОДЯГА"] = "Пылевые топи",
	["ДУГАН ГРОМОВОЙ МОЛОТ"] = "Восточные Чумные земли",
	["ЗАКАТНЫЙ ЛОВЕЦ"] = "Тельдрассил",
	["ПЫЛЬНЫЙ ПРИЗРАК"] = "Зул'Фаррак",
	["ЭК'АЛОМ"] = "Ясеневый лес",
	["ИДАН РЕВУН"] = "Дун Морог",
	["ГОЛОВОРЕЗ ЭМИЛЬГУНД"] = "Мулгор",
	["ИНЖЕНЕР БЕЗОБРАЗЕЦ"] = "Степи",
	["ПАВШИЙ ВОИТЕЛЬ"] = "Монастырь Алого ордена",
	["ФЕРМЕР СОЛЛИДЕН"] = "Тирисфальские леса",
	["НЕИСПРАВНЫЙ БОЕВОЙ ГОЛЕМ"] = "Тлеющее ущелье",
	["ФЕДФЕНХЕЛЬ"] = "Элвиннский лес",
	["ТЕНЬ ФЕЛЛИСЕНТЫ"] = "Тирисфальские леса",
	["ФЕНРОС"] = "Сумеречный лес",
	["УЗКИЙ ПЛАВНИК"] = "Болото Печали",
	["РАДИСОН ПРИЗЫВАТЕЛЬ ОГНЯ"] = "Темные берега",
	["ГРЯЗНЮК ЖЕСТОКИЙ"] = "Темные берега",
	["ВРАГОРЕЗ-4"] = "Западный Край",
	["ШТЕЙГЕР ГРИЛЗ"] = "Степи",
	["ШТЕЙГЕР ДЖЕРРИС"] = "Западные Чумные земли",
	["ШТЕЙГЕР МАРКРИД"] = "Западные Чумные земли",
	["СКВЕРНОГРИВ"] = "Западные Чумные земли",
	["ФУРИЯ ШЕЛЬДА"] = "Тельдрассил",
	["ГАРНЕГ ОБУГЛЕННЫЙ ЧЕРЕП"] = "Болотина",
	["ПРИВРАТНИК ГРОЗНОРЕВ"] = "Азшара",
	["ГЕНЕРАЛ ФАНГФЕРРОР"] = "Азшара",
	["ВЛАДЫЧИЦА ЗЕМЕЛЬ РЯБКА"] = "Дуротар",
	["ГЕОМАНТ КРЕМНЕНОЖ"] = "Нагорье Арати",
	["ЖРИЦА ЗЕМЛИ ГУКК'РОК"] = "Степи",
	["ПРИЗРАЧНЫЙ ВОЙ"] = "Мулгор",
	["ГЛУПОШМЫГ"] = "Тысяча Игл",
	["ГИБЛОМОР"] = "Дун Морог",
	["ХОХОТУНЬЯ"] = "Пустоши",
	["ГИЛМОРИАН"] = "Болото Печали",
	["ГИШ НЕДВИЖИМЫЙ"] = "Восточные Чумные земли",
	["БАРАБУЛЬ"] = "Тернистая долина",
	["БРАТ ЛИСТВЫ"] = "Фералас",
	["КОСТОГЛОД"] = "Болотина",
	["ЖУТКОКЛЫК"] = "Серебряный бор",
	["ГОРГОН'ОХ"] = "Пылающие степи",
	["ГРАВИС СЛИПНОТ"] = "Альтеракские горы",
	["ВЕЛИКИЙ ОТЕЦ АРКТИКУС"] = "Дун Морог",
	["БОЛЬШОЙ ОГНЕКРЫЛ"] = "Танарис",
	["ГРЕТИР"] = "Силитус",
	["ЗЛОВЕЩАЯ УТРОБА"] = "Тельдрассил",
	["ТЕМНОЗУБ"] = "Альтеракская долина",
	["ГРИЗЛАК"] = "Лок Модан",
	["ГРИЗЗЛ СНЕЖНАЯ ЛАПА"] = "Зимние Ключи",
	["ГРУБТОР"] = "Силитус",
	["ГРАФФ БЫСТРОХВАТ"] = "Элвиннский лес",
	["ГРУКЛАШ"] = "Пылающие степи",
	["ХРЮГГЕР"] = "Выжженные земли",
	["ХААРКА НЕНАСЫТНЫЙ"] = "Танарис",
	["ХАК'ЗОР"] = "Пылающие степи",
	["ТВЕРДОСПИН"] = "Дун Морог",
	["ХАРБ ПОГАНАЯ ГОРА"] = "Тысяча Игл",
	["ХАЙОК"] = "Пылевые топи",
	["ХЕД'МАШ ГНИЮЩИЙ"] = "Восточные Чумные земли",
	["ХЕГГИН КАМНЕУС"] = "Степи",
	["ВЕРХОВНЫЙ ГЕНЕРАЛ АББЕНДИС"] = "Восточные Чумные земли",
	["ШШШПЕРАК"] = "Пустоши",
	["ВОЖАК СТАИ ХУМАР"] = "Степи",
	["УРАГАНИЙ"] = "Силитус",
	["СТАЛЕСПИН"] = "Внутренние земли",
	["ЖЕЛЕЗНОСПИН"] = "Монастырь Алого ордена",
	["ДЖАЛИНДА ДРАКОН ЛЕТА"] = "Внутренние земли",
	["ДЖИММИ КРОВОПУСК"] = "Альтеракские горы",
	["КАСКК"] = "Пустоши",
	["КАЗОН"] = "Красногорье",
	["КОВОРК"] = "Нагорье Арати",
	["КРЕГГ КИЛЬВАТЕЛЬ"] = "Танарис",
	["КРЕГГ КИЛЬВАТЕЛЬ"] = "Силитус",
	["КРЕТИС ТЕНЕТКАЧ"] = "Серебряный бор",
	["КУРМОКК"] = "Тернистая долина",
	["ЛЕДИ ХЕДЕРИНА"] = "Зимние Ключи",
	["ЛЕДИ ЛУНООКАЯ"] = "Темные берега",
	["ЛЕДИ СЕССПИРА"] = "Азшара",
	["ЛЕДИ СЗАЛЛА"] = "Фералас",
	["ЛЕДИ ВЕСПИЯ"] = "Ясеневый лес",
	["ЛЕДИ ВЕСПИРА"] = "Темные берега",
	["ЛЕДИ ЗЕФРИС"] = "Предгорья Хилсбрада",
	["ЛАПРЕСС"] = "Силитус",
	["БОЛЬШОЙ ОЗЕРНЫЙ КРОКОЛИСК"] = "Лок Модан",
	["КРОВАВАЯ ВДОВА"] = "Болотина",
	["ЛЕПРИТУС"] = "Западный Край",
	["ЛИСИЛЛИН"] = "Темные берега",
	["ЛО'ГРОШ"] = "Альтеракские горы",
	["МОРСКОЙ ЧЕРТ"] = "Пылевые топи",
	["ЛОРД КОНДАР"] = "Лок Модан",
	["ЛОРД ТЕМНОКОС"] = "Восточные Чумные земли",
	["ЛОРД МАЛАТРОМ"] = "Сумеречный лес",
	["ЛОРД МАЛДАЗЗАР"] = "Западные Чумные земли",
	["ЛОРД САКРАСИС"] = "Тернистая долина",
	["ЛОРД НЕЧЕСТИВЕЦ"] = "Темные берега",
	["ВОЖДЬ ИЗ ПЛЕМЕНИ ЗАБЛУДШИХ"] = "Болото Печали",
	["ПОВАР ИЗ ПЛЕМЕНИ ЗАБЛУДШИХ"] = "Болото Печали",
	["ЗАБЛУДШАЯ ДУША"] = "Тирисфальские леса",
	["ВОЛКУС"] = "Сумеречный лес",
	["МА'РУК ЗМЕИНАЯ ЧЕШУЯ"] = "Болотина",
	["МАГИСТР СОКОЛИНЫЙ ШЛЕМ"] = "Азшара",
	["МАГОШ"] = "Лок Модан",
	["МАГРОНОС НЕУСТУПЧИВЫЙ"] = "Выжженные земли",
	["СЛОМАННЫЙ РАЗОРИТЕЛЬ"] = "Пылающие степи",
	["МАЛГИН ЯЧМЕНОВАР"] = "Степи",
	["СТАРШИЙ ЗЕМЛЕКОП"] = "Западный Край",
	["МАСТЕР СТРАХОЖУТЬ"] = "Азшара",
	["МАЗЗРАНАЧ"] = "Мулгор",
	["МЕЗЗИР РЕВУН"] = "Зимние Ключи",
	["ПОДБОЛОТНИК"] = "Болотина",
	["РЕВУН ИЗ ТУМАНА"] = "Ясеневый лес",
	["МОДЖО ЗЛОВРЕДНЫЙ"] = "Выжженные земли",
	["МОЛОК СОКРУШИТЕЛЬ"] = "Нагорье Арати",
	["ОБЛЕЗЛЫЙ ШИП"] = "Болото Печали",
	["ПОЛУКРОВ"] = "Оскверненный лес",
	["МОРГАНА ЛУКАВАЯ"] = "Элвиннский лес",
	["МАТЬ КЛЫК"] = "Элвиннский лес",
	["МУАД"] = "Тирисфальские леса",
	["ШОКОЛАДНЫЙ ПЛАВНИК"] = "Ясеневый лес",
	["БЕЗЖАЛОСТНЫЙ ХРОМОНОГ"] = "Танарис",
	["НАЛ'ТАЗАР"] = "Когтистые горы",
	["НАРАКСИС"] = "Сумеречный лес",
	["НАРГ НАДСМОТРЩИК"] = "Элвиннский лес",
	["НЕФАРУ"] = "Сумеречный лес",
	["НИМАР ДУШЕГУБ"] = "Нагорье Арати",
	["ДУБОЛАП"] = "Ясеневый лес",
	["СТАРЫЙ УТЕСНЫЙ ПРЫГУН"] = "Внутренние земли",
	["СТАРЫЙ СЕРОБРЮХ"] = "Фералас",
	["СТАРЫЙ ГУБАЧ"] = "Серебряный бор",
	["ОЛМ МУДРЫЙ"] = "Оскверненный лес",
	["ОМГОРН ЗАБЛУДШИЙ"] = "Танарис",
	["СЛИЗНЕЧЕРВ"] = "Пылевые топи",
	["ВЕЛИЧАВЫЙ ПАТРИАРХ"] = "Когтистые горы",
	["ПРИНЦ КЕЛЛЕН"] = "Пустоши",
	["ПРИНЦ НАЗДЖАК"] = "Нагорье Арати",
    ["ПРИНЦ РЕЙЗ"] = "Ясеневый лес",
    ["ГНИЛИУС"] = "Западные Чумные земли",
    ["КВИРОТ"] = "Фералас",
    ["ЛАПА ЯРОСТИ"] = "Оскверненный лес",
    ["РАК'ШИРИ"] = "Зимние Ключи",
    ["ПРЕДВОДИТЕЛЬ СЛЕДОПЫТОВ ЯСТРЕБИНОЕ КОПЬЕ"] = "Восточные Чумные земли",
    ["РАТОРИАН"] = "Степи",
    ["РАЗОР"] = "Выжженные земли",
    ["РАВАЗАВР-МАТРИАРХ"] = "Кратер Ун'Горо",
    ["РЕГЕНТ КОГТЯ ВОРОНА"] = "Серебряный бор",
    ["ОСТРОЗУБ-МАТРИАРХ"] = "Болотина",
    ["БРИТВОКОГОТЬ"] = "Внутренние земли",
    ["РЕКК'ТИЛАК"] = "Тлеющее ущелье",
    ["КУССАН ЖАЛЯЩИЙ"] = "Тирисфальские леса",
    ["РЕТЕРОКК БЕРСЕРК"] = "Внутренние земли",
    ["КОСТЕЛОМ"] = "Красногорье",
    ["ПОТРОШИЛА"] = "Тернистая долина",
    ["ЧЕШУЕКУС"] = "Пылевые топи",
    ["РО'БАРК"] = "Предгорья Хилсбрада",
    ["РОХХ МОЛЧАЛИВЫЙ"] = "Красногорье",
    ["РОЛОХ"] = "Тернистая долина",
    ["РОРГИШ МОЩНАЯ ЧЕЛЮСТЬ"] = "Ясеневый лес",
    ["КОСТОЛОМ ИЗ СТАИ ГНИЛОШКУРОВ"] = "Серебряный бор",
    ["ГРОХОТУН"] = "Бесплодные земли",
    ["САНДАРР РАЗОРИТЕЛЬ БАРХАНОВ"] = "Зул'Фаррак",
    ["ЖАР"] = "Тлеющее ущелье",
    ["ЧЕШУЙЧАТОЕ БРЮХО"] = "Тернистая долина",
    ["ШРАМНИК"] = "Предгорья Хилсбрада",
    ["ДОЗНАВАТЕЛЬ ИЗ АЛОГО ОРДЕНА"] = "Западные Чумные земли",
    ["СУДЬЯ ИЗ АЛОГО ОРДЕНА"] = "Западные Чумные земли",
    ["КУЗНЕЦ ИЗ АЛОГО ОРДЕНА"] = "Западные Чумные земли",
    ["ИСКАТЕЛЬ АКВАЛОН"] = "Красногорье",
    ["ЧАСОВОЙ АМАРАССАН"] = "Когтистые горы",
    ["СЕРЖАНТ ОСТРЫЙ КОГОТЬ"] = "Западный Край",
    ["СЕТИС"] = "Силитус",
    ["ТВАРЬ ИЗ КЛОАК"] = "Штормград",
    ["ТЕНЕКОГОТЬ"] = "Темные берега",
    ["ТЕНЕГОРНСКИЙ КОМАНДИР"] = "Бесплодные земли",
    ["ШАНДА ПРЯДИЛЬЩИЦА"] = "Лок Модан",
    ["ШЛЕЙПНАРР"] = "Тлеющее ущелье",
    ["СИЛИТИД-ЖНЕЦ"] = "Степи",
    ["ОПУСТОШИТЕЛЬ-СИЛИТИД"] = "Тысяча Игл",
    ["ПЕВИЦА"] = "Нагорье Арати",
    ["СКВОЙ"] = "Альтеракские горы",
    ["СЛАРК"] = "Западный Край",
    -- ["ПОВЕЛИТЕЛЬ РАБОВ ЧЕРНОСЕРД"] = "Тлеющее ущелье", -- underground mob, may wanna disable
    ["СЛЯКОХЛЮП"] = "Степи",
    ["БОЛОТНЫЙ СЛЯКОЧ"] = "Болотина",
    ["СМОЛДАР"] = "Тлеющее ущелье",
    ["КРИВОЕ КОПЬЕ"] = "Мулгор",
    ["РЫКУН"] = "Фералас",
    ["ОГНЕМОРДИК"] = "Красногорье",
    ["СПУТАННАЯ ГРИВА"] = "Серебряный бор",
    ["ФЫРК ДРАЗНИЛА"] = "Степи",
    ["СОРИИД ПОЖИРАТЕЛЬ"] = "Танарис",
    ["ЗЛОБОКЛЮЙ"] = "Выжженные земли",
    ["КАЛЬМАРНИК"] = "Красногорье",
    ["ШРИ'СКАЛК"] = "Тирисфальские леса",
    ["КАМЕННАЯ ЯРОСТЬ"] = "Альтеракские горы",
    ["КАМЕННАЯ РУКА"] = "Степи",
    ["ДОЛГОНОГ-НЕСУШКА"] = "Темные берега",
    ["ИСКРА УЖАСА"] = "Пылающие степи",
    ["ВОЖАК ТЕРРОВОЛКОВ"] = "Ясеневый лес",
    ["ТАУРИС БАЛЬГАРР"] = "Пылающие степи",
    ["ЧИСТИЛЬЩИК"] = "Восточные Чумные земли",
    ["ЭВАЛЧАРР"] = "Азшара",
    ["КИКИМОРД"] = "Западные Чумные земли",
    ["ОНГАР"] = "Оскверненный лес",
    ["ЦАП-ЦАРАП"] = "Мулгор",
    ["РАЗЗА"] = "Забытый Город",
    ["РИК"] = "Внутренние земли",
    ["ГНИЛЬ"] = "Пылевые топи",
    ["ТРЕГГИЛ"] = "Тельдрассил",
    ["ГРОМОСТУП"] = "Степи",
    ["ТУРОС ЛОВКОРУК"] = "Элвиннский лес",
    ["СЕРЫЙ"] = "Дун Морог",
    ["СТРАДАЮЩАЯ ДУША"] = "Тирисфальские леса",
    ["ВЛАДЫКА ЭВЕРАН ИЗ КУЛЬТА СУМЕРЕЧНОГО МОЛОТА"] = "Силитус",
    ["АК'ЛОК"] = "Кратер Ун'Горо",
    ["УРСОЛ'ЛОК"] = "Ясеневый лес",
    ["УРУСОН"] = "Тельдрассил",
    ["ПРИВИДЕНИЕ ВАРО'ТЕНА"] = "Азшара",
    ["МСТИТЕЛЬНЫЙ ДРЕВНЯК"] = "Когтистые горы",
    ["МИГАФОНИКС "] = "Тернистая долина",
    ["ВОЛХАН"] = "Пылающие степи",
    ["САРЫЧ"] = "Западный Край",
    ["БОЕВОЙ ГОЛЕМ"] = "Бесплодные земли",
    ["ПОЛКОВОДЕЦ КОЛКАНИС"] = "Дуротар",
    ["ПОЛКОВОДЕЦ МОЛОТ'ДЖИН"] = "Восточные Чумные земли",
    ["КОМАНДИР СТРАЖИ ЗАЛАФИЛ"] = "Дуротар",
    ["СУХОСЕРД ЛОВЧИЙ"] = "Внутренние земли",
    ["ЗАЛАС СУХОКОЖИЙ"] = "Нагорье Арати",
    ["ЗОРА"] = "Силитус",
    ["ЗУЛ'БРИН КРИВОДРЕВ"] = "Восточные Чумные земли",
    ["ЗУЛ'АРЕК ЗЛОБНЫЙ ОХОТНИК"] = "Внутренние земли",
    -- Thanks to Macumba for finding these rares
	["МАСТЕР ЛОПАТОРУК"] = "Бесплодные земли",
	["ЧУДИЩЕ"] = "Черная гора",
    ["ТРЕГЛА"] = "Леса Вечной Песни",
	["ЗОМБИРОВАННЫЙ ДВОРЯНИН"] = "Мертвые копи",
	["ТРИГОР ХЛЕСТУН"] = "Пещеры Стенаний",
	["БОАН"] = "Пещеры Стенаний",
	["ЦАПЧИК"] = "Пустоши",
	["ЗЕККИС"] = "Храм Атал'Хаккар",
	["ВЕЙЖАК КАННИБАЛ"] = "Храм Атал'Хаккар",
	-- TBC
    ["ШАДИКИТ СКОЛЬЗЯЩИЙ"] = "Каражан",
    ["ХИАКИСС СКРЫТЕНЬ"] = "Каражан",
    ["РОКАД ОПУСТОШИТЕЛЬ"] = "Каражан",
    ["ЖУТКОЗУБ"] = "Награнд",
    ["ОХОТНИК БЕЗДНЫ ЯР"] = "Награнд",
    ["БРО'ГАЗ БЕЗ КЛАНА"] = "Награнд",
    ["МАРТИКАР"] = "Зангартопь",
    ["ТРЯСИННЫЙ СКРЫТЕНЬ"] = "Зангартопь",
    ["ЭМИССАР РЕЗЕРВУАРА КРИВОГО КЛЫКА"] = "Зангартопь",
    ["НУРАМОК"] = "Пустоверть",
    ["НЕДРЕМЛЮЩИЙ КАРАТЕЛЬ"] = "Пустоверть",
    ["ГЛАВНЫЙ ИНЖЕНЕР ЛОРТАНДЕР"] = "Пустоверть",
    ["ПОСОЛ ЖЕРРИКАР "] = "Долина Призрачной Луны",
    ["СТРАЖ ПОРТАЛА КОЛЛИДУС"] = "Долина Призрачной Луны",
    ["КРААТОР"] = "Долина Призрачной Луны",
    ["ВОРАКЕМ ГЛАШАТАЙ СУДЬБЫ"] = "Полуостров Адского Пламени",
    ["ОБЖОРЕНЬ"] = "Полуостров Адского Пламени",
    ["МЕКТОРГ ДИКИЙ"] = "Полуостров Адского Пламени",
    ["ГЕМАТИОН"] = "Острогорье",
    ["МОРКРУШ"] = "Острогорье",
    ["ПРОПОВЕДНИК МАРГРОМ"] = "Острогорье",
    ["ЭЛДИНАРКУС"] = "Леса Вечной Песни",
    ["ДОКТОР БЕЛОРУЧКА"] = "Призрачные земли",
    ["РАСЧЛЕНИТЕЛЬ"] = "Лес Тероккар",
    ["ВЕСТНИК РОКА ДЖУРИМ"] = "Лес Тероккар",
    ["ОКРЕК"] = "Лес Тероккар",
    ["ФЕНИССА УБИЙЦА"] = "Остров Кровавой Дымки",
    -- ["СУДЬБОЛОМ"] = "Долина Призрачной Луны", -- disabled world boss
    -- ["ВЛАДЫКА СУДЕБ КАЗЗАК"] = "Полуостров Адского Пламени", -- disabled world boss
    -- WOTLK
    ["ФУМБЛУБ ВЕТРОЗУБ"] = "Борейская тундра",
    ["ЛЕДОРОГ"] = "Борейская тундра",
    ["СТАРЫЙ КРИСТАЛЬНЫЙ ДРЕВЕНЬ"] = "Борейская тундра",
    ["ВЫЖИВШИЙ СУМАСШЕДШИЙ ИЗ ДЕРЕВНИ ИНДУ'ЛЕ"] = "Драконий Погост",
    ["ВЕРХОВНЫЙ ЛОРД АЛОГО НАТИСКА ДАЙОН"] = "Драконий Погост",
    ["ТЮКМУТ"] = "Драконий Погост",
    ["АРКТУР"] = "Седые холмы",
    ["ГРОКЛАР"] = "Седые холмы",
    ["ПЫЛАЮЩАЯ НЕНАВИСТЬ"] = "Седые холмы",
    ["СИРЕЙНА КОСТЕРЕЗ"] = "Седые холмы",
    ["КОРОЛЬ ПИНГ"] = "Ревущий фьорд",
    ["ПЕРОБАС КРОВОЖАДНЫЙ"] = "Ревущий фьорд",
    ["ВИГДИС ВОИТЕЛЬНИЦА"] = "Ревущий фьорд",
    ["ВЕРХОВНЫЙ ТАН ЙОРФУС"] = "Ледяная Корона",
    ["ХИЛЬДАНА ПОХИТИТЕЛЬНИЦА СМЕРТИ"] = "Ледяная Корона",
    ["ГНИЛЛИЙ ДРЕВНИЙ"] = "Ледяная Корона",
    ["АОТОНА"] = "Низина Шолазар",
    ["КОРОЛЬ КРУШ"] = "Низина Шолазар",
    ["ЛОКЕ'НАХАК"] = "Низина Шолазар",
    ["ДИРКИ"] = "Грозовая Гряда",
    ["СКОЛЛ"] = "Грозовая Гряда",
    ["ЗАТЕРЯННЫЙ ВО ВРЕМЕНИ ПРОТОДРАКОН"] = "Грозовая Гряда",
    ["ВИРАГОСА"] = "Грозовая Гряда",
    ["ГОНДРИЯ"] = "Зул'Драк",
    ["ГРИГЕН"] = "Зул'Драк",
    ["ТКАЧ УЖАСА"] = "Зул'Драк",
    ["ЧАСОВОЙ ЗУЛ'ДРАКА"] = "Зул'Драк",
    }
elseif currentLocale == "frFR" then
    rare_spawns = {
	["AZUROUS"] = "Berceau-de-l'Hiver",
	["GÉNÉRAL COLBATANN"] = "Berceau-de-l'Hiver",
	["KASHOCH LE RAVAGEUR"] = "Berceau-de-l'Hiver",
	["DAME HEDERINE"] = "Berceau-de-l'Hiver",
	["ALSHIRR SOUFFLÉAU"] = "Gangrebois",
	["DESSECUS"] = "Gangrebois",
	["IMMOLATUS"] = "Gangrebois",
	["MONNOS L'ANCIEN"] = "Azshara",
	["BARBE-D'ÉCAILLES"] = "Azshara",
	["FRÈRE CORVICHÊNE"] = "Les Serres-Rocheuses",
	["CONTREMAÎTRE GRÉEUR"] = "Les Serres-Rocheuses",
	["SŒUR RIVEN"] = "Les Serres-Rocheuses",
	["AILES DU DÉSESPOIR"] = "Les Serres-Rocheuses",
	["SOUS-CHEF FOUETTECROC"] = "Les Serres-Rocheuses",
	["AEAN ONDEVIVE"] = "Les Tarides",
	["AMBASSADEUR RAGESANG"] = "Les Tarides",
	["BRONTUS"] = "Les Tarides",
	["CAPITAINE GEROGG MARTÈLORTEIL"] = "Les Tarides",
	["ANCIENNE MYSTIQUE TRANCHEGROIN"] = "Les Tarides",
	["GESHARAHAN"] = "Les Tarides",
	["HAGG PLAIE-DES-TAURENS"] = "Les Tarides",
	["HANNAH FEUILLELAME"] = "Les Tarides",
	["MARCUS BEL"] = "Les Tarides",
	["ROCHELANCE"] = "Les Tarides",
	["SŒUR RATHTALON"] = "Les Tarides",
	["VIF-CRINS"] = "Les Tarides",
	["PEAU-PIQUANTE POURCEGART"] = "Les Tarides",
	["TAKK LE BONDISSEUR"] = "Les Tarides",
	["THORA PENNELUNE"] = "Les Tarides",
	["CAPITAINE PLATE-DÉFENSE"] = "Durotar",
	["GANGRETISSEUR ARROGG"] = "Durotar",
	["SOUFRESANG"] = "Marécage d'Âprefange",
	["SŒUR CINGLEHAINE"] = "Mulgore",
	["TRANCHECOEUR"] = "Mille pointes",
	["FERREGARD L’INVINCIBLE"] = "Mille pointes",
	["DARDEUR"] = "Mille pointes",
	["JIN'ZALLAH PORTE-SABLE"] = "Tanaris",
	["CHEF DE GUERRE KRAZZILAK"] = "Tanaris",
	["GRUFF"] = "Cratère d'Un'Goro",
	["ROI MOSH"] = "Cratère d'Un'Goro",
	["REX ASHIL"] = "Silithus",
	["BOURREAU ÉCARLATE"] = "Maleterres de l'ouest",
	["GRAND PRÊTRE ÉCARLATE"] = "Maleterres de l'ouest",
	["TAMRA FOUDREPIQUE"] = "Contreforts de Hautebrande",
	["NARILLASANZ"] = "Montagnes d'Alterac",
	["GRIMUNGOUS"] = "Les Hinterlands",
	["MITH'RETHIS L'ENCHANTEUR"] = "Les Hinterlands",
	["DARBEL MONTROSE"] = "Hautes-terres d'Arathi",
	["SOUILLEBEDON"] = "Hautes-terres d'Arathi",
	["RUUL UNEPIERRE"] = "Hautes-terres d'Arathi",
	["EMOGG LE BROYEUR"] = "Loch Modan",
	["GOLEM DE SIÈGE"] = "Terres ingrates",
	["GÉNÉRALISSIME MASTROGONDE"] = "Gorge des Vents brûlant",
	["HEMATOS"] = "Steppes ardentes",
	["SEIGNEUR-CAPITAINE WYRMAK"] = "Marais des Chagrins",
	["JADE"] = "Marais des Chagrins",
	["GRANDE PRÊTRESSE HAI'WATNA"] = "Vallée de Strangleronce",
	["BOUCHER MOSH'OGG"] = "Vallée de Strangleronce",
	["ANATHEMUS"] = "Terres ingrates",
	["ZARICOTL"] = "Terres ingrates",
	["DRAGON FÉERIQUE DÉVIANT"] = "Cavernes des lamentations",
	["MESHLOK LE MOISSONNEUR"] = "Maraudon",
	["CHASSEUR AVEUGLE"] = "Kraal de Tranchebauge",
	["IMPLORATEUR DE LA TERRE HALMGAR"] = "Kraal de Tranchebauge",
	["LANCEUR DE TRANCHEBAUGE"] = "Kraal de Tranchebauge",
	["ZERILLIS"] = "Zul'Farrak",
	["AZSHIR LE SANS-SOMMEIL"] = "Monastère écarlate",
	["CHANTELOGE FORRESTIN"] = "Stratholme",
	["KRÂN"] = "Stratholme",
	["ECHINE-DE-PIERRE"] = "Stratholme",
	["CAPITAINE LIGEMORT"] = "Donjon d'Ombrecroc",
	["AMBASSADEUR SOMBREFER"] = "Gnomeregan",
	["SEIGNEUR ROCCOR"] = "Profondeurs de Rochenoire",
	["PANZOR L'INVINCIBLE"] = "Profondeurs de Rochenoire",
	["PYROMANCIEN BLÉ-DU-SAVOIR"] = "Profondeurs de Rochenoire",
	["VEREK"] = "Profondeurs de Rochenoire",
	["GARDIEN STILGISS"] = "Profondeurs de Rochenoire",
	["BANNOK HACHE-SINISTRE"] = "Pic Rochenoire",
	["GANGREGARDE ARDENT"] = "Pic Rochenoire",
	["CROC CRISTALLIN"] = "Pic Rochenoire",
	["GHOK BOUNNEBAFFE"] = "Pic Rochenoire",
	["SEIGNEUR DE BATAILLE PIERRE-DU-PIC"] = "Pic Rochenoire",
	["BOUCHER PIERRE-DU-PIC"] = "Pic Rochenoire",
	["SEIGNEUR MAGUS PIERRE-DU-PIC"] = "Pic Rochenoire",
	["JED GUETTE-RUNES"] = "Pic Rochenoire",
	["BRUEGAL POING-DE-FER"] = "La Prison",
	["MINEUR JOHNSON"] = "Les Mortemines",
	["BÂLHAFR L'INVAINCU"] = "Hache-tripes",
	["MUSHGOG"] = "Hache-tripes",
	["7:XT"] = "Terres ingrates",
	["ONDULAME MAUDIT"] = "Désolace",
	["ACHELLIOS LE BANNI"] = "Mille pointes",
	["AKKRILUS"] = "Orneval",
	["AKUBAR LE PROPHÈTE"] = "Terres foudroyées",
	["ANTILOS"] = "Azshara",
	["ANTILUS LE PLANEUR"] = "Féralas",
	["APOTHICAIRE FALTHIS"] = "Orneval",
	["ARAGA"] = "Montagnes d'Alterac",
	["ARASH-ETHIS"] = "Féralas",
	["AZZERE LA LAME CÉLESTE"] = "Les Tarides",
	["BARNABUS"] = "Terres ingrates",
	["BAYNE"] = "Clairières de Tirisfal",
	["GROS SAMRAS"] = "Contreforts de Hautebrande",
	["BJARN"] = "Dun Morogh",
	["NOIREMOUSSE LE FÉTIDE"] = "Teldrassil",
	["RUGISSANG LE TRAQUEUR"] = "Féralas",
	["BOSS GALGOSH"] = "Loch Modan",
	["ROCHECOEUR"] = "Les Carmines",
	["BRACK"] = "Marche de l'Ouest",
	["MARISA DU'PAIGE"] = "Marche de l'Ouest",
	["BRISE-BRANCHE"] = "Orneval",
	["BRÈCHEDENT"] = "Terres ingrates",
	["BRISE-ÉPIEU"] = "Les Tarides",
	["PIQUE-LES-YEUX"] = "Marécage d'Âprefange",
	["CARNIVOUS LE CASSEUR"] = "Sombrivage",
	["CLIQUETEUSE"] = "Les Carmines",
	["CLACK LE SACCAGEUR"] = "Terres foudroyées",
	["MATRIARCHE ZAVAS"] = "Cratère d'Un'Goro",
	["COMMANDANT GANGRETROMBE"] = "Bois de la Pénombre",
	["BENJ LE TEIGNEUX"] = "Montagnes d'Alterac",
	["INSINUEUSE"] = "Contreforts de Hautebrande",
	["ELITE CRAMOISIE"] = "Maleterres de l'ouest",
	["CENTAURE MAUDIT"] = "Désolace",
	["CYCLOK LE FOL"] = "Tanaris",
	["COPISTE DE DALARAN"] = "Forêt des Pins argentés",
	["VEUVE DE SOMBREBRUME"] = "Marécage d'Âprefange",
	["FLÈCHE"] = "Marécage d'Âprefange",
	["ECORCHEUR MORTEL"] = "Durotar",
	["HURLEMORT"] = "Gangrebois",
	["OEIL-DE-MORT"] = "Terres foudroyées",
	["GUEULE-DU-TRÉPAS"] = "Steppes ardentes",
	["NÉCRORATEUR SELENDRE"] = "Maleterres de l'est",
	["DEEB"] = "Clairières de Tirisfal",
	["TÊTE-DE-DIAMANT"] = "Féralas",
	["TERRASSIER FORGEFLAMME"] = "Les Tarides",
	["DISHU"] = "Les Tarides",
	["MAÎTRE DE GUERRE GUEULE-DE-DRAGON"] = "Les Paluns",
	["DÉRISEFFROI"] = "Terres foudroyées",
	["DROGOTH LE VAGABOND"] = "Marécage d'Âprefange",
	["DUGGAN MARTEAU-HARDI"] = "Maleterres de l'est",
	["TRAQUEUR DU CRÉPUSCULE"] = "Teldrassil",
	["AME EN PEINE POUDREUSE"] = "Zul'Farrak",
	["ECK'ALOM"] = "Orneval",
	["EDAN LE HURLEUR"] = "Dun Morogh",
	["MASSACREUR EMILGUND"] = "Mulgore",
	["INGÉNIEUR TOURBICOTON"] = "Les Tarides",
	["CHAMPION DÉCHU"] = "Monastère écarlate",
	["FERMIER DE SOLLIDEN"] = "Clairières de Tirisfal",
	["GOLEM DE GUERRE DÉFAILLANT"] = "Gorge des Vents brûlant",
	["FENOUILLARD"] = "Forêt d'Elwynn",
	["OMBRE DE FELLICENT"] = "Clairières de Tirisfal",
	["FENROS"] = "Bois de la Pénombre",
	["FINGAT"] = "Marais des Chagrins",
	["MANDEFEU RADISON"] = "Sombrivage",
	["FLAGGLEMURK LE CRUEL"] = "Sombrivage",
	["DÉCOUPEUR 4000"] = "Marche de l'Ouest",
	["CONTREMAÎTRE GRILLS"] = "Les Tarides",
	["CONTREMAÎTRE JERRIS"] = "Maleterres de l'ouest",
	["CONTREMAÎTRE MARCRID"] = "Maleterres de l'ouest",
	["VILCRIN"] = "Maleterres de l'ouest",
	["FURIE SHELDA"] = "Teldrassil",
	["GARNEG GRILLE-CRÂNE"] = "Les Paluns",
	["PORTIER HURLERAGE"] = "Azshara",
	["GÉNÉRAL CROCDANGOIFFE"] = "Azshara",
	["GÉOMAÎTRESSE MOUCHETTE"] = "Durotar",
	["GÉOMANCIEN DAGUE-DE-SILEX"] = "Hautes-terres d'Arathi",
	["GÉOPRÊTRESSE GUKK'ROK"] = "Les Tarides",
	["HURLEUR FANTOMATIQUE"] = "Mulgore",
	["MARGOUILLOCHE"] = "Mille pointes",
	["MARGOUILLEUR"] = "Dun Morogh",
	["GLOUSSE"] = "Désolace",
	["GILMORIAN"] = "Marais des Chagrins",
	["GISH L'IMMOBILE"] = "Maleterres de l'est",
	["GLOUGLOUG"] = "Vallée de Strangleronce",
	["GNARL FRÈREFEUILLES"] = "Féralas",
	["RONGE-LES-OS"] = "Les Paluns",
	["CROQUETRIPE"] = "Forêt des Pins argentés",
	["GORGON'OCH"] = "Steppes ardentes",
	["GRAVIS LECOLLET"] = "Montagnes d'Alterac",
	["GRAND-PÈRE ARCTIKUS"] = "Dun Morogh",
	["GRAND OISEAU DE FEU"] = "Tanaris",
	["GRETHEER"] = "Silithus",
	["MORNEGUEULE"] = "Teldrassil",
	["MÂCHINISTRE"] = "Alterac Valley",
	["GRIZLAK"] = "Loch Modan",
	["GRISON NEIGEPATTE"] = "Berceau-de-l'Hiver",
	["GRUBTHOR"] = "Silithus",
	["GRUFF MORD-VITE"] = "Forêt d'Elwynn",
	["GRUKLASH"] = "Steppes ardentes",
	["GRUNTER"] = "Terres foudroyées",
	["HAARKA LE FÉROCE"] = "Tanaris",
	["HAHK'ZOR"] = "Steppes ardentes",
	["MARTELLÉCHINE"] = "Dun Morogh",
	["HARB MONT-SOUILLÉ"] = "Mille pointes",
	["HAYOC"] = "Marécage d'Âprefange",
	["HED'MUSH LE POURRISSANT"] = "Maleterres de l'est",
	["HEGGIN MOUSTACHE-DE-PIERRE"] = "Les Tarides",
	["GRAND GÉNÉRAL ABBENDIS"] = "Maleterres de l'est",
	["HISSPERAK"] = "Désolace",
	["HUMAR LE FIER"] = "Les Tarides",
	["OURAGANIEN"] = "Silithus",
	["DOS-DE-FER"] = "Les Hinterlands",
	["ECHINE-DE-FER"] = "Monastère écarlate",
	["JALINDE DRAKE-D'ÉTÉ"] = "Les Hinterlands",
	["JIMMY LE SAIGNANT"] = "Montagnes d'Alterac",
	["KASKK"] = "Désolace",
	["KAZON"] = "Les Carmines",
	["KOVORK"] = "Hautes-terres d'Arathi",
	["KREGG SOULAQUILLE"] = "Tanaris",
	["KRELLACK"] = "Silithus",
	["KRETHIS TISSOMBRE"] = "Forêt des Pins argentés",
	["KURMOKK"] = "Vallée de Strangleronce",
	["DAME HEDERINE"] = "Berceau-de-l'Hiver",
	["DAME MIRELUNE"] = "Sombrivage",
	["DAME SESSPIRA"] = "Azshara",
	["DAME SZALLAH"] = "Féralas",
	["DAME VESPIA"] = "Orneval",
	["DAME VESPIRA"] = "Sombrivage",
	["DAME ZEPHRIS"] = "Contreforts de Hautebrande",
	["LAPRESS"] = "Silithus",
	["GRAND CROCILISQUE DU LOCH"] = "Loch Modan",
	["VEUVE SANGUINE"] = "Les Paluns",
	["LEPRITHUS"] = "Marche de l'Ouest",
	["LICILLIN"] = "Sombrivage",
	["LO'GROSH"] = "Montagnes d'Alterac",
	["SEIGNEUR BAUDROIE"] = "Marécage d'Âprefange",
	["SEIGNEUR CONDAR"] = "Loch Modan",
	["SEIGNEUR SOMBREFAUX"] = "Maleterres de l'est",
	["SEIGNEUR MALATHROM"] = "Bois de la Pénombre",
	["SEIGNEUR MALDAZZAR"] = "Maleterres de l'ouest",
	["SEIGNEUR SAKRASIS"] = "Vallée de Strangleronce",
	["SEIGNEUR SALVASSIO"] = "Sombrivage",
	["CHEF PERDU"] = "Marais des Chagrins",
	["CUISINIER PERDU"] = "Marais des Chagrins",
	["AME ÉGARÉE"] = "Clairières de Tirisfal",
	["LUPOS"] = "Bois de la Pénombre",
	["MA'RUK WYRMÉCAILLE"] = "Les Paluns",
	["MAGISTÈRE FALCOIFFE"] = "Azshara",
	["MAGOSH"] = "Loch Modan",
	["MAGRONOS L'INFLEXIBLE"] = "Terres foudroyées",
	["SACCAGEUR DÉFECTUEUX"] = "Steppes ardentes",
	["MALGIN BRASSELORGE"] = "Les Tarides",
	["MAÎTRE TERRASSIER"] = "Marche de l'Ouest",
	["MAÎTRE TROUILLEFFROI"] = "Azshara",
	["MAZZRANACHE"] = "Mulgore",
	["MEZZIR LE HURLEUR"] = "Berceau-de-l'Hiver",
	["BAS-BOUEUX"] = "Les Paluns",
	["HURLEUR DES BRUMES"] = "Orneval",
	["MOJO LE TORDU"] = "Terres foudroyées",
	["MOLOK L’ANÉANTISSEUR"] = "Hautes-terres d'Arathi",
	["ROUGERONCE"] = "Marais des Chagrins",
	["MONGRESS"] = "Gangrebois",
	["MORGAINE LA RUSÉE"] = "Forêt d'Elwynn",
	["MÈRE CROC"] = "Forêt d'Elwynn",
	["MUAD"] = "Clairières de Tirisfal",
	["MOLDAILERON"] = "Orneval",
	["BRÛLEPATTE MEURTRIER"] = "Tanaris",
	["NAL'TASZAR"] = "Les Serres-Rocheuses",
	["NARAXIS"] = "Bois de la Pénombre",
	["NARG LE SOUS-CHEF"] = "Forêt d'Elwynn",
	["NEFARU"] = "Bois de la Pénombre",
	["NIMAR LE POURFENDEUR"] = "Hautes-terres d'Arathi",
	["CHÊNEPATTE"] = "Orneval",
	["VIEUX SAUTE-FALAISE"] = "Les Hinterlands",
	["VIEUX GRISEBEDAINE"] = "Féralas",
	["VIEUX VILE MÂCHOIRE"] = "Forêt des Pins argentés",
	["OLM LA SAGE"] = "Gangrebois",
	["OMGORN L'EGARÉ"] = "Tanaris",
	["VER DE LIMON"] = "Marécage d'Âprefange",
	["PATRIARCHE AILE-FIÈRE"] = "Les Serres-Rocheuses",
	["PRINCE KELLEN"] = "Désolace",
	["PRINCE NAZJAK"] = "Hautes-terres d'Arathi",
    ["PRINCE RAZE"] = "Orneval",
    ["PUTRIDIUS"] = "Maleterres de l'ouest",
    ["QIROT"] = "Féralas",
    ["RAGEPATTE"] = "Gangrebois",
    ["RAK'SHIRI"] = "Berceau-de-l'Hiver",
    ["SEIGNEUR FORESTIER EPERLANCE"] = "Maleterres de l'est",
    ["RATHORIAN"] = "Les Tarides",
    ["RAVAGE"] = "Terres foudroyées",
    ["MATRIARCHE RAVASAURE"] = "Cratère d'Un'Goro",
    ["RÉGENT SERRES-DE-CORBEAU"] = "Forêt des Pins argentés",
    ["MATRIARCHE TRANCHEGUEULES"] = "Les Paluns",
    ["TRANCHESERRE"] = "Les Hinterlands",
    ["REKK'TILAC"] = "Gorge des Vents brûlant",
    ["RESSAN LE HARCELEUR"] = "Clairières de Tirisfal",
    ["RETHEROKK LE BERSERKER"] = "Les Hinterlands",
    ["CHASSECÔTES"] = "Les Carmines",
    ["RIPPA"] = "Vallée de Strangleronce",
    ["ARRACHÉCAILLE"] = "Marécage d'Âprefange",
    ["RO'BARK"] = "Contreforts de Hautebrande",
    ["ROHH LE SILENCIEUX"] = "Les Carmines",
    ["ROLOCH"] = "Vallée de Strangleronce",
    ["JOUFFLU LE CROQUANT"] = "Orneval",
    ["COGNEUR POIL-PUTRIDE"] = "Forêt des Pins argentés",
    ["GRONDEUR"] = "Terres ingrates",
    ["SANDARR RAVADUNE"] = "Zul'farrak",
    ["BRÛLAR"] = "Gorge des Vents brûlant",
    ["VENTRÉCAILLE"] = "Vallée de Strangleronce",
    ["SCARGIL"] = "Contreforts de Hautebrande",
    ["INQUISITEUR ÉCARLATE"] = "Maleterres de l'ouest",
    ["JUGE ÉCARLATE"] = "Maleterres de l'ouest",
    ["FORGERON ÉCARLATE"] = "Maleterres de l'ouest",
    ["AQUALON LE CHERCHEUR"] = "Les Carmines",
    ["SENTINELLE AMARASSAN"] = "Les Serres-Rocheuses",
    ["SERGENT PROMPTEGRIFFE"] = "Marche de l'Ouest",
    ["SETIS"] = "Silithus",
    ["BÊTE DES ÉGOUTS"] = "Hurlevent",
    ["OMBREGRIFFE"] = "Sombrivage",
    ["COMMANDANT OMBREFORGE"] = "Terres ingrates",
    ["SHANDA LA TISSEUSE"] = "Loch Modan",
    ["SHLEIPNARR"] = "Gorge des Vents brûlant",
    ["MOISSONNEUR SILITHIDE"] = "Les Tarides",
    ["RAVAGEUR SILITHIDE"] = "Mille pointes",
    ["SINGER"] = "Hautes-terres d'Arathi",
    ["GRYBOU"] = "Montagnes d'Alterac",
    ["SLARK"] = "Marche de l'Ouest",
	-- ["MAÎTRE DES ESCLAVES COEUR-NOIR"] = "Gorge des Vents brûlant", -- underground mob, may wanna disable
    ["LIMACE BESTIALE"] = "Les Tarides",
    ["BOUILLASSEUX"] = "Les Paluns",
    ["FUMAR"] = "Gorge des Vents brûlant",
    ["TRAVÉPIEU"] = "Mulgore",
    ["GROGNEUR"] = "Féralas",
    ["GRONDEFUSE"] = "Les Carmines",
    ["GRONDECRIN"] = "Forêt des Pins argentés",
    ["NIFLE LA MOQUEUSE"] = "Les Tarides",
    ["SORIID LE DÉVOREUR"] = "Tanaris",
    ["ECORCHEBILE"] = "Terres foudroyées",
    ["SQUIDDIC"] = "Les Carmines",
    ["SRI'SKULK"] = "Clairières de Tirisfal",
    ["FURIE-DE-PIERRE"] = "Montagnes d'Alterac",
    ["BRAS-DE-PIERRE"] = "Les Tarides",
    ["MATRIARCHE TROTTEUSE"] = "Sombrivage",
    ["LUEUR TERRIFIANTE"] = "Steppes ardentes",
    ["CHEF DE MEUTE FRAYELOUP"] = "Orneval",
    ["THAURIS BALGARR"] = "Steppes ardentes",
    -- ["LE NETTOYEUR"] = "Maleterres de l'est",  -- doesnt drop anything and too much hp.
    ["L'EVALCHARR"] = "Azshara",
    ["LA BOGUE"] = "Maleterres de l'ouest",
    ["L'ONGAR"] = "Gangrebois",
    ["LE GRIFFU"] = "Mulgore",
    ["LA RAZZA"] = "Hache-tripes",
    ["LE JONC"] = "Les Hinterlands",
    ["LA POURRITURE"] = "Marécage d'Âprefange",
    ["THREGGIL"] = "Teldrassil",
    ["GRONDETERRE"] = "Les Tarides",
    ["THUROS DOIGTS-AGILES"] = "Forêt d'Elwynn",
    ["GRUMEUX"] = "Dun Morogh",
    ["ESPRIT TOURMENTÉ"] = "Clairières de Tirisfal",
    ["SEIGNEUR DU CRÉPUSCULE EVERUN"] = "Silithus",
    ["UHK'LOC"] = "Cratère d'Un'Goro",
    ["URSOL'LOK"] = "Orneval",
    ["URUSON"] = "Teldrassil",
    ["FANTÔME DE VARO'THEN"] = "Azshara",
    ["ANCIEN VENGEUR"] = "Les Serres-Rocheuses",
    ["DROLATIX"] = "Vallée de Strangleronce",
    ["VOLCHAN"] = "Steppes ardentes",
    ["VULTROS"] = "Marche de l'Ouest",
    ["GOLEM DE GUERRE"] = "Terres ingrates",
    ["SEIGNEUR DE GUERRE KOLKANIS"] = "Durotar",
    ["SEIGNEUR DE GUERRE THRESH'JIN"] = "Maleterres de l'est",
    ["COMMANDANT DE LA GARDE ZALAPHIL"] = "Durotar",
    ["FLÉTRICOEUR LE TRAQUEUR"] = "Les Hinterlands",
    ["ZALAS FÂNÉCORCE"] = "Hautes-terres d'Arathi",
    ["ZORA"] = "Silithus",
    ["ZUL'BRIN VOILEBRANCHE"] = "Maleterres de l'est",
    ["ZUL'AREK VOLAILLAÎNE"] = "Les Hinterlands",
    -- Thanks to Macumba for finding these rares.	
    -- ["SURVEILLANT NÉRUBIEN"] = "Maleterres de l'est", -- doesnt drop anything worth and too much hp.
	["MAÎTRE DES FOUILLES PELLAPHLANGE"] = "Terres ingrates",
	-- ["INTENDANT DU BOUCLIER BALAFRÉ"] = "Mont Rochenoire", -- doesnt drop anything worth
	["LE BÉHÉMOTH"] = "Mont Rochenoire",
	["TREGLA"] = "Bois des Chants éternels",
	["NOBLE MANIPULÉ"] = "Les Mortemines",
	["TRIGORE LE FLAGELLEUR"] = "Cavernes des lamentations",
	["BOAHN"] = "Cavernes des lamentations",
	["CROUSTILLE"] = "Désolace",
	["ZEKKIS"] = "Le temple d'Atal'Hakkar",
	["VEYZHAK LE CANNIBALE"] = "Le temple d'Atal'Hakkar",
	-- TBC
    ["SHADIKITH LE GLISSEUR"] = "Karazhan",
    ["HYAKISS LA RÔDEUSE"] = "Karazhan",
    ["RODAK LE RAVAGEUR"] = "Karazhan",
    ["SANGREDENT"] = "Nagrand",
    ["CHASSEUR DU VIDE YAR"] = "Nagrand",
    ["BRO'GAZ SANS-CLAN"] = "Nagrand",
    ["MARTICAR"] = "Marécage de Zangar",
    ["RÔDEUR DES TOURBIÈRES"] = "Marécage de Zangar",
    ["EMISSAIRE DE GLISSECROC"] = "Marécage de Zangar",
    ["NURAMOC"] = "Raz-de-Néant",
    ["PERMACOEUR LE PUNISSEUR"] = "Raz-de-Néant",
    ["INGÉNIEUR EN CHEF LORTHANDER"] = "Raz-de-Néant",
    ["AMBASSADEUR JERRIKAR"] = "Vallée d'Ombrelune",
    ["COLLIDUS LE GUETTEUR-DIMENSIONNEL"] = "Vallée d'Ombrelune",
    ["KRAATOR"] = "Vallée d'Ombrelune",
    ["VORAKEM PARLERUINE"] = "Péninsule des Flammes infernales",
    ["GOINFREPLEIN"] = "Péninsule des Flammes infernales",
    ["MEKTHORG LE SAUVAGE"] = "Péninsule des Flammes infernales",
    ["HEMATHION"] = "Les Tranchantes",
    ["MORCRASE"] = "Les Tranchantes",
    ["PORTE-PAROLE MAR'GROM"] = "Les Tranchantes",
    ["ELDINARCUS"] = "Bois des Chants éternels",
    ["DR GÂTEMEMBRE"] = "Les Terres fantômes",
    ["ESTROPIEUR"] = "Forêt de Terokkar",
    ["AUSPICE FUNESTE JURIM"] = "Forêt de Terokkar",
    ["OKREK"] = "Forêt de Terokkar",
    ["FENISSA L'ASSASSIN"] = "Ile de Brume-sang",
    -- WOTLK
    ["LARMAGAUCHE VENBRAYE"] = "Toundra Boréenne",
    ["CORNEGLACE"] = "Toundra Boréenne",
    ["VIEIL ÉCORCE-DE-CRISTAL"] = "Toundra Boréenne",
    ["SURVIVANT D'INDU'LE AFFOLÉ"] = "Désolation des dragons",
    ["GÉNÉRALISSIME ÉCARLATE DAION"] = "Désolation des dragons",
    ["TUKEMUTH"] = "Désolation des dragons",
    ["ARCTURIS"] = "Les Grisonnes",
    ["GROCKLAR"] = "Les Grisonnes",
    ["HAINE VENGERESSE"] = "Les Grisonnes",
    ["SYREIAN LA SCULPTEUSE D'OS"] = "Les Grisonnes",
    ["ROI PING"] = "Fjord Hurlant",
    ["PEROBAS LE CARNASSIER"] = "Fjord Hurlant",
    ["VIGDIS LA VIERGE DE GUERRE"] = "Fjord Hurlant",
    ["GRAND THANE JORFUS"] = "La Couronne de glace",
    ["HILDANA VOLEUSE-DE-MORT"] = "La Couronne de glace",
    ["PUTRIDUS L'ANTIQUE"] = "La Couronne de glace",
    ["AOTONA"] = "Bassin de Sholazar",
    ["ROI KRUSH"] = "Bassin de Sholazar",
    ["LOQUE'NAHAK"] = "Bassin de Sholazar",
    ["DIRKEE"] = "Les pics Foudroyés",
    ["SKOLL"] = "Les pics Foudroyés",
    ["PROTO-DRAKE PERDU DANS LE TEMPS"] = "Les pics Foudroyés",
    ["VYRAGOSA"] = "Les pics Foudroyés",
    ["GONDRIA"] = "Zul'Drak",
    ["GRIEGEN"] = "Zul'Drak",
    ["TISSEUSE DE TERREUR"] = "Zul'Drak",
    ["SENTINELLE DE ZUL'DRAK"] = "Zul'Drak",
    }
-- elseif currentLocale == "deDE" then
--     rare_spawns = {
--         ["Marschall Dughan"] = "Wald von Elwynn",
--     }
-- elseif currentLocale == "esES" or currentLocale == "esMX" then
--     rare_spawns = {
--         ["Mariscal Dughan"] = "Bosque de Elwynn",
--     }
else
    -- If the current locale is not recognized, you can define a default table or display an error message
    if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00unitscan warning:|r " .. "|cffffff9aunrecognized client language, rare list is not populated. Only enGB / enUS & ruRU clients are currently supported for rare list.|r" .. "|cFFFFFF00 \nYou can still add any units via unitscan commands!|r")
    end
    rare_spawns = {
    }
end


do
	local last_played
	
	function unitscan.play_sound()
		if not last_played or GetTime() - last_played > 3 then
			PlaySoundFile([[Interface\AddOns\unitscan\assets\Event_wardrum_ogre.ogg]], 'Sound')
			PlaySoundFile([[Sound\Interface\MapPing.wav]], 'Sound')
			last_played = GetTime()
		end
	end
end

function unitscan.target(name)
	forbidden = false
	TargetUnit(name)
	-- unitscan.print(tostring(UnitHealth(name)) .. " " .. name)
	-- if not deadscan and UnitIsCorpse(name) then
	-- 	return
	-- end
	if forbidden then
		if not found[name] then
			found[name] = true
			--FlashClientIcon()
			unitscan.play_sound()
			unitscan.flash.animation:Play()
			unitscan.discovered_unit = name
			if InCombatLockdown() then
				print("|cFF00FF00unitscan found - |r |cffffff00" .. name .. "|r")
			end
		end
	else
		found[name] = false
	end
end

function unitscan.LOAD()
	UIParent:UnregisterEvent'ADDON_ACTION_FORBIDDEN'
	do
		local flash = CreateFrame'Frame'
		unitscan.flash = flash
		flash:Show()
		flash:SetAllPoints()
		flash:SetAlpha(0)
		flash:SetFrameStrata'LOW'
		SetCVar("Sound_EnableErrorSpeech", 0)
		
		local texture = flash:CreateTexture()
		texture:SetBlendMode'ADD'
		texture:SetAllPoints()
		texture:SetTexture[[Interface\FullScreenTextures\LowHealth]]

		flash.animation = CreateFrame'Frame'
		flash.animation:Hide()
		flash.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .5 then
				flash:SetAlpha(t * 2)
			elseif t <= 1 then
				flash:SetAlpha(1)
			elseif t <= 1.5 then
				flash:SetAlpha(1 - (t - 1) * 2)
			else
				flash:SetAlpha(0)
				self.loops = self.loops - 1
				if self.loops == 0 then
					self.t0 = nil
					self:Hide()
				else
					self.t0 = GetTime()
				end
			end
		end)
		function flash.animation:Play()
			if self.t0 then
				self.loops = 2
			else
				self.t0 = GetTime()
				self.loops = 1
			end
			self:Show()
		end
	end
	
	local button = CreateFrame('Button', 'unitscan_button', UIParent, 'SecureActionButtonTemplate')
	-- first code to set left and right click of button
	button:SetAttribute("type1", "macro")
	button:SetAttribute("type2", "macro")
	-- rest of button code
	button:Hide()
	unitscan.button = button
	button:SetPoint('BOTTOM', UIParent, 0, 128)
	button:SetWidth(150)
	button:SetHeight(42)
	button:SetScale(1.25)
	button:SetMovable(true)
	button:SetUserPlaced(true)
	button:SetClampedToScreen(true)

	-- code to enable ctrl-click to move (it has nothing to do with left and right click function)
	 button:SetScript('OnMouseDown', function(self)
	    if IsControlKeyDown() then
	        self:RegisterForClicks("AnyDown", "AnyUp")
	        self:StartMoving()
	    end
	end)
	button:SetScript('OnMouseUp', function(self)
	    self:StopMovingOrSizing()
	    self:RegisterForClicks("AnyDown", "AnyUp")
	end) 

	button:SetFrameStrata'LOW'
	button:SetNormalTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Parchment-Horizontal]]
	button:SetBackdrop{
		tile = true,
		edgeSize = 16,
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	}
	button:SetBackdropBorderColor(unpack(BROWN))
	button:SetScript('OnEnter', function(self)
		self:SetBackdropBorderColor(unpack(YELLOW))
	end)
	button:SetScript('OnLeave', function(self)
		self:SetBackdropBorderColor(unpack(BROWN))
	end)

	function button:set_target(name)
		-- string that adds name text to the button
		self:SetText(name)
		-- second code to set left and right click of button macro texts
		self:SetAttribute("macrotext1", "/cleartarget\n/targetexact " .. name)
		self:SetAttribute("macrotext2", "/click unitscan_close") -- this is made to click "close" button code for which is defined below
		-- rest of code
		self:Show()
		self.glow.animation:Play()
		self.shine.animation:Play()
	end
	
	do
		local background = button:GetNormalTexture()
		background:SetDrawLayer'BACKGROUND'
		background:ClearAllPoints()
		background:SetPoint('BOTTOMLEFT', 3, 3)
		background:SetPoint('TOPRIGHT', -3, -3)
		background:SetTexCoord(0, 1, 0, .25)
	end
	
	do
		local title_background = button:CreateTexture(nil, 'BORDER')
		title_background:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Title]]
		title_background:SetPoint('TOPRIGHT', -5, -5)
		title_background:SetPoint('LEFT', 5, 0)
		title_background:SetHeight(18)
		title_background:SetTexCoord(0, .9765625, 0, .3125)
		title_background:SetAlpha(.8)

		local title = button:CreateFontString(nil, 'OVERLAY')
		--title:SetWordWrap(false)
		title:SetFont([[Fonts\FRIZQT__.TTF]], 14)
		title:SetShadowOffset(1, -1)
		title:SetPoint('TOPLEFT', title_background, 0, 0)
		title:SetPoint('RIGHT', title_background)
		button:SetFontString(title)

		local subtitle = button:CreateFontString(nil, 'OVERLAY')
		subtitle:SetFont([[Fonts\FRIZQT__.TTF]], 14)
		subtitle:SetTextColor(0, 0, 0)
		subtitle:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -4)
		subtitle:SetPoint('RIGHT', title)
		subtitle:SetText'Unit Found!'
	end
	
	do
		local model = CreateFrame('PlayerModel', nil, button)
		button.model = model
		model:SetPoint('BOTTOMLEFT', button, 'TOPLEFT', 0, -4)
		model:SetPoint('RIGHT', 0, 0)
		model:SetHeight(button:GetWidth() * .6)
	end
	
	do
		local close = CreateFrame('Button', "unitscan_close", button, 'UIPanelCloseButton')
		close:SetPoint('BOTTOMRIGHT', 5, -5)
		close:SetWidth(32)
		close:SetHeight(32)
		close:SetScale(.8)
		close:SetHitRectInsets(8, 8, 8, 8)
	end
	
	do
		local glow = button.model:CreateTexture(nil, 'OVERLAY')
		button.glow = glow
		glow:SetPoint('CENTER', button, 'CENTER')
		glow:SetWidth(400 / 300 * button:GetWidth())
		glow:SetHeight(171 / 70 * button:GetHeight())
		glow:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Alert-Glow]]
		glow:SetBlendMode'ADD'
		glow:SetTexCoord(0, .78125, 0, .66796875)
		glow:SetAlpha(0)

		glow.animation = CreateFrame'Frame'
		glow.animation:Hide()
		glow.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .2 then
				glow:SetAlpha(t * 5)
			elseif t <= .7 then
				glow:SetAlpha(1 - (t - .2) * 2)
			else
				glow:SetAlpha(0)
				self:Hide()
			end
		end)
		function glow.animation:Play()
			self.t0 = GetTime()
			self:Show()
		end
	end

	do
		local shine = button:CreateTexture(nil, 'ARTWORK')
		button.shine = shine
		shine:SetPoint('TOPLEFT', button, 0, 8)
		shine:SetWidth(67 / 300 * button:GetWidth())
		shine:SetHeight(1.28 * button:GetHeight())
		shine:SetTexture[[Interface\AddOns\unitscan\assets\UI-Achievement-Alert-Glow]]
		shine:SetBlendMode'ADD'
		shine:SetTexCoord(.78125, .912109375, 0, .28125)
		shine:SetAlpha(0)
		
		shine.animation = CreateFrame'Frame'
		shine.animation:Hide()
		shine.animation:SetScript('OnUpdate', function(self)
			local t = GetTime() - self.t0
			if t <= .3 then
				shine:SetPoint('TOPLEFT', button, 0, 8)
			elseif t <= .7 then
				shine:SetPoint('TOPLEFT', button, (t - .3) * 2.5 * self.distance, 8)
			end
			if t <= .3 then
				shine:SetAlpha(0)
			elseif t <= .5 then
				shine:SetAlpha(1)
			elseif t <= .7 then
				shine:SetAlpha(1 - (t - .5) * 5)
			else
				shine:SetAlpha(0)
				self:Hide()
			end
		end)
		function shine.animation:Play()
			self.t0 = GetTime()
			self.distance = button:GetWidth() - shine:GetWidth() + 8
			self:Show()
			button:SetAlpha(1)
		end
	end
end

do
	unitscan.last_check = GetTime()
	function unitscan.UPDATE()
		if is_resting then return end
		if not InCombatLockdown() and unitscan.discovered_unit then
			unitscan.button:set_target(unitscan.discovered_unit)
			unitscan.discovered_unit = nil
		end
		if GetTime() - unitscan.last_check >= unitscan_defaults.CHECK_INTERVAL then
			unitscan.last_check = GetTime()
			for name in pairs(unitscan_targets) do
				unitscan.target(name)
			end
			for _, name in pairs(nearby_targets) do
				unitscan.target(name)
			end
		end
	end
end

function unitscan.print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00/unitscan|r " .. "|cffffff9a" .. msg .. "|r")
    end
end

function unitscan.ignoreprint(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00/unitscan ignore|r " .. "|cffff0000" .. msg .. "|r")
    end
end



function unitscan.sorted_targets()
	local sorted_targets = {}
	for key in pairs(unitscan_targets) do
		tinsert(sorted_targets, key)
	end
	sort(sorted_targets, function(key1, key2) return key1 < key2 end)
	return sorted_targets
end

function unitscan.toggle_target(name)
	local key = strupper(name)
	if unitscan_targets[key] then
		unitscan_targets[key] = nil
		found[key] = nil
		unitscan.print('- ' .. key)
	elseif key ~= '' then
		unitscan_targets[key] = true
		unitscan.print('+ ' .. key)
	end
end
	
SlashCmdList["UNITSCAN"] = function(parameter)
	local _, _, command, args = string.find(parameter, "(%a+)%s*(.*)")
	
	if command == "" then
		unitscan.print("/unitscan target - Add the name of your current target to the scanner.")
		unitscan.print("/unitscan <name>        - Adds/removes the 'name' from the unit scanner.")
		unitscan.print("/unitscan nearby        - Lists the nearby units in the same zone.")
	elseif command == "target" then
		local targetName = UnitName("target")
		if targetName then
			local key = strupper(targetName)
			if not unitscan_targets[key] then
				unitscan_targets[key] = true
				unitscan.print("+ " .. key)
			else
				unitscan_targets[key] = nil
				unitscan.print("- " .. key)
				found[key] = nil
			end
		else
			unitscan.print("No target selected.")
		end


	elseif command == "interval" then
		local newInterval = tonumber(args)
		if newInterval then
			unitscan_defaults.CHECK_INTERVAL = newInterval
			unitscan.print("Check interval set to " .. newInterval)
		else
			unitscan.print("Invalid interval value. Usage: /unitscan interval <number>")
		end


	elseif command == "ignore" then
		if args == "" then
			-- print list of ignored NPCs
			print("|cffff0000" .. " Ignore list " .. "|r"  .. "currently contains:")
				for npc in pairs(unitscan_ignored) do
					unitscan.ignoreprint(npc)
				end

				return
		else
	        local npc = string.upper(args)
	        if rare_spawns[npc] == nil then
	            -- NPC does not exist in rare_spawns table
	            unitscan.print("|cffffff00" .. args .. "|r" .. " is not a valid rare spawn.")

	            return
	    end

		if unitscan_ignored[npc] then
			-- remove NPC from ignore list
			unitscan_ignored[npc] = nil
			unitscan.ignoreprint("- " .. npc)
			unitscan.refresh_nearby_targets()
		else
			-- add NPC to ignore list
			unitscan_ignored[npc] = true
			unitscan.ignoreprint("+ " .. npc)
			unitscan.refresh_nearby_targets()
		end

		return
		end

	elseif command == "name" then
		unitscan.print("replace 'name' with npc you want to scan. usage: /unitscan <unit name>")
	elseif command == "targets" then
		if unitscan_targets then
			for k, v in pairs(unitscan_targets) do
				unitscan.print(tostring(k))
			end
		end
	elseif command == "nearby" then
		unitscan.print("Is someone missing? \n Add it to your list with \"/unitscan name\"")
		for key,val in pairs(nearby_targets) do
			if not (val == "Lumbering Horror" or val == "Spirit of the Damned" or val == "Bone Witch") then
				unitscan.print(val)
			end
		end
	elseif not command then
		unitscan.print("target")
		print(" - Adds/removes the name of your current target to the scanner.")
		-- print(" ")
		unitscan.print("name")
		print(" - Adds/removes the mob/player 'name' from the unit scanner.")
		-- print(" ")
		unitscan.print("nearby")
		print(" - List of rare mob names that are being scanned in your current zone.")
		-- print(" ")
		if unitscan_targets then
			if next(unitscan_targets) == nil then
				unitscan.print("Unit scanner is currently empty.")
			else
				print(" |cFF00FF00Unit scanner|r currently contains:")
				for k, v in pairs(unitscan_targets) do
					unitscan.print(tostring(k))
				end
			end
		end
	else
		unitscan.toggle_target(parameter)
	end
end
SLASH_UNITSCAN1 = "/unitscan"


