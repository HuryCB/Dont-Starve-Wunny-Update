require "behaviours/wander"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
--require "behaviours/choptree"
require "behaviours/findlight"
require "behaviours/panic"
require "behaviours/chattynode"
require "behaviours/leash"

local BrainCommon = require("brains/braincommon")

local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 5
local MAX_FOLLOW_DIST = 9
local MAX_WANDER_DIST = 20

local LEASH_RETURN_DIST = 10
local LEASH_MAX_DIST = 30

local START_FACE_DIST = 6
local KEEP_FACE_DIST = 8
local START_RUN_DIST = 3
local STOP_RUN_DIST = 30
local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30
local SEE_LIGHT_DIST = 20
local TRADE_DIST = 20
local SEE_TREE_DIST = 15
local SEE_TARGET_DIST = 20
local SEE_FOOD_DIST = 10

local SEE_BURNING_HOME_DIST_SQ = 20 * 20

local KEEP_CHOPPING_DIST = 10

local RUN_AWAY_DIST = 5
local STOP_RUN_AWAY_DIST = 8
local SEE_PLAYER_DIST = 6

local GETTRADER_MUST_TAGS = { "player" }
local FINDFOOD_CANT_TAGS = { "outofreach" }

local CHOP_MUST_TAGS = { "CHOP_workable" }

-- local function IsDeciduousTreeMonster(guy)
--     return guy.monster and guy.prefab == "deciduoustree"
-- end

-- local function FindDeciduousTreeMonster(inst)
--     return FindEntity(inst, SEE_TREE_DIST / 3, IsDeciduousTreeMonster, CHOP_MUST_TAGS)
-- end

local function KeepChoppingAction(inst)
    return inst.tree_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst:IsNear(inst.components.follower.leader, KEEP_CHOPPING_DIST))
end

local function StartChoppingCondition(inst)
    return inst.tree_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst.components.follower.leader.sg ~= nil and
            inst.components.follower.leader.sg:HasStateTag("chopping"))
end

local function FindTreeToChopAction(inst)
    local target = FindEntity(inst, SEE_TREE_DIST, nil, CHOP_MUST_TAGS)
    if target ~= nil then
        if inst.tree_target ~= nil then
            target = inst.tree_target
            inst.tree_target = nil
        end
        return BufferedAction(inst, target, ACTIONS.CHOP)
    end
end

function FindEntity(inst, radius, fn, musttags, canttags, mustoneoftags)
    if inst ~= nil and inst:IsValid() then
        local x, y, z = inst.Transform:GetWorldPosition()
        --print("FIND", inst, radius, musttags and #musttags or 0, canttags and #canttags or 0, mustoneoftags and #mustoneoftags or 0)
        local ents = TheSim:FindEntities(x, y, z, radius, musttags, canttags, mustoneoftags) -- or we could include a flag to the search?
        for i, v in ipairs(ents) do
            if v ~= inst and v.entity:IsVisible() and (fn == nil or fn(v, inst)) then
                return v
            end
        end
    end
end

------MINING-----

local function KeepMiningAction(inst)
    return inst.tree_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst:IsNear(inst.components.follower.leader, KEEP_CHOPPING_DIST))
end

local function StartMiningCondition(inst)
    return inst.tree_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst.components.follower.leader.sg ~= nil and
            inst.components.follower.leader.sg:HasStateTag("mining"))
end

local function FindRockToMineAction(inst)
    local target = FindEntity(inst, SEE_TREE_DIST, nil, { "MINE_workable" })
    if target ~= nil then
        if inst.tree_target ~= nil then
            target = inst.tree_target
            inst.tree_target = nil
        end
        return BufferedAction(inst, target, ACTIONS.MINE)
    end
end

------END MINING-----

local function GetTraderFn(inst)
    return FindEntity(inst, TRADE_DIST, function(target) return inst.components.trader:IsTryingToTradeWithMe(target) end
        , GETTRADER_MUST_TAGS)
end

local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
end

