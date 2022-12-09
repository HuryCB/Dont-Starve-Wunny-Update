local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
	Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
	Asset("ANIM", "anim/rabbit_hole.zip"),
}

local prefabsItens = {
	"carrot"
}

TUNING.WUNNY_HEALTH = 115
TUNING.WUNNY_HUNGER = 175
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

local BEARDLORD_SKINS = {
	"beardlord_skin",
}

local NORMAL_SKINS = {
	"normal_skin",
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

	-- "bernie_inactive",
	-- "lucy",
	-- "spidereggsack",

	-- "abigail_flower"
}

local prefabs =
{
	"wobybig",
	"wobysmall",
}
local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
	start_inv[string.lower(k)] = v.WUNNY
end

prefabs = FlattenTree({ prefabs, start_inv }, true)

local function SpawnWoby(inst)
	local player_check_distance = 40
	local attempts = 0

	local max_attempts = 30
	local x, y, z = inst.Transform:GetWorldPosition()

	local woby = SpawnPrefab(TUNING.WALTER_STARTING_WOBY)
	inst.woby = woby
	woby:LinkToPlayer(inst)
	inst:ListenForEvent("onremove", inst._woby_onremove, woby)

	while true do
		local offset = FindWalkableOffset(inst:GetPosition(), math.random() * PI, player_check_distance + 1, 10)

		if offset then
			local spawn_x = x + offset.x
			local spawn_z = z + offset.z

			if attempts >= max_attempts then
				woby.Transform:SetPosition(spawn_x, y, spawn_z)
				break
			elseif not IsAnyPlayerInRange(spawn_x, 0, spawn_z, player_check_distance) then
				woby.Transform:SetPosition(spawn_x, y, spawn_z)
				break
			else
				attempts = attempts + 1
			end
		elseif attempts >= max_attempts then
			woby.Transform:SetPosition(x, y, z)
			break
		else
			attempts = attempts + 1
		end
	end

	return woby
end

local function ResetOrStartWobyBuckTimer(inst)
	if inst.components.timer:TimerExists("wobybuck") then
		inst.components.timer:SetTimeLeft("wobybuck", TUNING.WALTER_WOBYBUCK_DECAY_TIME)
	else
		inst.components.timer:StartTimer("wobybuck", TUNING.WALTER_WOBYBUCK_DECAY_TIME)
	end
end

local function OnTimerDone(inst, data)
	if data and data.name == "wobybuck" then
		inst._wobybuck_damage = 0
	end
end

local function OnAttacked(inst, data)
	if inst.components.rider:IsRiding() then
		local mount = inst.components.rider:GetMount()
		if mount:HasTag("woby") then
			local damage = data and data.damage or TUNING.WALTER_WOBYBUCK_DAMAGE_MAX * 0.5 -- Fallback in case of mods.
			inst._wobybuck_damage = inst._wobybuck_damage + damage
			if inst._wobybuck_damage >= TUNING.WALTER_WOBYBUCK_DAMAGE_MAX then
				inst.components.timer:StopTimer("wobybuck")
				inst._wobybuck_damage = 0
				mount.components.rideable:Buck()
			else
				ResetOrStartWobyBuckTimer(inst)
			end
		end
	end
end

local function OnWobyTransformed(inst, woby)
	if inst.woby ~= nil then
		inst:RemoveEventCallback("onremove", inst._woby_onremove, inst.woby)
	end

	inst.woby = woby
	inst:ListenForEvent("onremove", inst._woby_onremove, woby)
end

local function OnWobyRemoved(inst)
	inst.woby = nil
	inst._replacewobytask = inst:DoTaskInTime(1,
		function(i) i._replacewobytask = nil if i.woby == nil then SpawnWoby(i) end end)
end

local function OnRemoveEntity(inst)
	-- hack to remove pets when spawned due to session state reconstruction for autosave snapshots
	if inst.woby ~= nil and inst.woby.spawntime == GetTime() then
		inst:RemoveEventCallback("onremove", inst._woby_onremove, inst.woby)
		inst.woby:Remove()
	end

	if inst._story_proxy ~= nil and inst._story_proxy:IsValid() then
		inst._story_proxy:Remove()
	end
end

local function OnDespawn(inst)
	if inst.woby ~= nil then
		inst.woby:OnPlayerLinkDespawn()
		inst.woby:PushEvent("player_despawn")
	end
