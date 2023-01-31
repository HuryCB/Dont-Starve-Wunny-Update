local assets =
{
    Asset("ANIM", "anim/manrabbit_basic.zip"),
    Asset("ANIM", "anim/manrabbit_actions.zip"),
    Asset("ANIM", "anim/manrabbit_attacks.zip"),
    Asset("ANIM", "anim/manrabbit_build.zip"),
    Asset("ANIM", "anim/manrabbit_boat_jump.zip"),

    -- Asset("ANIM", "anim/manrabbit_beard_build.zip"),
    Asset("ANIM", "anim/manrabbit_beard_basic.zip"),
    Asset("ANIM", "anim/manrabbit_beard_actions.zip"),
    Asset("SOUND", "sound/bunnyman.fsb"),
}

local prefabs =
{
    "meat",
    "monstermeat",
    "manrabbit_tail",
    "beardhair",
    "nightmarefuel",
    "carrot",
    "shadow_despawn",
    "statue_transition_2",
    "pondfish",
    "kelp",
    "froglegs",
    "merm_king_splash",
    "snakeking",
}

local beardlordloot = { "beardhair", "beardhair", "monstermeat" }
local forced_beardlordloot = { "nightmarefuel", "beardhair", "beardhair", "monstermeat" }

local brain = require("brains/bunnykingbrain")

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30

local trading_items =
{
    { prefabs = { "kelp" }, min_count = 2, max_count = 4, reset = false, add_filler = false, },
    { prefabs = { "kelp" }, min_count = 2, max_count = 3, reset = false, add_filler = false, },
    { prefabs = { "seeds" }, min_count = 4, max_count = 6, reset = false, add_filler = false, },
    { prefabs = { "tentaclespots" }, min_count = 1, max_count = 1, reset = false, add_filler = true, },
    { prefabs = { "cutreeds" }, min_count = 1, max_count = 2, reset = false, add_filler = true, },
    -- { prefabs = { "rabbit" }, min_count = 1, max_count = 2, reset = false, add_filler = true, },

    {
        prefabs = { -- These trinkets are generally good for team play, but tend to be poor for solo play.
            -- Theme
            "trinket_12", -- Dessicated Tentacle
            "trinket_25", -- Air Unfreshener
            -- Team
            "trinket_1", -- Melted Marbles
            -- Fishing
            "trinket_17", -- Bent Spork
            "trinket_8", -- Rubber Bung
        },
        min_count = 1, max_count = 1, reset = false, add_filler = true,
    },

    {
        prefabs = { "durian_seeds", "pepper_seeds", "eggplant_seeds", "pumpkin_seeds", "onion_seeds", "garlic_seeds" },
        min_count = 1, max_count = 2, reset = false, add_filler = true,
    },
}

local trading_filler = { "seeds", "kelp", "seeds", "seeds" }

local isStarving = false

local function SpawnSnake(inst)
    print("realmente tentando spawnar cobra")
    local snake = SpawnPrefab("snakeking")
    local spawnpos = inst:GetPosition()
    -- local offset = FindWalkableOffset(spawnpos, math.random() * 2 * PI, 1, 8, true, false, IsPositionValidForEnt(inst, 2))
    -- spawnpos = offset ~= nil and spawnpos + offset or spawnpos
    snake.Transform:SetPosition(spawnpos:Get())
end

local function OnDeath(inst)

    print("morreu, tentando spawnar cobra")
    -- print(lootdropper)
    -- print(inst.components.inventory.lootdropper)--pode crashar
    -- TheWorld:DoTaskInTime(5000, SpawnSnake(inst))

end

local function DoShadowFx(inst, isnightmare)
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("statue_transition_2")
    fx.Transform:SetPosition(x, y, z)
    fx.Transform:SetScale(1.2, 1.2, 1.2)

    --When forcing into nightmare state, shadow_trap would've already spawned this fx
    if not isnightmare then
        fx = SpawnPrefab("shadow_despawn")
        local platform = inst:GetCurrentPlatform()
        if platform ~= nil then
            fx.entity:SetParent(platform.entity)
            fx.Transform:SetPosition(platform.entity:WorldToLocalSpace(x, y, z))
            fx:ListenForEvent("onremove", function()
                fx.Transform:SetPosition(fx.Transform:GetWorldPosition())
                fx.entity:SetParent(nil)
            end, platform)
        else
            fx.Transform:SetPosition(x, y, z)
        end
    end
end

