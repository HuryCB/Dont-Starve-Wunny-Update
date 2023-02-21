local assets =
{
    Asset("ANIM", "anim/manrabbit_basic.zip"),
    Asset("ANIM", "anim/manrabbit_actions.zip"),
    Asset("ANIM", "anim/manrabbit_attacks.zip"),
    Asset("ANIM", "anim/shadowmanrabbit_build.zip"),
    Asset("ANIM", "anim/manrabbit_boat_jump.zip"),

    Asset("ANIM", "anim/shadowmanrabbit_build.zip"),
    -- Asset("ANIM", "anim/manrabbit_beard_basic.zip"),
    -- Asset("ANIM", "anim/manrabbit_beard_actions.zip"),
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
}

local beardlordloot = { "beardhair", "beardhair", "monstermeat" }
local forced_beardlordloot = { "nightmarefuel" }

local brain = require("brains/shadowbunnymanbrain")

local MAX_TARGET_SHARES = 5
local SHARE_TARGET_DIST = 30

local function SuggestTreeTarget(inst, data)
    local ba = inst:GetBufferedAction()
    if data ~= nil and data.tree ~= nil and (ba == nil or ba.action ~= ACTIONS.CHOP) then
        inst.tree_target = data.tree
    end
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
        inst.components.combat:SetDefaultDamage(TUNING.BUNNYMAN_DAMAGE * 100 / 100)
        inst.components.combat:SetAttackPeriod(TUNING.BUNNYMAN_ATTACK_PERIOD * 100 / 100)
    end
end

local function SetObserverdBeardLord(inst)
    inst.beardlord = true
    inst.components.combat:SetDefaultDamage(66)
    inst.components.combat:SetAttackPeriod(0.9)
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
        -- inst.AnimState:SetBuild("shadowmanrabbit_build")
        if inst.clearbeardlordtask == nil then
            inst.beardlord = nil
            inst.components.combat:SetDefaultDamage(TUNING.BUNNYMAN_DAMAGE * 100 / 100)
            inst.components.combat:SetAttackPeriod(TUNING.BUNNYMAN_ATTACK_PERIOD * 100 / 100)
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
    inst.components.combat:SetDefaultDamage(66)
    inst.components.combat:SetAttackPeriod(0.9)
    -- inst.AnimState:SetBuild("shadowmanrabbit_build")
    inst:ListenForEvent("timerdone", OnTimerDone)
end

local function OnForceNightmareState(inst, data)
    if data ~= nil and data.duration ~= nil then
        DoShadowFx(inst, true)
        SetForcedBeardLord(inst, data.duration)
    end
end

local function CalcSanityAura(inst, observer)
    -- if IsCrazyGuy(observer) then
    --     SetObserverdBeardLord(inst)
    --     return 0
    -- elseif IsForcedNightmare(inst) then
    --     return 0
    -- end
    return inst.components.follower ~= nil
        and inst.components.follower:GetLeader() == observer
        and TUNING.SANITYAURA_TINY
        or 0
end

local function ShouldAcceptItem(inst, item)
    return ( --accept all hats!
        item.components.equippable ~= nil and
        item.components.equippable.equipslot == EQUIPSLOTS.HEAD
        ) or
        ( --accept all hands!
        item.components.equippable ~= nil and
        item.components.equippable.equipslot == EQUIPSLOTS.HANDS
        ) or
        ( --accept all armors!
        item.components.equippable ~= nil and
        item.components.equippable.equipslot == EQUIPSLOTS.BODY
        ) or
        ( --accept all backs (armors)!
        item.components.equippable ~= nil and
        item.components.equippable.equipslot == EQUIPSLOTS.BACK
        ) or
        ( --accept food, but not too many carrots for loyalty!
        inst.components.eater:CanEat(item) and
        ((item.prefab ~= "carrot" and item.prefab ~= "carrot_cooked") or
        inst.components.follower.leader == nil or
        inst.components.follower:GetLoyaltyPercent() <= .9
        )
        )
