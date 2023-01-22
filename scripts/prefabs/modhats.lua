-- local function MakeHat(name, fn, custom_init, prefabs)
--   local fname = "hat_"..name
--   local symname = name.."hat"
--   local prefabname = symname

--   local function onequip(inst, owner, symbol_override)
--     local skin_build = inst:GetSkinBuild()
--     if skin_build ~= nil then
--       owner:PushEvent("equipskinneditem", inst:GetSkinName())
--       owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, symbol_override or "swap_hat", inst.GUID, fname)
--     else
--       owner.AnimState:OverrideSymbol("swap_hat", fname, symbol_override or "swap_hat")
--     end
--     owner.AnimState:Show("HAT")
--     owner.AnimState:Show("HAIR_HAT")
--     owner.AnimState:Hide("HAIR_NOHAT")
--     owner.AnimState:Hide("HAIR")

--     if owner:HasTag("player") then
--       owner.AnimState:Hide("HEAD")
--       owner.AnimState:Show("HEAD_HAT")
--     end

--     if inst.components.fueled ~= nil then
--       inst.components.fueled:StartConsuming()
--     end
--   end

--   local function onunequip(inst, owner)
--     local skin_build = inst:GetSkinBuild()
--     if skin_build ~= nil then
--       owner:PushEvent("unequipskinneditem", inst:GetSkinName())
--     end

--     owner.AnimState:ClearOverrideSymbol("swap_hat")
--     owner.AnimState:Hide("HAT")
--     owner.AnimState:Hide("HAIR_HAT")
--     owner.AnimState:Show("HAIR_NOHAT")
--     owner.AnimState:Show("HAIR")

--     if owner:HasTag("player") then
--       owner.AnimState:Show("HEAD")
--       owner.AnimState:Hide("HEAD_HAT")
--     end

--     if inst.components.fueled ~= nil then
--       inst.components.fueled:StopConsuming()
--     end
--   end

--   local imageAtlas = "images/"..symname..".xml"

--   local function simple(custom_init)
--     local inst = CreateEntity()

--     inst.entity:AddTransform()
--     inst.entity:AddAnimState()
--     inst.entity:AddNetwork()

--     MakeInventoryPhysics(inst)

--     inst.AnimState:SetBank(symname)
--     inst.AnimState:SetBuild(fname)
--     inst.AnimState:PlayAnimation("anim")

--     inst:AddTag("hat")
--     inst:AddTag(name)

--     if custom_init ~= nil then
--       custom_init(inst)
--     end

--     local tagAlias = "_hat"
--     inst:AddTag(tagAlias)
--     inst.entity:SetPristine()
--     if not TheWorld.ismastersim then
--       return inst
--     end
--     inst:RemoveTag(tagAlias)

--     inst:AddComponent("inventoryitem")
--     inst.components.inventoryitem.atlasname = imageAtlas

--     inst:AddComponent("inspectable")

--     inst:AddComponent("tradable")

--     inst:AddComponent("equippable")
--     inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
--     inst.components.equippable:SetOnEquip(onequip)
--     inst.components.equippable:SetOnUnequip(onunequip)

--     MakeHauntableLaunch(inst)

--     return inst
--   end

--   local function default()
--     return simple()
--   end

--   local assets =
--   {
--     Asset("ANIM", "anim/"..fname..".zip"),
--     Asset("ATLAS", imageAtlas),
--   }

--   return Prefab(prefabname, fn and function(Sim)
--     return fn(simple(custom_init or nil))
--   end or default, assets, prefabs or nil)
-- end

-- return MakeHat("pigcrown", function(inst)
--   if TheWorld.ismastersim then
--     if TUNING.DAPPERNESS_PIGCROWNHAT then
--       inst.components.equippable.dapperness = TUNING.DAPPERNESS_PIGCROWNHAT
--     end
--   end
--   return inst
-- end)
