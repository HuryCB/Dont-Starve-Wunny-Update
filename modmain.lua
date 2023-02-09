PrefabFiles = {
    "wunny",
    "wunny_none",
    "rabbithole_placer",
    -- "everythingbunnyhouse_placer",
    "rabbithouse",
    "wunnyrabbithouse",
    "carrot",
    "birchnuthat",
    -- "bunnyback",
    "coolerpack",
    "beardlordpack",
    "beardlordhat",
    -- "batbunny",
    "newbunnyhouse",
    "daybunnyhouse",
    "dwarfbunnyhouse",
    "everythingbunnyhouse",
    "everythingbunnyman",
    "ultrabunnyhouse",
    "ultrabunnyman",
    "shadowbunnyman",
    "shadowbunnyhouse",
    "newbunnyman",
    "daybunnyman",
    "dwarfbunnyman",
    "rabbitamulet",
    "wunny_catapult",
    "bunnykinghouse",
    "bunnyking",
    "wunny_spotlight",
    "wunny_battery_low",
    "wunny_battery_high",
    "snakeking",
    "sewing_tape",
    "spiderbunny",
    "bunnybat",
    -- "modhats",

    "wunnyslingshot",
    -- "beardlordback"
}

Assets = {
    Asset("IMAGE", "images/saveslot_portraits/wunny.tex"),
    Asset("ATLAS", "images/saveslot_portraits/wunny.xml"),

    Asset("IMAGE", "images/selectscreen_portraits/wunny.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/wunny.xml"),
    Asset("IMAGE", "images/selectscreen_portraits/wunny_silho.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/wunny_silho.xml"),

    Asset("IMAGE", "bigportraits/wunny.tex"),
    Asset("ATLAS", "bigportraits/wunny.xml"),

    Asset("IMAGE", "images/map_icons/wunny.tex"),
    Asset("ATLAS", "images/map_icons/wunny.xml"),

    Asset("IMAGE", "images/avatars/avatar_wunny.tex"),
    Asset("ATLAS", "images/avatars/avatar_wunny.xml"),

    Asset("IMAGE", "images/avatars/avatar_ghost_wunny.tex"),
    Asset("ATLAS", "images/avatars/avatar_ghost_wunny.xml"),

    Asset("IMAGE", "images/avatars/self_inspect_wunny.tex"),
    Asset("ATLAS", "images/avatars/self_inspect_wunny.xml"),

    Asset("IMAGE", "images/names_wunny.tex"),
    Asset("ATLAS", "images/names_wunny.xml"),

    Asset("IMAGE", "images/names_gold_wunny.tex"),
    Asset("ATLAS", "images/names_gold_wunny.xml"),

    Asset("ATLAS", "images/inventoryimages/rabbithole.xml"),
    Asset("IMAGE", "images/inventoryimages/rabbithole.tex"),

    Asset("IMAGE", "images/inventoryimages/rabbithole.tex"),

    Asset("IMAGE", "images/rabbit_hole.tex"),
    Asset("ATLAS", "images/rabbit_hole.xml"),

    Asset("ATLAS", "images/inventoryimages/birchnuthat.xml"),

    -- Asset("ATLAS", "images/inventoryimages/ham_bat.xml"),

    Asset("ATLAS", "images/inventoryimages/bat_bunny.xml"),

    Asset("ATLAS", "images/inventoryimages/beardlordhat.xml"),

    Asset("ATLAS", "images/inventoryimages/bunny.xml"),

    Asset("ATLAS", "images/inventoryimages/bunnyhouse.xml"),
    Asset("ATLAS", "images/inventoryimages/winona_catapult.xml"),
    Asset("ATLAS", "images/inventoryimages/wunny_spotlight.xml"),
    Asset("ATLAS", "images/inventoryimages/wunny_battery_low.xml"),
    Asset("ATLAS", "images/inventoryimages/wunny_battery_high.xml"),
    Asset("ATLAS", "images/inventoryimages/coolerpack.xml"),
    Asset("ATLAS", "images/inventoryimages/beardlordpack.xml"),
    -- Asset("IMAGE", "images/inventoryimages/coolerpack.tex"),


    Asset("ANIM", "anim/swap_coolerpack.zip"),

    Asset("ANIM", "anim/everythingmanrabbit_build.zip"),

    Asset("ANIM", "anim/bat_bunny.zip"),
    Asset("ANIM", "anim/swap_bat_bunny.zip"),

    Asset("ANIM", "anim/slingshot.zip"),
    Asset("ANIM", "anim/swap_slingshot.zip"),
    Asset("IMAGE", "images/inventoryimages/slingshot.tex"),


}

