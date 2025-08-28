special_round <- Ware_SpecialRoundData
({
	name             = "Bad weather"
	author           = "tilderain"
	description      = "Can't see shit in 2fort!"
	category         = ""
})
fog <- null
sky_name <- ""

function KillViewModel(player)
{
	local viewmodel = GetPropEntityArray(player, "m_hViewModel", 0)
	if (viewmodel)
	{
		MarkForPurge(viewmodel)
		viewmodel.Kill()
	}
}
function OnStart()
{
	fog = SpawnEntityFromTableSafe("env_fog_controller",
	{
		fogenable = true,
		fogcolor = "0 0 0",
		fogcolor2 = "0 0 0",
		fogstart = 0,
		fogend = 1,
		fogmaxdensity = 0.9975,
		fogRadial = true,
	})
	
	foreach (player in Ware_MinigamePlayers)
	{
		SetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl", fog)
		//I'm gonna assume there's no way to change the viewmodel lighting
		KillViewModel(player)
	}
	SetSkyboxTexture("sky_borealis01")

	for (local prop; prop = FindByClassname(prop, "prop_dynamic");)
		prop.Kill()
	//can't kill the planet or mountains :(
		
}

function OnPlayerSpawn(player)
{
	SetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl", fog)
	KillViewModel(player)
}
function OnEnd()
{
	SetSkyboxTexture(sky_name)
}