end

local function OnReroll(inst)
	if inst.woby ~= nil then
		inst.woby:OnPlayerLinkDespawn(true)
	end
end

-- When the character is revived from human
local function onbecamehuman(inst)
	-- Set speed when not a ghost (optional)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunny_speed_mod", 1)
end

local function onbecameghost(inst)
	-- Remove speed modifier when becoming a ghost
	-- inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wunny_speed_mod")
end

-- When loading or spawning the character
local function onload(inst, data)
	inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
	inst:ListenForEvent("ms_becameghost", onbecameghost)

	if inst:HasTag("playerghost") then
		onbecameghost(inst)
	else
		onbecamehuman(inst)
	end

	if data ~= nil then
		if data.woby ~= nil then
			inst._woby_spawntask:Cancel()
			inst._woby_spawntask = nil

			local woby = SpawnSaveRecord(data.woby)
			inst.woby = woby
			if woby ~= nil then
				if inst.migrationpets ~= nil then
					table.insert(inst.migrationpets, woby)
				end
				woby:LinkToPlayer(inst)

				woby.AnimState:SetMultColour(0, 0, 0, 1)
				woby.components.colourtweener:StartTween({ 1, 1, 1, 1 }, 19 * FRAMES)
				local fx = SpawnPrefab(woby.spawnfx)
				fx.entity:SetParent(woby.entity)

				inst:ListenForEvent("onremove", inst._woby_onremove, woby)
			end
		end
		inst._wobybuck_damage = data.buckdamage or 0
	end
end

-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst)
	-- Minimap icon
	inst.MiniMapEntity:SetIcon("wunny.tex")
end

local function OnSave(inst, data)
	data.woby = inst.woby ~= nil and inst.woby:GetSaveRecord() or nil
	data.buckdamage = inst._wobybuck_damage > 0 and inst._wobybuck_damage or nil
end

local function SetSkin(inst)
	if inst.sg:HasStateTag("nomorph") or
		inst:HasTag("playerghost") or
		inst.components.health:IsDead() then
		return
	end

	-- Set skin
	-- local s = inst.fluffstage + 1
	-- inst.components.skinner:SetSkinMode(inst.isbeardlord and BEARDLORD_SKINS[0] or NORMAL_SKINS[1], "wilson")
	inst.components.skinner:SetSkinMode("normal_skin", "wilson")
end

local function OnSanityDelta(inst, data)
	if not inst.isbeardlord and data.newpercent < BEARDLORD_SANITY_THRESOLD then
		-- Becoming beardlord
		-- inst.components.sanity.current = 0
		inst.isbeardlord = true
		inst.components.sanity.dapperness = -TUNING.DAPPERNESS_TINY
		inst.components.combat:SetAttackPeriod(0.5)
		inst.components.sanity:DoDelta(-TUNING.WUNNY_SANITY)
		inst.components.sanity:SetPercent(0)
		inst.components.combat.damagemultiplier = 1.1
		inst.components.health:SetAbsorptionAmount(TUNING.WATHGRITHR_ABSORPTION)
		TUNING.WUNNY_HUNGER_RATE = 1.2
		
		inst.components.beard.prize = "beardhair"
		inst:AddTag("playermonster")
		inst:AddTag("monster")
		inst.components.skinner:SetSkinMode("beardlord_skin", "wilson")
		if inst.components.eater ~= nil then
			inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODTYPE.MEAT, FOODTYPE.GOODIES })
			inst.components.eater:SetStrongStomach(true)
			inst.components.eater:SetCanEatRawMeat(true)
		end
		-- inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
		-- SetSkin(inst)
	elseif inst.isbeardlord and data.newpercent >= BEARDLORD_SANITY_THRESOLD then
		-- Becoming bunny
		inst.isbeardlord = false
		inst.components.sanity.dapperness = 0
		
		inst.components.health:SetAbsorptionAmount(0)
		TUNING.WUNNY_HUNGER_RATE = 1
		inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD * 110 / 100)
		if TheWorld:HasTag("cave") then
			inst.components.combat.damagemultiplier = 0.5
		else
			inst.components.combat.damagemultiplier = 0.5
		end
		inst.components.beard.prize = "manrabbit_tail"
		inst:RemoveTag("playermonster")
		inst:RemoveTag("monster")
		-- inst.components.sanityaura.aura = 0
		inst.components.skinner:SetSkinMode("normal_skin", "wilson")
		if inst.components.eater ~= nil then
			inst.components.eater:SetDiet({ FOODGROUP.VEGETARIAN }, { FOODGROUP.VEGETARIAN })
			inst.components.eater:SetStrongStomach(false)
			inst.components.eater:SetCanEatRawMeat(false)
		end
		-- SetSkin(inst)
		-- Adjust stats
		-- AdjustLowSanityStats(inst, 0)
	end

	-- Adjust stats
	if inst.isbeardlord then
		-- local bonus = LOW_SANITY_BONUS_THRESHOLD - inst.components.sanity.current
		-- AdjustLowSanityStats(inst, bonus > 0 and bonus or 0)
	end
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
	if not inst.isbearlord then
		inst.components.combat.damagemultiplier = 0.5
	end
	-- inst.components.sanity.custom_rate_fn = caveSanityfn
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
	if not inst.isbearlord then
		inst.components.combat.damagemultiplier = 0.5
	end

	-- inst.components.sanity.custom_rate_fn = surfaceSanityfn

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
local BEARD_BITS = { 1, 3, 9 }

