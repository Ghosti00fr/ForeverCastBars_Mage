-- ============================================================
--  Forever Cast Bars — pack Mage
--  Cadres (braises, givre, givrefeu, arcane rose / bleu), remplissages
--  et objets animés des prototypes mage. Exige ForeverCastBars.
--  Sans ce pack, les sorts du mage gardent leur thème d'école.
-- ============================================================

if not (FCB and FCB.Looks and FCB.Looks.RegisterPack and FCB.Props) then return end

local M = "Interface\\AddOns\\ForeverCastBars_Mage\\textures\\"   -- sprites du pack
local B = FCB.TEX_PATH .. "crafts\\"                                -- sprites de la base
local Props = FCB.Props
local Put, END = Props.Put, Props.END
local sin, cos, pi, max, min = math.sin, math.cos, math.pi, math.max, math.min

-- sprite étiré (anneaux aplatis, traînées)
local function PutWH(st, i, file, x, y, w, h, rot, a, col, add)
    Put(st, i, file, x, y, w, rot, a, col, add)
    if st.sl[i] then st.sl[i]:SetSize(max(1, w), max(1, h)) end
end
-- anneau aplati qui s'élargit (u 0..1)
local function Ring(st, i, x, y, rmax, u, col, flat)
    PutWH(st, i, B .. "P_Bubble", x, y, 20 + rmax * u, (20 + rmax * u) * (flat or .55), 0, 1 - u, col, true)
end
local function R(name, slots, Draw) Props.Register("mage_" .. name, { slots = slots, Draw = Draw }) end

-- ---------------------------------------------------------------- projectiles (boule de feu, éclair de givre, givrefeu)
local function Bolt(name, tex, col, g0, g1)
    R(name, 4, function(st, c)
        if not c.te then
            local s = 20 * (g0 + (g1 - g0) * c.p)
            Put(st, 1, B .. "P_Glow", c.frontX + 8, c.cy + 5, s * 2.2, 0, .6 * c.p, col, true)
            Put(st, 2, M .. tex, c.frontX + 8, c.cy + 5 + sin(c.t * 11) * 1.2, s, c.t * 40, 1)
            return
        end
        if c.te >= .3 then return end
        local u = c.te / .3; local x = END(c) - 20 + u * 24            -- part vers le bout, sans sortir du cadre
        PutWH(st, 1, B .. "P_Glow", x - 30, c.cy + 5, 70, 14, 0, 1 - u, col, true)
        Put(st, 2, M .. tex, x, c.cy + 5, 36, 0, 1 - u)
        Ring(st, 3, END(c) - 10, c.cy + 5, 140, u, col)
        Put(st, 4, B .. "P_Glow", END(c) - 10, c.cy + 5, 120 * (1 - u), 0, 1 - u, col, true)
    end)
end
Bolt("bolt_fire", "P_Fireball", { 1, .6, .2 }, .8, 1.7)
Bolt("bolt_ice", "P_IceShard", { .7, .9, 1 }, .5, 1.6)
Bolt("bolt_frostfire", "P_FrostfireOrb", { .9, .6, .8 }, .6, 1.8)

-- ---------------------------------------------------------------- Explosion pyrotechnique : flammes en orbite, puis anneau et éclair
R("orbit_flames", 10, function(st, c)
    if not c.te then
        if c.p < .6 then return end
        local k = (c.p - .6) / .4; local r = 14 + 26 * k
        for i = 0, 7 do
            local ang = c.t * 5 + i * pi / 4
            Put(st, i + 1, B .. "P_Flame", c.frontX + cos(ang) * r, c.cy + 5 + sin(ang) * r * .8, 14 + 12 * k, math.deg(-ang + pi / 2), 1, { 1, .6, .15 }, true)
        end
        return
    end
    if c.te >= .6 then return end
    local u = c.te / .6
    Ring(st, 9, END(c) - 20, c.cy + 5, 160, u, { 1, .78, .47 })
    Put(st, 10, B .. "P_Glow", END(c) - 20, c.cy + 5, 200 * (1 - u * .5), 0, 1 - u, { 1, .95, .8 }, true)
end)

