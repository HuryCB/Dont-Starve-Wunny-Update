local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
	Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
	Asset("ANIM", "anim/rabbit_hole.zip"),
	Asset("ANIM", "anim/bunnybeard.zip"),
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
	"boards",
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
	"rabbit",
	"rabbit",
	"boards",
	"boards",
	"boards",
	"boards",
	"boards",
	"boards",
	"boards",
	"tophat",
	"tophat",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"nightmarefuel",
	"silk",
	"waxwelljournal",
	-- "shovel",

	-- "carrot",
	-- "carrot",

	-- "carrot",
	-- "carrot",
	-- "carrot",
	-- "carrot",
	-- "carrot",
	-- "carrot",
	-- "carrot",
	-- "carrot",

	"manrabbit_tail",
	"manrabbit_tail",

	-- "tophat_magician",

	-- "bookstation",
	-- "book_birds",
	-- "book_horticulture",
	-- "book_silviculture",
	-- "book_sleep",
	-- "book_brimstone",
	-- "book_tentacles",

	-- "book_fish",
	-- "book_fire",
	-- "book_web",
	-- "book_temperature",
	-- "book_light",
	-- "book_rain",
	-- "book_moon",
	-- "book_bees",
	-- "book_research_station",

	-- "book_horticulture_upgraded",
	-- "book_light_upgraded",

	-- "monstermeat",
	-- "monstermeat",
	-- "monstermeat",
	-- "manrabbit_tail",
	-- "manrabbit_tail",
	-- "manrabbit_tail",
	-- "manrabbit_tail",

	-- "boards",
	-- "boards",
	-- "boards",
	-- "boards",
	-- "bernie_inactive",
	-- "lucy",
	-- "spidereggsack",
	-- "pigskin",
	-- "meat",
	-- "meat",

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

local function ForceDespawnShadowMinions(inst)
    local todespawn = {}
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("shadowminion") then
            table.insert(todespawn, v)
        end
    end
    for i, v in ipairs(todespawn) do
        inst.components.petleash:DespawnPet(v)
    end
end

local function OnDespawn(inst, migrationdata)
	if inst.woby ~= nil then
		inst.woby:OnPlayerLinkDespawn()
		inst.woby:PushEvent("player_despawn")
	end

	if migrationdata ~= nil then
		ForceDespawnShadowMinions(inst)
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
	--resistencia da willow
	inst.components.freezable:SetResistance(3)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "wunny_speed_mod", 1)
end

local function onbecameghost(inst)
	-- Remove speed modifier when becoming a ghost
	-- inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "wunny_speed_mod")
	for k, v in pairs(inst.components.petleash:GetPets()) do
		if v:HasTag("shadowminion") then
			inst:RemoveEventCallback("onremove", inst._onpetlost, v)
			inst.components.sanity:RemoveSanityPenalty(v)
			if v._killtask == nil then
				v._killtask = v:DoTaskInTime(math.random(), KillPet)
			end
		end
	end
	if not GetGameModeProperty("no_sanity") then
		inst.components.sanity.ignore = false
		inst.components.sanity:SetPercent(.5, true)
		inst.components.sanity.ignore = true
	end
end

-- When loading or spawning the character
local function onload(inst, data)
	inst.components.magician:StopUsing()
    -- OnSkinsChanged(inst, {nofx = true})

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

