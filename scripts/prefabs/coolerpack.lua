local assets =
{
	
	Asset("ANIM", "anim/swap_coolerpack.zip"),
	
	Asset("ATLAS", "images/inventoryimages/coolerpack.xml"),
    Asset("IMAGE", "images/inventoryimages/coolerpack.tex"),
}
prefabs = {
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "swap_coolerpack", "coolerpack")
    owner.AnimState:OverrideSymbol("swap_body", "swap_coolerpack", "swap_body")
    
    if owner.components.hunger ~= nil then
        owner.components.hunger.burnratemodifiers:SetModifier(inst, TUNING.BUNNYPACK_HUNGER)
        -- owner.components.hunger:DoDelta(-5)
    end

    inst.components.container:Open(owner)
    
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("coolerpack")

    if owner.components.hunger ~= nil then
        owner.components.hunger.burnratemodifiers:RemoveModifier(inst)
    end

    inst.components.container:Close(owner)
end

local function fn()
	local inst = CreateEntity()
	    
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("coolerpack1")
    inst.AnimState:SetBuild("swap_coolerpack")
    inst.AnimState:PlayAnimation("anim")
	
    inst.MiniMapEntity:SetIcon("piggyback.png")
    
    inst.foleysound = "dontstarve/movement/foley/backpack"
	
	-- inst:AddTag("fridge")

    inst:AddTag("backpack")

    MakeInventoryFloatable(inst, "small", 0.1, 0.85)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
	inst.components.inventoryitem.atlasname = "images/inventoryimages/coolerpack.xml"
    inst.components.inventoryitem.imagename = "coolerpack"

    inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst.components.equippable:SetOnEquip(onequip)
    -- inst.components.equippable.dapperness = -TUNING.DAPPERNESS_TINY
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("coolerpack")
    -- inst.components.container:WidgetSetup("krampus_sack")

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("common/inventory/coolerpack", fn, assets)