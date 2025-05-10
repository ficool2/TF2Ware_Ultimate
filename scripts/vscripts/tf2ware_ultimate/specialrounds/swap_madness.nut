special_round <- Ware_SpecialRoundData
({
	name = "Swap Madness"
	author = "CzechMate"
	description = "Players will randomly swap positions during a minigame!"
	category = "teleport"
    min_players = 2
})

teleport_sound <- "misc/halloween/spell_teleport.wav"

function OnPrecache()
{
    PrecacheSound(teleport_sound)
}

function OnMinigameStart()
{
    // Swapping positions right at the start or right at the end doesn't feel right
    local duration = Ware_Minigame.duration
    local min = Max(1.0, duration/10.0)
    local max = duration - Max(2.0, duration/5.0)
    local randomFloat = ceil(RandomFloat(min, max) * 10) / 10.0
    Ware_CreateTimer(@() SwapPlayerPositions(), randomFloat)
}

function SwapPlayerPositions()
{
    local players = Ware_MinigamePlayers
    local alivePlayers = []
    
    foreach (player in players)
    {
        if (player.IsAlive())
            alivePlayers.append(player)
    }

    local alivePlayerCount = alivePlayers.len()
    if (alivePlayerCount < 2)
        return

    Shuffle(alivePlayers)

    for (local i = 0; i < alivePlayerCount - 1; i += 2)
    {
        local player1 = alivePlayers[i]
        local player2 = alivePlayers[i + 1]

        local pos1 = player1.GetOrigin()
        local pos2 = player2.GetOrigin()

        local ang1 = player1.GetAbsAngles()
        local ang2 = player2.GetAbsAngles()

        local vel1 = player1.GetAbsVelocity()
        local vel2 = player2.GetAbsVelocity()

        //player 1
        if (player1.GetMoveParent())
		    SetPlayerParentPlayer(player1, null)
        if (player1.GetMoveType() == MOVETYPE_NONE)
            player1.SetMoveType(MOVETYPE_WALK, 0)
        Ware_TeleportPlayer(player1, pos2, ang2, vel2)
        Ware_SpawnParticle(player1, player1.GetTeam() == TF_TEAM_RED ? "teleported_red" : "teleported_blue")
        
        //player 2
        if (player2.GetMoveParent())
		    SetPlayerParentPlayer(player2, null)
        if (player2.GetMoveType() == MOVETYPE_NONE)
            player2.SetMoveType(MOVETYPE_WALK, 0)
        Ware_TeleportPlayer(player2, pos1, ang1, vel1)
        Ware_SpawnParticle(player2, player2.GetTeam() == TF_TEAM_RED ? "teleported_red" : "teleported_blue")

        Ware_PlaySoundOnAllClients(teleport_sound)
    }
}
