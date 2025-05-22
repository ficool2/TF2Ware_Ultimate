minigame <- Ware_MinigameData
({
	name           = "We are in the beam"
	author         = "tilderain"
	description    = "We are in the beam"
	duration       = 10
	location       = "dirtsquare"
	music          = "mystery"
})

ufo <- null

beam_sound <- "tf2ware_ultimate/temp_inbeam_own.mp3"

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT)
    CreateUFO()
}

xRange <- [-750, 750]
yRange <- [-750, 750]

find_sound <- "MatchMaking.MedalClickRare"


function OnUpdate() 
{
    local minigameLocation = Ware_MinigameLocation.center
    local margin = 0.1


    local vel = ufo.GetAbsVelocity()
    local pos = ufo.GetOrigin()

    if (pos.x - minigameLocation.x > xRange[1]) 
	{
        vel.x = -abs(vel.x)
		//ufo.KeyValueFromVector("origin", Vector(minigameLocation.x + xRange[1] - margin, pos.y, pos.z))
    }
	else if (pos.x - minigameLocation.x < xRange[0]) 
	{
        vel.x = abs(vel.x)
		//ufo.KeyValueFromVector("origin", Vector(minigameLocation.x + xRange[0] + margin, pos.y, pos.z))
    }

    if (pos.y - minigameLocation.y > yRange[1]) 
	{
        vel.y = -abs(vel.y)
		//ufo.KeyValueFromVector("origin", Vector(pos.x, pos.y, minigameLocation.y + yRange[1] - margin))
    }
	else if (pos.y - minigameLocation.y < yRange[0]) 
	{
        vel.y = abs(vel.y)
		//ufo.KeyValueFromVector("origin", Vector(pos.x, pos.y, minigameLocation.y + yRange[0] + margin))
    }

    ufo.SetAbsVelocity(vel)
    
}

function OnPrecache()
{
	PrecacheParticle("alien_abduction2")
	PrecacheParticle("flamethrower")
    PrecacheSound(beam_sound)
    PrecacheScriptSound(find_sound)
}

function OnCorrectTouch()
{
    local player = activator
	
	if (player.IsPlayer() && player.IsValid())
	{
        local minidata = Ware_GetPlayerMiniData(player)
        if(!("beamsound" in minidata))
        {
            minidata.beamsound <- true
            Ware_PlaySoundOnClient(player, Ware_MinigameScope.beam_sound, 0.25)
        }
        player.AddCond(TF_COND_SWIMMING_CURSE)
	}
}
function OnTriggerEndTouch()
{
    local player = activator
	
	if (player.IsPlayer() && player.IsValid())
	{
        player.RemoveCond(TF_COND_SWIMMING_CURSE)
        player.RemoveCond(TF_COND_URINE)
	}
}

function OnEnd()
{
	foreach (player in Ware_MinigamePlayers)
	{
		player.RemoveCond(TF_COND_SWIMMING_CURSE)
		player.RemoveCond(TF_COND_URINE)
	}
}

function OnEnterUFO()
{
	local player = activator
	if (player)
	{
		Ware_TeleportPlayer(player, Ware_Location.beach.center, ang_zero, vec3_zero)
		Ware_ShowScreenOverlay(player, null)
		Ware_CreateTimer(function()
		{
			if (player)
			{
				player.EmitSound(Ware_MinigameScope.find_sound)
				Ware_PassPlayer(player, true)
				Ware_StripPlayer(player, true)
			}
		}, 0.1)
	}
}


function CreateUFO()
{


	/*local trigger_push = Ware_SpawnEntity("trigger_push", 
    {
        targetname = "ufo_lift_trigger_bottom"
        origin     = pos
        pushdir    = QAngle(-90, 0, 0)
        speed      = 550
        spawnflags = 1
		StartDisabled = 0
    })*/
    trigger_push.SetSize(Vector(-20, -20, 0), Vector(20, 20, 50))
    trigger_push.SetSolid(SOLID_BBOX)
    EntFireByHandle(trigger_push, "Disable", "", 0.5, null, null)
	ufo = FindByName(null, "ufo_tracktrain")
    ufo.SetOrigin(Ware_MinigameLocation.center + Vector(0,0, 1600))

	ufo.SetMoveType(MOVETYPE_FLY, MOVECOLLIDE_FLY_BOUNCE)

	Ware_SlapEntity(ufo, RandomFloat(200, 300))
	local vel = ufo.GetAbsVelocity()
	vel = Vector(vel.x * 1, vel.y * 1, vel.z * 0)
	ufo.SetAbsVelocity(vel)

	local particle = Ware_SpawnEntity("info_particle_system",
	{
		origin = Ware_MinigameLocation.center + Vector(0,0,500),
		effect_name = "alien_abduction2",
		start_active = true
	})
    Ware_ChatPrint(null, "{int}", particle.GetOrigin())

	//SetEntityParent(particle, ufo)
	for (local ent; ent = FindByName(ent, "ufo_*");)
    {
        SetPropBool(ent, "m_bDisabled", true)
        EntityAcceptInput(ent, "Enable")
        SetPropBool(ent, "m_bActive", false)		
		//ent.SetDrawEnabled(true)
        ent.ValidateScriptScope()
        local scope = ent.GetScriptScope()
		scope.OnStartTouch <- OnCorrectTouch
		ent.ConnectOutput("OnStartTouch", "OnStartTouch")
        ent.GetScriptScope().OnEndTouch <- OnTriggerEndTouch
		ent.ConnectOutput("OnEndTouch", "OnEndTouch")
    }
    for (local ent; ent = FindByName(ent, "trigger_deposit*");)
    {
        SetPropBool(ent, "m_bDisabled", false)
        EntityAcceptInput(ent, "Enable")
        ent.ValidateScriptScope()
        local scope = ent.GetScriptScope()
		scope.OnStartTouch <- OnEnterUFO
		ent.ConnectOutput("OnStartTouch", "OnStartTouch")
    }

    //DispatchParticleEffect("alien_abduction2", Ware_MinigameLocation.center + Vector(0,0,1000), Vector())

    
}


function OnEnd()
{
    local ufo = FindByName(null, "ufo_tracktrain")
    ufo.SetOrigin(Vector(-1823, -7061, 1210))
}