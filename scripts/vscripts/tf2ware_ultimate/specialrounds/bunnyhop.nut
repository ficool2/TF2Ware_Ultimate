special_round <- Ware_SpecialRoundData
({
	name = "Bunnyhop"
	author = "ficool2"
	description = "Hold space to bunny hop!"
	categories = []
	convars =
	{
		sv_airaccelerate = 100.0
	}
})

local gravity = 800.0

function BunnyhopInit(player)
{
	local data = Ware_GetPlayerSpecialRoundData(player)
	data.self <- player
	data.on_ground <- player.GetFlags() & FL_ONGROUND

	player.GetScriptScope().BunnyhopThink <- BunnyhopThink.bindenv(data)
	AddThinkToEnt(player, "BunnyhopThink")
}

function BunnyhopThink()
{
	local was_on_ground = on_ground
	on_ground = self.GetFlags() & FL_ONGROUND
	if (!was_on_ground && on_ground && (GetPropInt(self, "m_nButtons") & IN_JUMP))
	{
		local velocity = self.GetAbsVelocity()
		velocity.z = 289.0 - ((gravity * FrameTime()) * 0.5)
		self.SetAbsVelocity(velocity)
	}
	return -1
}

function OnPlayerSpawn(player)
{
	BunnyhopInit(player)
}

function OnStart()
{
	foreach (player in Ware_Players)
		BunnyhopInit(player)
}

function OnEnd()
{
	foreach (player in Ware_Players)
		AddThinkToEnt(player, null)
}

function OnUpdate()
{
	gravity = Convars.GetFloat("sv_gravity")
}