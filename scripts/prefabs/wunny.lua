local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
	Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
	Asset("ANIM", "anim/rabbit_hole.zip"),
}

local prefabsItens = {
	"carrot"
}

TUNING.WUNNY_HEALTH = 115
TUNING.WUNNY_HUNGER = 150
TUNING.WUNNY_SANITY = 185

PrefabFiles = {
	"smallmeat",
	"cookedsmallmeat",
	"cookedmonstermeat",
	"beardhair",
	"monstermeat",
	"nightmarefuel",
	"carrot",
	"manrabbit_tail",
	"carrot_cooked",
}

-- Custom starting inventory
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.WUNNY = {
	"rabbit",
	"rabbit",
	
	"shovel",

	"carrot",
	"carrot",

	"manrabbit_tail",
	"manrabbit_tail",
	
}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.WUNNY
end
local prefabs = FlattenTree(start_inv, true)

-- When the character is revived from human
local function onbecamehuman(inst)
	-- Set speed when not a ghost (optional)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunny_speed_mod", 1)
end

local function onbecameghost(inst)
	-- Remove speed modifier when becoming a ghost
	inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wunny_speed_mod")
end

-- When loading or spawning the character
local function onload(inst)
	inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
	inst:ListenForEvent("ms_becameghost", onbecameghost)

	if inst:HasTag("playerghost") then
		onbecameghost(inst)
	else
		onbecamehuman(inst)
	end
end

-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst)
	-- Minimap icon
	inst.MiniMapEntity:SetIcon("wunny.tex")
end

--is incave
-- local isInCave = function(inst)
-- 	if TheWorld:HasTag("cave")
-- 	then return true
-- 	end
-- 	return false
-- end

local caveSanityfn = function(inst)
	local delta = 0
	if TheWorld.state.iscaveday
	then delta = -10 / 60
	end
	return delta
end

local surfaceSanityfn = function(inst)
	local delta = 0
	if TheWorld.state.isdusk
	then delta = -2.5 / 60
	elseif TheWorld.state.isnight
	then delta = -7.5 / 60
	end
	return delta
end


local caveDay = function(inst)
	inst.components.locomotor.runspeed = 7.2
	TUNING.WUNNY_RUNNING_HUNGER_RATE = 1.2
	print("print caveday")
end

local caveDusk = function(inst)
	inst.components.locomotor.runspeed = 7.8
	TUNING.WUNNY_RUNNING_HUNGER_RATE = 1.3
	print("print cavedusk")
end

local caveNight = function(inst)
	if TheWorld.state.iscavenight
	then
		inst.components.locomotor.runspeed = 7.5
		TUNING.WUNNY_RUNNING_HUNGER_RATE = 1.25
		print("print cavenight")
	end
end

local caveBehaviour = function(inst)
	inst.components.combat.damagemultiplier = 1.1
	inst.components.sanity.custom_rate_fn = caveSanityfn
	if TheWorld.state.iscaveday
	then
		caveDay(inst)
	elseif TheWorld.state.iscavedusk
	then
		caveDusk(inst)
	else
		caveNight(inst)
	end

	inst:WatchWorldState("iscaveday", caveDay)
	inst:WatchWorldState("iscavedusk", caveDusk)
	inst:WatchWorldState("iscavenight", caveNight)
end

local surfaceDay = function(inst)
	inst.components.locomotor.runspeed = 7.8
	TUNING.WUNNY_RUNNING_HUNGER_RATE = 1.3
end

local surfaceDusk = function(inst)
	inst.components.locomotor.runspeed = 7.5
	TUNING.WUNNY_RUNNING_HUNGER_RATE = 1.25
end

local surfaceNight = function(inst)
	inst.components.locomotor.runspeed = 7.2
	TUNING.WUNNY_RUNNING_HUNGER_RATE = 1.2
end

local surfaceBehaviour = function(inst)
	inst.components.combat.damagemultiplier = 0.9

	inst.components.sanity.custom_rate_fn = surfaceSanityfn

	if TheWorld.state.isday
	then
		surfaceDay(inst)
	elseif TheWorld.state.isdusk
	then
		surfaceDusk(inst)
	else
		surfaceNight(inst)
	end

	inst:WatchWorldState("isday", surfaceDay)
	inst:WatchWorldState("isdusk", surfaceDusk)
	inst:WatchWorldState("isnight", surfaceNight)