local function IsCrazyGuy(guy)
    local sanity = guy ~= nil and guy.replica.sanity or nil
    return sanity ~= nil and sanity:IsInsanityMode() and
        sanity:GetPercentNetworked() <=
        (guy:HasTag("dappereffects") and TUNING.DAPPER_BEARDLING_SANITY or TUNING.BEARDLING_SANITY)
end

local function IsForcedNightmare(inst)
    return inst.components.timer:TimerExists("forcenightmare")
end

local function ontalk(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/bunnyman/idle_med")
end

local function ClearObservedBeardlord(inst)
    inst.clearbeardlordtask = nil
    if not IsForcedNightmare(inst) then
        inst.beardlord = nil
    end
end

local function SetObserverdBeardLord(inst)
    inst.beardlord = true
    if inst.clearbeardlordtask ~= nil then
        inst.clearbeardlordtask:Cancel()
    end
    inst.clearbeardlordtask = inst:DoTaskInTime(5, ClearObservedBeardlord)
end

local function OnTimerDone(inst, data)
    if data ~= nil and data.name == "forcenightmare" then
        if not (inst:IsInLimbo() or inst:IsAsleep()) then
            if inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("sleeping") then
                inst.components.timer:StartTimer("forcenightmare", 1)
                return
            end
            DoShadowFx(inst, false)
        end
        inst:RemoveEventCallback("timerdone", OnTimerDone)
        inst.AnimState:SetBuild("manrabbit_build")
        if inst.clearbeardlordtask == nil then
            inst.beardlord = nil
        end
    end
end

local function SetForcedBeardLord(inst, duration)
    --duration nil is loading, so don't perform checks
    if duration ~= nil then
        if inst.components.health:IsDead() then
            return
        end
        local t = inst.components.timer:GetTimeLeft("forcenightmare")
        if t ~= nil then
            if t < duration then
                inst.components.timer:SetTimeLeft("forcenightmare", duration)
            end
            return
        end
        inst.components.timer:StartTimer("forcenightmare", duration)
    end
    inst.beardlord = true
    inst.AnimState:SetBuild("manrabbit_beard_build")
    inst:ListenForEvent("timerdone", OnTimerDone)
end

local function OnForceNightmareState(inst, data)
    if data ~= nil and data.duration ~= nil then
        DoShadowFx(inst, true)
        SetForcedBeardLord(inst, data.duration)
    end
end

local function CalcSanityAura(inst, observer)
    return 0
end

local function ShouldAcceptItem(inst, item)
    print(item)
    print(item.prefab)
    local can_eat = (item.components.edible and inst.components.eater:CanEat(item)) and
        (inst.components.hunger and inst.components.hunger:GetPercent() < 1)
    return can_eat or item:HasTag("fish") or item.prefab == "rabbit"
end

local function OnGetItemFromPlayer(inst, giver, item)
    if item.components.edible ~= nil then
        if inst.components.combat:TargetIs(giver) then
            inst.components.combat:SetTarget(nil)
        end

        if inst.components.eater:CanEat(item) then
            local hunger = item.components.edible:GetHunger(inst)
            local chews = 2 -- Most crockpot foods.
            if hunger < TUNING.CALORIES_SMALL then -- 12.5
                chews = 0
            elseif hunger < TUNING.CALORIES_MEDSMALL then -- 18.75
                chews = 1
            end
            inst.sg:GoToState("eat", { chews = chews, })
            inst.components.eater:Eat(item)
        else
            inst.sg:GoToState("trade")
            inst.itemtotrade = item
            inst.tradegiver = giver
        end
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("refuse")
    -- if inst.components.sleeper:IsAsleep() then
    --     inst.components.sleeper:WakeUp()
    -- end
end

local function OnAttacked(inst, data)
    -- inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST,
        function(dude) return dude.prefab == inst.prefab end, MAX_TARGET_SHARES)
end

local function OnNewTarget(inst, data)
    -- inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, function(dude) return dude.prefab == inst.prefab end, MAX_TARGET_SHARES)
end

local function is_meat(item)
    -- return item.components.edible ~= nil and item.components.edible.foodtype == FOODTYPE.MEAT and not item:HasTag("smallcreature")
    return false