local function OnGrowShortBeard(inst, skinname)
	if skinname == nil then
		inst.AnimState:OverrideSymbol("beard", "beard", "beard_short")
	else
		inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_short")
	end
	inst.components.beard.bits = BEARD_BITS[1]
end

local function OnGrowMediumBeard(inst, skinname)
	if skinname == nil then
		inst.AnimState:OverrideSymbol("beard", "beard", "beard_medium")
	else
		inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_medium")
	end
	inst.components.beard.bits = BEARD_BITS[2]
end

local function OnGrowLongBeard(inst, skinname)
	if skinname == nil then
		inst.AnimState:OverrideSymbol("beard", "beard", "beard_long")
	else
		inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_long")
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

	inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD * 110 / 100)
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
	inst:AddTag(UPGRADETYPES.SPIDER .. "_upgradeuser")

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
	-- inst:AddTag("monster")
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
			inst.components.hunger:SetRate(TUNING.WUNNY_RUNNING_HUNGER_RATE * TUNING.WUNNY_HUNGER_RATE) --1.20
		else
			inst.components.hunger:SetRate(1 * TUNING.WUNNY_HUNGER_RATE)
		end
	end)

	-- Stats
	inst.components.health:SetMaxHealth(TUNING.WUNNY_HEALTH)
	inst.components.hunger:SetMax(TUNING.WUNNY_HUNGER)
	inst.components.sanity:SetMax(TUNING.WUNNY_SANITY)

	-- Sanity rate
	-- inst.components.sanity.night_drain_mult = 0

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
	inst.components.petleash:SetMaxPets(0) -- walter can only have Woby as a pet

	inst._wobybuck_damage = 0
	inst:ListenForEvent("timerdone", OnTimerDone)

	inst._woby_spawntask = inst:DoTaskInTime(0, function(i) i._woby_spawntask = nil SpawnWoby(i) end)
	inst._woby_onremove = function(woby) OnWobyRemoved(inst) end

	inst.OnWobyTransformed = OnWobyTransformed

	inst.OnSave = OnSave
	inst.OnLoad = onload
	inst.OnNewSpawn = onload
	inst.OnDespawn = OnDespawn
	inst:ListenForEvent("ms_playerreroll", OnReroll)
	inst:ListenForEvent("sanitydelta", OnSanityDelta)

	inst:ListenForEvent("onremove", OnRemoveEntity)
	inst:ListenForEvent("attacked", OnAttacked)

	local moisture = inst.components.moisture
	local GetDryingRate_prev = moisture.GetDryingRate
	function moisture:GetDryingRate(moisturerate, ...)
		local rate = GetDryingRate_prev(self, moisturerate, ...)
		rate = rate * (1 - (1 * 0.20))
		return rate
	end

end

return MakePlayerCharacter("wunny", prefabs, assets, common_postinit, master_postinit, prefabs, prefabsItens)
-- ,MakePlacer("common/rabbithole_placer", "rabbithole", "rabbit_hole", "anim")
