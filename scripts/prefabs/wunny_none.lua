local assets =
{
	Asset( "ANIM", "anim/wunny.zip" ),
	Asset( "ANIM", "anim/ghost_wunny_build.zip" ),
}

local skins =
{
	normal_skin = "wunny",
	ghost_skin = "ghost_wunny_build",
}

return CreatePrefabSkin("wunny_none",
{
	base_prefab = "wunny",
	type = "base",
	assets = assets,
	skins = skins, 
	skin_tags = {"WUNNY", "CHARACTER", "BASE"},
	build_name_override = "wunny",
	rarity = "Character",
})