end

local function OnGetItemFromPlayer(inst, giver, item)
    --I eat food
    if item.components.edible ~= nil then
        if (item.prefab == "carrot" or
            item.prefab == "carrot_cooked"
            ) and
            item.components.inventoryitem ~= nil and
            ( --make sure it didn't drop due to pockets full
            item.components.inventoryitem:GetGrandOwner() == inst or
            --could be merged into a stack
            (not item:IsValid() and
            inst.components.inventory:FindItem(function(obj)
                return obj.prefab == item.prefab
                    and obj.components.stackable ~= nil
                    and obj.components.stackable:IsStack()
            end) ~= nil)
            ) then
            if inst.components.combat:TargetIs(giver) then
                inst.components.combat:SetTarget(nil)
            elseif giver.components.leader ~= nil then
                if giver.components.minigame_participator == nil then
                    giver:PushEvent("makefriend")
                    giver.components.leader:AddFollower(inst)
                end
                inst.components.follower:AddLoyaltyTime(
                    giver:HasTag("polite")
                    and TUNING.RABBIT_CARROT_LOYALTY + TUNING.RABBIT_POLITENESS_LOYALTY_BONUS
                    or TUNING.RABBIT_CARROT_LOYALTY
                )
            end
        end
        -- if inst.components.sleeper:IsAsleep() then
        --     inst.components.sleeper:WakeUp()
        -- end
    end

    --I wear hats
    if item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current ~= nil then
            inst.components.inventory:DropItem(current)
        end
        inst.components.inventory:Equip(item)
        inst.AnimState:Show("hat")
    end
    --I wear weapons
    if item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HANDS then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if current ~= nil then
            inst.components.inventory:DropItem(current)
        end
        inst.components.inventory:Equip(item)
        -- inst.AnimState:Show("hat")
    end

    --I wear armors
    if item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.BODY then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
        if current ~= nil then
            inst.components.inventory:DropItem(current)
        end
        inst.components.inventory:Equip(item)
        -- inst.AnimState:Show("hat")
        return
    end

    --I wear back (armors)
    if item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.BACK then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BACK)
        if current ~= nil then
            inst.components.inventory:DropItem(current)
        end
        print("tentou equipar o item")
        inst.components.inventory:Equip(item)
        -- inst.AnimState:Show("hat")
    end
end

local function OnRefuseItem(inst, item)
    inst.sg:GoToState("refuse")
    -- if inst.components.sleeper:IsAsleep() then
    --     inst.components.sleeper:WakeUp()
    -- end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST,
        function(dude) return dude.prefab == inst.prefab end, MAX_TARGET_SHARES)
end

local function OnNewTarget(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST,
        function(dude) return dude.prefab == inst.prefab end, MAX_TARGET_SHARES)
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
                return inst.components.combat:CanTarget(guy)
                    and
                    (
                    -- guy:HasTag("monster")--talvez tirando isso para de atacar spider
                    -- or
                    guy:HasTag("wonkey")
                    or guy:HasTag("pirate")
                    or guy:HasTag("shadowcreature")
                    -- or (guy.components.inventory ~= nil and
                    --     guy:IsNear(inst, TUNING.BUNNYMAN_SEE_MEAT_DIST) and
                    --     guy.components.inventory:FindItem(is_meat) ~= nil)
                    -- or guy:HasTag("shadowcreature")
                    )
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
    -- local guy = lootdropper.inst.causeofdeath
    -- if IsForcedNightmare(lootdropper.inst) then
    --     -- forced beard lord
    --     lootdropper:SetLoot(forced_beardlordloot)
    -- elseif IsCrazyGuy(guy ~= nil and guy.components.follower ~= nil and guy.components.follower.leader or guy) then
    -- beard lord
    lootdropper:SetLoot(forced_beardlordloot)
    -- else
    --     -- regular loot
    --     lootdropper:AddRandomLoot("carrot", 3)
    --     lootdropper:AddRandomLoot("meat", 3)
    --     lootdropper:AddRandomLoot("manrabbit_tail", 2)
    --     lootdropper.numrandomloot = 1
    -- end
