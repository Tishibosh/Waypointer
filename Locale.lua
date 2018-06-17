local addon, Waypointer = ...
Waypointer.Locale = {}
Waypointer.EnglishLocale = {}

Waypointer.FrenchLocale = {
    ["Ignore quest"] = "Ignore quest",
    ["Restore quest"] = "Restore quest",
    ["Unrepeatable"] = "Non répétable",
    ["Zone"] = "Zone",
    ["Language"] = "Langue",
    ["Filter"] = "Filtre",
	["Select quest to see description"] = "Sélectionnez quête pour voir la description",
	["Show icon button"] = "Révélez le bouton d'icône",
	["Lock icon button"] = "Bouton d'icône de serrure",
	["Hide zones with no quests"] = "Ne montrez pas de zones sans quête",
	["None"] = "Aucun",
	["Void Stone"] = "Pierre du Vide",
	["Infinity Stone"] = "Pierre de l'Infini",
	["Sourcestone"] = "Pierre de source",
	["Eternal Crystallized Insight"] = "Intuition cristallisée éternelle",
	["Spirit Infusion"] = "Infusion spirituelle",
	["Minion Card"] = "Carte de Sbire",
	["Artisan's Mark"] = "Marque de l'artisan",
	["Master Craftsman's Mark"] = "Marque de Maître artisan",
	["Grandmaster Craftsman's Mark"] = "Marque de Grand-maître artisan",
	["The Order of the Eye"] = "L'Ordre de l'Œil",
	["The Unseen"] = "Les Invisibles",
	["The Achyati"] = "Les Achyati",
	["Quarry Rats"] = "Rats de carrière",
	["Whitefall Brigade"] = "Brigade des Chutes blanches",
	["Manugo League"] = "Ligue de Manugo",
	["The Storm Guard"] = "La Garde-tempête",
	["Runic Sages"] = "Sages runiques",
	["The Seekers"] = "Les Chercheurs",
	["Arcane Hand"] = "Main d'arcane",
	["The Runeguard"] = "La Garde runique",
	["Caretakers"] = "Reliquaires",
	["The Moribund"] = "Les Moribonds",
	["Hailol"] = "Hailol",
	["Empyreal Alliance"] = "Alliance empyréenne",
	["Eldritch Seekers"] = "Chercheurs eldritch",
	["The Unspoken"] = "L’Implicite",
	["The Onir"] = "Les Onir",
	["Order of Life Serene"] = "Ordre de la Vie Sereine",
	["Students of the Vale"] = "Étudiants du Val",
	["Order of the Death Serpent"] = "Ordre du Serpent de la Mort",
	["Atragarians"] = "Atragarians",
	["The Grim Disciples"] = "Les Sinistres Disciples",
	["Quicksilver Scholars"] = "Érudits de l'Académie de Vif-Argent",
	["Freemarch Wardens"] = "Gardes de la Marche",
	["Gloamwood Waykeepers"] = "Gardes-voies du Bois du Crépuscule",
	["Granite Falls"] = "Chutes de Granite",
	["The Storm Inquisition"] = "L’Inquisition de la Tempête",
	["Cerulean Rhenke"] = "Rhenke céruléen",
	["Ember Scholars"] = "Érudits de braise",
	["Zephyrian Collective"] = "Collectif Zéphyrien",
	["Ridgerunner Mercenaries"] = "Mercenaires Cavalarêtes",
	["Order of the Flame"] = "Ordre de la Flamme",
	["Mendicant Order"] = "Ordre mendiant",
	["Order of Purity"] = "Ordre de la Pureté",
	["The Shale Collegiate"] = "La Collégiale du Schiste",
	["Pelagic Order"] = "Ordre pélagien",
	["Mercurial Savants"] = "Savants lunatiques",
	["The Farclan"] = "Le Clan-Lointain",
	["Kelari Expedition"] = "Expédition kelari",
	["Noble Guard"] = "Garde noble",
	["Defiants"] = "Renégats",
	["Eldritch Vanguard"] = "Avant-garde eldritch",
	["Guardians"] = "Gardiens",
	["Dragonslayer Covenant"] = "Alliance des Tueurs de dragons",
	["Iron Claw Trappers"] = "Trappeurs Griffes de fer",
	["Red Scar Trackers"] = "Pisteurs de Rouge-balafre",
	["The Keepers"] = "Le Phalanstère",
	["Icewatch"] = "L’Œil-glacé",
	["Order of Mathos"] = "Ordre de Mathos",
	["Necropolis Caretakers"] = "Reliquaires de la Nécropole",
	["The Lycini"] = "Les Lycinis",
	["The Ghar"] = "Les Ghars",
	["Torvan Hunters"] = "Chasseurs torvains",
	["The Order of the Eye"] = "L'Ordre de l'Œil",
	["The Unseen"] = "Les Invisibles",
	["The Achyati"] = "Les Achyati",
	["Quarry Rats"] = "Rats de carrière",
	["Whitefall Brigade"] = "Brigade des Chutes blanches",
	["Manugo League"] = "Ligue de Manugo",
	["The Storm Guard"] = "La Garde-tempête",
	["Runic Sages"] = "Sages runiques",
	["The Seekers"] = "Les Chercheurs",
	["Arcane Hand"] = "Main d'arcane",
	["The Runeguard"] = "La Garde runique",
	["Caretakers"] = "Reliquaires",
	["The Moribund"] = "Les Moribonds",
	["Hailol"] = "Hailol",
	["Empyreal Alliance"] = "Alliance empyréenne",
	["Eldritch Seekers"] = "Chercheurs eldritch",
	["The Unspoken"] = "L’Implicite",
	["The Onir"] = "Les Onir",
	["Order of Life Serene"] = "Ordre de la Vie Sereine",
	["Students of the Vale"] = "Étudiants du Val",
	["Order of the Death Serpent"] = "Ordre du Serpent de la Mort",
	["Atragarians"] = "Atragarians",
	["The Grim Disciples"] = "Les Sinistres Disciples",
	["Quicksilver Scholars"] = "Érudits de l'Académie de Vif-Argent",
	["Freemarch Wardens"] = "Gardes de la Marche",
	["Gloamwood Waykeepers"] = "Gardes-voies du Bois du Crépuscule",
	["Granite Falls"] = "Chutes de Granite",
	["The Storm Inquisition"] = "L’Inquisition de la Tempête",
	["Cerulean Rhenke"] = "Rhenke céruléen",
	["Ember Scholars"] = "Érudits de braise",
	["Zephyrian Collective"] = "Collectif Zéphyrien",
	["Ridgerunner Mercenaries"] = "Mercenaires Cavalarêtes",
	["Order of the Flame"] = "Ordre de la Flamme",
	["Mendicant Order"] = "Ordre mendiant",
	["Order of Purity"] = "Ordre de la Pureté",
	["The Shale Collegiate"] = "La Collégiale du Schiste",
	["Pelagic Order"] = "Ordre pélagien",
	["Mercurial Savants"] = "Savants lunatiques",
	["The Farclan"] = "Le Clan-Lointain",
	["Kelari Expedition"] = "Expédition kelari",
	["Noble Guard"] = "Garde noble",
	["Defiants"] = "Renégats",
	["Eldritch Vanguard"] = "Avant-garde eldritch",
	["Guardians"] = "Gardiens",
	["Dragonslayer Covenant"] = "Alliance des Tueurs de dragons",
	["Iron Claw Trappers"] = "Trappeurs Griffes de fer",
	["Red Scar Trackers"] = "Pisteurs de Rouge-balafre",
	["The Keepers"] = "Le Phalanstère",
	["Icewatch"] = "L’Œil-glacé",
	["Order of Mathos"] = "Ordre de Mathos",
	["Necropolis Caretakers"] = "Reliquaires de la Nécropole",
	["The Lycini"] = "Les Lycinis",
	["The Ghar"] = "Les Ghars",
	["Torvan Hunters"] = "Chasseurs torvains",
	["Mark quest start"] = "Point de départ",
	["Quest Start Locations"] = "Coordonnées de début de quête"
}

