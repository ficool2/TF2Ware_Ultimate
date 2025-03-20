//This script clearly isn't meant to be reused, turns out, it has been reused in TF2ware!
//This is a shitpost so really I didn't care about cleaning it up
//May god have mercy on your soul whoever reads those lines, this has been ported as-it-is from the original map
//Script by Alex Turtle

TriggerEnding <- true

SpawnCenter <- Vector(-32, -13280, -12608)

WegaArray <- array(0)
WegaTargetArray <- array(0)

AggroClosest <- false
AntiStall <- false

PlayersCount <- 1

music_wega <- "wexecution"
music_urio <- "wexecution_urio_theme"

model_hands <- "models/wega/hands.mdl"
model_wega_doll <- "models/wega/wega.mdl"

sound_collect <- "tf2ware_ultimate/baseball_hit.mp3"
sound_stalker_scream <- "npc/stalker/go_alert2a.wav"
sound_wega_scream <- "tf2ware_ultimate/wega_scream.wav"

overlay_counter <- "wega/wega_counter.vmt"
overlay_wega_jumpscare <- "wega/wega_jumpscare.vtf"
overlay_urio_jumpscare <- "wega/uario_jumpscare.vtf"

material_wega <- "wega/wega.vmt"

//This is the TF2Ware part, the only part I will keep clean
minigame <- Ware_MinigameData
({
	name           = "Wega's challenge"
	author         =  ["Alex Turtle"]
	description    = "Win Wega's Challenge!"
	custom_overlay = "wega_challenge"
	duration       = 300.0
    end_delay      = 3.0
	location       = "wega_challenge"
	music          = music_wega
	start_pass     = false
    fail_on_death  = true
    boss           = true
    start_freeze   = 4.0
	max_scale      = 1.6
    convars        =
	{
        tf_avoidteammates_pushaway = 0
        sv_Friction = 1
        tf_scout_air_dash_count = 0
	}
})

function OnPrecache()
{
    PrecacheModel(model_hands)
    PrecacheModel(model_wega_doll)
    PrecacheSound(sound_collect)
    PrecacheSound(sound_stalker_scream)
    PrecacheSound(sound_wega_scream)
    PrecacheOverlay(overlay_counter)
    PrecacheOverlay(overlay_wega_jumpscare)
    PrecacheOverlay(overlay_urio_jumpscare)
    PrecacheMaterial(material_wega)
    Ware_PrecacheMinigameMusic(music_wega, true)
    Ware_PrecacheMinigameMusic(music_urio, true)
}

fog <- null

function OnStart()
{
    fog = Ware_SpawnEntity("env_fog_controller",
	{
		fogenable = true,
		fogcolor = "0 0 0",
		fogcolor2 = "0 0 0",
		fogstart = 0,
		fogend = 1250.0,
		fogmaxdensity = 1.0,
	})

    Generate()

    Ware_CreateTimer(function()
	{
        foreach (player in Ware_MinigamePlayers)
	    {
            player.SetScriptOverlayMaterial(overlay_counter)
        }
		AddWegas()
	}, 7.0)

    Ware_CreateTimer(function()
	{
        ActivateWegaAntiStall()
	}, 170.0)

	Ware_SetGlobalLoadout(TF_CLASS_SCOUT, "Bat")

    foreach (player in Ware_MinigamePlayers)
	{
        Ware_AddPlayerAttribute(player, "no_attack", 1, -1)
		Ware_AddPlayerAttribute(player, "no double jump", 1, -1)
		Ware_AddPlayerAttribute(player, "increased jump height", 0.0, -1)
        Ware_AddPlayerAttribute(player, "move speed bonus", 1.07, -1)
        Ware_GetPlayerMiniData(player).jumping <- false
        SetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl", fog)

        player.AddHudHideFlags(HIDEHUD_WEAPONSELECTION)
        player.AddHudHideFlags(HIDEHUD_FLASHLIGHT)
        player.AddHudHideFlags(HIDEHUD_HEALTH)
        player.AddHudHideFlags(HIDEHUD_MISCSTATUS)
        player.AddHudHideFlags(HIDEHUD_CROSSHAIR)
        player.AddHudHideFlags(HIDEHUD_BONUS_PROGRESS)
        player.AddHudHideFlags(HIDEHUD_TARGET_ID)
        player.SetScriptOverlayMaterial("wega/wega_counter.vmt")

        local weapon = player.GetActiveWeapon()
        NetProps.SetPropBool(weapon, "m_bBeingRepurposedForTaunt", true)
        weapon.SetModelSimple("")
        NetProps.SetPropInt(weapon, "m_nRenderMode", 4)
        NetProps.SetPropInt(weapon, "m_clrRender", 0)
        NetProps.SetPropInt(weapon, "m_nRenderFX", 0)
        weapon.SetCustomViewModel(model_hands)
	}

    EntFire("wega_challenge_start", "Enable")
    EntFire("wega_fall", "Enable")
}

