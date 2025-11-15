
special_round <- Ware_SpecialRoundData
({
	name = "Adrenaline Shot"
	author = ["Gemidyne", "pokemonPasta"]
	description = "The round starts fast, then slows down."
	categories = ["timescale"]
})

local interval = Ware_SpeedUpInterval * 1.5

function OnPrecache()
{
	PrecacheOverlay("hud/tf2ware_ultimate/slow_down")
}

function OnStart()
{
	local high_scale = (Ware_BossThreshold / Ware_SpeedUpThreshold) * interval
	Ware_SetTimeScale(1.0 + high_scale)
}

function OnSpeedup()
{
	Ware_SetTimeScale(Ware_GetTimeScale() - interval)
	
	EntityEntFire(Ware_SkyboxParticles.slowdown, "Start")
	
	Ware_PlayGameSound(null, "speedup")
	foreach (player in Ware_Players)
	{
		Ware_ShowScreenOverlay(player, "hud/tf2ware_ultimate/slow_down")
		Ware_ShowScreenOverlay2(player, null)
	}

	CreateTimer(@() Ware_BeginIntermission(false), Ware_GetThemeSoundDuration("speedup"))
	return true
}