AddMinimapAtlas("images/map_icons/wunny.xml")
AddMinimapAtlas("images/map_icons/coolerpack.xml")
AddMinimapAtlas("images/map_icons/beardlordpack.xml")

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local RECIPETABS = GLOBAL.RECIPETABS
local Ingredient = GLOBAL.Ingredient
local TECH = GLOBAL.TECH
local _G = GLOBAL
local ACTIONS = GLOBAL.ACTIONS
local ActionHandler = GLOBAL.ActionHandler
-- _G.speedMultiplier = 1

modimport("strings.lua")

local containers = require "containers"

local params = {}

local OVERRIDE_WIDGETSETUP = false
local containers_widgetsetup_base = containers.widgetsetup

function containers.widgetsetup(container, prefab)
    local t = params[prefab or container.inst.prefab]
    if t ~= nil then
        for k, v in pairs(t) do
            container[k] = v
        end
        container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
        if OVERRIDE_WIDGETSETUP then
            container.type = "coolerpack"
        end
    else
        containers_widgetsetup_base(container, prefab)
    end
end

params.coolerpack = {
    widget =
    {
        slotpos = {},
        animbank = "ui_piggyback_2x6",
        animbuild = "ui_piggyback_2x6",
        pos = GLOBAL.Vector3( -5, -50, 0),
    },
    issidewidget = true,
    type = "pack",
}

for y = 0, 5 do
    table.insert(params.coolerpack.widget.slotpos, GLOBAL.Vector3( -162, -75 * y + 170, 0))
    table.insert(params.coolerpack.widget.slotpos, GLOBAL.Vector3( -162 + 75, -75 * y + 170, 0))
end

function params.coolerpack.itemtestfn(container, item, slot)
    -- if item.prefab == "spoiled_food" then
    --     return true
    -- end

    -- --Perishable
    -- if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
    --     return false
    -- end

    -- --Edible
    -- for k, v in pairs(GLOBAL.FOODTYPE) do
    --     if item:HasTag("edible_" .. v) then
    --         return true
    --     end
    -- end

    return true
end

AddRecipe("coolerpack", {
    Ingredient("manrabbit_tail", 4) --4
    , Ingredient("silk", 6),
    Ingredient("rope", 2)
},
    RECIPETABS.SURVIVAL
    , TECH.NONE, nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/coolerpack.xml",
    "coolerpack.tex")
--beardlordpack
AddRecipe("beardlordpack", {
    Ingredient("manrabbit_tail", 4) --4
    , Ingredient("silk", 6),
    Ingredient("rope", 2)
    , Ingredient("beardhair", 2)
},
    RECIPETABS.SURVIVAL
    , TECH.NONE, nil,
    nil,
    nil,
    nil,
    "wunny", "images/inventoryimages/beardlordpack.xml",
    "beardlordpack.tex")
--end of beardlordpack

local containers_widgetsetup_custom = containers.widgetsetup
local MAXITEMSLOTS = containers.MAXITEMSLOTS

AddPrefabPostInit("world_network", function(inst)
    if containers.widgetsetup ~= containers_widgetsetup_custom then
        OVERRIDE_WIDGETSETUP = true
        local containers_widgetsetup_base2 = containers.widgetsetup
        function containers.widgetsetup(container, prefab)
            containers_widgetsetup_base2(container, prefab)
            if container.type == "coolerpack" then
                container.type = "pack"
            end
        end
    end
    if containers.MAXITEMSLOTS < MAXITEMSLOTS then
        containers.MAXITEMSLOTS = MAXITEMSLOTS
    end
end)