function OnUpdate()
{
    if (AntiStall)
        IncreaseWegaSpeedByOne()

    foreach (player in Ware_MinigamePlayers)
	{
        Wega_player_tick(player)
    }

    Ware_ShowText(Ware_Players, CHANNEL_MINIGAME, wegacount.tostring(), 0.5, "255 255 255", 0.1, 0.06)

    local wegaEntity = null
    while (wegaEntity = FindByName(wegaEntity, "multiplayer_wega_brush*"))
    {
        Wega_entity_tick(wegaEntity)
    }

    if (TriggerEnding && wegacount == 1)
    {
        ClearSounds()
        EntFire("wega_final_chase_template", "ForceSpawn")
        EntFire("start_final_chase", "Trigger")
        TriggerEnding = false
        EntFire("wega_brush*", "Kill")
        EntFire("wega_sound*", "Kill")
        EntFire("multiplayer_wega_brush*", "Kill")
        EntFire("multiplayer_wega_sound*", "Kill")
        EntFire("wega_teleport", "Enable")
        WegaArray.clear()
        Ware_PlayMinigameMusic(null, music_wega, SND_STOP)
        Ware_PlayMinigameMusic(null, music_urio)

        Ware_CreateTimer(function()
	    {
            local urioBrush = FindByName(null, "uario_brush")
            urioBrush.ValidateScriptScope()
            urioBrush.GetScriptScope().sound_stalker_scream <- sound_stalker_scream
            urioBrush.GetScriptScope().overlay_urio_jumpscare <- overlay_urio_jumpscare
            urioBrush.GetScriptScope().JumpscareUario <- function(){
                local victim = activator
                EmitSoundEx({
	            sound_name = this.sound_stalker_scream,
	            entity = victim,
	            filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
                })
                victim.SetScriptOverlayMaterial(this.overlay_urio_jumpscare)
                Ware_AddPlayerAttribute(victim, "move speed penalty", 0.0, -1)
                Ware_CreateTimer(function()
	            {
                    victim.TakeDamage(1000, DMG_SLASH, null)
                    victim.SetScriptOverlayMaterial("")
                }, 1.5)
            }
        }, 0.1)
    }
}

function OnEnd()
{
    
    EntFire("uario_brush", "Kill")
    EntFire("uario_path_*", "Kill")
    EntFire("antifall_brush", "Kill")
    EntFire("final_collectible", "Kill")
    EntFire("wega_challenge_start", "Disable")
    EntFire("wega_teleport", "Disable")
    EntFire("wega_challenge_floor", "Kill")
    EntFire("wega_challenge_doll", "Kill")
    EntFire("wega_fall", "Disable")
    EntFire("wega_brush*", "Kill")
    EntFire("wega_sound*", "Kill")
    EntFire("multiplayer_wega_brush*", "Kill")
    EntFire("multiplayer_wega_sound*", "Kill")
    DeactivateWegaAntiStall()

    if (TriggerEnding)
    {
        ClearSounds()

        Ware_PlayMinigameMusic(null, music_wega, SND_STOP)
    }
    else
    {
        Ware_PlayMinigameMusic(null, music_urio, SND_STOP)
    }

    foreach (player in Ware_MinigamePlayers)
	{
        SetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl", null)
    }
}

function OnCheckEnd()
{
	return Ware_GetUnpassedPlayers(true).len() == 0
}

function ClearSounds()
{
    local wegaEntity = null
    while (wegaEntity = FindByName(wegaEntity, "multiplayer_wega_brush*"))
    {
        EmitSoundEx({
	    sound_name = sound_wega_scream,
	    entity = wegaEntity,
        sound_level = 70.0,
        flags = SND_STOP
        })
    }   
}