-- ---------------------------------------------------------------- Choc de flammes : cercle de feu qui se trace, puis colonne de flammes
R("zone_circle", 22, function(st, c)
    local zx, rx, ry = c.fillLX + c.fillW * .45, c.fillW * .42, 34
    local k = c.te and 1 or c.p
    for i = 0, 11 do
        if i / 12 <= k then
            local ang = pi / 2 + 2 * pi * i / 12
            Put(st, i + 1, B .. "P_Flame", zx + rx * cos(ang), c.cy + 5 + ry * sin(ang), 14, 0, .35 + .5 * k, { 1, .55, .12 }, true)
        end
    end
    if not (c.te and c.te < .8) then return end
    local te = c.te; local u = max(0, te - .1) / .7
    local w = 60 * (1 - max(0, te - .25) / .55)
    if w > 2 then PutWH(st, 13, B .. "P_Flame", zx, c.cy + 40, w, 110 * min(1, te / .06), 180, 1, { 1, .55, .12 }, true) end
    for i = 0, 8 do                                       -- flammes qui s'étalent sur la barre
        local h = 40 * (1 - u) * (.6 + .4 * sin(i * 1.7 + te * 20))
        if te > .1 then PutWH(st, 14 + i, B .. "P_Flame", zx + (i - 4) / 4 * rx * u, c.cy + 5 + h / 2, 22, h, 0, 1 - u, { 1, .55, .12 }, true) end
    end
end)

-- ---------------------------------------------------------------- Brûlure : jet de flamme à la pointe, puis la barre roussit
R("scorch", 3, function(st, c)
    if not c.te then
        local l = (18 + 26 * c.p) * (.85 + .15 * sin(c.t * 31))
        Put(st, 1, B .. "P_Flame", c.frontX + l / 2, c.cy + 5, l, -90, 1, { 1, .55, .1 }, true)
        Put(st, 2, B .. "P_Flame", c.frontX + l * .3, c.cy + 5, l * .6, -90, 1, { 1, .9, .5 }, true)
        return
    end
    if c.te >= .35 then return end
    local u = c.te / .35; local w = c.fillW * min(1, u * 1.5)
    PutWH(st, 3, B .. "P_Shine", c.fillLX + w / 2, c.cy + 5, w, 30, 0, 1 - u, { 1, .7, .3 }, true)
end)

-- ---------------------------------------------------------------- Blizzard : neige oblique, éclats de glace à chaque seconde
R("snow", 24, function(st, c)
    for i = 1, 20 do
        local x0, y0, sp = st.r[i] * c.fillW, st.r[i + 1 > 20 and 1 or i + 1] * 80, 40 + 40 * st.r[(i % 19) + 1]
        local x = c.fillLX - 30 + (x0 - c.t * sp * 1.4) % (c.fillW + 60)
        local y = c.cy + 45 - (y0 + c.t * sp) % 90
        Put(st, i, B .. "P_Star", x, y, 4 + 5 * st.r[i], (c.t + i) * 57, .8, { .9, .97, 1 }, true)
    end
    local tick = c.t % 1
    if c.te or tick >= .35 then return end
    for j = 0, 3 do
        Put(st, 21 + j, M .. "P_IceShard", c.fillLX + c.fillW * (j + .5) / 4, c.cy + 50 - tick / .35 * 50, 30, -75, 1 - tick / .35 * .4)
    end
end)

-- ---------------------------------------------------------------- Métamorphose : spirale rose, puis moutons qui sautent
R("sheep", 16, function(st, c)
    if not c.te then
        for i = 0, 11 do
            local ang = c.t * 4 + i * pi / 6; local r = 22 + 6 * sin(c.t * 3 + i)
            Put(st, i + 1, B .. "P_Star", c.frontX + cos(ang) * r, c.cy + 12 + sin(ang) * r * .5, 7, math.deg(ang), .9, { 1, .65, 1 }, true)
        end
        return
    end
    if c.te >= .7 then return end
    local u = c.te / .7
    for i = 0, 3 do
        Put(st, 13 + i, M .. "P_Sheep", c.fillLX + c.fillW * (.2 + .2 * i), c.cy + 5 + sin(u * pi) * (20 + 8 * i), 26, 0, 1 - u)
    end
end)

-- ---------------------------------------------------------------- Projectiles des arcanes : un trait par seconde depuis la pointe
R("missiles", 3, function(st, c)
    if c.te then return end
    local n = math.floor(c.t - .5)
    if n < 0 then return end
    local u = (c.t - .5 - n) / .45
    if u > 1 then return end
    local x = c.frontX + u * (END(c) - c.frontX)
    PutWH(st, 1, B .. "P_Glow", x - 30, c.cy + 5, 60, 12, 0, 1 - u * .3, { .85, .5, 1 }, true)
    Put(st, 2, B .. "P_Glow", x, c.cy + 5, 26, 0, 1, { 1, .85, 1 }, true)
    if u < .25 then Put(st, 3, B .. "P_Glow", c.frontX, c.cy + 5, 60, 0, 1 - u * 4, { .9, .6, 1 }, true) end
end)