local function FindFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    local target =
    inst.components.inventory ~= nil and
        inst.components.eater ~= nil and
        inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end) or
        nil

    if target == nil then
        local time_since_eat = inst.components.eater:TimeSinceLastEating()
        if time_since_eat == nil or time_since_eat > TUNING.PIG_MIN_POOP_PERIOD * 2 then
            local noveggie = time_since_eat ~= nil and time_since_eat < TUNING.PIG_MIN_POOP_PERIOD * 4
            target = FindEntity(inst,
                SEE_FOOD_DIST,
                function(item)
                    return item:GetTimeAlive() >= 8
                        and item.prefab ~= "mandrake"
                        and item.components.edible ~= nil
                        and (not noveggie or item.components.edible.foodtype == FOODTYPE.MEAT)
                        and inst.components.eater:CanEat(item)
                        and item:IsOnPassablePoint()
                end,
                nil,
                FINDFOOD_CANT_TAGS
            )
        end
    end

    return target ~= nil and BufferedAction(inst, target, ACTIONS.EAT) or nil
end

local function HasValidHome(inst)
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
    return home ~= nil
        and home:IsValid()
        and not (home.components.burnable ~= nil and home.components.burnable:IsBurning())
        and not home:HasTag("burnt")
end

local function GoHomeAction(inst)
    if
        HasValidHome(inst) and
        not inst.components.combat.target then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

local function IsHomeOnFire(inst)
    return inst.components.homeseeker
        and inst.components.homeseeker.home
        and inst.components.homeseeker.home.components.burnable
        and inst.components.homeseeker.home.components.burnable:IsBurning()
        and inst:GetDistanceSqToInst(inst.components.homeseeker.home) < SEE_BURNING_HOME_DIST_SQ
end

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetHomePos(inst)
    return HasValidHome(inst) and inst.components.homeseeker:GetHomePos()
end

local function GetNoLeaderHomePos(inst)
    if GetLeader(inst) then
        return nil
    end
    return GetHomePos(inst)
end

local UltraBunnymanBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function UltraBunnymanBrain:OnStart()
    --print(self.inst, "PigBrain:OnStart")
    local root =
    PriorityNode(
        {
            BrainCommon.PanicWhenScared(self.inst, .25, "RABBIT_PANICBOSS"),
            BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "CHOP", -- Required.
                chatterstring = "MERM_TALK_HELP_CHOP_WOOD",
            }),
            BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "MINE", -- Required.
                chatterstring = "MERM_TALK_HELP_MINE_ROCK",
            }),
            IfThenDoWhileNode(function() return StartChoppingCondition(self.inst) end,
                function() return KeepChoppingAction(self.inst) end, "chop",
                LoopNode {
                    ChattyNode(self.inst, "PIG_TALK_HELP_CHOP_WOOD",
                        DoAction(self.inst, FindTreeToChopAction))
                }),
            IfThenDoWhileNode(function() return StartMiningCondition(self.inst) end,
                function() return KeepMiningAction(self.inst) end, "MINE",
                LoopNode {
                    ChattyNode(self.inst, "PIG_TALK_HELP_MINE_ROCK",
                        DoAction(self.inst, FindRockToMineAction))
                }),
            WhileNode(function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end,
                "PanicHaunted",
                ChattyNode(self.inst, "RABBIT_PANICHAUNT",
                    Panic(self.inst))),
            WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire",
                ChattyNode(self.inst, "RABBIT_PANICFIRE",
                    Panic(self.inst))),
            WhileNode(function() return self.inst.components.health:GetPercent() < TUNING.BUNNYMAN_PANIC_THRESH end,
                "LowHealth",
                ChattyNode(self.inst, "RABBIT_RETREAT",
                    RunAway(self.inst, "scarytoprey", SEE_PLAYER_DIST, STOP_RUN_DIST))),
            ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
            WhileNode(function() return IsHomeOnFire(self.inst) end, "OnFire",
                ChattyNode(self.inst, "RABBIT_PANICHOUSEFIRE",
                    Panic(self.inst))),
            FaceEntity(self.inst, GetTraderFn, KeepTraderFn),
            DoAction(self.inst, FindFoodAction),
            Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
            -- WhileNode(function() return not self.inst.beardlord and TheWorld.state.iscaveday end, "IsDay",
            --     DoAction(self.inst, GoHomeAction, "go home", true), 1),
            Leash(self.inst, GetNoLeaderHomePos, LEASH_MAX_DIST, LEASH_RETURN_DIST),
            Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST),

        }, .5)

    self.bt = BT(self.inst, root)
end

return UltraBunnymanBrain
