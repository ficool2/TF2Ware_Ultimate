special_round <- Ware_SpecialRoundData
({
	name        = "Silent Hill"
	author      = "ficool2"
	description = "The fog is coming."
})

fog         <- null
skybox_name <- ""
sky3d_area  <- 255

function UpdateFog()
{
	foreach (player in Ware_Players)
	{
		SetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl", fog)		
		SetPropInt(player, "m_Local.m_skybox3d.area", 255)
	}
}

function OnStart()
{
	fog = SpawnEntityFromTableSafe("env_fog_controller",
	{
		fogenable     = true
		fogcolor      = "200 200 200"
		fogstart      = -200.0
		fogend        = 500.0
		fogmaxdensity = 1
		fogRadial     = true
	})
	
	local sky_camera = FindByClassname(null, "sky_camera")
	if (sky_camera)
		sky3d_area = GetPropInt(sky_camera, "m_skyboxData.area")
	
	UpdateFog()
	
	skybox_name = Convars.GetStr("sv_skyname")
	SetSkyboxTexture("white_sky")
}

function OnMinigameEnd()
{
	UpdateFog()
}

function OnEnd()
{
	foreach (player in Ware_Players)
	{
		SetPropInt(player, "m_Local.m_skybox3d.area", sky3d_area)
	}

	SetSkyboxTexture(skybox_name)
	fog.Kill()
}