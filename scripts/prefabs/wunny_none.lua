local assets =
{
	Asset( "ANIM", "anim/wunny.zip" ),
	Asset( "ANIM", "anim/wunny_beardlord.zip" ),
	Asset( "ANIM", "anim/ghost_wunny_build.zip" ),
}

local skins =
{
	normal_skin = "wunny",
	beardlord_skin="wunny_beardlord",
	ghost_skin = "ghost_wunny_build",
}

-- local buildslist = { 
-- 	"wunny",
-- 	"wunny_beardlord",
-- }

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