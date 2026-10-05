local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local WindowSkin = require(RS:WaitForChild("Shared"):WaitForChild("WindowSkin"))

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local function consider(o)
	if o.Name == "Header" and o:IsA("GuiObject") then
		local panel = o.Parent
		if panel and panel:IsA("GuiObject") then
			task.spawn(WindowSkin.watch, panel)
		end
	end
end

playerGui.DescendantAdded:Connect(consider)
for _, d in playerGui:GetDescendants() do
	consider(d)
end

-- EN/FR localization layer ---------------------------------------------------
-- English stays the source/fallback language. French is selected from the
-- player's Roblox client locale. This layer only changes client-visible text;
-- it does not rename instances, remotes, attributes, tools, or saved data.
local __LocalizationService = game:GetService("LocalizationService")
local __locale = string.lower(__LocalizationService.RobloxLocaleId or __LocalizationService.SystemLocaleId or "en-us")
local __isFrench = string.sub(__locale, 1, 2) == "fr"

if __isFrench then
    local EXACT = {
        ["recommended"] = "recommandé",
        ["SAFE ZONE"] = "ZONE SÛRE",
        ["FASTEST"] = "PLUS RAPIDE",
        ["PLAYTIME"] = "PLUS ACTIFS",
        ["TOP SPENDER"] = "TOP DÉPENSE ROBUX",
        ["GROUP REWARDS"] = "GRATUIT !",
        ["SELL"] = "VENDRE",
        ["SELL PETS"] = "VENDRE LES ANIMAUX",
        ["SELL EGGS"] = "VENDRE LES ŒUFS",
        ["SELL ALL"] = "TOUT VENDRE",
        ["TRAILS SHOP"] = "BOUTIQUE DE SENTIERS",
        ["TRAIL SHOP"] = "BOUTIQUE DE SENTIERS",
        ["SETTINGS"] = "PARAMÈTRES",
        ["ON"] = "ACTIVÉ",
        ["OFF"] = "DÉSACTIVÉ",
        ["MUSIC"] = "MUSIQUE",
        ["SFX"] = "EFFETS",
        ["SOUND EFFECTS"] = "EFFETS SONORES",
        ["HIDE MY PETS"] = "MASQUER MES ANIMAUX",
        ["HIDE OTHER PETS"] = "MASQUER LES AUTRES ANIMAUX",
        ["GROWING EGGS"] = "ŒUFS EN CROISSANCE",
        ["GROW ALL"] = "TOUT FAIRE GRANDIR",
        ["OPEN"] = "OUVRIR",
        ["Drop"] = "Lâcher",
        ["Search"] = "Rechercher",
        ["No results"] = "Aucun résultat",
        ["No pets yet"] = "Aucun animal pour le moment",
        ["No eggs yet - steal one and bring it home"] = "Aucun œuf - vole-en un et ramène-le chez toi",
        ["No items yet - steal an egg and bring it home"] = "Aucun objet - vole un œuf et ramène-le chez toi",
        ["TRAPPED"] = "PIÉGÉ",
        ["RUN!"] = "COURS !",
        ["Slow Mode"] = "Mode lent",
        ["ONLY 1"] = "PLUS QU'1",
        ["MAX SPEED"] = "VITESSE MAX",
        ["You already have the MAX speed level!"] = "Tu as déjà le niveau de vitesse MAX !",
        ["REBIRTH"] = "RENAISSANCE",
        ["Skip Rebirth"] = "Passer la renaissance",
        ["Max rebirth reached!"] = "Nombre maximal de renaissances atteint !",
        ["Not enough cash!"] = "Pas assez d'argent !",
        ["Not enough money"] = "Pas assez d'argent",
        ["PET INDEX"] = "INDEX DES ANIMAUX",
        ["Equip Bat!"] = "Équiper la batte !",
        ["CLAIMED!"] = "RÉCUPÉRÉ !",
        ["CLAIM!"] = "RÉCUPÉRER !",
        ["HATCH TO UNLOCK"] = "FAIRE ÉCLORE POUR DÉBLOQUER",
        ["HATCH FROM "] = "ÉCLOSION DEPUIS ",
        [" REWARD"] = " RÉCOMPENSE",
        ["EVENT OVER!"] = "ÉVÉNEMENT TERMINÉ !",
        ["NOBODY HELD THE EGG"] = "PERSONNE N'A GARDÉ L'ŒUF",
        ["ALL EGGS RESET!"] = "TOUS LES ŒUFS ONT ÉTÉ RÉINITIALISÉS !",
        ["The map is closed at night!"] = "La carte est fermée la nuit !",
        ["LEGENDARY EGG"] = "ŒUF LÉGENDAIRE",
        ["FREE REWARDS"] = "RÉCOMPENSES GRATUITES",
        ["Like the Game!"] = "Aime le jeu !",
        ["Join Our Group!"] = "Rejoins notre groupe !",
        ["Thank You!"] = "Merci !",
        ["Join First"] = "Rejoins d'abord",
        ["Try Later"] = "Réessaie plus tard",
        ["Reward claimed!"] = "Récompense récupérée !",
        ["Join the group first"] = "Rejoins d'abord le groupe",
        ["Reward unavailable"] = "Récompense indisponible",
        ["The rewards window hasn't loaded yet"] = "La fenêtre des récompenses n'est pas encore chargée",
        ["already claimed"] = "déjà récupérée",
        ["join the group first"] = "rejoins d'abord le groupe",
        ["You already claimed the group reward"] = "Tu as déjà récupéré la récompense du groupe",
        ["TRAIL SHOP"] = "BOUTIQUE DE SENTIERS",
        ["OWNED"] = "POSSÉDÉ",
        ["PASSES"] = "PASSES",
        ["Gift Player"] = "Offrir à un joueur",
        ["No other players in this server"] = "Aucun autre joueur sur ce serveur",
        ["EQUIP BEST"] = "ÉQUIPER LES MEILLEURS",
        ["UNEQUIP"] = "DÉSÉQUIPER",
        ["MAX LEVEL"] = "NIVEAU MAX",
        ["No pets on your plot\nPress EQUIP BEST or place pets"] = "Aucun animal sur ton terrain\nAppuie sur ÉQUIPER LES MEILLEURS ou place des animaux",
        ["Fuse Machine"] = "Machine de fusion",
        ["Bring <font color=\"#FF4B4B\">3</font> of the same pet to fuse"] = "Apporte <font color=\"#FF4B4B\">3</font> animaux identiques pour les fusionner",
        ["<font color=\"#6BFF4A\">Better pets</font> give more <font color=\"#6BFF4A\">Luck</font> \\u{1F340}!"] = "Les <font color=\"#6BFF4A\">meilleurs animaux</font> donnent plus de <font color=\"#6BFF4A\">Chance</font> \\u{1F340}!",
        ["Choose a pet"] = "Choisir un animal",
        ["BACK"] = "RETOUR",
        ["Back"] = "Retour",
        ["No more matching pets in your backpack"] = "Plus aucun animal correspondant dans ton sac",
        ["No pets in your backpack"] = "Aucun animal dans ton sac",
        ["Put 3 of the same pet in the machine"] = "Place 3 animaux identiques dans la machine",
        ["Fused! The egg is in your backpack"] = "Fusion réussie ! L'œuf est dans ton sac",
        ["SORT BY:"] = "TRIER PAR :",
        ["SIZE"] = "TAILLE",
        ["VALUE"] = "VALEUR",
        ["SELECT ALL"] = "TOUT SÉLECTIONNER",
        ["CLEAR"] = "EFFACER",
        ["TOTAL VALUE:"] = "VALEUR TOTALE :",
        ["No pets to sell"] = "Aucun animal à vendre",
        ["No eggs to sell"] = "Aucun œuf à vendre",
        ["Nothing to sell yet"] = "Rien à vendre pour le moment",
        ["READY!"] = "PRÊT !",
        ["HATCHING"] = "ÉCLOSION",
        ["Hatch"] = "Faire éclore",
        ["Hatching"] = "Éclosion",
        ["This isn't your plot"] = "Ce n'est pas ton terrain",
        ["You can only place "] = "Tu peux seulement placer ",
        [" on your own plot"] = " sur ton propre terrain",
        ["ADMIN PANEL"] = "PANNEAU ADMIN",
        ["PLAYERS"] = "JOUEURS",
        ["SELECT"] = "SÉLECTIONNER",
        ["nobody selected"] = "aucun joueur sélectionné",
        ["CONFIRM"] = "CONFIRMER",
        ["CANCEL"] = "ANNULER",
        ["ECONOMY"] = "ÉCONOMIE",
        ["EGGS"] = "ŒUFS",
        ["EVENTS"] = "ÉVÉNEMENTS",
        ["ACTIONS"] = "ACTIONS",
        ["MODERATION"] = "MODÉRATION",
        ["KICK"] = "EXPULSER",
        ["BAN"] = "BANNIR",
        ["UNBAN"] = "DÉBANNIR",
        ["TELEPORT TO"] = "SE TÉLÉPORTER VERS",
        ["ANNOUNCEMENT"] = "ANNONCE",
        ["SEND"] = "ENVOYER",
        ["REFRESH"] = "ACTUALISER",
        ["DAY / NIGHT"] = "JOUR / NUIT",
        ["NIGHT NOW"] = "NUIT MAINTENANT",
        ["DAY NOW"] = "JOUR MAINTENANT",
        ["RESET EGGS"] = "RÉINITIALISER LES ŒUFS",
        ["GLOBAL MULTIPLIERS"] = "MULTIPLICATEURS GLOBAUX",
        ["THIS SERVER"] = "CE SERVEUR",
        ["ALL SERVERS"] = "TOUS LES SERVEURS",
        ["ALL OFF"] = "TOUT DÉSACTIVER",
        ["RARE EGGS"] = "ŒUFS RARES",
        ["HATCH SPEED"] = "VITESSE D'ÉCLOSION",
        ["FUSE LUCK"] = "CHANCE DE FUSION",
        ["ADMIN TREADMILL"] = "TAPIS ADMIN",
        ["CAPTURE EGG"] = "CAPTURE DE L'ŒUF",
        ["SPECIAL EVENTS"] = "ÉVÉNEMENTS SPÉCIAUX",
        ["UPDATE"] = "METTRE À JOUR",
        ["LEVELS"] = "NIVEAUX",
        ["RESET"] = "RÉINITIALISER",
        ["TREADMILL"] = "TAPIS",
        ["PLOT"] = "TERRAIN",
        ["BAT"] = "BATTE",
        ["DEFAULT"] = "PAR DÉFAUT",
        ["WHAT TO GIVE"] = "QUOI DONNER",
        ["GIVE EGG TO SELECTED"] = "DONNER UN ŒUF AU JOUEUR SÉLECTIONNÉ",
        ["READY: SELECTED"] = "PRÊT : SÉLECTIONNÉ",
        ["READY: THIS SERVER"] = "PRÊT : CE SERVEUR",
        ["READY: ALL SERVERS"] = "PRÊT : TOUS LES SERVEURS",
        ["MAPEGGS"] = "ŒUFS DE LA CARTE",
        ["EGGS ON THE MAP"] = "ŒUFS SUR LA CARTE",
        ["ALL ZONES: ON"] = "TOUTES LES ZONES : ACTIVÉ",
        ["ALL ZONES: OFF"] = "TOUTES LES ZONES : DÉSACTIVÉ",
        ["Forest"] = "Forêt",
        ["Lake"] = "Lac",
        ["Desert"] = "Désert",
        ["Jungle"] = "Jungle",
        ["Snow"] = "Neige",
        ["Volcano"] = "Volcan",
        ["Abyss Ocean"] = "Océan abyssal",
        ["Prehistoric"] = "Préhistoire",
        ["Cosmic"] = "Cosmique",
        ["Cherry Blossom"] = "Fleurs de cerisier",
        ["Titan Temple"] = "Temple des Titans",
        ["Monster Lair"] = "Repaire des monstres",
        ["Common"] = "Commun",
        ["Uncommon"] = "Peu commun",
        ["Rare"] = "Rare",
        ["Legendary"] = "Légendaire",
        ["Tiny"] = "Minuscule",
        ["Small"] = "Petit",
        ["Normal"] = "Normal",
        ["Large"] = "Grand",
        ["Huge"] = "Énorme",
        ["Giant"] = "Géant",
        ["All Items"] = "Tous les objets",
        ["Y: place   B: cancel"] = "Y : placer   B : annuler",
        ["You can't use this in the safe zone"] = "Tu ne peux pas utiliser ça dans la zone sûre",
        ["Your hands are full - you're carrying an egg"] = "Tu as les mains pleines - tu portes un œuf",
        ["No traps left - wait for one to snap"] = "Plus de pièges - attends qu'un piège se déclenche",
        ["You can't use this here"] = "Tu ne peux pas utiliser ça ici",
        ["Bear trap! You're stuck"] = "Piège à ours ! Tu es bloqué",
        ["Sort By"] = "Trier par",
    }

    local function translateText(text)
        if type(text) ~= "string" or text == "" then return text end
        local exact = EXACT[text]
        if exact then return exact end

        local n
        n = text:match("^Level (%d+) %- Max$")
        if n then return "Niveau " .. n .. " - Max" end
        local a, b = text:match("^Level (%d+) > Level (%d+)$")
        if a then return "Niveau " .. a .. " > Niveau " .. b end
        n = text:match("^Level (%d+)$")
        if n then return "Niveau " .. n end
        n = text:match("^CLAIM ALL %((%d+)%)!$")
        if n then return "TOUT RÉCUPÉRER (" .. n .. ") !" end
        a, b = text:match("^UNLOCKED: (%d+) / (%d+)$")
        if a then return "DÉBLOQUÉS : " .. a .. " / " .. b end
        n = text:match("^(%d+) Pet Left$")
        if n then return n .. " animal restant" end
        n = text:match("^(%d+) Pets Left$")
        if n then return n .. " animaux restants" end
        a, b = text:match("^(%d+)/(%d+) ACTIVE$")
        if a then return a .. "/" .. b .. " ACTIFS" end
        n = text:match("^%+(%d+) more Legendary eggs!$")
        if n then return "+" .. n .. " œufs légendaires supplémentaires !" end
        local who = text:match("^(.-) WON!$")
        if who then return who .. " A GAGNÉ !" end
        local label = text:match("^(.-) %- coming soon$")
        if label then return (EXACT[label] or label) .. " - bientôt disponible" end
        local mult = text:match("^x(%d+) Speed$")
        if mult then return "x" .. mult .. " Vitesse" end
        local pct = text:match("^%+(.-) Speed!$")
        if pct then return "+" .. pct .. " Vitesse !" end
        local only = text:match("^ONLY (.+)$")
        if only then return "PLUS QUE " .. only end
        local who2, what = text:match("^(.-) gifted you (.-)!$")
        if who2 then return who2 .. " t'a offert " .. what .. " !" end
        local target, gift = text:match("^You gifted (.-) to (.-)!$")
        if target then return "Tu as offert " .. target .. " à " .. gift .. " !" end
        local count, kind, plural, value = text:match("^Sold (%d+) (.-)(s?) for (.+)!$")
        if count then return "Vendu " .. count .. " " .. kind .. plural .. " pour " .. value .. " !" end
        local z = text:match("^Zone (%d+)$")
        if z then return "Zone " .. z end
        local mins, secs = text:match("^in (%d+)m (%d+)s$")
        if mins then return "dans " .. mins .. "m " .. secs .. "s" end
        secs = text:match("^in (%d+)s$")
        if secs then return "dans " .. secs .. "s" end
        local nm = text:match("^NEW PET: (.-) %- claim your reward in the Index!$")
        if nm then return "NOUVEL ANIMAL : " .. nm .. " - récupère ta récompense dans l'Index !" end
        local up, lv = text:match("^(.-) upgraded to Level (%d+)!$")
        if up then return up .. " amélioré au niveau " .. lv .. " !" end
        if text == "No eggs growing\nPlace eggs on your plot" then
            return "Aucun œuf en croissance\nPlace des œufs sur ton terrain"
        end
        if string.find(text, "Egg size and Luck", 1, true) then
            local p1,p2=text:match("Luck %((%-?%d+)%%%% to %+(%d+)%%%%%)")
            if p1 then return "La taille de l'œuf et la Chance ("..p1.."% à +"..p2.."%) sont aléatoires" end
        end
        return text
    end

    local watched = setmetatable({}, {__mode = "k"})
    local changing = setmetatable({}, {__mode = "k"})

    local function applyText(obj, property)
        if changing[obj] then return end
        local ok, value = pcall(function() return obj[property] end)
        if not ok then return end
        local translated = translateText(value)
        if translated ~= value then
            changing[obj] = true
            pcall(function() obj[property] = translated end)
            changing[obj] = nil
        end
    end

    local function watch(obj)
        if watched[obj] then return end
        local prop
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            prop = "Text"
        elseif obj:IsA("TextBox") then
            -- Never translate player-entered TextBox.Text; only its hint.
            prop = "PlaceholderText"
        elseif obj:IsA("ProximityPrompt") then
            watched[obj] = true
            applyText(obj, "ActionText")
            applyText(obj, "ObjectText")
            obj:GetPropertyChangedSignal("ActionText"):Connect(function() applyText(obj, "ActionText") end)
            obj:GetPropertyChangedSignal("ObjectText"):Connect(function() applyText(obj, "ObjectText") end)
            return
        else
            return
        end
        watched[obj] = true
        applyText(obj, prop)
        obj:GetPropertyChangedSignal(prop):Connect(function() applyText(obj, prop) end)
    end

    -- Player UI + world-space text/prompts. Workspace is scanned once; new
    -- descendants are localized as zones/UI stream in.
    for _, obj in playerGui:GetDescendants() do watch(obj) end
    playerGui.DescendantAdded:Connect(watch)
    for _, obj in workspace:GetDescendants() do watch(obj) end
    workspace.DescendantAdded:Connect(watch)