Waypointer.GermanLocale = {
    ["Ignore quest"] = "Ignore quest",
    ["Restore quest"] = "Restore quest",
    ["Unrepeatable"] = "Unrepeatable",
    ["Zone"] = "Gebiet",
    ["Language"] = "Sprache",
    ["Filter"] = "Filter",
	["Select quest to see description"] = "Wählen quest, um Beschreibung zu sehen",
	["Show icon button"] = "Symbolschaltfläche anzeigen",
	["Lock icon button"] = "Schloss-Symbol-Taste",
	["Hide zones with no quests"] = "Verbergen Sie Zonen ohne quest",
	["None"] = "Nichts",
	["Void Stone"] = "Stein der Leere",
	["Infinity Stone"] = "Stein der Unendlichkeit",
	["Sourcestone"] = "Quellstein",
	["Eternal Crystallized Insight"] = "Ewiger Kristallisierter Einblick",
	["Spirit Infusion"] = "Geistesinfusion",
	["Minion Card"] = "Schergenkarte",
	["Artisan's Mark"] = "Zeichen des Handwerkers",
	["Master Craftsman's Mark"] = "Zeichen des Meister-Handwerkers",
	["Grandmaster Craftsman's Mark"] = "Zeichen des Großmeister-Handwerkers",
	["The Order of the Eye"] = "Der Orden des Auges",
	["The Unseen"] = "Die Ungesehenen",
	["The Achyati"] = "Die Achyati",
	["Quarry Rats"] = "Grubenratte",
	["Whitefall Brigade"] = "Weißfall-Brigade",
	["Manugo League"] = "Manugo-Liga",
	["The Storm Guard"] = "Die Sturmwache",
	["Runic Sages"] = "Runenweise",
	["The Seekers"] = "Die Sucher",
	["Arcane Hand"] = "Arkane Hand",
	["The Runeguard"] = "Die Runengarde",
	["Caretakers"] = "Wärter",
	["The Moribund"] = "Die Sterbenden",
	["Hailol"] = "Hailol",
	["Empyreal Alliance"] = "Empyreische Allianz",
	["Eldritch Seekers"] = "Unheimliche Suchende",
	["The Unspoken"] = "Die Unaussprechlichen",
	["The Onir"] = "Die Onir",
	["Order of Life Serene"] = "Orden des Heiteren Lebens",
	["Students of the Vale"] = "Schüler des Tals",
	["Order of the Death Serpent"] = "Orden der Todesschlange",
	["Atragarians"] = "Atragarianer",
	["The Grim Disciples"] = "Die grimmigen Jünger",
	["Quicksilver Scholars"] = "Quecksilber-Gelehrte",
	["Freemarch Wardens"] = "Freimark-Bewahrer",
	["Gloamwood Waykeepers"] = "Dämmerwald-Weghüter",
	["Granite Falls"] = "Granitsturz",
	["The Storm Inquisition"] = "Die Sturminquisition",
	["Cerulean Rhenke"] = "Himmelblaue Rhenke",
	["Ember Scholars"] = "Glut-Gelehrte",
	["Zephyrian Collective"] = "Zephirischer Verband",
	["Ridgerunner Mercenaries"] = "Gradrenner-Söldner",
	["Order of the Flame"] = "Orden der Flamme",
	["Mendicant Order"] = "Bettelmönchsorden",
	["Order of Purity"] = "Orden der Reinheit",
	["The Shale Collegiate"] = "Die Shale-Akademie",
	["Pelagic Order"] = "Pelagischer Orden",
	["Mercurial Savants"] = "Sprunghafte Gelehrte",
	["The Farclan"] = "Die Farclan",
	["Kelari Expedition"] = "Kelari-Expedition",
	["Noble Guard"] = "Edelwacht",
	["Defiants"] = "Skeptiker",
	["Eldritch Vanguard"] = "Unheimliche Vorhut",
	["Guardians"] = "Wächter",
	["Dragonslayer Covenant"] = "Drachentöterbund",
	["Iron Claw Trappers"] = "Eisenklauen-Trapper",
	["Red Scar Trackers"] = "Rotnarbenaufspürer",
	["The Keepers"] = "Die Hüter",
	["Icewatch"] = "Eiswacht",
	["Order of Mathos"] = "Orden von Mathos",
	["Necropolis Caretakers"] = "Nekropolis-Wärter",
	["The Lycini"] = "Die Lycini",
	["The Ghar"] = "Die Ghar",
	["Torvan Hunters"] = "Torvan-Jäger",
	["Mark quest start"] = "Quest startet",
	["Quest Start Locations"] = "Quest startet koordinaten"
}