--------------------------------------------------------------------------
--[[ slingshot ]]
--------------------------------------------------------------------------

-- local params = {}
-- local containers = { MAXITEMSLOTS = 0 }

-- containers.params = params

-- function containers.widgetsetup(container, prefab, data)
--     local t = data or params[prefab or container.inst.prefab]
--     if t ~= nil then
--         for k, v in pairs(t) do
--             container[k] = v
--         end
--         container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
--     end
-- end

-- params.slingshot =
-- {
--     widget =
--     {
--         slotpos =
--         {
--             Vector3(0,   32 + 4,  0),
--         },
--         slotbg =
--         {
--             { image = "slingshot_ammo_slot.tex" },
--         },
--         animbank = "ui_cookpot_1x2",
--         animbuild = "ui_cookpot_1x2",
--         pos = Vector3(0, 15, 0),
--     },
--     usespecificslotsforitems = true,
--     type = "hand_inv",
--     excludefromcrafting = true,
-- }

-- function params.slingshot.itemtestfn(container, item, slot)
-- 	return item:HasTag("slingshotammo")
-- end


-- for k, v in pairs(params) do
--     containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
-- end
--------------------------------------------------------------------------

-- The character select screen lines
STRINGS.CHARACTER_TITLES.wunny = "The Bunnylord"
STRINGS.CHARACTER_NAMES.wunny = "Wunny MODED"
STRINGS.CHARACTER_DESCRIPTIONS.wunny =
"*Transforms into a beardlord\n*Befriends bunnyman\n*Is a Vegetarian\n*Has some perks of others survivors... you will have to find out"
-- STRINGS.CHARACTER_QUOTES.wunny = "\"Quote\""
STRINGS.CHARACTER_SURVIVABILITY.wunny = "Grim"

--variables
TUNING.WUNNY_SPEED = 6
TUNING.WUNNY_RUNNING_HUNGER_RATE = 1
TUNING.WUNNY_HUNGER_RATE = TUNING.WILSON_HUNGER_RATE
TUNING.BUNNYPACK_HUNGER = 1.15 --mudar para 1.1
TUNING.BEARDLORDPACK_HUNGER = 1.175 --mudar para 1.1
-- WUNNY_RUNNING_HUNGER_RATETUNNIN.WUNNY_IDLE_HUNGER_RATE = 1

---CUSTOM TUNINGS

TUNING.SNAKE_SPEED = 3
TUNING.SNAKE_TARGET_DIST = 8
TUNING.SNAKE_KEEP_TARGET_DIST = 15
TUNING.SNAKE_HEALTH = 100
TUNING.SNAKE_DAMAGE = 10
TUNING.SNAKE_ATTACK_PERIOD = 3
TUNING.SNAKE_POISON_CHANCE = 0.25
TUNING.SNAKE_POISON_START_DAY = 3 -- the day that poison snakes have a chance to show up
TUNING.SNAKEDEN_RELEASE_TIME = 5
TUNING.SNAKE_JUNGLETREE_CHANCE = 0.5 -- chance of a normal snake
TUNING.SNAKE_JUNGLETREE_POISON_CHANCE = 0.25 -- chance of a poison snake
TUNING.SNAKE_JUNGLETREE_AMOUNT_TALL = 2 -- num of times to try and spawn a snake from a tall tree
TUNING.SNAKE_JUNGLETREE_AMOUNT_MED = 1 -- num of times to try and spawn a snake from a normal tree
TUNING.SNAKE_JUNGLETREE_AMOUNT_SMALL = 1 -- num of times to try and spawn a snake from a small tree
TUNING.SNAKEDEN_MAX_SNAKES = 3
-- Custom speech strings
STRINGS.CHARACTERS.WUNNY = require "speech_wunny"