end

local function CarrotPreserverRate(inst, item)
	return (item ~= nil and item == "carrot" or item == "coocked_carrot") and TUNING.WURT_FISH_PRESERVER_RATE or nil
end

local function OnResetBeard(inst)
    inst.AnimState:ClearOverrideSymbol("beard")
end

local BEARD_DAYS = { 4, 8, 16 }
local BEARD_BITS = { 1, 3,  9 }

local function OnGrowShortBeard(inst, skinname)
    if skinname == nil then
        inst.AnimState:OverrideSymbol("beard", "beard", "beard_short")
    else
        inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_short" )
    end
    inst.components.beard.bits = BEARD_BITS[1]
end

local function OnGrowMediumBeard(inst, skinname)
    if skinname == nil then
        inst.AnimState:OverrideSymbol("beard", "beard", "beard_medium")
    else
        inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_medium" )
    end
    inst.components.beard.bits = BEARD_BITS[2]
end

local function OnGrowLongBeard(inst, skinname)
    if skinname == nil then
        inst.AnimState:OverrideSymbol("beard", "beard", "beard_long")
    else
        inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_long" )
    end
    inst.components.beard.bits = BEARD_BITS[3]
end

local master_postinit = function(inst)

	--beard
	inst:AddComponent("beard")
    inst.components.beard.onreset = OnResetBeard
    inst.components.beard.prize = "manrabbit_tail"
    inst.components.beard.is_skinnable = true
    inst.components.beard:AddCallback(BEARD_DAYS[1], OnGrowShortBeard)
    inst.components.beard:AddCallback(BEARD_DAYS[2], OnGrowMediumBeard)
    inst.components.beard:AddCallback(BEARD_DAYS[3], OnGrowLongBeard)


	inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

	inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD*90/100)
	inst.soundsname = "willow"
	inst:AddTag("wunny")

	--Waxwell
	inst:AddTag("shadowmagic")
    inst:AddTag("dappereffects")
	inst:AddTag("magician")
    inst:AddTag("reader")

	--Webber
	inst:AddTag("spiderwhisperer")
	inst:AddTag("dualsoul")
    inst:AddTag(UPGRADETYPES.SPIDER.."_upgradeuser")

	--Wendy
	inst:AddTag("ghostlyfriend")
    inst:AddTag("elixirbrewer")

	--Wes
	inst:AddTag("mime")
    inst:AddTag("balloonomancer")

	--wickerbottom
	inst:AddTag("bookbuilder")

	--willow
	inst:AddTag("pyromaniac")
    inst:AddTag("expertchef")
    inst:AddTag("bernieowner")

	--winona
	inst:AddTag("handyperson")
    inst:AddTag("fastbuilder")
    inst:AddTag("hungrybuilder")

	--wolfgang
	-- inst:AddTag("strongman")

	--Woodie
	inst:AddTag("woodcutter")
    inst:AddTag("polite")
    inst:AddTag("werehuman")

	--Wormwood
	inst:AddTag("plantkin")
    inst:AddTag("self_fertilizable")

	--Wortox
	inst:AddTag("monster")
    inst:AddTag("soulstealer")
	inst:AddTag("souleater")

	--Wurt
	inst:AddTag("merm_builder")

	--wx78
	-- inst:AddTag("batteryuser")          -- from batteryuser component
    -- inst:AddTag("chessfriend")
    -- inst:AddTag("HASHEATER")            -- from heater component
    -- inst:AddTag("soulless")
    -- inst:AddTag("upgrademoduleowner") 

	--Warly
	inst:AddTag("masterchef")
    inst:AddTag("professionalchef")
    inst:AddTag("expertchef")

	--Walter
	inst:AddTag("pebblemaker")
    inst:AddTag("pinetreepioneer")
    -- inst:AddTag("allergictobees")
    inst:AddTag("slingshot_sharpshooter")
    -- inst:AddTag("efficient_sleeper")
    inst:AddTag("dogrider")
    inst:AddTag("nowormholesanityloss")
	inst:AddTag("storyteller") -- for storyteller component

	--Wanda
	inst:AddTag("clockmaker")
	inst:AddTag("pocketwatchcaster")

	--Wigfrid
	inst:AddTag("valkyrie")
    -- inst:AddTag("battlesinger")

	--Wilson
	inst:AddTag("bearded")