-- ---------------------------------------------------------------- Déflagration des arcanes : anneaux de plus en plus rapides
R("blast_rings", 5, function(st, c)
    if not c.te then
        local hz = 1 + 4 * c.p * c.p
        for j = 0, 2 do
            local u = (c.t * hz + j / 3) % 1; local r = 8 + 34 * u
            PutWH(st, j + 1, B .. "P_Bubble", c.frontX, c.cy + 5, r * 2, r * 2, 0, .8 * (1 - u) * c.p, { 1, .67, 1 }, true)
        end
        return
    end
    if c.te >= .6 then return end
    local u = c.te / .6
    Ring(st, 4, END(c) - 20, c.cy + 5, 150, u, { 1, .7, 1 })
    Put(st, 5, B .. "P_Glow", END(c) - 20, c.cy + 5, 180 * (1 - u * .5), 0, 1 - u, { 1, .8, 1 }, true)
end)

-- ---------------------------------------------------------------- Évocation : le mana revient vers l'icône
R("evocation", 17, function(st, c)
    for i = 0, 15 do
        local u = (c.t * .45 + i / 16) % 1; local x0 = c.fillLX + 30 + st.r[i + 1] * (c.fillW - 30)
        local x = x0 + (c.iconX - x0) * u
        Put(st, i + 1, B .. "P_Glow", x, c.cy + 5 + sin(u * 6 + st.r[i + 1] * 6) * 22 * (1 - u), 6 + 6 * u, 0, sin(pi * u), { .45, .7, 1 }, true)
    end
    Put(st, 17, B .. "P_Glow", c.iconX, c.cy + 5, 95, 0, .35 + .25 * sin(c.t * 4), { .5, .75, 1 }, true)
end)

-- ---------------------------------------------------------------- Invocation d'eau / de nourriture : l'objet se forme au bout de la barre
local function Conjure(name, item, col, extra)
    R(name, 22, function(st, c)
        local x, y = c.te and END(c) - 24 or c.frontX, c.cy + 5
        local k = c.te and 1 or c.p
        for i = 0, 4 do                                    -- flux de mana de l'icône vers l'objet
            local u = (c.t * .7 + i / 5) % 1; local px = c.iconX + 30 + (x - c.iconX - 30) * u
            Put(st, i + 1, B .. "P_Glow", px, y + sin(u * 9 + i) * 6, 4 + 4 * u, 0, sin(pi * u) * .8, col, true)
        end
        local rad = 18 + 14 * k
        for i = 0, 3 do                                    -- cercle de runes sous l'objet
            local ang = c.t * 1.6 + i * pi / 2
            Put(st, i + 6, B .. "P_Rune_0" .. (i + 1), x + cos(ang) * rad, y - 16 + sin(ang) * rad * .35, 16, math.deg(ang), .4 + .6 * k, { .95, .7, 1 }, true)
        end
        local bounce = (c.te and c.te < .5) and sin(c.te * 18) * (1 - c.te / .5) * 6 or 0
        local sz = (6 + 30 * k ^ 1.4) * (1 + ((c.te and c.te < .5) and .25 * (1 - c.te / .5) or 0))
        Put(st, 10, B .. "P_Glow", x, y, sz * 2.6, 0, .5 + .3 * sin(c.t * 6), col, true)
        Put(st, 11, M .. item, x, y + bounce + sin(c.t * 5) * 2, sz, 0, min(1, .3 + k))
        extra(st, c, x, y, k)
        if not (c.te and c.te < .6) then return end
        local u = c.te / .6                                -- éclat final
        Ring(st, 16, x, y, 120, u, col, .6)
        for i = 0, 5 do
            local ang = i * pi / 3; local r2 = u * 60
            Put(st, 17 + i, B .. "P_Star", x + cos(ang) * r2, y + sin(ang) * r2 * .6, 8 * (1 - u), math.deg(ang), 1 - u, { 1, .95, 1 }, true)
        end
    end)
end
Conjure("conjure_water", "P_DropBlue", { .5, .75, 1 }, function(st, c, x, y, k)
    for i = 0, 3 do
        local ang = c.t * 3 + i * 1.57; local r = (20 + 6 * sin(c.t * 2 + i)) * (.5 + .5 * k)
        Put(st, 12 + i, M .. "P_DropBlue", x + cos(ang) * r, y + sin(ang) * r * .6, 8, 0, 1)
    end
end)
Conjure("conjure_food", "P_Bread", { 1, .75, .35 }, function(st, c, x, y, k)
    for i = 0, 2 do
        local u = (c.t * .5 + i / 3) % 1
        Put(st, 12 + i, B .. "P_Smoke", x + sin(u * 6 + i) * 6, y + 14 + u * 40, 10 + 14 * u, 0, sin(pi * u) * .35 * k, { 1, .95, .85 })
    end
end)