end

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_ONEOF_TAGS = { "monster", "player", "pirate" }
local function NormalRetargetFn(inst)
    return not inst:IsInLimbo()
        and FindEntity(
            inst,
            TUNING.PIG_TARGET_DIST,
            function(guy)
                return nil
                -- inst.components.combat:CanTarget(guy)
                -- and (guy:HasTag("monster")
                --     or guy:HasTag("wonkey")
                --     or guy:HasTag("pirate")
                --     or (guy.components.inventory ~= nil and
                --         guy:IsNear(inst, TUNING.BUNNYMAN_SEE_MEAT_DIST) and
                --         guy.components.inventory:FindItem(is_meat) ~= nil))
            end,
            RETARGET_MUST_TAGS, -- see entityreplica.lua
            nil,
            RETARGET_ONEOF_TAGS
        )
        or nil
end

local function NormalKeepTargetFn(inst, target)
    return not (target.sg ~= nil and target.sg:HasStateTag("hiding")) and inst.components.combat:CanTarget(target)
end

local function giveupstring()
    return "RABBIT_GIVEUP", math.random(#STRINGS["RABBIT_GIVEUP"])
end

local function battlecry(combatcmp, target)
    local strtbl =
    target ~= nil and
        target.components.inventory ~= nil and
        target.components.inventory:FindItem(is_meat) ~= nil and
        "RABBIT_MEAT_BATTLECRY" or
        "RABBIT_BATTLECRY"
    return strtbl, math.random(#STRINGS[strtbl])
end

local function GetStatus(inst)
    return inst.components.follower.leader ~= nil and "FOLLOWER" or nil
end

local function LootSetupFunction(lootdropper)
    local guy = lootdropper.inst.causeofdeath
    if IsForcedNightmare(lootdropper.inst) then
        -- forced beard lord
        lootdropper:SetLoot(forced_beardlordloot)
    elseif IsCrazyGuy(guy ~= nil and guy.components.follower ~= nil and guy.components.follower.leader or guy) then
        -- beard lord
        lootdropper:SetLoot(beardlordloot)
    else
        -- regular loot
        lootdropper:AddRandomLoot("carrot", 3)
        lootdropper:AddRandomLoot("meat", 3)
        lootdropper:AddRandomLoot("manrabbit_tail", 2)
        lootdropper.numrandomloot = 1
    end
end

local function OnLoad(inst)
    if IsForcedNightmare(inst) then
        SetForcedBeardLord(inst, nil)
    end
end

local function launchitem(item, angle)
    print("launchitem: ", item)
    local speed = math.random() * 4 + 2
    angle = (angle + math.random() * 60 - 30) * DEGREES
    item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
end

local function OnSpawned(inst)
    local hat = SpawnPrefab("ruinshat")
    print("tentando spawnar chapeu")
    if hat then
        inst.components.inventory:Equip(hat)
    end

    local armor = SpawnPrefab("armorwood")
    if armor then
        inst.components.inventory:Equip(armor)
    end

    local spear = SpawnPrefab("cane")
    if spear then
        inst.components.inventory:Equip(spear)
    end
end

local function TradeItem(inst)
    print("tradeItem")

    local item = inst.itemtotrade
    local giver = inst.tradegiver

    local x, y, z = inst.Transform:GetWorldPosition()
    y = 5.5

    local angle
    if giver ~= nil and giver:IsValid() then
        angle = 180 - giver:GetAngleToPoint(x, 0, z)
    else
        local down = TheCamera:GetDownVec()
        angle = math.atan2(down.z, down.x) / DEGREES
        giver = nil
    end

    local selected_index = math.random(1, #inst.trading_items)
    local selected_item = inst.trading_items[selected_index]

    local isabigheavyfish = item.components.weighable and
        item.components.weighable:GetWeightPercent() >= TUNING.WEIGHABLE_HEAVY_WEIGHT_PERCENT or false
    local bigheavyreward = isabigheavyfish and math.random(1, 2) or 0

    local filler_min = 2 -- Not biasing minimum for filler.
    local filler_max = 4 + bigheavyreward
    local reward_count = math.random(selected_item.min_count, selected_item.max_count) + bigheavyreward

    for k = 1, reward_count do
        local reward_item = SpawnPrefab(selected_item.prefabs[math.random(1, #selected_item.prefabs)])
        reward_item.Transform:SetPosition(x, y, z)
        launchitem(reward_item, angle)
    end

    if selected_item.add_filler then
        for i = filler_min, filler_max do
            local filler_item = SpawnPrefab(trading_filler[math.random(1, #trading_filler)])
            filler_item.Transform:SetPosition(x, y, z)
            launchitem(filler_item, angle)
        end
    end
    if item:HasTag("oceanfish") then
        local goldmin, goldmax, goldprefab = 1, 2, "goldnugget"
        if item.prefab:find("oceanfish_medium_") == 1 then
            goldmin, goldmax = 2, 4
            if item.prefab == "oceanfish_medium_6_inv" or item.prefab == "oceanfish_medium_7_inv" then -- YoT events.
                goldprefab = "lucky_goldnugget"
            end
        end

        local amt = math.random(goldmin, goldmax) + bigheavyreward
        for i = 1, amt do
            local reward_item = SpawnPrefab(goldprefab)
            reward_item.Transform:SetPosition(x, y, z)
            launchitem(reward_item, angle)
        end
    end

    -- Cycle out rewards.
    table.remove(inst.trading_items, selected_index)
    if #inst.trading_items == 0 or selected_item.reset then
        inst.trading_items = deepcopy(trading_items)
    end

    inst.itemtotrade = nil
    inst.tradegiver  = nil

    item:Remove()
end


local function HungerDelta(inst, data)
    if data.newpercent then
        local increase = false
        if inst.lastpercent_hunger and data.newpercent - inst.lastpercent_hunger > 0 then
            increase = true
        end
        inst.lastpercent_hunger = data.newpercent

        if not inst.components.timer:TimerExists("hungrytalk_cooldown") or data.newpercent == 1 or (increase and not inst.components.timer:TimerExists("hungrytalk_increase_cooldown") ) then

          
            if data.newpercent <= 0 then
                inst.components.talker:Say(STRINGS.MERM_KING_TALK_HUNGER_STARVING)
            elseif data.newpercent < 0.1 then
                inst.components.talker:Say(STRINGS.MERM_KING_TALK_HUNGER_CLOSE_STARVING)
            elseif data.newpercent < 0.25 then
                inst.components.talker:Say(STRINGS.MERM_KING_TALK_HUNGER_VERY_HUNGRY)
            elseif data.newpercent < 0.5 then
                inst.components.talker:Say(STRINGS.MERM_KING_TALK_HUNGER_HUNGRY)
            elseif data.newpercent < 0.95 then
                inst.components.talker:Say(STRINGS.MERM_KING_TALK_HUNGER_HUNGRISH)
            else
                inst.components.talker:Say(STRINGS.MERM_KING_TALK_HUNGER_FULL)
            end

            local time = Remap(data.newpercent, 1,0, 30,8)
            if increase then
                inst.components.timer:StopTimer("hungrytalk_increase_cooldown")
                inst.components.timer:StartTimer("hungrytalk_increase_cooldown", 10)
            end
            inst.components.timer:StopTimer("hungrytalk_cooldown")
            inst.components.timer:StartTimer("hungrytalk_cooldown", time)
        end

        if data.newpercent <= 0 then
            -- inst.components.health:StopRegen()
            isStarving = true
            print(isStarving)
        end

        -- if data.oldpercent and data.oldpercent == 0 and data.newpercent > data.oldpercent then
        --     inst.components.health:StartRegen(TUNING.MERM_KING_HEALTH_REGEN, TUNING.MERM_KING_HEALTH_REGEN_PERIOD)
        -- end
    end

end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("manrabbit_build")

    MakeCharacterPhysics(inst, 50, .5)

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()
    -- inst.Transform:SetScale(1.25, 1.25, 1.25)
    inst.Transform:SetScale(1.25 * 3, 1.25 * 3, 1.25 * 3)

    inst:AddTag("cavedweller")
    inst:AddTag("character")
    inst:AddTag("pig")
    inst:AddTag("manrabbit")
    -- inst:AddTag("scarytoprey")

    inst.AnimState:SetBank("manrabbit")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:Hide("hat")
    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAIR_HAT")

    inst.AnimState:SetClientsideBuildOverride("insane", "manrabbit_build", "manrabbit_beard_build")

    --trader (from trader component) added to pristine state for optimization
    inst:AddTag("trader")

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 24
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -500, 0)
    inst.components.talker:MakeChatter()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst.components.talker.ontalk = ontalk

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED * 2.2 -- account for them being stopped for part of their anim
    inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED * 1.9 -- account for them being stopped for part of their anim

    -- boat hopping setup
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst:AddComponent("embarker")
    inst:AddComponent("drownable")

    inst:AddComponent("bloomer")

    ------------------------------------------
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })
    inst.components.eater:SetCanEatRaw()

    --eu, fome
    inst:AddComponent("hunger")
    inst.components.hunger:SetMax(TUNING.MERM_KING_HUNGER)
    inst.components.hunger:SetKillRate(TUNING.MERM_KING_HEALTH / TUNING.MERM_KING_HUNGER_KILL_TIME)
    inst.components.hunger:SetRate(TUNING.MERM_KING_HUNGER_RATE)
    inst:ListenForEvent("hungerdelta", function(_, data) HungerDelta(inst, data) end)

    ------------------------------------------
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "manrabbit_torso"
    inst.components.combat.panic_thresh = TUNING.BUNNYMAN_PANIC_THRESH

    inst.components.combat.GetBattleCryString = battlecry
    inst.components.combat.GetGiveUpString = giveupstring

    MakeMediumBurnableCharacter(inst, "manrabbit_torso")

    inst:AddComponent("named")
    inst.components.named.possiblenames = STRINGS.BUNNYMANNAMES
    inst.components.named:PickNewName()

    ------------------------------------------
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = TUNING.PIG_LOYALTY_MAXTIME
    ------------------------------------------
    inst:AddComponent("health")
    inst.components.health.destroytime = 3.5 --será?
    -- inst.components.health:StartRegen(TUNING.BUNNYMAN_HEALTH_REGEN_AMOUNT, TUNING.BUNNYMAN_HEALTH_REGEN_PERIOD)

    ------------------------------------------

    inst:AddComponent("inventory")

    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLootSetupFn(LootSetupFunction)

    ------------------------------------------

    inst:AddComponent("knownlocations")
    inst:AddComponent("timer")

    ------------------------------------------

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    inst.components.trader.deleteitemonaccept = false

    inst.trading_items = deepcopy(trading_items)
    inst.TradeItem = TradeItem

    ------------------------------------------

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    ------------------------------------------

    -- inst:AddComponent("sleeper")
    -- inst.components.sleeper.watchlight = true

    ------------------------------------------
    MakeMediumFreezableCharacter(inst, "pig_torso")

    ------------------------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    ------------------------------------------

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    -- inst.components.sleeper:SetResistance(2)
    -- inst.components.sleeper.sleeptestfn = NocturnalSleepTest
    -- inst.components.sleeper.waketestfn = NocturnalWakeTest

    inst.components.combat:SetDefaultDamage(TUNING.BUNNYMAN_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.BUNNYMAN_ATTACK_PERIOD)
    inst.components.combat:SetKeepTargetFunction(NormalKeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)

    inst.components.locomotor.runspeed = 0
    inst.components.locomotor.walkspeed = 0

    -- inst.components.health:SetMaxHealth(TUNING.MERM_KING_HEALTH)
    inst.components.health:SetMaxHealth(1)

    MakeHauntablePanic(inst)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGbunnyking")

    --shadow_trap interaction
    inst.has_nightmare_state = true
    inst:ListenForEvent("ms_forcenightmarestate", OnForceNightmareState)

    inst.OnLoad = OnLoad

    ------
    inst:ListenForEvent("death", OnDeath)

    inst.AnimState:OverrideSymbol("swap_object", "swap_cane", "swap_cane")

    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")

    inst.AnimState:OverrideSymbol("swap_hat", "hat_ruins", "swap_hat")
    inst.AnimState:Show("HAT")
    inst.AnimState:Show("HAT_HAIR")
    inst.AnimState:Hide("HAIR_NOHAT")
    inst.AnimState:Hide("HAIR")
    -- 

    --chapeu
    -- inst.OnSpawned = OnSpawned

    -- local hasHat = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    -- if not hasHat then
    --     print("n tem chapeu")
    --     print(inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD))
    --     local hat = SpawnPrefab("ruinshat")
    --     print("tentando spawnar chapeu")
    --     if hat then
    --         inst.components.inventory:Equip(hat)
    --     end
    -- end

    -- local hasArmor = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    -- if not hasArmor then
    --     print("n tem armor")
    --     print(inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY))
    --     local armor = SpawnPrefab("armorwood")
    --     if armor then
    --         inst.components.inventory:Equip(armor)
    --     end
    -- end

    -- local hasWepon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    -- if not hasWepon then
    --     print("n tem arma")
    --     print(inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS))
    --     local spear = SpawnPrefab("cane")
    --     if spear then
    --         inst.components.inventory:Equip(spear)
    --     end
    -- end

    return inst
end

return Prefab("bunnyking", fn, assets, prefabs)