local BEARDLORD_SANITY_THRESOLD = 0.4 -- 50 sanity
local function OnSanityDelta(inst, data)
	-- local BEARD_BITS = { 1, 3, 9 }

	if not inst.isbeardlord and data.newpercent < BEARDLORD_SANITY_THRESOLD then
		-- Becoming beardlord
		-- inst.components.sanity.current = 0
		inst.isbeardlord = true
		print("barba do beard")
		print(inst.nivelDaBarba)
		-- inst.components.sanity.dapperness = -TUNING.DAPPERNESS_TINY


		inst.components.combat:SetAttackPeriod(0.5)
		-- inst.components.sanity:DoDelta(-TUNING.WUNNY_SANITY)
		inst.components.sanity:SetPercent(0)
		inst.components.combat.damagemultiplier = 1.1
		inst.components.health:SetAbsorptionAmount(0.1)

		inst.components.beard.prize = "beardhair"
		-- inst:AddTag("playermonster")
		inst:AddTag("monster")
		inst.components.skinner:SetSkinMode("beardlord_skin", "wilson")
		if inst.components.eater ~= nil then
			inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODTYPE.MEAT, FOODTYPE.GOODIES })
			inst.components.eater:SetStrongStomach(true)
			inst.components.eater:SetCanEatRawMeat(true)
		end
		-- inst.components.sanityaura.aura = -TUNING.SANITYAURA_SMALL
		-- SetSkin(inst)
		print("monster de barba")
		print(inst.nivelDaBarba)
		-- if inst.nivelDaBarba == 1
		-- then
		-- 	inst.AnimState:OverrideSymbol("beard", "beard", "beard_short")
		-- 	inst.AnimState:OverrideSymbol("beard", "beard_silk", "beard_short")
		-- elseif inst.nivelDaBarba == 2
		-- then
		-- 	inst.AnimState:OverrideSymbol("beard", "beard", "beard_medium")
		-- elseif inst.nivelDaBarba == 3
		-- then
		-- 	inst.AnimState:OverrideSymbol("beard", "beard", "beard_long")
		-- end

	elseif inst.isbeardlord and data.newpercent >= BEARDLORD_SANITY_THRESOLD then
		-- Becoming bunny
		inst.isbeardlord = false

		-- inst.components.sanity.dapperness = 0

		inst.components.health:SetAbsorptionAmount(0)
		inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
		if TheWorld:HasTag("cave") then
			inst.components.combat.damagemultiplier = 0.5
		else
			inst.components.combat.damagemultiplier = 0.5
		end
		inst.components.beard.prize = "manrabbit_tail"
		-- inst:RemoveTag("playermonster")
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
	-- print("barba sã")
	-- print(inst.nivelDaBarba)
	-- if inst.nivelDaBarba == 1
	-- then
	-- 	inst.AnimState:OverrideSymbol("beard", "beard_silk", "beardsilk_short")
	-- elseif inst.nivelDaBarba == 2
	-- then
	-- 	inst.AnimState:OverrideSymbol("beard", "beard_silk", "beardsilk_medium")
	-- elseif inst.nivelDaBarba == 3
	-- then
	-- 	inst.AnimState:OverrideSymbol("beard", "beard_silk", "beardsilk_long")
	-- end
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
	inst.runningSpeed = 1.2
	print("print caveday")
end

local caveDusk = function(inst)
	inst.components.locomotor.runspeed = 7.8
	inst.runningSpeed = 1.3
	print("print cavedusk")
end

local caveNight = function(inst)
	if TheWorld.state.iscavenight
	then
		inst.components.locomotor.runspeed = 7.5
		inst.runningSpeed = 1.25
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
	inst.runningSpeed = 1.3
end

local surfaceDusk = function(inst)
	inst.components.locomotor.runspeed = 7.5
	inst.runningSpeed = 1.25
end

local surfaceNight = function(inst)
	inst.components.locomotor.runspeed = 7.2
	inst.runningSpeed = 1.2
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
	inst.nivelDaBarba = 0

	inst.AnimState:ClearOverrideSymbol("beard")
end

local BEARD_DAYS = { 4, 8, 16 } --mudar depois para 4, 8 ,16
local BEARD_BITS = { 1, 3, 9 }

local function OnGrowShortBeard(inst, skinname)
	inst.nivelDaBarba = 1
	print("teste barba short")
	print(inst.nivelDaBarba)

	-- if inst.isbeardlord then
	-- 	if skinname == nil then
	-- 		inst.AnimState:OverrideSymbol("beard", "beard_silk", "beard_short")
	-- 	else
	-- 		inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_short")
	-- 	end
	-- end
	-- if not inst.isbeardlord then
	if skinname == nil then
		inst.AnimState:OverrideSymbol("beard", "bunnybeard", "beard_short")
	else
		inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_short")
	end
	-- end
	inst.components.beard.bits = BEARD_BITS[1]
end

local function OnGrowMediumBeard(inst, skinname)
	inst.nivelDaBarba = 2
	print("teste barba medi")
	print(inst.nivelDaBarba)
	if skinname == nil then
		inst.AnimState:OverrideSymbol("beard", "bunnybeard", "beard_medium")
	else
		inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_medium")
	end
	inst.components.beard.bits = BEARD_BITS[2]
end

local function OnGrowLongBeard(inst, skinname)
	inst.nivelDaBarba = 3
	print("teste barba long")
	print(inst.nivelDaBarba)
	if skinname == nil then
		inst.AnimState:OverrideSymbol("beard", "bunnybeard", "beard_long")
	else
		inst.AnimState:OverrideSkinSymbol("beard", skinname, "beard_long")
	end
	inst.components.beard.bits = BEARD_BITS[3]
end

