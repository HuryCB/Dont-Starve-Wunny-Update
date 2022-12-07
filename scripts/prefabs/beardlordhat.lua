local assets =
{ 
    Asset("ANIM", "anim/beardlordhat.zip"),
    Asset("ANIM", "anim/birchnuthat_swap.zip"), 

    Asset("ATLAS", "images/inventoryimages/birchnuthat.xml"),
    Asset("IMAGE", "images/inventoryimages/birchnuthat.tex"),
}

local prefabs = 
{
}
--
local function procfn(inst, data)
	if data.attacker ~= nil then
		local dtatk = data.attacker
		if dtatk and dtatk.components.health and dtatk.components.combat then
			dtatk.components.combat:GetAttacked(inst, 6) -- Damage done to attacker		
		end
	end -- IT SHOULD WORK NOW.
end
--


local function OnEquip(inst, owner, data) 
    owner.AnimState:OverrideSymbol("swap_hat", "beardlordhat", "swap_hat")
	
    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAT_HAIR")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")
    -- owner.components.hunger:SetRate();
    -- owner.components.
    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        if TheSim:GetGameID()=="DST" then
			owner.AnimState:Show("HEAD_HAT")
		else
			owner.AnimState:Show("HEAD_HAIR")
		end
	end

	--
	-- inst.tryproc = function(inst, data) procfn(inst,data) end 
    -- owner:ListenForEvent("attacked", inst.tryproc)
	
	--
	end


local function OnUnequip(inst, owner, data) 

    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAT_HAIR")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        if TheSim:GetGameID()=="DST" then
			owner.AnimState:Hide("HEAD_HAT")
		else
			owner.AnimState:Hide("HEAD_HAIR")
		end
    end
	--
	-- owner:RemoveEventCallback("attacked", inst.tryproc)
	--
end

local function fn()

    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("beardlordhat")
    inst.AnimState:SetBuild("beardlordhat")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("hat")

	if TheSim:GetGameID()=="DST" then
		inst.entity:AddNetwork()
		
		if not TheWorld.ismastersim then
			return inst
		end
		
		inst.entity:SetPristine()
		
	    MakeHauntableLaunch(inst)
	end
	
	inst:AddComponent("armor")
	inst.components.armor:InitCondition(550, 0.85)
	
    inst:AddComponent("inspectable")

    inst:AddComponent("tradable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "birchnuthat"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/birchnuthat.xml"
    
	
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable.dapperness = -TUNING.DAPPERNESS_TINY
	-- inst.components.equippable.walkspeedmult = 1.6
    inst.components.equippable:SetOnUnequip(OnUnequip)
	
	--if TheSim:GetGameID()=="DST" or IsDLCEnabled(REIGN_OF_GIANTS) then
		-- inst:AddComponent("waterproofer")
		-- inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
	--end

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

    return inst
end


return  Prefab("common/inventory/beardlordhat", fn, assets, prefabs)