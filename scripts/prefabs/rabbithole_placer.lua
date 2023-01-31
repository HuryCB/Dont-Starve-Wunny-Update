local assets =
{
    Asset("ANIM", "anim/rabbithole.zip"),
    -- Asset("ANIM", "anim/rabbitnest.zip"),
	Asset("ATLAS", "images/inventoryimages/rabbitnest.xml"),
	Asset("IMAGE", "images/inventoryimages/rabbitnest.tex"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("rabbitnest")
    inst.AnimState:SetBuild("rabbitnest")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/rabbitnest.xml"
    return inst
end

return 
Prefab("common/objects/rabbitnest", fn, assets),
    -- MakePlacer("rabbithole_placer", "rabbithouse", "rabbit_house", "idle", nil, nil, nil, 0.2)
    MakePlacer("rabbit_placer", "rabbithole", "rabbit_hole", "idle")