end
-- End EN/FR localization layer -----------------------------------------------

-- COMPLETE EN/FR visible-text pass ------------------------------------------
-- This second pass complements the base localizer with every visible string
-- found in the shipped client, plus generated pet/trail/bat names.
do
    local __LS = game:GetService("LocalizationService")
    local __locale2 = string.lower(__LS.RobloxLocaleId or __LS.SystemLocaleId or "en-us")
    if string.sub(__locale2, 1, 2) == "fr" then
        local D = {
            -- Main HUD / navigation
            ["Rebirth"]="Renaissance", ["Shop"]="Boutique", ["Index"]="Index",
            ["Eggs"]="Œufs", ["Pets"]="Animaux", ["Speed"]="Vitesse", ["SPEED"]="VITESSE",
            ["Settings"]="Paramètres", ["Sell"]="Vendre", ["Fuse"]="Fusionner",
            ["Open"]="Ouvrir", ["Close"]="Fermer", ["Buy"]="Acheter", ["Equip"]="Équiper",
            ["Unequip"]="Déséquiper", ["Claim"]="Récupérer", ["Claimed"]="Récupéré",
            ["Locked"]="Verrouillé", ["Ready"]="Prêt", ["Owned"]="Possédé",
            ["Luck"]="Chance", ["Hatch"]="Faire éclore", ["TAP"]="APPUYER",
            ["YES"]="OUI", ["NO"]="NON", ["VOLUME"]="VOLUME",
            ["MONEY"]="ARGENT", ["TOP"]="TOP", ["PLAYER"]="JOUEUR", ["SERVER"]="SERVEUR",
            ["START"]="DÉMARRER", ["SET"]="DÉFINIR", ["MAX"]="MAX",
            ["RICHEST"]="PLUS RICHE", ["FASTEST"]="PLUS RAPIDE", ["FUSE MACHINE"]="MACHINE DE FUSION",

            -- Window headings / controls
            ["FREE REWARDS"]="RÉCOMPENSES GRATUITES", ["PET INDEX"]="INDEX DES ANIMAUX",
            ["TRAIL SHOP"]="BOUTIQUE DE SENTIERS", ["Fuse Machine"]="Machine de fusion",
            ["GROWING EGGS"]="ŒUFS EN CROISSANCE", ["ACTIVE PETS"]="ANIMAUX ACTIFS",
            ["REBIRTH"]="RENAISSANCE", ["SETTINGS"]="PARAMÈTRES", ["SHOP"]="BOUTIQUE",
            ["SELL SHOP"]="BOUTIQUE DE VENTE", ["SELL"]="VENDRE", ["FUSE"]="FUSIONNER",
            ["OPEN"]="OUVRIR", ["CLOSE"]="FERMER", ["BUY"]="ACHETER", ["EQUIP"]="ÉQUIPER",
            ["UNEQUIP"]="DÉSÉQUIPER", ["CLAIM"]="RÉCUPÉRER", ["LOCKED"]="VERROUILLÉ",
            ["READY"]="PRÊT", ["OWNED"]="POSSÉDÉ",

            -- Economy / progression
            ["PEN"]="ENCLOS", ["MILL"]="TAPIS", ["TREADMILL"]="TAPIS",
            ["PLOT"]="TERRAIN", ["COINS"]="PIÈCES", ["COINS FOR THE SELECTED PLAYER"]="PIÈCES POUR LE JOUEUR SÉLECTIONNÉ",
            ["SET COINS"]="DÉFINIR LES PIÈCES", ["SET COINS EXACTLY"]="DÉFINIR EXACTEMENT LES PIÈCES",
            ["GIVE COINS TO EVERYONE ON THIS SERVER"]="DONNER DES PIÈCES À TOUS SUR CE SERVEUR",
            ["GIVE TO ALL"]="DONNER À TOUS", ["+10K COINS"]="+10K PIÈCES", ["+1M COINS"]="+1M PIÈCES",
            ["+1B COINS"]="+1B PIÈCES", ["-1M COINS"]="-1M PIÈCES",
            ["MAX SPEED"]="VITESSE MAX", ["Slow Mode"]="Mode lent",
            ["Skip Rebirth"]="Passer la renaissance", ["MAX LEVEL"]="NIVEAU MAX",
            ["+1 EQUIP"]="+1 ÉQUIPÉ", ["EQUIP BEST"]="ÉQUIPER LES MEILLEURS",

            -- Shop / rewards
            ["PASSES"]="PASSES", ["Gift Player"]="Offrir à un joueur", ["Like the Game!"]="Aime le jeu !",
            ["Join Our Group!"]="Rejoins notre groupe !", ["Join First"]="Rejoins d'abord",
            ["Try Later"]="Réessaie plus tard", ["Thank You!"]="Merci !",
            ["Reward claimed!"]="Récompense récupérée !", ["Reward unavailable"]="Récompense indisponible",
            ["No other players in this server"]="Aucun autre joueur sur ce serveur",

            -- Inventory / sell / fuse
            ["All Items"]="Tous les objets", ["SORT BY:"]="TRIER PAR :", ["Sort By"]="Trier par",
            ["SIZE"]="TAILLE", ["VALUE"]="VALEUR", ["SELECT ALL"]="TOUT SÉLECTIONNER",
            ["CLEAR"]="EFFACER", ["TOTAL VALUE:"]="VALEUR TOTALE :",
            ["SELL ALL"]="TOUT VENDRE", ["SELL EGGS"]="VENDRE LES ŒUFS", ["SELL PETS"]="VENDRE LES ANIMAUX",
            ["Choose a pet"]="Choisir un animal", ["BACK"]="RETOUR", ["Back"]="Retour",
            ["3 Pets Left"]="3 animaux restants", ["Put 3 of the same pet in the machine"]="Place 3 animaux identiques dans la machine",
            ["Fused! The egg is in your backpack"]="Fusion réussie ! L'œuf est dans ton sac",
            ["No more matching pets in your backpack"]="Plus aucun animal correspondant dans ton sac",
            ["No pets in your backpack"]="Aucun animal dans ton sac", ["No pets to sell"]="Aucun animal à vendre",
            ["No eggs to sell"]="Aucun œuf à vendre", ["Nothing to sell yet"]="Rien à vendre pour le moment",
            ["No pets yet"]="Aucun animal pour le moment", ["No results"]="Aucun résultat",
            ["no parts streamed in"]="éléments pas encore chargés",

            -- Egg / nest gameplay
            ["Drop"]="Lâcher", ["READY!"]="PRÊT !", ["HATCHING"]="ÉCLOSION",
            ["TRAPPED"]="PIÉGÉ", ["RUN!"]="COURS !", ["Pick up"]="Ramasser",
            ["HELD BY "]="PORTÉ PAR ", ["The map is closed at night!"]="La carte est fermée la nuit !",
            ["ALL EGGS RESET!"]="TOUS LES ŒUFS ONT ÉTÉ RÉINITIALISÉS !", ["LEGENDARY EGG"]="ŒUF LÉGENDAIRE",
            ["A Legendary egg spawned in"]="Un œuf légendaire est apparu dans",
            ["No eggs growing\nPlace eggs on your plot"]="Aucun œuf en croissance\nPlace des œufs sur ton terrain",
            ["No eggs yet - steal one and bring it home"]="Aucun œuf - vole-en un et ramène-le chez toi",
            ["No items yet - steal an egg and bring it home"]="Aucun objet - vole un œuf et ramène-le chez toi",
            ["This isn't your plot"]="Ce n'est pas ton terrain",
            ["Your hands are full - you're carrying an egg"]="Tu as les mains pleines - tu portes un œuf",
            ["You can't use this in the safe zone"]="Tu ne peux pas utiliser ça dans la zone sûre",
            ["You can't use this here"]="Tu ne peux pas utiliser ça ici",
            ["No traps left - wait for one to snap"]="Plus de pièges - attends qu'un piège se déclenche",
            ["Bear trap! You're stuck"]="Piège à ours ! Tu es bloqué",

            -- Index
            ["Equip Bat!"]="Équiper la batte !", ["Default Bat"]="Batte par défaut",
            ["HATCH FROM "]="ÉCLOSION DEPUIS ", [" REWARD"]=" RÉCOMPENSE",
            ["CLAIMED!"]="RÉCUPÉRÉ !", ["CLAIM!"]="RÉCUPÉRER !",
            ["HATCH TO UNLOCK"]="FAIRE ÉCLORE POUR DÉBLOQUER",

            -- Settings
            ["MUSIC"]="MUSIQUE", ["SFX"]="EFFETS", ["SOUND EFFECTS"]="EFFETS SONORES",
            ["HIDE MY PETS"]="MASQUER MES ANIMAUX", ["HIDE OTHER PETS"]="MASQUER LES AUTRES ANIMAUX",
            ["ON"]="ACTIVÉ", ["OFF"]="DÉSACTIVÉ",

            -- Admin UI (visible only to admins, still localized)
            ["ADMIN PANEL"]="PANNEAU ADMIN", ["ADMIN"]="ADMIN", ["PLAYERS"]="JOUEURS",
            ["SELECT"]="SÉLECTIONNER", ["nobody selected"]="aucun joueur sélectionné",
            ["selected: "]="sélectionné : ", ["CONFIRM"]="CONFIRMER", ["CANCEL"]="ANNULER",
            ["ECONOMY"]="ÉCONOMIE", ["EGGS"]="ŒUFS", ["EVENTS"]="ÉVÉNEMENTS",
            ["ACTIONS"]="ACTIONS", ["MODERATION"]="MODÉRATION", ["KICK"]="EXPULSER",
            ["BAN"]="BANNIR", ["UNBAN"]="DÉBANNIR", ["UNBAN BY USERID"]="DÉBANNIR PAR USERID",
            ["TELEPORT TO"]="SE TÉLÉPORTER VERS", ["ANNOUNCEMENT"]="ANNONCE",
            ["SEND"]="ENVOYER", ["REFRESH"]="ACTUALISER", ["REFRESH THE PLAYER LIST"]="ACTUALISER LA LISTE DES JOUEURS",
            ["DAY / NIGHT"]="JOUR / NUIT", ["NIGHT NOW"]="NUIT MAINTENANT", ["DAY NOW"]="JOUR MAINTENANT",
            ["RESET EGGS"]="RÉINITIALISER LES ŒUFS", ["GLOBAL MULTIPLIERS"]="MULTIPLICATEURS GLOBAUX",
            ["THIS SERVER"]="CE SERVEUR", ["ALL SERVERS"]="TOUS LES SERVEURS", ["ALL OFF"]="TOUT DÉSACTIVER",
            ["RARE EGGS"]="ŒUFS RARES", ["HATCH SPEED"]="VITESSE D'ÉCLOSION", ["FUSE LUCK"]="CHANCE DE FUSION",
            ["ADMIN TREADMILL"]="TAPIS ADMIN", ["CAPTURE EGG"]="CAPTURE DE L'ŒUF",
            ["SPECIAL EVENTS"]="ÉVÉNEMENTS SPÉCIAUX", ["EVENTS_SPECIAL"]="ÉVÉNEMENTS SPÉCIAUX",
            ["UPDATE"]="METTRE À JOUR", ["LEVELS"]="NIVEAUX", ["RESET"]="RÉINITIALISER",
            ["BAT"]="BATTE", ["DEFAULT"]="PAR DÉFAUT", ["WHAT TO GIVE"]="QUOI DONNER",
            ["GIVE EGG TO SELECTED"]="DONNER UN ŒUF AU JOUEUR SÉLECTIONNÉ",
            ["READY: SELECTED"]="PRÊT : SÉLECTIONNÉ", ["READY: THIS SERVER"]="PRÊT : CE SERVEUR",
            ["READY: ALL SERVERS"]="PRÊT : TOUS LES SERVEURS", ["MAPEGGS"]="ŒUFS DE LA CARTE",
            ["EGGS ON THE MAP"]="ŒUFS SUR LA CARTE", ["ALL ZONES: ON"]="TOUTES LES ZONES : ACTIVÉ",
            ["ALL ZONES: OFF"]="TOUTES LES ZONES : DÉSACTIVÉ", ["HATCHING"]="ÉCLOSION",
            ["SPEED - player pace and boss pace"]="VITESSE - allure du joueur et du boss",
            ["BAT - what the selected player holds"]="BATTE - ce que tient le joueur sélectionné",
            ["UPGRADE LEVELS - selected player (or you)"]="NIVEAUX D'AMÉLIORATION - joueur sélectionné (ou toi)",
            ["THRESHOLDS FROM THE ZONE SIGNS"]="SEUILS DES PANNEAUX DE ZONE",
            ["text everyone will see"]="texte que tout le monde verra",
            ["minutes (0 = no limit)"]="minutes (0 = sans limite)",
            ["pick a player on the PLAYER tab first"]="sélectionne d'abord un joueur dans l'onglet JOUEUR",
            ["nothing to announce"]="rien à annoncer",

            -- Capture event
            ["EVENT OVER!"]="ÉVÉNEMENT TERMINÉ !", ["NOBODY HELD THE EGG"]="PERSONNE N'A GARDÉ L'ŒUF",
            ["YOU!"]="TOI !",

            -- Rarity / size
            ["Common"]="Commun", ["Uncommon"]="Peu commun", ["Rare"]="Rare", ["Legendary"]="Légendaire",
            ["Epic"]="Épique", ["Mythic"]="Mythique", ["Divine"]="Divin",
            ["Tiny"]="Minuscule", ["Small"]="Petit", ["Normal"]="Normal", ["Large"]="Grand",
            ["Huge"]="Énorme", ["Giant"]="Géant",

            -- Zones
            ["Forest"]="Forêt", ["Lake"]="Lac", ["Desert"]="Désert", ["Jungle"]="Jungle",
            ["Snow"]="Neige", ["Volcano"]="Volcan", ["Abyss Ocean"]="Océan abyssal",
            ["Prehistoric"]="Préhistoire", ["Cosmic"]="Cosmique", ["Cherry Blossom"]="Fleurs de cerisier",
            ["Titan Temple"]="Temple des Titans", ["Monster Lair"]="Repaire des monstres",

            -- Trails
            ["White Trail"]="Traînée blanche", ["Green Trail"]="Traînée verte", ["Blue Trail"]="Traînée bleue",
            ["Purple Trail"]="Traînée violette", ["Golden Trail"]="Traînée dorée", ["Orange Trail"]="Traînée orange",
            ["Red Trail"]="Traînée rouge",

            -- Bats
            ["Forest Bat"]="Batte de la forêt", ["Lake Bat"]="Batte du lac", ["Desert Bat"]="Batte du désert",
            ["Jungle Bat"]="Batte de la jungle", ["Snow Bat"]="Batte des neiges", ["Volcano Bat"]="Batte du volcan",
            ["Abyss Ocean Bat"]="Batte de l'océan abyssal", ["Prehistoric Bat"]="Batte préhistorique",
            ["Cosmic Bat"]="Batte cosmique", ["Cherry Blossom Bat"]="Batte des fleurs de cerisier",
            ["Titan Temple Bat"]="Batte du temple des Titans", ["Monster Lair Bat"]="Batte du repaire des monstres",

            -- 96 pet species
            ["Rabbit"]="Lapin", ["Squirrel"]="Écureuil", ["Hedgehog"]="Hérisson", ["Fawn"]="Faon",
            ["Fox"]="Renard", ["Badger"]="Blaireau", ["Owl"]="Hibou", ["Wild Boar"]="Sanglier",
            ["Duck"]="Canard", ["Frog"]="Grenouille", ["Dragonfly"]="Libellule", ["Beaver"]="Castor",
            ["Heron"]="Héron", ["Otter"]="Loutre", ["Turtle"]="Tortue", ["Koi Carp"]="Carpe koï",
            ["Jerboa"]="Gerboise", ["Meerkat"]="Suricate", ["Horned Lizard"]="Lézard à cornes", ["Fennec Fox"]="Fennec",
            ["Scorpion"]="Scorpion", ["Rattlesnake"]="Crotale", ["Vulture"]="Vautour", ["Camel"]="Chameau",
            ["Tree Frog"]="Rainette", ["Monkey"]="Singe", ["Parrot"]="Perroquet", ["Toucan"]="Toucan",
            ["Chameleon"]="Caméléon", ["Sloth"]="Paresseux", ["Gorilla"]="Gorille", ["Panther"]="Panthère",
            ["Arctic Hare"]="Lièvre arctique", ["Penguin"]="Manchot", ["Seal Pup"]="Bébé phoque", ["Arctic Fox"]="Renard arctique",
            ["Snowy Owl"]="Harfang des neiges", ["Reindeer"]="Renne", ["Walrus"]="Morse", ["Polar Bear Cub"]="Ourson polaire",
            ["Ash Crow"]="Corbeau de cendre", ["Ember Bat"]="Chauve-souris de braise", ["Lava Toad"]="Crapaud de lave", ["Magma Slug"]="Limace de magma",
            ["Flame Lizard"]="Lézard de feu", ["Fire Salamander"]="Salamandre de feu", ["Cinder Ram"]="Bélier de cendre", ["Obsidian Beetle"]="Scarabée d'obsidienne",
            ["Lanternfish"]="Poisson-lanterne", ["Jellyfish"]="Méduse", ["Deep Sea Crab"]="Crabe des abysses", ["Moray Eel"]="Murène",
            ["Nautilus"]="Nautile", ["Anglerfish"]="Poisson-pêcheur", ["Manta Ray"]="Raie manta", ["Octopus"]="Poulpe",
            ["Pterodactyl"]="Ptérodactyle", ["Raptor"]="Raptor", ["Stegosaurus"]="Stégosaure", ["Ankylosaurus"]="Ankylosaure",
            ["Triceratops"]="Tricératops", ["Sabertooth Cat"]="Félin à dents de sabre", ["Mammoth"]="Mammouth", ["Brontosaurus"]="Brontosaure",
            ["Meteor Beetle"]="Scarabée météore", ["Alien Blob"]="Blob extraterrestre", ["Moon Rabbit"]="Lapin lunaire", ["Star Cat"]="Chat stellaire",
            ["Satellite Owl"]="Hibou satellite", ["Nebula Jellyfish"]="Méduse nébuleuse", ["Galaxy Fox"]="Renard galactique", ["Comet Whale"]="Baleine comète",
            ["Butterfly"]="Papillon", ["Songbird"]="Oiseau chanteur", ["Sakura Koi"]="Koï sakura", ["Crane"]="Grue",
            ["Red Panda"]="Panda roux", ["Tanuki"]="Tanuki", ["Blossom Cat"]="Chat des fleurs", ["Sakura Deer"]="Cerf sakura",
            ["Bronze Scarab"]="Scarabée de bronze", ["Obelisk Beetle"]="Scarabée obélisque", ["Clay Serpent"]="Serpent d'argile", ["Marble Owl"]="Hibou de marbre",
            ["Jade Tortoise"]="Tortue de jade", ["Granite Ape"]="Singe de granit", ["Guardian Lion"]="Lion gardien", ["Stone Golem"]="Golem de pierre",
            ["One Eyed Blob"]="Blob cyclope", ["Slime Cube"]="Cube de slime", ["Horned Imp"]="Diablotin cornu", ["Ghost Wisp"]="Feu follet fantôme",
            ["Bat Demon"]="Démon chauve-souris", ["Spike Worm"]="Ver épineux", ["Shadow Hound"]="Molosse des ombres", ["Tentacle Beast"]="Bête tentaculaire",
        }

        local ZONE = {
            ["Forest"]="Forêt", ["Lake"]="Lac", ["Desert"]="Désert", ["Jungle"]="Jungle", ["Snow"]="Neige",
            ["Volcano"]="Volcan", ["Abyss Ocean"]="Océan abyssal", ["Prehistoric"]="Préhistoire", ["Cosmic"]="Cosmique",
            ["Cherry Blossom"]="Fleurs de cerisier", ["Titan Temple"]="Temple des Titans", ["Monster Lair"]="Repaire des monstres",
        }

        local function tr2(text)
            if type(text) ~= "string" or text == "" then return text end
            if D[text] then return D[text] end

            local n,a,b,c
            n=text:match("^Level (%d+)$"); if n then return "Niveau "..n end
            n=text:match("^Level (%d+) %- Max$"); if n then return "Niveau "..n.." - Max" end
            a,b=text:match("^Level (%d+) > Level (%d+)$"); if a then return "Niveau "..a.." > Niveau "..b end
            n=text:match("^CLAIM ALL %((%d+)%)!$"); if n then return "TOUT RÉCUPÉRER ("..n..") !" end
            a,b=text:match("^UNLOCKED: (%d+) / (%d+)$"); if a then return "DÉBLOQUÉS : "..a.." / "..b end
            n=text:match("^(%d+) Pet Left$"); if n then return n.." animal restant" end
            n=text:match("^(%d+) Pets Left$"); if n then return n.." animaux restants" end
            a,b=text:match("^(%d+)/(%d+) ACTIVE$"); if a then return a.."/"..b.." ACTIFS" end
            n=text:match("^%+1 EQUIP %[(.-)%]$"); if n then return "+1 ÉQUIPÉ ["..n.."]" end
            n=text:match("^x([%d%.]+) Speed$"); if n then return "x"..n.." Vitesse" end
            n=text:match("^x(%d+) Speed pass %- not available right now$"); if n then return "Pass Vitesse x"..n.." - indisponible pour le moment" end
            a=text:match("^(.-) %- not available right now$"); if a then return (D[a] or a).." - indisponible pour le moment" end
            a=text:match("^(.-) %- coming soon$"); if a then return (D[a] or a).." - bientôt disponible" end
            a=text:match("^(.-) unlocked!$"); if a then return (D[a] or a).." débloqué !" end
            a=text:match("^%+(.-) Speed!$"); if a then return "+"..a.." Vitesse !" end
            a=text:match("^ONLY (.+)$"); if a then return "PLUS QUE "..a end
            a,b=text:match("^(.-) gifted you (.-)!$"); if a then return a.." t'a offert "..(D[b] or b).." !" end
            a,b=text:match("^You gifted (.-) to (.-)!$"); if a then return "Tu as offert "..(D[a] or a).." à "..b.." !" end
            a,b,c=text:match("^(.-): %+(.-)  %+(.-) SPEED$"); if a then return (D[a] or a).." : +"..b.."  +"..c.." VITESSE" end
            n,a,b=text:match("^CLAIMED (%d+): %+(.-)  %+(.-) SPEED$"); if n then return "RÉCUPÉRÉ "..n.." : +"..a.."  +"..b.." VITESSE" end
            n=text:match("^%+(%d+) more Legendary eggs!$"); if n then return "+"..n.." œufs légendaires supplémentaires !" end
            a=text:match("^(.-) WON!$"); if a then return a.." A GAGNÉ !" end
            a=text:match("^NEW PET: (.-) %- claim your reward in the Index!$"); if a then return "NOUVEL ANIMAL : "..(D[a] or a).." - récupère ta récompense dans l'Index !" end
            a,n=text:match("^(.-) upgraded to Level (%d+)!$"); if a then return (D[a] or a).." amélioré au niveau "..n.." !" end
            a,b=text:match("^Sold (%d+) (.-) for (.+)!$"); if a then return "Vendu "..a.." "..b.." pour "..c.." !" end
            n=text:match("^Zone (%d+)$"); if n then return "Zone "..n end
            a,b=text:match("^in (%d+)m (%d+)s$"); if a then return "dans "..a.."m "..b.."s" end
            a=text:match("^in (%d+)s$"); if a then return "dans "..a.."s" end
            a=text:match("^Whacked by (.-)$"); if a then return "Frappé par "..a end
            a=text:match("^You can only place (.-) on your own plot$"); if a then return "Tu peux seulement placer "..(D[a] or a).." sur ton propre terrain" end
            a,b,c=text:match("^You get a (.-) egg %- random size, Luck (%-?%d+)%%%% to %+(%d+)%%%%$")
            if a then return "Tu obtiens un œuf "..(D[a] or a).." - taille aléatoire, Chance "..b.."% à +"..c.."%" end
            a,b,c=text:match("^(.-) (.-) Egg\nLuck ([%+%-]?%d+)%%%%$")
            if a then return (D[a] or a).." "..(D[b] or b).." Œuf\nChance "..c.."%" end
            a=text:match("^FUSE (.+)$"); if a then return "FUSIONNER "..a end
            a=text:match("^ACTIVE %- (%d+:%d+) left$"); if a then return "ACTIF - "..a.." restant" end
            a,b=text:match("^ACTIVE x(.+) %- (%d+:%d+) left$"); if a then return "ACTIF x"..a.." - "..b.." restant" end
            a=text:match("^ACTIVE x(.+) %- no limit$"); if a then return "ACTIF x"..a.." - sans limite" end
            a=text:match("^%<font color=\"#47FF48\"%>(.-)%</font%> Speed$"); if a then return '<font color="#47FF48">'..a..'</font> Vitesse' end
            a,b=text:match("^(.+) needs a time: set minutes to (.+) above$"); if a then return a.." nécessite une durée : règle les minutes sur "..b.." ci-dessus" end
            if text=="Egg size and Luck (%d%% to +%d%%) are random" then return "La taille de l'œuf et la Chance sont aléatoires" end
            if string.find(text,"Egg size and Luck",1,true) and string.find(text,"are random",1,true) then
                return (text:gsub("Egg size and Luck","La taille de l'œuf et la Chance"):gsub("are random","sont aléatoires"))
            end
            if string.find(text,"FUSE LUCK x",1,true) and string.find(text,"ACTIVE",1,true) then
                return text:gsub("FUSE LUCK","CHANCE DE FUSION"):gsub("ACTIVE","ACTIVE")
            end
            if string.find(text," Speed",1,true) and string.find(text,"<font",1,true) then
                return text:gsub(" Speed"," Vitesse")
            end
            return text
        end

        local seen=setmetatable({}, {__mode="k"})
        local busy=setmetatable({}, {__mode="k"})
        local function apply(o,p)
            if busy[o] then return end
            local ok,v=pcall(function() return o[p] end); if not ok then return end
            local nv=tr2(v)

            -- The world Trail Shop sign used TextScaled + wrapping. Its effective
            -- layout changed with camera projection, so the French title jumped
            -- between one and two lines. For this world-space sign only, use a
            -- fixed font size and continuously keep wrapping disabled.
            local isTrailShop = p == "Text"
                and (o:IsA("TextLabel") or o:IsA("TextButton"))
                and o:IsDescendantOf(workspace)
                and (
                    v == "TRAILS SHOP"
                    or v == "TRAIL SHOP"
                    or v == "BOUTIQUE DE TRAÎNÉES"
                    or v == "BOUTIQUE DE SENTIERS"
                    or nv == "BOUTIQUE DE SENTIERS"
                )

            if isTrailShop then
                nv = "BOUTIQUE DE SENTIERS"
                busy[o]=true
                pcall(function()
                    o.Text = nv
                    o.TextWrapped = false
                    o.TextScaled = false
                    o.TextSize = 24
                    o.TextXAlignment = Enum.TextXAlignment.Center
                    o.TextYAlignment = Enum.TextYAlignment.Center
                end)
                busy[o]=nil
                return
            end

            if nv~=v then busy[o]=true; pcall(function() o[p]=nv end); busy[o]=nil end
        end
        local function bind(o)
            if seen[o] then return end
            if o:IsA("TextLabel") or o:IsA("TextButton") then
                seen[o]=true
                apply(o,"Text")
                o:GetPropertyChangedSignal("Text"):Connect(function() apply(o,"Text") end)

                -- Re-assert the fixed world-sign layout if another script/UI
                -- recalculates these properties after the initial translation.
                if o:IsDescendantOf(workspace) then
                    local function keepTrailShopStable()
                        local t = o.Text
                        if t == "TRAILS SHOP" or t == "TRAIL SHOP"
                            or t == "BOUTIQUE DE TRAÎNÉES"
                            or t == "BOUTIQUE DE SENTIERS" then
                            if busy[o] then return end
                            busy[o]=true
                            pcall(function()
                                o.Text = "BOUTIQUE DE SENTIERS"
                                o.TextWrapped = false
                                o.TextScaled = false
                                o.TextSize = 24
                            end)
                            busy[o]=nil
                        end
                    end
                    o:GetPropertyChangedSignal("TextWrapped"):Connect(keepTrailShopStable)
                    o:GetPropertyChangedSignal("TextScaled"):Connect(keepTrailShopStable)
                    o:GetPropertyChangedSignal("TextSize"):Connect(keepTrailShopStable)
                end
            elseif o:IsA("TextBox") then
                seen[o]=true; apply(o,"PlaceholderText"); o:GetPropertyChangedSignal("PlaceholderText"):Connect(function() apply(o,"PlaceholderText") end)
            elseif o:IsA("ProximityPrompt") then
                seen[o]=true; apply(o,"ActionText"); apply(o,"ObjectText")
                o:GetPropertyChangedSignal("ActionText"):Connect(function() apply(o,"ActionText") end)
                o:GetPropertyChangedSignal("ObjectText"):Connect(function() apply(o,"ObjectText") end)
            end
        end
        local pg=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        for _,o in ipairs(pg:GetDescendants()) do bind(o) end
        pg.DescendantAdded:Connect(bind)
        for _,o in ipairs(workspace:GetDescendants()) do bind(o) end
        workspace.DescendantAdded:Connect(bind)
    end
end
-- End COMPLETE EN/FR visible-text pass --------------------------------------