--TAGS COM ERRO
	-- inst:AddTag("engineering")
	-- inst:AddTag("handyperson")
	-- inst:AddTag("masterchef")
	-- inst:AddTag("professionalchef")
	-- inst:AddTag("merm_builder")
	-- inst:AddTag("battlesinger")
	-- inst:AddTag("pebblemaker")
	-- inst:AddTag("pinetreepioneer")
	-- inst:AddTag("bookbuilder")
	-- inst:AddTag("spiderwhisperer")
	-- inst:AddTag("plantkin")
	-- inst:AddTag("clockmaker")
	-- inst:AddTag("balloonomancer")
	-- inst:AddTag("slingshot_sharpshooter")
	-- inst:AddTag("pocketwatchcaster")

	inst.components.foodaffinity:AddFoodtypeAffinity(FOODTYPE.VEGGIE, 1.33)
	inst.components.foodaffinity:AddPrefabAffinity("carrot", 1.5)
	inst.components.foodaffinity:AddPrefabAffinity("carrot_cooked", 1.5)
	
	inst:AddComponent("preserver")
	inst.components.preserver:SetPerishRateMultiplier(CarrotPreserverRate)

	if inst.components.eater ~= nil then 
		inst.components.eater:SetDiet({ FOODGROUP.VEGETARIAN }, { FOODGROUP.VEGETARIAN })
	end

	inst:ListenForEvent("locomote", function()
		if inst.sg ~= nil and inst.sg:HasStateTag("moving") then
			inst.components.hunger:SetRate(TUNING.WUNNY_RUNNING_HUNGER_RATE * TUNING.WILSON_HUNGER_RATE) --1.20
		else
			inst.components.hunger:SetRate(1 * TUNING.WILSON_HUNGER_RATE)
		end
	end)

	-- Stats
	inst.components.health:SetMaxHealth(TUNING.WUNNY_HEALTH)
	inst.components.hunger:SetMax(TUNING.WUNNY_HUNGER)
	inst.components.sanity:SetMax(TUNING.WUNNY_SANITY)

	-- Sanity rate
	inst.components.sanity.night_drain_mult = 0

	inst:DoPeriodicTask(.1, function()
		local pos = Vector3(inst.Transform:GetWorldPosition())
		local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 6)
		for k, v in pairs(ents) do
			if v.prefab then
				if v.prefab == "bunnyman" then
					if v.components.follower.leader == nil
					then
						if v.components.combat:TargetIs(inst) then
							v.components.combat:SetTarget(nil)
						end
						inst.components.leader:AddFollower(v)
					end
				end
			end
		end
	end)

	inst:RemoveTag("scarytoprey")

	if TheWorld:HasTag("cave") then
		caveBehaviour(inst)

	else
		surfaceBehaviour(inst)
	end

	local function OnKill(victim, inst)
		if victim and victim.prefab then
			if victim.prefab == "rabbit" then
				inst.components.sanity:DoDelta(-10)
				local dropChance = math.random(0, 1)
				if dropChance == 1 then
					local item = SpawnPrefab("carrot")
					inst.components.inventory:GiveItem(item, nil, inst:GetPosition())
				end
			end

		elseif victim and victim.prefab then
			if victim.prefab == "bunnyman" or victim.prefab:HasTag("manrabbit") then
				inst.components.sanity:DoDelta(-10)
				local dropChance = math.random(0, 1)
				if dropChance == 1 then
					local item = SpawnPrefab("manrabbit_tail")
					inst.components.inventory:GiveItem(item, nil, inst:GetPosition())
				end
			end
		end
	end

	inst:ListenForEvent("killed", function(inst, data) OnKill(data.victim, inst) end)

	-- local function OnInsane(inst)
	-- 	-- inst.components.locomotor.runspeed = 6
	-- end

	-- inst:DoPeriodicTask(1, function()
	-- 	if inst.components.sanity.current < 60 and inst.components.health.currenthealth > 0 then

	-- 		OnInsane(inst)
	-- 	end
	-- end)

	inst.OnLoad = onload
	inst.OnNewSpawn = onload

end

return MakePlayerCharacter("wunny", prefabs, assets, common_postinit, master_postinit, prefabs, prefabsItens)
-- ,MakePlacer("common/rabbithole_placer", "rabbithole", "rabbit_hole", "anim")