Chunk <- class
{
    model = null
    possible_up = null
    possible_right = null
    possible_down = null
    possible_left = null
    doll_locations = null

    constructor(model, possible_up, possible_right, possible_down, possible_left, doll_locations)
	{
        this.model = model
        this.possible_up = possible_up
        this.possible_right = possible_right
        this.possible_down = possible_down
        this.possible_left = possible_left
        this.doll_locations = doll_locations
        PrecacheModel(model)
    }

}

DollPositions <-
[
    //Starting from bottom-left, going up then left
    Vector(384, 384, 84)
    Vector(384, 192, 84)
    Vector(384, 0, 84)
    Vector(384, -192, 84)
    Vector(384, -384, 84)
    Vector(192, 384, 84)
    Vector(192, 192, 84)
    Vector(192, 0, 84)
    Vector(192, -192, 84)
    Vector(192, -384, 84)
    Vector(0, 384, 84)
    Vector(0, 192, 84)
    Vector(0, 0, 84)
    Vector(0, -192, 84)
    Vector(0, -384, 84)
    Vector(-192, 384, 84)
    Vector(-192, 192, 84)
    Vector(-192, 0, 84)
    Vector(-192, -192, 84)
    Vector(-192, -384, 84)
    Vector(-384, 384, 84)
    Vector(-384, 192, 84)
    Vector(-384, 0, 84)
    Vector(-384, -192, 84)
    Vector(-384, -384, 84)
    //25 to 49
    Vector(384, 384, 164)
    Vector(384, 192, 164)
    Vector(384, 0, 164)
    Vector(384, -192, 164)
    Vector(384, -384, 164)
    Vector(192, 384, 164)
    Vector(192, 192, 164)
    Vector(192, 0, 164)
    Vector(192, -192, 164)
    Vector(192, -384, 164)
    Vector(0, 384, 164)
    Vector(0, 192, 164)
    Vector(0, 0, 164)
    Vector(0, -192, 164)
    Vector(0, -384, 164)
    Vector(-192, 384, 164)
    Vector(-192, 192, 164)
    Vector(-192, 0, 164)
    Vector(-192, -192, 164)
    Vector(-192, -384, 164)
    Vector(-384, 384, 164)
    Vector(-384, 192, 164)
    Vector(-384, 0, 164)
    Vector(-384, -192, 164)
    Vector(-384, -384, 164)
    //50 to 74
    Vector(384, 384, 5)
    Vector(384, 192, 5)
    Vector(384, 0, 5)
    Vector(384, -192, 5)
    Vector(384, -384, 5)
    Vector(192, 384, 5)
    Vector(192, 192, 5)
    Vector(192, 0, 5)
    Vector(192, -192, 5)
    Vector(192, -384, 5)
    Vector(0, 384, 5)
    Vector(0, 192, 5)
    Vector(0, 0, 5)
    Vector(0, -192, 5)
    Vector(0, -384, 5)
    Vector(-192, 384, 5)
    Vector(-192, 192, 5)
    Vector(-192, 0, 5)
    Vector(-192, -192, 5)
    Vector(-192, -384, 5)
    Vector(-384, 384, 5)
    Vector(-384, 192, 5)
    Vector(-384, 0, 5)
    Vector(-384, -192, 5)
    Vector(-384, -384, 5)
]


enum DIRECTION
{
    UP,
    RIGHT,
    DOWN,
    LEFT,
}