Waypointer.Locale.currentLocale = Waypointer.EnglishLocale

local function BuildReverseMap()
	if Waypointer.lang == "Francais" and Waypointer.Locale.French2English == nil then
		local french2English = {}
		for key, value in pairs(Waypointer.FrenchLocale) do
			french2English[value] = key
		end
		
		Waypointer.Locale.French2English = french2English
	elseif Waypointer.lang == "Deutsch" and Waypointer.Locale.German2English == nil then
		local german2English = {}
		for key, value in pairs(Waypointer.GermanLocale) do
			german2English[value] = key
		end
		
		Waypointer.Locale.German2English = german2English
	end
end

function Waypointer.SetLocale()
	BuildReverseMap()
	
	if Waypointer.lang == "Francais" then
		Waypointer.Locale.currentLocale = Waypointer.FrenchLocale
	elseif Waypointer.lang == "Deutsch" then
		Waypointer.Locale.currentLocale = Waypointer.GermanLocale
	else
		Waypointer.lang = "English"
		Waypointer.Locale.currentLocale = Waypointer.EnglishLocale
	end
end

function Waypointer.GetLocaleValue(key)
	local ret = Waypointer.Locale.currentLocale[key]
	if ret ~= nil then
		return ret
	end
	
	return key
end

function Waypointer.GetEnglishValue(key)
	if Waypointer.lang == "Francais" then
		local ret = Waypointer.Locale.French2English[key]
		if ret ~= nil then
			return ret
		end
		
		return key
	elseif Waypointer.lang == "Deutsch" then
		local ret = Waypointer.Locale.German2English[key]
		if ret ~= nil then
			return ret
		end
		
		return key
	end
	
	return key
end
