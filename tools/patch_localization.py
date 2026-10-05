from pathlib import Path
import struct, ctypes, re

SRC=Path('/mnt/data/stealanegg14.rbxl')
DST=Path('/mnt/data/stealanegg14_EN_FR.rbxl')

lib=ctypes.CDLL('libzstd.so')
lib.ZSTD_decompress.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t]
lib.ZSTD_decompress.restype=ctypes.c_size_t
lib.ZSTD_compressBound.argtypes=[ctypes.c_size_t]
lib.ZSTD_compressBound.restype=ctypes.c_size_t
lib.ZSTD_compress.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t,ctypes.c_int]
lib.ZSTD_compress.restype=ctypes.c_size_t
lib.ZSTD_isError.argtypes=[ctypes.c_size_t]
lib.ZSTD_isError.restype=ctypes.c_uint

def decompress(raw, size):
    out=ctypes.create_string_buffer(size)
    src=ctypes.create_string_buffer(raw)
    got=lib.ZSTD_decompress(out,size,src,len(raw))
    if lib.ZSTD_isError(got) or got != size:
        raise RuntimeError(f'zstd decompress failed {got}/{size}')
    return out.raw[:size]

def compress(raw, level=3):
    bound=lib.ZSTD_compressBound(len(raw))
    out=ctypes.create_string_buffer(bound)
    src=ctypes.create_string_buffer(raw)
    got=lib.ZSTD_compress(out,bound,src,len(raw),level)
    if lib.ZSTD_isError(got):
        raise RuntimeError('zstd compress failed')
    return out.raw[:got]

LOCALIZER = r'''

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
        ["SELL"] = "VENDRE",
        ["SELL PETS"] = "VENDRE LES ANIMAUX",
        ["SELL EGGS"] = "VENDRE LES ŒUFS",
        ["SELL ALL"] = "TOUT VENDRE",
        ["TRAILS SHOP"] = "BOUTIQUE DE TRAÎNÉES",
        ["TRAIL SHOP"] = "BOUTIQUE DE TRAÎNÉES",
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
        ["TRAIL SHOP"] = "BOUTIQUE DE TRAÎNÉES",
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
'''

DAYNIGHT_PREAMBLE = r'''
local __LocalizationService = game:GetService("LocalizationService")
local __locale = string.lower(__LocalizationService.RobloxLocaleId or __LocalizationService.SystemLocaleId or "en-us")
local __isFrench = string.sub(__locale, 1, 2) == "fr"
local function __L(en, fr) return __isFrench and fr or en end
local __ZONE_FR = {
    ["Forest"]="Forêt", ["Lake"]="Lac", ["Desert"]="Désert", ["Jungle"]="Jungle",
    ["Snow"]="Neige", ["Volcano"]="Volcan", ["Abyss Ocean"]="Océan abyssal",
    ["Prehistoric"]="Préhistoire", ["Cosmic"]="Cosmique", ["Cherry Blossom"]="Fleurs de cerisier",
    ["Titan Temple"]="Temple des Titans", ["Monster Lair"]="Repaire des monstres",
}
local function __zoneName(name) return __isFrench and (__ZONE_FR[name] or name) or name end
'''

def patch_windowskin(src):
    if 'EN/FR localization layer' in src:
        return src
    return src.rstrip() + LOCALIZER + '\n'

def patch_daynight(src):
    if '__ZONE_FR' not in src:
        # Insert after original service declarations / before first blank after services is not necessary;
        # prepending is safe because it only obtains LocalizationService.
        src = DAYNIGHT_PREAMBLE + '\n' + src
    src = src.replace('local name = Cfg.NAMES[zone] or ("Zone " .. tostring(zone))',
                      'local name = __zoneName(Cfg.NAMES[zone] or ("Zone " .. tostring(zone)))')
    src = src.replace('hexFade("LEGENDARY EGG", LEGEND_FROM, LEGEND_TO)',
                      'hexFade(__L("LEGENDARY EGG", "ŒUF LÉGENDAIRE"), LEGEND_FROM, LEGEND_TO)')
    src = src.replace(' .. " in " .. zoneFade(zone, name) .. "!"',
                      ' .. __L(" in ", " dans ") .. zoneFade(zone, name) .. "!"')
    src = src.replace('hexFade("A Legendary egg spawned in", LEGEND_FROM, LEGEND_TO, true)',
                      'hexFade(__L("A Legendary egg spawned in", "Un œuf légendaire est apparu dans"), LEGEND_FROM, LEGEND_TO, true)')
    return src

b=SRC.read_bytes()
header=b[:32]
pos=32
out=[header]
classes={}
modified=[]

while pos+16 <= len(b):
    start=pos
    typ=b[pos:pos+4]
    clen,ulen,res=struct.unpack_from('<III',b,pos+4)
    data_len=clen or ulen
    raw=b[pos+16:pos+16+data_len]
    pos += 16+data_len

    d=None
    if typ in (b'INST', b'PROP'):
        d=decompress(raw,ulen) if clen else raw

    if typ==b'INST':
        cid=struct.unpack_from('<I',d,0)[0]
        ln=struct.unpack_from('<I',d,4)[0]
        cname=d[8:8+ln].decode('utf-8')
        off=8+ln
        count=struct.unpack_from('<I',d,off+1)[0]
        classes[cid]=(cname,count)

    changed=False
    if typ==b'PROP' and d is not None:
        cid=struct.unpack_from('<I',d,0)[0]
        ln=struct.unpack_from('<I',d,4)[0]
        pname=d[8:8+ln].decode('utf-8','replace')
        tid=d[8+ln]
        if cid==40 and pname=='Source' and tid==1:
            payload=d[9+ln:]
            vals=[]; o=0
            for _ in range(classes[cid][1]):
                n=struct.unpack_from('<I',payload,o)[0];o+=4
                vals.append(payload[o:o+n].decode('utf-8'));o+=n
            # LocalScript index 32 = WindowSkinClient; 22 = DayNightClient.
            before=vals[32]; vals[32]=patch_windowskin(vals[32])
            if vals[32]!=before: modified.append(('WindowSkinClient',len(before),len(vals[32])))
            before=vals[22]; vals[22]=patch_daynight(vals[22])
            if vals[22]!=before: modified.append(('DayNightClient',len(before),len(vals[22])))
            newpayload=bytearray()
            for s in vals:
                bs=s.encode('utf-8'); newpayload += struct.pack('<I',len(bs))+bs
            d=d[:9+ln]+bytes(newpayload)
            changed=True

    if changed:
        comp=compress(d,3)
        out.append(typ+struct.pack('<III',len(comp),len(d),res)+comp)
    else:
        out.append(b[start:pos])
    if typ==b'END\x00':
        # Copy any trailing bytes, though normal rbxl ends here.
        if pos < len(b): out.append(b[pos:])
        break

DST.write_bytes(b''.join(out))
print('Wrote',DST, DST.stat().st_size)
print('Modified:', modified)