local function sanityfn(inst) --, dt)
	local delta = inst.components.temperature:IsFreezing() and -TUNING.SANITYAURA_LARGE or 0
	local x, y, z = inst.Transform:GetWorldPosition()
	local max_rad = 10
	-- local ents = TheSim:FindEntities(x, y, z, max_rad, FIRE_TAGS)
	for i, v in ipairs(ents) do
		if v.components.burnable ~= nil and v.components.burnable:IsBurning() then
			local rad = v.components.burnable:GetLargestLightRadius() or 1
			local sz = TUNING.SANITYAURA_TINY * math.min(max_rad, rad) / max_rad
			local distsq = inst:GetDistanceSqToInst(v) - 9
			-- shift the value so that a distance of 3 is the minimum
			delta = delta + sz / math.max(1, distsq)
		end
	end
	return delta
end

local SHADOWCREATURE_MUST_TAGS = { "shadowcreature", "_combat", "locomotor" }
local SHADOWCREATURE_CANT_TAGS = { "INLIMBO", "notaunt" }
local function OnReadFn(inst, book)
	if inst.components.sanity:IsInsane() then

		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 16, SHADOWCREATURE_MUST_TAGS, SHADOWCREATURE_CANT_TAGS)

		if #ents < TUNING.BOOK_MAX_SHADOWCREATURES then
			TheWorld.components.shadowcreaturespawner:SpawnShadowCreature(inst)
		end
	end
end

local function OnDeath(inst)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("shadowminion") and v._killtask == nil then
            v._killtask = v:DoTaskInTime(math.random(), KillPet)
        end
    end
end

local function KillPet(pet)
	if pet.components.health:IsInvincible() then
		--reschedule
		pet._killtask = pet:DoTaskInTime(.5, KillPet)
	else
		pet.components.health:Kill()
	end
end

local function OnSpawnPet(inst, pet)
    if pet:HasTag("shadowminion") then
        if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
			--if not inst.components.builder.freebuildmode then
	            inst.components.sanity:AddSanityPenalty(pet, TUNING.SHADOWWAXWELL_SANITY_PENALTY[string.upper(pet.prefab)])
			--end
            inst:ListenForEvent("onremove", inst._onpetlost, pet)
            pet.components.skinner:CopySkinsFromPlayer(inst)
        elseif pet._killtask == nil then
            pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
        end
    elseif inst._OnSpawnPet ~= nil then
        inst:_OnSpawnPet(pet)
    end
end

local function OnDespawnPet(inst, pet)
    if pet:HasTag("shadowminion") then
		if not inst.is_snapshot_user_session and pet.sg ~= nil then
			pet.sg:GoToState("quickdespawn")
		else
			pet:Remove()
		end
    elseif inst._OnDespawnPet ~= nil then
        inst:_OnDespawnPet(pet)
    end
end