ChunkList <-
[
    Chunk("models/wega/floor_0.mdl", [0, 2, 3, 5, 6, 7, 8, 11, 12], [], [2, 3, 4, 5, 6, 8], [0, 2, 3, 6, 7, 8], [15, 19, 10, 12, 14])
    Chunk("models/wega/floor_1.mdl", [], [1, 3, 6, 7, 8, 9, 10], [], [1, 3, 6, 7, 9, 10], [6, 8, 16, 18])
    Chunk("models/wega/floor_2.mdl", [3, 6, 8], [4, 6, 7, 8], [0, 3, 4, 6, 7, 8], [3, 6, 8], [0, 24, 35, 37, 45, 47])
    Chunk("models/wega/floor_3.mdl", [0, 3, 6, 7, 8], [0, 1, 2, 4, 6, 7, 8, 9, 10], [0, 3, 4, 6, 7, 8], [0, 1, 2, 4, 6, 7, 8, 9, 10], [1, 3, 21, 23, 61, 63])
    Chunk("models/wega/floor_4.mdl", [0, 2, 3, 5, 6, 7, 8, 10, 11, 12], [2, 4, 6, 7, 8], [], [2, 4, 5, 6], [5, 6, 7, 10, 12, 15, 16, 17])
    Chunk("models/wega/floor_5.mdl", [6, 7], [0, 3, 6, 7, 8], [0, 3, 4, 6, 7, 8], [0, 6, 7, 8], [0, 2, 10, 12, 14, 22, 24])
    Chunk("models/wega/floor_6.mdl", [0, 2, 3, 5, 6, 7, 8], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [0, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [1, 2, 3, 21, 22, 23,37])
    Chunk("models/wega/floor_7.mdl", [0, 2, 3, 6, 7, 8], [1, 3, 6, 7, 8, 9, 10], [0, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [22])
    Chunk("models/wega/floor_8.mdl", [0, 2, 3, 6, 7, 8, 11, 12], [3, 5, 6, 7, 8, 9, 10], [0, 3, 4, 5, 6, 7, 8, 11, 12], [2, 3, 4, 5, 6, 7, 8, 9, 10], [0, 2, 4, 10, 14, 20, 22, 24])
    Chunk("models/wega/floor_9.mdl", [], [1, 3, 6, 7, 8], [], [1, 3, 6, 7], [32, 37, 42])
    Chunk("models/wega/floor_10.mdl", [], [1, 3, 6, 7, 8], [], [1, 3, 6, 7], [2, 7, 12, 17, 22])
    Chunk("models/wega/floor_11.mdl", [0], [], [0, 4], [], [61, 62, 63])
    Chunk("models/wega/floor_12.mdl", [0], [], [0, 4], [], [10, 11, 12, 13, 14])
    Chunk("models/wega/floor_13.mdl", [0, 2, 3, 5, 6, 7, 8, 11, 12, 13], [1, 2, 3, 4, 5, 6, 8, 13], [0, 2, 3, 5, 6, 13], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [15, 19, 21, 23, 67])
]

CellWidth <- 960

Size <- 10


//Depth First implementation
function Generate()
{

    CalculateSize()

    local direction = null
    local CellArray = array(Size);

    for (local i = 0 ; i < Size ; i++) {
        CellArray[i] = array(Size);
    }

    CellArray[0][0] = 8
    CellArray[Size-1][Size-1] = 8



    local x = 1
    local y = 0

    //Connect to the other spawn first
    while (x < Size-1 || y < Size-1)
    {
    
        if (x < Size-1 && y < Size-1)
        {

            local rnd = RandomInt(0, 1)
            if (rnd == 0)
            {
                direction = DIRECTION.UP
            }
            else
            {
                direction = DIRECTION.RIGHT
            }
        }
        else
        {
            if (x >= Size-1 && y < Size-1)
            {
                direction = DIRECTION.RIGHT
            }

            if (y >= Size-1 && x < Size-1)
            {
                direction = DIRECTION.UP
            }
        }
        local possibleList = [3, 5, 6, 8, 13]

        switch(direction)
        {
            case DIRECTION.UP:
            if (CellArray[x][y] != null)
            {
                possibleList = ChunkList[CellArray[x][y]].possible_up
      
            }

            x++
            break

            case DIRECTION.RIGHT:
            if (CellArray[x][y] != null)
                possibleList = ChunkList[CellArray[x][y]].possible_right

            y++
            break

        }
        if (y == Size-1 && x == Size-1)
            break

        local possibleList = [3, 5, 6, 8, 13]
        local rnd = RandomInt(0, possibleList.len()-1)

        local selectedChunk = possibleList[rnd]
        CellArray[x][y] = selectedChunk 
    }

    //Phase 2, fill everything
    local possibleList = [0, 2, 3, 5, 6, 7, 8, 11, 12, 13]
    local selectedChunk = null


    x = 0
    while (x < Size-1)
    {
        y = 0

        x++

        if (CellArray[x][y] == null) 
        {

            if (CellArray[x-1][y] == null)
                break

            direction = DIRECTION.RIGHT
            possibleList = ChunkList[CellArray[x-1][y]].possible_right

            if (possibleList.len() > 0)
            {
                local rnd = RandomInt(0, possibleList.len()-1)
                selectedChunk = possibleList[rnd]
                CellArray[x][y] = selectedChunk 
            }
        }   



        while (y < Size-1)
        {  
            y++

            if (CellArray[x][y] != null)
                break

            direction = DIRECTION.UP
            if (CellArray[x][y-1] != null)
            {
            possibleList = ChunkList[CellArray[x][y-1]].possible_up

            if (possibleList.len() < 1)
                break

            local rnd = RandomInt(0, possibleList.len()-1)
            selectedChunk = possibleList[rnd]
            CellArray[x][y] = selectedChunk 
    


            }
        }

    }

    //Phase 3, fill the other way

    y = Size-1
    while (y > 0)
    {
        x = Size-1
        y--

        if (CellArray[x][y] == null || y == Size-2) 
        {
            if (CellArray[x][y+1] == null && y != Size-2)
                break

            direction = DIRECTION.DOWN

            if (y == Size-2)
                possibleList = ChunkList[CellArray[x][y+1]].possible_down
            else
                possibleList = [3, 5, 6, 8, 13]

            if (possibleList.len() > 0)
            {
                local rnd = RandomInt(0, possibleList.len()-1)
                selectedChunk = possibleList[rnd]
                CellArray[x][y] = selectedChunk 
            }
        }   



        while (x > 0)
        {  
            x--

            if (CellArray[x][y] != null && x != 0)
                break

            direction = DIRECTION.LEFT
            if (CellArray[x+1][y] != null || x == 0)
            {

            if (x == 0)
                possibleList = [3, 5, 6, 8, 13]
            else
                possibleList = ChunkList[CellArray[x+1][y]].possible_left

            if (possibleList.len() < 1)
                break

            local rnd = RandomInt(0, possibleList.len()-1)
            selectedChunk = possibleList[rnd]
            CellArray[x][y] = selectedChunk 
    


            }
        }


    }


    //Phase 4
    x = Size-1
    y = Size-1

    while(x >= 0)
    {
        local possibleList = [3, 5, 6, 8, 13]
        local rnd = RandomInt(0, possibleList.len()-1)

        local selectedChunk = possibleList[rnd]
        CellArray[x][Size-1] = selectedChunk 
        x--
    }

    while(y >= 0)
    {
        local possibleList = [3, 5, 6, 8, 13]
        local rnd = RandomInt(0, possibleList.len()-1)

        local selectedChunk = possibleList[rnd]
        CellArray[0][y] = selectedChunk 
        y--
    }




    //Phase 5, more random
    local possibleList = [3, 5, 6, 8, 13]
    local selectedChunk = null


    x = 0
    while (x < Size-1)
    {
        y = 0

        x++

        if (CellArray[x][y] == null) 
        {

            if (CellArray[x-1][y] == null)
                break

            direction = DIRECTION.RIGHT
            possibleList = ChunkList[CellArray[x-1][y]].possible_right

            if (possibleList.len() > 0)
            {
                local rnd = RandomInt(0, possibleList.len()-1)
                selectedChunk = possibleList[rnd]
                CellArray[x][y] = selectedChunk 

            }
        }   



        while (y < Size-1)
        {  
            y++

            if (CellArray[x][y] != null)
                break

            direction = DIRECTION.UP
            if (CellArray[x][y-1] != null)
            {
                possibleList = ChunkList[CellArray[x][y-1]].possible_up

                if (possibleList.len() < 1)
                    break

                local rnd = RandomInt(0, possibleList.len()-1)
                selectedChunk = possibleList[rnd]
                CellArray[x][y] = selectedChunk 
            }
        }

    }
    CellArray[0][Size-1] = 8
    CellArray[Size-1][Size-2] = 8

    //Phase 6, spawn templates
    x = 0
    while (x <= Size-1)
    {
        y = 0
        while (y <= Size-1)
        {
            if ((y == 0 && x == 0) || (y == Size-1 && x == Size-1))
            {
                y++
                continue
            }

            if (CellArray[x][y] != null)
            {
                local prop = Ware_SpawnEntity("prop_dynamic",
                {
                    targetname = "wega_challenge_floor"
                    origin = Vector(x*CellWidth,y*CellWidth,0) + SpawnCenter,
                    model = ChunkList[CellArray[x][y]].model,
                    solid = 6
                })

                for(local i = 0; i < ChunkList[CellArray[x][y]].doll_locations.len(); i++)
                {
                    local prop = Ware_SpawnEntity("prop_dynamic",
                    {
                        targetname = "wega_challenge_doll"
                        origin = Vector(x*CellWidth,y*CellWidth,0) + DollPositions[ChunkList[CellArray[x][y]].doll_locations[i]] + SpawnCenter,
                        model = model_wega_doll
                        DefaultAnim = "idle"
                    })

                    prop.ValidateScriptScope()
                    prop.GetScriptScope().sound_collect <- sound_collect
                    prop.GetScriptScope().WegaCollect <- function(player){
                        self.Kill()
                        EmitSoundEx({
	                    sound_name = this.sound_collect,
	                    entity = player,
	                    filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
                    })
                        

                    }
                }
            }
            y++
        }
        x++

    }

    PrepareObjective()
}

function CalculateSize()
{
    PlayersCount = Ware_MinigamePlayers.len() 
    local buffer = ceil(sqrt(PlayersCount + 4))
    buffer += 3
    if (buffer < 4)
        buffer = 4

    //multi is size of 6 min
    if (PlayersCount > 1)
    {
        buffer++
        if (buffer < 6)
            buffer = 6
    }
    else
    {
        buffer = 4
    }

    if (buffer > 10)
        buffer = 10

    Size = buffer
}

wegacount <- 0

function PrepareObjective()
{
    local wega = null
    while (wega = FindByClassname(wega, "prop_dynamic"))
    {
        if (wega.GetModelName() == model_wega_doll)
        {
            local rnd = RandomInt(0, 359)
            wega.SetAbsAngles(QAngle(0, rnd, 0))
            wegacount++
        }
    }
}

function CreateWega(location)
{
    local wega = Ware_SpawnEntity("env_sprite_oriented",
    {
        targetname = "multiplayer_wega_brush",
        model = material_wega,
        scale = 0.35,
        spawnflags = 1
        origin = Vector(location.x, location.y, location.z + 80.0)
    })

    EmitSoundEx({
	    sound_name = sound_wega_scream,
	    entity = wega,
        sound_level = 70.0,
        filter_type = RECIPIENT_FILTER_GLOBAL
    })

    WegaTargetArray.append(null)

    return wega
}

function AddWegas()
{
    CreateWega(Vector(-1*CellWidth,-1*CellWidth,0) + SpawnCenter)

    //How many wegas?
    local playerCount = Ware_MinigamePlayers.len() 
    local extraWegas = 0

    //Multi only
    if (playerCount > 1)
    {
        extraWegas = ceil(sqrt(playerCount*4))

        if (extraWegas + 1 > playerCount)
            extraWegas = playerCount - 1
    }
    //Above 20
    if (playerCount > 20)
    {
        extraWegas = ceil(playerCount / 2.5)
        extraWegas++
    }

    local buffer = Size
    if (buffer > 6)
        buffer = 7

    for (local i = 0; i < extraWegas ; i++)
    {
        local rnd = RandomInt(1, 4)
        switch (rnd)
        {
        case 1:
        CreateWega(Vector((buffer)*CellWidth,-1*CellWidth,0) + SpawnCenter)
        break
        case 2:
        CreateWega(Vector(-1*CellWidth,-1*CellWidth,0) + SpawnCenter)
        break
        case 3:
        CreateWega(Vector(-1*CellWidth,(buffer)*CellWidth,0) + SpawnCenter)
        break
        case 4:
        CreateWega(Vector((buffer)*CellWidth,(buffer)*CellWidth,0) + SpawnCenter)
        break
        }

    }

	local wegaEntity = null
    local i = 0
    while (wegaEntity = FindByName(wegaEntity, "multiplayer_wega_brush*"))
    {
        
        wegaEntity.ValidateScriptScope()
        wegaEntity.GetScriptScope().id <- i
        wegaEntity.GetScriptScope().speed <- 345
        if (i < 15)
            wegaEntity.GetScriptScope().speed += ((i+1) * 2)

        wegaEntity.GetScriptScope().sound_stalker_scream <- sound_stalker_scream
        wegaEntity.GetScriptScope().overlay_wega_jumpscare <- overlay_wega_jumpscare
        wegaEntity.GetScriptScope().Jumpscare <- function(victim){
            EmitSoundEx({
	        sound_name = this.sound_stalker_scream,
	        entity = victim,
	        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_SINGLE_PLAYER
            })
            victim.SetScriptOverlayMaterial(this.overlay_wega_jumpscare)
            Ware_CreateTimer(function()
	        {
                victim.TakeDamage(1000, DMG_SLASH, null)
                victim.SetScriptOverlayMaterial("")
            }, 1.5)
        }

        i++
        WegaArray.append(wegaEntity)
    }
}

function Wega_entity_tick(wega)
{
    local scope = wega.GetScriptScope()
    local id = scope.id
    local speed = scope.speed
    local playerDistance = 9999999
    local wegaOrigin = wega.GetOrigin()
    local wegaOriginOffset = Vector(wega.GetOrigin().x, wega.GetOrigin().y, wega.GetOrigin().z - 80.0)
    WegaTargetArray[id] = null

    foreach (player in Ware_Players)
    {
        if (!player.IsAlive())
            continue

        local distance = (wegaOriginOffset - player.GetOrigin()).Length()

        //player already being chased by another one?
        if (!AggroClosest && WegaTargetArray.find(player) != null)
        {
            continue
        }


        if (distance < playerDistance)
        {
            playerDistance = distance
            WegaTargetArray[id] = player
        }
    }
    if (WegaTargetArray[id] == null)
        foreach (player in Ware_Players)
        {
            if (!player.IsAlive())
                continue

            local distance = (wegaOriginOffset - player.GetOrigin()).Length()

            if (distance < playerDistance)
            {
                playerDistance = distance
                WegaTargetArray[id] = player
            }
        }

    if (WegaTargetArray[id] == null)
        return

    local direction = (wegaOriginOffset - WegaTargetArray[id].GetOrigin())

    direction.Norm()

    direction *= speed

    direction *= FrameTime()

    wega.SetOrigin(wegaOrigin - direction)

    ScreenShake(wegaOriginOffset, 8.0, 100, 0.05, 800, 0, true)

    local caughtPlayer = null
    while (caughtPlayer = FindByClassnameWithin(caughtPlayer, "player", wegaOriginOffset, 60.0))
    {
        if (!caughtPlayer.IsAlive())
            continue

        if (caughtPlayer.GetScriptOverlayMaterial() == overlay_wega_jumpscare)
            continue

        Ware_AddPlayerAttribute(caughtPlayer, "move speed penalty", 0.0, -1)
        wega.GetScriptScope().Jumpscare(caughtPlayer)
    }

    return -1

}

function ShouldSwitchTargets(player, otherId)
{
    local distance = (self.GetOrigin() - player.GetOrigin()).Length()
    local currentDistance = 999999999.0
    if (currentTarget != null)
        currentDistance = (self.GetOrigin() - currentTarget.GetOrigin()).Length()
    if (distance < currentDistance)
    {
        WegaTargetArray[otherId] = currentTarget
        WegaTargetArray[id] = player
        return true
    }
    return false

}

function Wega_player_tick(player)
{

    if (!player.IsAlive())
        return 100

    local origin = player.GetOrigin()
    origin.z += 54.0
    local wegaDoll = null


    wegaDoll = FindByNameNearest("wega_challenge_doll*", origin, 80.0)

    if (wegaDoll != null)
    {
        if (wegaDoll.GetName() == "wega_challenge_doll")
        {
            wegaDoll.GetScriptScope().WegaCollect(player)
            wegacount--
        }
        else
        {
            Ware_CreateTimer(function()
	        {
                Ware_TeleportPlayer(player, Ware_Location.home.center, ang_zero, vec3_zero)
	            Ware_ShowScreenOverlay(player, null)
	            Ware_PassPlayer(player, true)
            }, 0.1)
        }
    }

    return 0.05

}

function ToggleAggroClosest()
{
    if (AggroClosest)
        AggroClosest = false
    else
        AggroClosest = true
}

function ActivateWegaAntiStall()
{
    AntiStall = true
}

function DeactivateWegaAntiStall()
{
    AntiStall = false
}

function IncreaseWegaSpeedByOne()
{
    foreach (wega in WegaArray)
        wega.GetScriptScope().speed++
}