-- ---------------------------------------------------------------- Téléportation : tourbillon, la barre se dissout vers le haut
R("teleport", 18, function(st, c)
    local k = c.te and 1 or c.p; local x = c.te and END(c) - 24 or c.frontX
    Put(st, 1, B .. "P_PortalSwirl", x, c.cy + 5, 30 + 60 * k, math.deg(c.t * 4), .5 + .5 * k, { .8, .45, 1 }, true)
    for i = 0, 15 do
        if i / 16 <= k then
            local x0 = c.fillLX + st.r[i + 1] * max(1, x - c.fillLX); local u = (c.t * .6 + st.r[i + 2 > 20 and 1 or i + 2]) % 1
            Put(st, i + 2, B .. "P_Glow", x0, c.cy - 10 + u * 70, 3 + 4 * st.r[i + 1], 0, sin(pi * u), { .85, .6, 1 }, true)
        end
    end
    if c.te and c.te < .3 then Put(st, 18, B .. "P_Glow", c.fillLX + c.fillW / 2, c.cy, 220, 0, 1 - c.te / .3, { 1, .9, 1 }, true) end
end)

-- ---------------------------------------------------------------- Portail : un grand portail ovale se forme au centre
R("portal", 10, function(st, c)
    local zx, rx, ry = c.fillLX + c.fillW * .5, 34, 70
    local k = c.te and 1 or c.p
    PutWH(st, 1, B .. "P_PortalSwirl", zx, c.cy + 5, 2 * rx, 2 * ry, math.deg(c.t * 2.5), k * k * .9, { .75, .4, 1 }, true)
    for i = 0, 7 do
        if i / 8 <= k then
            local ang = pi / 2 + 2 * pi * k * i / 8
            Put(st, i + 2, B .. "P_Glow", zx + rx * cos(ang), c.cy + 5 + ry * sin(ang), 10, 0, 1, { 1, .9, 1 }, true)
        end
    end
    if c.te and c.te < .3 then Put(st, 10, B .. "P_Glow", zx, c.cy, 200, 0, 1 - c.te / .3, { 1, .85, 1 }, true) end
end)

-- ---------------------------------------------------------------- looks des sorts
local FIRE, FROST, ARC = { 1, .55, .15 }, { .6, .85, 1 }, { .75, .45, 1 }
FCB.Looks:RegisterPack(M, {
    families = { "embers", "embers_big", "ice", "frostfire", "arcane_pink", "arcane_blue" },
    spells = {
        fireball    = { family = "embers",      fill = "Fill_fireball",  props = { "mage_bolt_fire" },      veil = FIRE },
        pyroblast   = { family = "embers_big",  fill = "Fill_pyroblast", props = { "mage_orbit_flames" },   veil = FIRE, veilAlpha = { .2, .45 }, shake = { late = 3, finish = 10 } },
        flamestrike = { family = "embers",      fill = "Fill_fireball",  props = { "mage_zone_circle" },    veil = FIRE },
        scorch      = { family = "embers",                               props = { "mage_scorch" },         veil = FIRE, wakeCurve = 1.4 },
        frostbolt   = { family = "ice",                                  props = { "mage_bolt_ice" },       veil = FROST },
        blizzard    = { family = "ice",                                  props = { "mage_snow" },           veil = FROST },
        frostfire   = { family = "frostfire",   fill = "Fill_frostfire", props = { "mage_bolt_frostfire" }, veil = { .85, .7, .8 } },
        polymorph   = { family = "arcane_pink", fill = "Fill_polymorph", bg = "BG_polymorph", props = { "mage_sheep" }, veil = { 1, .55, .9 }, wakeCurve = 1.4 },
        arcmissiles = { family = "arcane",                               props = { "mage_missiles" },       veil = ARC },
        arcblast    = { family = "arcane",                               props = { "mage_blast_rings" },    veil = ARC },
        evocation   = { family = "arcane_blue", fill = "Fill_arcane_blue", props = { "mage_evocation" },    veil = { .45, .65, 1 } },
        conjure     = { family = "arcane",                               props = { "mage_conjure_water" },  veil = ARC },
        conjurefood = { family = "arcane",                               props = { "mage_conjure_food" },   veil = ARC },
        teleport    = { family = "arcane",                               props = { "mage_teleport" },       veil = ARC },
        portal      = { family = "arcane",                               props = { "mage_portal" },         veil = ARC },
    },
})