local master_postinit = function(inst)

	inst.runningSpeed = 1

	inst.nivelDaBarba = 0

	inst.components.builder.science_bonus = 1 --voltar, mudar para este depois
	-- inst.components.builder.science_bonus = 2

	--beard
	inst:AddComponent("beard")
	inst.components.beard.onreset = OnResetBeard
	inst.components.beard.prize = "manrabbit_tail"
	inst.components.beard.is_skinnable = true
	inst.components.beard:AddCallback(BEARD_DAYS[1], OnGrowShortBeard)
	inst.components.beard:AddCallback(BEARD_DAYS[2], OnGrowMediumBeard)
	inst.components.beard:AddCallback(BEARD_DAYS[3], OnGrowLongBeard)


	inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default

	inst.components.combat:SetAttackPeriod(TUNING.WILSON_ATTACK_PERIOD)
	inst.soundsname = "willow"
	inst:AddTag("wunny")

	--Waxwell
	inst:AddTag("shadowmagic")
	inst:AddTag("magician")
	inst:AddTag("reader")
	inst:AddComponent("magician")
	inst:AddComponent("reader")

	inst.components.reader:SetSanityPenaltyMultiplier(TUNING.MAXWELL_READING_SANITY_MULT)
    inst.components.reader:SetOnReadFn(OnReadFn)

	if inst.components.petleash ~= nil then
        inst._OnSpawnPet = inst.components.petleash.onspawnfn
        inst._OnDespawnPet = inst.components.petleash.ondespawnfn
		inst.components.petleash:SetMaxPets(inst.components.petleash:GetMaxPets() + 6)
    else
        inst:AddComponent("petleash")
		inst.components.petleash:SetMaxPets(6)
    end

	inst.components.petleash:SetOnSpawnFn(OnSpawnPet)
    inst.components.petleash:SetOnDespawnFn(OnDespawnPet)

	inst._onpetlost = function(pet) inst.components.sanity:RemoveSanityPenalty(pet) end

	inst:ListenForEvent("death", OnDeath)

	--Webber
	inst:AddTag("spiderwhisperer")
	inst:AddTag(UPGRADETYPES.SPIDER .. "_upgradeuser")

	--Wendy
	-- inst:AddTag("ghostlyfriend")
	-- inst:AddTag("elixirbrewer")

	--Wes
	inst:AddTag("mime")
	inst:AddTag("balloonomancer")

	--wickerbottom
	inst:AddTag("bookbuilder")
	inst:AddComponent("reader")
	inst.components.reader:SetOnReadFn(OnReadFn)

	--willow
	inst:AddTag("pyromaniac")
	inst:AddTag("expertchef")
	inst:AddTag("bernieowner")
	-- inst.components.sanity.custom_rate_fn = sanityfn
	inst.components.temperature.inherentinsulation = -TUNING.INSULATION_TINY
	inst.components.temperature:SetFreezingHurtRate(TUNING.WILSON_HEALTH / TUNING.WILLOW_FREEZING_KILL_TIME)

	--winona
	inst:AddTag("handyperson")

	--wolfgang
	-- inst:AddTag("strongman")

	--Woodie
	inst:AddTag("woodcutter")
	-- inst:AddTag("werehuman")

	--Wormwood
	inst:AddTag("plantkin")
	-- inst:AddTag("self_fertilizable")

	--Wortox
	-- inst:AddTag("monster")
	-- inst:AddTag("soulstealer")
	-- inst:AddTag("souleater")

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
	-- inst:AddTag("expertchef") -- já tem na Willow

	--Walter
	inst:AddTag("pebblemaker")
	inst:AddTag("pinetreepioneer")
	-- inst:AddTag("allergictobees")
	inst:AddTag("slingshot_sharpshooter")
	-- inst:AddTag("efficient_sleeper")
	inst:AddTag("dogrider")
	inst:AddTag("nowormholesanityloss") -- talvez tirar para balancear
	-- inst:AddTag("storyteller") -- for storyteller component

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
			-- inst.components.hunger:SetRate(
			-- 	inst.runningSpeed
			-- -- * TUNING.WILSON_HUNGER_RATE *
			-- --  TUNING.WUNNY_HUNGER_RATE
			-- ) --1.20
			inst.components.hunger.hungerrate = inst.runningSpeed * TUNING.WILSON_HUNGER_RATE
		else
			-- 	inst.components.hunger:SetRate(
			-- 		-- 1
			-- 	-- *
			-- 	TUNING.WILSON_HUNGER_RATE
			-- 	-- * TUNING.WUNNY_HUNGER_RATE
			-- )
			inst.components.hunger.hungerrate = TUNING.WILSON_HUNGER_RATE
		end
	end)

	-- Stats
	inst.components.health:SetMaxHealth(TUNING.WUNNY_HEALTH)
	inst.components.hunger:SetMax(TUNING.WUNNY_HUNGER)
	inst.components.sanity:SetMax(TUNING.WUNNY_SANITY)

	-- Sanity rate
	-- inst.components.sanity.night_drain_mult = 0

	inst:DoPeriodicTask(.2, function()
		local pos = Vector3(inst.Transform:GetWorldPosition())
		local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 6)
		-- local isNearbyRabbit = false
		for k, v in pairs(ents) do
			if v.prefab then
				if v.prefab == "bunnyman"
					or v.prefab == "newbunnyman"
					or v.prefab == "everythingbunnyman"
					or v.prefab == "daybunnyman"
				then
					if v.components.follower.leader == nil
					then
						if v.components.combat:TargetIs(inst) then
							v.components.combat:SetTarget(nil)
						end
						inst.components.leader:AddFollower(v)
						--lose hunger on befriending
						inst.components.hunger:DoDelta(-12.5)
					end
				end
			end
			if v.prefab == "rabbit" then
				-- isNearbyRabbit = true
				v.components.inventoryitem.canbepickedup = true
			end
		end

		-- local pos = Vector3(inst.Transform:GetWorldPosition())
		-- local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 24)
		-- for k, v in pairs(ents) do
		-- 	if v.prefab == "rabbit" then
		-- 		-- if isNearbyRabbit == false then
		-- 			v.components.inventoryitem.canbepickedup = false
		-- 		-- end
		-- 	end
		-- end
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
			elseif victim.prefab == "bunnyman" or victim.prefab == "newbunnyman" or victim.prefab == "everythingbunnyman" or
				victim.prefab == "daybunnyman" then
				inst.components.sanity:DoDelta(-10)
				local dropChance = math.random(0, 2)
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
	-- inst.components.petleash:SetMaxPets(0) -- walter can only have Woby as a pet

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