end

local function OnLoad(inst)
    if IsForcedNightmare(inst) then
        SetForcedBeardLord(inst, nil)
    end
end

local function SleepTest()
    return false
end

function StandardWakeChecks(inst)
    return (inst.components.combat ~= nil and inst.components.combat.target ~= nil)
        or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning())
        or (inst.components.freezable ~= nil and inst.components.freezable:IsFrozen())
        or (inst.components.teamattacker ~= nil and inst.components.teamattacker.inteam)
        or (inst.components.health ~= nil and inst.components.health.takingfiredamage)
end

local CAMPFIRE_TAGS = { "campfire", "fire" }
local function NormalShouldSleep(inst)
    return DefaultSleepTest(inst)
        and (inst.components.follower == nil or inst.components.follower.leader == nil
        or (FindEntity(inst, 6, nil, CAMPFIRE_TAGS) ~= nil and inst:IsInLight()))
end

function DefaultSleepTest(inst)
    local watchlight = inst.LightWatcher ~= nil or (inst.components.sleeper and inst.components.sleeper.watchlight)
    return StandardSleepChecks(inst)
        -- sleep in the overworld at night
        and (not TheWorld:HasTag("cave") and TheWorld.state.isnight
        -- in caves, sleep at night if we have a lightwatcher and are in the dark
        or (TheWorld:HasTag("cave") and TheWorld.state.iscavenight and (not watchlight or not inst:IsInLight())))
end

local function ShouldSleep(inst)
    return
    -- local sleeper = inst.components.sleeper
    -- if sleeper == nil then
    --     return
    -- end
    -- sleeper.lasttesttime = GetTime()
    -- if sleeper.sleeptestfn ~= nil and sleeper.sleeptestfn(inst) then
    --     sleeper:GoToSleep()
    -- end
end

function DefaultWakeTest(inst)
    local watchlight = inst.LightWatcher ~= nil or (inst.components.sleeper and inst.components.sleeper.watchlight)

    return StandardWakeChecks(inst)
        -- wake when it's not night
        or (not TheWorld:HasTag("cave") and not TheWorld.state.isnight)
        -- in caves, wake if it's not night and we've got a light shining on us
        or (TheWorld:HasTag("cave") and not TheWorld.state.iscavenight and (not watchlight or inst:IsInLight()))
end