-- The character's name as appears in-game
STRINGS.NAMES.WUNNY = "Wunny"
STRINGS.SKIN_NAMES.wunny_none = "Wunny"

-- The skins shown in the cycle view window on the character select screen.
-- A good place to see what you can put in here is in skinutils.lua, in the function GetSkinModes
local skin_modes = {
    {
        type = "ghost_skin",
        anim_bank = "ghost",
        idle_anim = "idle",
        scale = 0.75,
        offset = { 0, -25 }
    },
}

--idk
local spacing = 2

--function of rabbithole recipe
local function rabbithole_recipe(ingredients, level)
    AddRecipe("rabbithole", ingredients, RECIPETABS.SURVIVAL, level,
        "rabbit_placer", spacing, nil, nil, "wunny", "images/inventoryimages/rabbithole.xml")
end

rabbithole_recipe({ Ingredient("carrot", 2), Ingredient("rabbit", 2), Ingredient("shovel", 1) }, TECH.NONE)
STRINGS.RECIPE_DESC.RABBITHOLE = "A new home for the rabbits."

--newbunnymanhouse
local function bunnyhouse_recipe(ingredientes, level)
    AddRecipe("newbunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "rabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

bunnyhouse_recipe(
    {
        Ingredient("carrot", 5),
        Ingredient("manrabbit_tail", 2)
        , Ingredient("boards", 2)
    , Ingredient("axe", 1)
    }, TECH.NONE)

--end newbunnyhouse

--bunnykinghouse
local function bunnykinghouse_recipe(ingredientes, level)
    AddRecipe("bunnykinghouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "kingrabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

bunnykinghouse_recipe(
    {
        Ingredient("carrot", 10),
        Ingredient("manrabbit_tail", 4)
        , Ingredient("boards", 4)
    }, TECH.NONE)

--end bunnykinghouse

--dwarfunnymanhouse
local function dwarfbunnyhouse_recipe(ingredientes, level)
    AddRecipe("dwarfbunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "dwarfrabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

dwarfbunnyhouse_recipe(
    {
        Ingredient("carrot", 3),
        Ingredient("manrabbit_tail", 2)
        , Ingredient("boards", 1)
    , Ingredient("axe", 1)
    , Ingredient("pickaxe", 1)
    }, TECH.NONE)

--end dwarfunnymanhouse

--everythingbunnyman house
local function everythingbunnyhouse_recipe(ingredientes, level)
    AddRecipe("everythingbunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "rabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

everythingbunnyhouse_recipe(
    {
        Ingredient("carrot", 5),
        Ingredient("manrabbit_tail", 2)
        , Ingredient("boards", 2)
    , Ingredient("axe", 1)
    , Ingredient("pickaxe", 1)
    , Ingredient("spear", 1)
    }, TECH.NONE)
--end everything

--start daybunny
local function day_recipe(ingredientes, level)
    AddRecipe("daybunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "rabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

day_recipe(
    {
        Ingredient("carrot", 5),
        Ingredient("manrabbit_tail", 2)
        , Ingredient("boards", 2)
    , Ingredient("axe", 1)
    , Ingredient("pickaxe", 1)
    , Ingredient("spear", 1)
    }, TECH.NONE)
--end daybunny

--start ultrabunnyman house
local function ultrabunnyhouse_recipe(ingredientes, level)
    AddRecipe("ultrabunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "rabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

ultrabunnyhouse_recipe(
    {
        Ingredient("carrot", 5),
        Ingredient("manrabbit_tail", 2)
        , Ingredient("boards", 2)
    , Ingredient("axe", 1)
    , Ingredient("pickaxe", 1)
    , Ingredient("spear", 1)
    , Ingredient("livinglog", 1)
    }, TECH.NONE)
--end ultragbunnyman house

--start shadowbunnyman house
local function shadowbunnyhouse_recipe(ingredientes, level)
    AddRecipe("shadowbunnyhouse", ingredientes, RECIPETABS.SURVIVAL, level,
        "rabbithouse_placer", nil, nil, nil, "wunny", "images/inventoryimages/bunnyhouse.xml",
        "bunnyhouse.tex")
end

shadowbunnyhouse_recipe(
    {
        Ingredient("carrot", 5),
        Ingredient("manrabbit_tail", 1)
        -- , Ingredient("boards", 2)
        -- , Ingredient("axe", 1)
        , Ingredient("spear", 1)
    , Ingredient("beardhair", 1)
    , Ingredient("livinglog", 2)
    , Ingredient("nightmarefuel", 1)
    }, TECH.NONE)
--end ultragbunnyman house


--DEFAULT RABBIT HOUSE for crafting options
-- local function rabbithouse_recipe(ingredientes, level)
--     AddRecipe("rabbithouse", ingredientes, RECIPETABS.SURVIVAL, level,
--         "rabbithouse_placer", nil, nil, nil, "wunny")
-- end

-- rabbithouse_recipe(
--     {
--         Ingredient("carrot", 5),
--         Ingredient("manrabbit_tail", 2)
--         , Ingredient("boards", 2)
--     }, TECH.NONE)



AddRecipe("wunnyslingshot",
    {
        Ingredient("twigs", 2)
        , Ingredient("mosquitosack", 3)
    , Ingredient("livinglog", 1)
    , Ingredient("silk", 1)

    }, RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    -- "images/inventoryimages/slingshot.xml",
    nil,
    "slingshot.tex"
)


AddRecipe("lucy",
    {
        Ingredient("axe", 1),
        Ingredient("goldenaxe", 1),
        Ingredient("moonglassaxe", 1),
        Ingredient("livinglog", 1),
        Ingredient("nightmarefuel", 1),
    },
    RECIPETABS.SURVIVAL,
    TECH.MAGIC_ONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    nil,
    "lucy.tex")

AddRecipe("spear_wathgrithr",
    { Ingredient("twigs", 2), Ingredient("flint", 2), Ingredient("goldnugget", 2) }
    , TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny")
AddRecipe("wathgrithrhat", { Ingredient("goldnugget", 2), Ingredient("rocks", 2) }, TECH.NONE, nil,
    nil,
    nil,
    nil,
    "wunny")
-- AddRecipe("batbunny",
--     {
--         Ingredient("manrabbit_tail", 1)
--         -- , Ingredient("twigs", 2)
--         -- , Ingredient("meat", 2)
--     },
--     RECIPETABS.WAR,
--     TECH.NONE,
--     nil,
--     nil,
--     nil,
--     nil,
--     "wunny"
--     ,
--     "images/inventoryimages/bat_bunny.xml",
--     "bat_bunny.tex"
-- )

-- AddRecipe("hambat",
--     {
--         Ingredient("manrabbit_tail", 1)
--         , Ingredient("twigs", 2)
--         , Ingredient("meat", 2)
--     },
--     RECIPETABS.WAR,
--     TECH.NONE,
--     nil,
--     nil,
--     nil,
--     nil,
--     "wunny"
--     ,
--     "images/inventoryimages/bat_bunny.xml",
--     "bat_bunny.tex"
-- )
--sweing-tape
AddRecipe("sewing_tape",
    { Ingredient("silk", 1), Ingredient("cutgrass", 3) },
    RECIPETABS.SURVIVAL,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    nil,
    nil
)
--end of sweing tape
--catapult
AddRecipe("wunny_catapult",
    { Ingredient("sewing_tape", 1)
    , Ingredient("twigs", 3)
    , Ingredient("rocks", 15)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/winona_catapult.xml",
    "winona_catapult.tex")
--end catapult
--wunny_battery_low
AddRecipe("wunny_battery_low",
    { Ingredient("sewing_tape", 1)
    , Ingredient("log", 2)
    , Ingredient("nitre", 2)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/wunny_battery_low.xml",
    "wunny_battery_low.tex")
--end wunny_battery_low
--wunny_battery_high
AddRecipe("wunny_battery_high",
    { Ingredient("sewing_tape", 1)
    , Ingredient("boards", 2)
    , Ingredient("transistor", 2)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/wunny_battery_high.xml",
    "wunny_battery_high.tex")
--end wunny_battery_high
--wunny_spotlight
AddRecipe("wunny_spotlight",
    { Ingredient("sewing_tape", 1)
    , Ingredient("goldnugget", 2)
    , Ingredient("fireflies", 2)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/wunny_spotlight.xml",
    "wunny_spotlight.tex")
--end wunny_spotlight

AddRecipe("birchnuthat",
    { Ingredient("manrabbit_tail", 1)
    , Ingredient("rope", 1)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/birchnuthat.xml",
    "birchnuthat.tex")

AddRecipe("beardlordhat",
    { Ingredient("manrabbit_tail", 1)
    , Ingredient("rope", 1)
    , Ingredient("beardhair", 1)
    },
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
    "wunny",
    "images/inventoryimages/beardlordhat.xml",
    "beardlordhat.tex")

--rabbitamulet
-- AddRecipe("rabbitamulet",
--     { Ingredient("manrabbit_tail", 1)
--         -- , Ingredient("rope", 1)
--         -- , Ingredient("beardhair", 1)
--     },
--     RECIPETABS.WAR,
--     TECH.NONE,
--     nil,
--     nil,
--     nil,
--     nil,
--     "wunny",
--     "images/inventoryimages/beardlordhat.xml",
--     "beardlordhat.tex")
--end of rabbitamulet
-- AddRecipe("bunnyback", { Ingredient("pigskin", 4), Ingredient("silk", 6), Ingredient("rope", 2) }, TECH.NONE)

--"bunnybat"
-- AddRecipe("bunnybat",
--     { Ingredient("manrabbit_tail", 1), Ingredient("twigs", 2), Ingredient("meat", 2) },
--     RECIPETABS.WAR,
--     TECH.SCIENCE_TWO,
--     nil,
--     nil,
--     nil,
--     nil,
--     "wunny",
--     "images/inventoryimages/ham_bat.xml",
--     "ham_bat.tex"
-- )
--end "bunnybat"
-- AddRecipe("bunnyback", { Ingredient("manrabbit_tail", 4), Ingredient("silk", 6), Ingredient("rope", 2) },
--     RECIPETABS.SURVIVAL, TECH.NONE)

-- AddRecipe("bunnyback", { Ingredient("rabbit", 1) },
--     RECIPETABS.SURVIVAL, TECH.NONE, nil,
--     nil,
--     nil,
--     nil,
--     "wunny","images/inventoryimages/coolerpack.xml")
-- local containers_widgetsetup_custom = containers.widgetsetup

-- AddRecipe("bunnyback", { Ingredient("manrabbit_tail", 4), Ingredient("silk", 6), Ingredient("rope", 2) },
-- RECIPETABS.SURVIVAL, TECH.NONE, nil,
-- nil,
-- nil,
-- nil,
-- "wunny", "images/inventoryimages/birchnuthat.xml",
-- "birchnuthat.tex")

--add carrot to rabbithole drop
AddPrefabPostInit("rabbithole", function(inst)
    GLOBAL.MakeInventoryPhysics(inst)

    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    local dig_up_old = inst.components.workable.onfinish
    local function dig_up(inst, chopper)
        inst.components.lootdropper:SpawnLootPrefab("carrot")
        if dig_up_old ~= nil then
            dig_up_old(inst, chopper)
        end
    end

    inst.components.workable:SetOnFinishCallback(dig_up)
end)

local DidSkinnerPostInit = false
AddComponentPostInit("skinner", function(self, inst)
    -- Only do this if we haven't done this
    if DidSkinnerPostInit then return end
    DidSkinnerPostInit = true

    -- Make sure skinner is loaded first before attempting this
    local SetSkinsOnAnim_prev = GLOBAL.SetSkinsOnAnim
    GLOBAL.SetSkinsOnAnim = function(anim_state, prefab, base_skin, clothing_names, skintype, ...)
        if prefab == "wunny" and skintype ~= "ghost_skin" then
            skintype = "normal_skin"
        end
        return SetSkinsOnAnim_prev(anim_state, prefab, base_skin, clothing_names, skintype, ...)
    end
end)


-- local containers_widgetsetup_custom = containers.widgetsetup

-- AddPrefabPostInit("world_network", function(inst)
--     if containers.widgetsetup ~= containers_widgetsetup_custom then
--         OVERRIDE_WIDGETSETUP = true
--         local containers_widgetsetup_base2 = containers.widgetsetup
--         function containers.widgetsetup(container, prefab)
--             containers_widgetsetup_base2(container, prefab)
--             if container.type == "bunnypack" then
--                 container.type = "pack"
--             end
--         end
--     end

-- end)
-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
local function NewQuickAction(inst, action)
    -- if action.target ~= nil and action.target.prefab == "berrybush_juicy" then return "dojostleaction" end
    -- local quick = false
    -- if inst and inst:HasTag("wunny") then
    --     quick = true
    -- end
    -- if quick then
    --     return "doshortaction"
    -- else
    --     return "dolongaction"
    -- end

    if inst and inst:HasTag("wunny") then
        return "doshortaction"
    end

    return (inst.replica.rider ~= nil and inst.replica.rider:IsRiding() and "dolongaction")
        or (action.target:HasTag("jostlepick") and "dojostleaction")
        or (action.target:HasTag("quickpick") and "doshortaction")
        or (inst:HasTag("fastpicker") and "doshortaction")
        or (inst:HasTag("quagmire_fasthands") and "domediumaction")
        or "dolongaction"
end

-- AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.PICK, NewQuickAction))
-- AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.TAKEITEM, NewQuickAction))
-- AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.HARVEST, NewQuickAction))
-- AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.PICK, NewQuickAction))
-- AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.TAKEITEM, NewQuickAction))
-- AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.HARVEST, NewQuickAction))

