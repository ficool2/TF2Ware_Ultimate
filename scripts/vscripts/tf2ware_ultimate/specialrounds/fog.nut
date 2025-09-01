special_round <- Ware_SpecialRoundData
({
	name             = "Bad weather"
	author           = "tilderain"
	description      = "Can't see shit in 2fort!"
	category         = ""
})
fog <- null
sky_fog <- null
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
		fogmaxdensity = 0.9966,
		fogRadial = true,
		fogblend = true,

	})
	CreateTimer(function()
	{
		foreach (player in Ware_Players)
		{
			SetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl", fog)
			//I'm gonna assume there's no way to change the viewmodel lighting
			KillViewModel(player)
		}
	}, 0.3)
	
	sky_name = Convars.GetStr("sv_skyname")
	SetSkyboxTexture("sky_borealis01")

	sky_fog = SpawnEntityFromTableSafe("sky_camera",
	{
		fogenable = true,
		fogcolor = "0 0 0",
		fogcolor2 = "0 0 0",
		fogstart = 0,
		fogend = 1,
		fogmaxdensity = 0.9966,
		fogRadial = true,
		fogblend = true,
		origin = Vector(6909, -1374, 1632),
		scale = 8
	})
}

function OnPlayerSpawn(player)
{
	SetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl", fog)
	KillViewModel(player)
}
function OnEnd()
{
	SetSkyboxTexture(sky_name)
	sky_fog.Kill()
}