special_round <- Ware_SpecialRoundData
({
	name             = "Singleplayer"
	author           = ["Mecha the Slag", "tilderain"]
	description      = "You're playing alone...?"
	category         = ""
    min_players		 = 2
	convars			 = 
	{
		mp_show_voice_icons = 0
	}
})

function DisablePlayerVisibility(player)
{
    player.AddCustomAttribute("voice pitch scale", 0, -1)
    Ware_TogglePlayerWearables(player, false)
    player.AddHudHideFlags(HIDEHUD_TARGET_ID)
    SetPropInt(player, "m_nRenderMode", kRenderNone)
    player.RemoveCond(TF_COND_TELEPORTED)
}

function OnPlayerDeath(player, attacker, params)
{
	CreateTimer(@() KillPlayerRagdoll(player), 0.0)
}

function OnUpdate()
{
    foreach (player in Ware_Players)
    {
        EntFire("tf_ragdoll", "Kill")
        player.RemoveCond(TF_COND_TELEPORTED)
        player.AddHudHideFlags(HIDEHUD_TARGET_ID)
        //Bad performance?
        Ware_TogglePlayerWearables(player, false)
		// hides medic bubbles
		SetPropBool(player, "m_bSaveMeParity", false)
    }
}

function OnPlayerInventory(player)
{
	foreach (player in Ware_Players)
    {
        DisablePlayerVisibility(player)
    }
}

function OnMinigameStart()
{
	foreach (player in Ware_Players)
    {
        DisablePlayerVisibility(player)
    }
}

function OnMinigameCleanup()
{
	foreach (player in Ware_Players)
    {
        DisablePlayerVisibility(player)
    }
}

function OnBeginIntermission(is_boss)
{
	foreach (player in Ware_Players)
    {
        DisablePlayerVisibility(player)
    }
}


function OnStart()
{
	foreach (player in Ware_Players)
    {
        DisablePlayerVisibility(player)
    }
}

function OnEnd()
{
	foreach (player in Ware_Players)
    {
        player.RemoveHudHideFlags(HIDEHUD_TARGET_ID)
        SetPropInt(player, "m_nRenderMode", kRenderNormal)
        Ware_TogglePlayerWearables(player, true)
    }
}