local function OnKill(inst, data)
    local victim = data.victim
    print("on kill do shadow")
    if victim and victim:HasTag("shadow") then
        print("caiu if 1")
        print(inst._playerlink)
        print(victim.sanityreward)
        print(inst)
        if victim.sanityreward ~= nil then
            if inst._playerlink ~= nil then
                print("caiu if 2")
                print("sanityreward", victim.sanityreward)
                -- local sanityGain = victim.sanityreward / SANITY_REWARD
                -- if (sanityGain <= 0) then
                    inst._playerlink.components.sanity:DoDelta(victim.sanityreward)
                -- else
                --     inst._playerlink.components.sanity:DoDelta(victim.sanityreward / SANITY_REWARD)
                -- end
            elseif inst.components.follower ~= nil then
                inst.components.follower:GetLeader().components.sanity:DoDelta(victim.sanityreward)
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("shadowmanrabbit_build")

    -- MakeCharacterPhysics(inst, 50, .5)
    MakeCharacterPhysics(inst, 75, .75)

    -- inst.DynamicShadow:SetSize(1.5, .75)
    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()
    -- inst.Transform:SetScale(1.25, 1.25, 1.25)
    inst.Transform:SetScale(1.3, 1.3, 1.3)
    -- inst.Transform:SetScale(1.56, 1.56, 1.56)
    -- inst.Transform:SetScale(2.5, 2.5, 2.5)
    -- inst.Transform:SetScale(2, 2, 2)

    inst:AddTag("cavedweller")
    inst:AddTag("character")
    inst:AddTag("crazy")

    -- inst:AddTag("crazy")
    -- inst:AddTag("pig")
    -- inst:AddTag("manrabbit")
    inst:AddTag("notraptrigger")
    -- inst:AddTag("scarytoprey")

    inst.AnimState:SetBank("manrabbit")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:Hide("hat")
    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAIR_HAT")

    inst.AnimState:SetClientsideBuildOverride("insane", "shadowmanrabbit_build", "shadowmanrabbit_build")

    --trader (from trader component) added to pristine state for optimization
    inst:AddTag("trader")

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 24
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -500, 0)
    inst.components.talker:MakeChatter()
    MakeFeedableSmallLivestockPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst.components.talker.ontalk = ontalk

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.PIG_RUN_SPEED *
        2.2 -- account for them being stopped for part of their anim
    inst.components.locomotor.walkspeed = TUNING.PIG_WALK_SPEED *
        1.9 -- account for them being stopped for part of their anim

    -- boat hopping setup
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst:AddComponent("embarker")
    inst:AddComponent("drownable")

    inst:AddComponent("bloomer")

    ------------------------------------------
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })
    inst.components.eater:SetCanEatRaw()

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
    inst.components.health:StartRegen(TUNING.BUNNYMAN_HEALTH_REGEN_AMOUNT, TUNING.BUNNYMAN_HEALTH_REGEN_PERIOD)

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

    ------------------------------------------

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    ------------------------------------------

    -- inst:AddComponent("sleeper")
    -- inst.components.sleeper.watchlight = false
    -- inst.components.sleeper:SetSleepTest(ShouldSleep)
    -- inst.components.sleeper:SetWakeTest(DefaultWakeTest)

    ------------------------------------------
    MakeMediumFreezableCharacter(inst, "pig_torso")

    ------------------------------------------

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    ------------------------------------------

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewTarget)

    inst:ListenForEvent("suggest_tree_target", SuggestTreeTarget)

    -- inst.components.sleeper:SetResistance(2)
    -- inst.components.sleeper.sleeptestfn = NormalShouldSleep
    -- inst.components.sleeper.waketestfn = DefaultWakeTest

    inst.components.combat:SetDefaultDamage(TUNING.BUNNYMAN_DAMAGE * 100 / 100)
    inst.components.combat:SetAttackPeriod(TUNING.BUNNYMAN_ATTACK_PERIOD * 100 / 100)
    inst.components.combat:SetKeepTargetFunction(NormalKeepTargetFn)
    inst.components.combat:SetRetargetFunction(3, NormalRetargetFn)

    inst.components.locomotor.runspeed = TUNING.BUNNYMAN_RUN_SPEED * 120 / 100
    inst.components.locomotor.walkspeed = TUNING.BUNNYMAN_WALK_SPEED * 120 / 100

    inst.components.health:SetMaxHealth(TUNING.BUNNYMAN_HEALTH * 100 / 100)

    MakeHauntablePanic(inst)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGbunnyman")

    --shadow_trap interaction
    inst.has_nightmare_state = true
    inst:ListenForEvent("ms_forcenightmarestate", OnForceNightmareState)

    inst:ListenForEvent("killed", OnKill)

    inst.OnLoad = OnLoad

    --remover isto
    -- inst:AddComponent("inventoryitem")
    -- inst.components.inventoryitem.nobounce = true
    -- inst.components.inventoryitem.canbepickedup = true
    -- inst.components.inventoryitem.canbepickedupalive = true
    -- inst.components.inventoryitem:SetSinks(true)
    -- inst.components.inventoryitem.imagename = "bunny"
    -- inst.components.inventoryitem.atlasname = "images/inventoryimages/bunny.xml"
    -- MakeFeedableSmallLivestock(inst, TUNING.RABBIT_PERISH_TIME, nil, nil)

    -- --até aqui


    return inst
end

return Prefab("shadowbunnyman", fn, assets, prefabs)