-- local function GetGameMode(game_mode)
--     return GAME_MODES[game_mode] or GameModeError(game_mode)
-- end

-- function IsRecipeValidInGameMode(game_mode, recipe_name)
--     local invalid_recipes = GetGameMode(game_mode).invalid_recipes
--     return not table.contains(invalid_recipes, recipe_name)
-- end

-- function GetValidRecipe(recname)
--     if not IsRecipeValidInGameMode(TheNet:GetServerGameMode(), recname) then
--         return
--     end
--     local rec = AllRecipes[recname]
--     return rec ~= nil and not rec.is_deconstruction_recipe and (rec.require_special_event == nil or IsSpecialEventActive(rec.require_special_event)) and rec or nil
-- end

AddStategraphPostInit("wilson", function(sg)
    -- local actionhandler = GLOBAL.ActionHandler(GLOBAL.ACTIONS.PICK, NewQuickAction)
    sg.actionhandlers[GLOBAL.ACTIONS.PICK] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.PICK, function(inst, action)
            if inst and inst:HasTag("wunny") then
                inst.components.hunger:DoDelta(-50)--testando issoo
                return "doshortaction"
            end

            return (inst.replica.rider ~= nil and inst.replica.rider:IsRiding() and "dolongaction")
                or (action.target:HasTag("jostlepick") and "dojostleaction")
                or (action.target:HasTag("quickpick") and "doshortaction")
                or (inst:HasTag("fastpicker") and "doshortaction")
                or (inst:HasTag("quagmire_fasthands") and "domediumaction")
                or "dolongaction"
        end)
    sg.actionhandlers[GLOBAL.ACTIONS.TAKEITEM] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.TAKEITEM, function(inst, action)
            if inst and inst:HasTag("wunny") and action.target ~= nil and action.target.takeitem ~= nil then
                return "doshortaction"
            end
            return action.target ~= nil
                and action.target.takeitem ~= nil --added for quagmire
                and "give"
                or "dolongaction"
        end)
    sg.actionhandlers[GLOBAL.ACTIONS.HARVEST] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.HARVEST, function(inst)
            if inst and inst:HasTag("wunny") then
                return "doshortaction"
            end
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end)
    sg.actionhandlers[GLOBAL.ACTIONS.COOK] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.COOK, function(inst, action)
            if inst:HasTag("wunny") then
                return "doshortaction"
            end
            return inst:HasTag("expertchef") and "domediumaction" or "dolongaction"
        end)
    sg.actionhandlers[GLOBAL.ACTIONS.REPAIR] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.REPAIR, function(inst, action)
            if inst:HasTag("wunny") then
                return "doshortaction"
            end
            return action.target:HasTag("repairshortaction") and "doshortaction" or "dolongaction"
        end)
    sg.actionhandlers[GLOBAL.ACTIONS.MANUALEXTINGUISH] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.MANUALEXTINGUISH,
            function(inst)
                if inst:HasTag("wunny") then
                    return "doshortaction"
                end
                return inst:HasTag("pyromaniac") and "domediumaction" or "dolongaction"
            end)
    sg.actionhandlers[GLOBAL.ACTIONS.SHAVE] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.SHAVE, function(inst, action)
            if inst:HasTag("wunny") then
                return "doshortaction"
            end
            return "dolongaction"
        end)
    sg.actionhandlers[GLOBAL.ACTIONS.MAKEBALLOON] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.MAKEBALLOON,
            function(inst, action)
                if inst:HasTag("wunny") then
                    return "doshortaction"
                end
                return "dolongaction"
            end)
    sg.actionhandlers[GLOBAL.ACTIONS.HEAL] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.HEAL, function(inst, action)
            if inst:HasTag("wunny") then
                return "doshortaction"
            end
            return "dolongaction"
        end)
    sg.actionhandlers[GLOBAL.ACTIONS.FEED] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.FEED, function(inst, action)
            if inst:HasTag("wunny") then
                return "doshortaction"
            end
            return "dolongaction"
        end)
    sg.actionhandlers[GLOBAL.ACTIONS.BUILD] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.BUILD, function(inst, action)
            -- local rec = GetValidRecipe(action.recipe)
            return
            -- (rec ~= nil and rec.sg_state)
            -- or
                (inst:HasTag("wunny") and "doshortaction")
                or (inst:HasTag("hungrybuilder") and "dohungrybuild")
                or (inst:HasTag("fastbuilder") and "domediumaction")
                or (inst:HasTag("slowbuilder") and "dolongestaction")
                or "dolongaction"
        end)
    sg.actionhandlers[GLOBAL.ACTIONS.MURDER] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.MURDER,
            function(inst)
                if inst:HasTag("wunny") then
                    return "doshortaction"
                end
                return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
            end)
    -- sg.actionhandlers[GLOBAL.ACTIONS.FERTILIZE] = GLOBAL.ActionHandler(GLOBAL.ACTIONS.FERTILIZE, function(inst, action)
    --     return (action.target ~= nil and action.target ~= inst and "doshortaction")
    --         or (action.invobject ~= nil and action.invobject:HasTag("slowfertilize") and "fertilize")
    --         or "fertilize_short"
    -- end)
end)

-- AddStategraphPostInit("wilson", ActionHandler(ACTIONS.TAKEITEM, NewQuickAction))
-- AddStategraphPostInit("wilson", ActionHandler(ACTIONS.HARVEST, NewQuickAction))
-- AddStategraphPostInit("wilson_client", ActionHandler(ACTIONS.PICK, NewQuickAction))
-- AddStategraphPostInit("wilson_client", ActionHandler(ACTIONS.TAKEITEM, NewQuickAction))
-- AddStategraphPostInit("wilson_client", ActionHandler(ACTIONS.HARVEST, NewQuickAction))
GLOBAL.package.loaded["stategraphs/SGwilson"] = nil

AddModCharacter("wunny", "MALE", skin_modes)
