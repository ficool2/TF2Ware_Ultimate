// by ficool2

const EFL_USER = 2097152

const INT_MIN = 0x80000000
const INT_MAX = 0x7FFFFFFF
const FLT_MAX = 3.402823466e+38
const RAD2DEG = 57.295779513
const DEG2RAD = 0.0174532924

vec3_zero    <- Vector()
vec3_epsilon <- Vector(0, 0, 1e-6)
vec3_up      <- Vector(0, 0, 1)
ang_zero     <- QAngle()

const TICKDT = 0.015 // assuming 66 tickrate
const NDEBUG_TICK = 0.03 // for debug drawing per-tick

const MASK_ALL                   = -1
const MASK_SOLID_BRUSHONLY       = 16395
const MASK_PLAYERSOLID_BRUSHONLY = 81931
const MASK_PLAYERSOLID           = 33636363
const MASK_SOLID 	             = 33570827

const MAX_WEAPONS = 7

const DAMAGE_NO				= 0
const DAMAGE_EVENTS_ONLY	= 1
const DAMAGE_YES			= 2
const DAMAGE_AIM			= 3

const SF_TRIGGER_ALLOW_CLIENTS				= 1
const SF_TRIGGER_ALLOW_NPCS					= 2
const SF_TRIGGER_ALLOW_PUSHABLES			= 4
const SF_TRIGGER_ALLOW_PHYSICS				= 8
const SF_TRIGGER_ONLY_PLAYER_ALLY_NPCS		= 16
const SF_TRIGGER_ONLY_CLIENTS_IN_VEHICLES	= 32
const SF_TRIGGER_ALLOW_ALL					= 64

const SF_PHYSPROP_TOUCH	= 16

const DMG_SAWBLADE = 65536
const DMG_CRIT     = 1048576

const SND_CHANGE_VOL   = 1
const SND_CHANGE_PITCH = 2
const SND_STOP         = 4

const CHAN_REPLACE  = -1
const CHAN_AUTO     = 0
const CHAN_WEAPON   = 1
const CHAN_VOICE    = 2
const CHAN_ITEM     = 3
const CHAN_BODY     = 4
const CHAN_STREAM   = 5
const CHAN_STATIC   = 6
const CHAN_VOICE2   = 7

const PATTACH_ABSORIGIN			= 0
const PATTACH_ABSORIGIN_FOLLOW	= 1
const PATTACH_CUSTOMORIGIN		= 2
const PATTACH_POINT				= 3
const PATTACH_POINT_FOLLOW		= 4
const PATTACH_WORLDORIGIN		= 5
const PATTACH_ROOTBONE_FOLLOW	= 6

const TF_TEAM_MASK = 2 // red and blue

const TF_CLASS_FIRST = 1
const TF_CLASS_LAST  = 9

const TF_SLOT_PRIMARY   = 0
const TF_SLOT_SECONDARY = 1
const TF_SLOT_MELEE     = 2
const TF_SLOT_PDA       = 3
const TF_SLOT_PDA2      = 4

const TF_AMMO_DUMMY 	= 0
const TF_AMMO_PRIMARY 	= 1
const TF_AMMO_SECONDARY = 2
const TF_AMMO_METAL 	= 3
const TF_AMMO_GRENADES1 = 4
const TF_AMMO_GRENADES2 = 5
const TF_AMMO_GRENADES3 = 6
const TF_AMMO_COUNT 	= 7 

const TF_STUN_NONE                  = 0
const TF_STUN_MOVEMENT              = 1
const TF_STUN_CONTROLS 	            = 2
const TF_STUN_MOVEMENT_FORWARD_ONLY = 4
const TF_STUN_SPECIAL_SOUND         = 8
const TF_STUN_DODGE_COOLDOWN        = 16
const TF_STUN_NO_EFFECTS            = 32
const TF_STUN_LOSER_STATE           = 64
const TF_STUN_BY_TRIGGER            = 128
const TF_STUN_SOUND                 = 256 

const TF_DEATH_FEIGN_DEATH = 32

const OBJ_DISPENSER         = 0
const OBJ_TELEPORTER        = 1
const OBJ_SENTRYGUN         = 2
const OBJ_ATTACHMENT_SAPPER = 3

const TFCOLLISION_GROUP_GRENADES                          = 20
const TFCOLLISION_GROUP_OBJECT                            = 21
const TFCOLLISION_GROUP_OBJECT_SOLIDTOPLAYERMOVEMENT      = 22
const TFCOLLISION_GROUP_COMBATOBJECT                      = 23
const TFCOLLISION_GROUP_ROCKETS                           = 24
const TFCOLLISION_GROUP_RESPAWNROOMS                      = 25
const TFCOLLISION_GROUP_PUMPKIN_BOMB                      = 26
const TFCOLLISION_GROUP_ROCKET_BUT_NOT_WITH_OTHER_ROCKETS = 27

const COLOR_RED        = "FF0000"
const COLOR_GREEN      = "00FF00"
const COLOR_BLUE       = "0000FF"
const COLOR_YELLOW     = "FFFF00"
const COLOR_LIME       = "22FF22"
const COLOR_WHITE      = "FFFFFF"
const COLOR_BLACK      = "000000"
const COLOR_MAGENTA    = "FF00FF"
const COLOR_CYAN       = "00FFFF"
const COLOR_ORANGE     = "E59620"
const COLOR_LIGHTRED   = "EF3C39" // logo colors
const COLOR_DARKBLUE   = "0785dd"
const TF_COLOR_DEFAULT = "FBECCB"
const TF_COLOR_RED     = "FF3F3F"
const TF_COLOR_BLUE    = "99CCFF"
const TF_COLOR_SPEC    = "CCCCCC"

// skipping channel 0 and 1 to reduce chance of conflicts with sourcemod plugins
const CHANNEL_MINIGAME     = 3
const CHANNEL_SPECIALROUND = 4
const CHANNEL_MISC         = 2
const CHANNEL_BACKUP       = 1 // not reliable as plugins may use it

const SFX_WARE_FIREWORKS = "Summer.Fireworks"
const SFX_WARE_PASS      = "TF2Ware_Ultimate.Pass"
const SFX_WARE_PASSME    = "TF2Ware_Ultimate.PassMe"
const SFX_WARE_KART_HORN = "TF2Ware_Ultimate.KartHorn"
const SFX_WARE_ERROR     = "TF2Ware_Ultimate.Error"
const SFX_WARE_FAIL      = "TF2Ware_Ultimate.Fail"

const PFX_WARE_FIREWORKS = "mvm_pow_gold_seq_firework_mid"
const PFX_WARE_PASS_RED  = "teleportedin_red"
const PFX_WARE_PASS_BLUE = "teleportedin_blue"

const SPRITE_WINNER	= "tf2ware/tf2ware_points99.vmt"

CONST.MAX_CLIENTS <- MaxClients().tointeger()

TF_CLASS_ARMS <-
{
	[TF_CLASS_SCOUT]		= "models/weapons/c_models/c_scout_arms.mdl",
	[TF_CLASS_SOLDIER]		= "models/weapons/c_models/c_soldier_arms.mdl",
	[TF_CLASS_PYRO]			= "models/weapons/c_models/c_pyro_arms.mdl",
	[TF_CLASS_DEMOMAN]		= "models/weapons/c_models/c_demo_arms.mdl",
	[TF_CLASS_HEAVYWEAPONS]	= "models/weapons/c_models/c_heavy_arms.mdl",
	[TF_CLASS_ENGINEER] 	= "models/weapons/c_models/c_engineer_arms.mdl",	
	[TF_CLASS_MEDIC]		= "models/weapons/c_models/c_medic_arms.mdl",
	[TF_CLASS_SNIPER]		= "models/weapons/c_models/c_sniper_arms.mdl",
	[TF_CLASS_SPY]			= "models/weapons/c_models/c_spy_arms.mdl",
}

ITEM_PROJECTILE_MAP <-
{
	[18]   = "tf_projectile_rocket",
	[127]  = "tf_projectile_rocket",
	[1178] = "tf_projectile_balloffire",
	[19]   = "tf_projectile_pipe",
	[20]   = "tf_projectile_pipe_remote",
	[308]  = "tf_projectile_pipe",
	[44]   = "tf_projectile_stun_ball",
	[56]   = "tf_projectile_arrow",
	[58]   = "tf_projectile_jar",
	[1152] = "tf_projectile_grapplinghook",
}

STOCK_MELEE_MAP <- 
{
	[TF_CLASS_SCOUT]        = "Bat",
	[TF_CLASS_SOLDIER]      = "Shovel",
	[TF_CLASS_PYRO]         = "Fire Axe",
	[TF_CLASS_DEMOMAN]      = "Bottle",
	[TF_CLASS_HEAVYWEAPONS] = "Fists",
	[TF_CLASS_ENGINEER]     = "Wrench",
	[TF_CLASS_MEDIC]        = "Bonesaw",
	[TF_CLASS_SNIPER]       = "Kukri",
	[TF_CLASS_SPY]          = "Knife",
}

SAXXY_CLASSNAME_MAP <-
{
	[TF_CLASS_SCOUT]        = "tf_weapon_bat",
	[TF_CLASS_SOLDIER]      = "tf_weapon_shovel",
	[TF_CLASS_PYRO]         = "tf_weapon_fireaxe",
	[TF_CLASS_DEMOMAN]      = "tf_weapon_bottle",
	[TF_CLASS_HEAVYWEAPONS] = "tf_weapon_fists",
	[TF_CLASS_ENGINEER]     = "tf_weapon_wrench",
	[TF_CLASS_MEDIC]        = "tf_weapon_bonesaw",
	[TF_CLASS_SNIPER]       = "tf_weapon_club",
	[TF_CLASS_SPY]          = "tf_weapon_knife",
}

PrecacheScriptSound(SFX_WARE_FIREWORKS)
PrecacheScriptSound(SFX_WARE_PASS)
PrecacheScriptSound(SFX_WARE_PASSME)
PrecacheScriptSound(SFX_WARE_KART_HORN)
PrecacheScriptSound(SFX_WARE_ERROR)
PrecacheScriptSound(SFX_WARE_FAIL)

PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar.mdl")
PrecacheModel("models/props_halloween/bumpercar_cage.mdl")

PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = PFX_WARE_FIREWORKS })
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = PFX_WARE_PASS_RED })
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = PFX_WARE_PASS_BLUE })

PrecacheModel(SPRITE_WINNER)

KART_SOUNDS <-
[
	"BumperCar.Spawn"
    "BumperCar.SpawnFromLava"
    "BumperCar.GoLoop"
    "BumperCar.Screech"
    "BumperCar.HitGhost"
    "BumperCar.Bump"
    "BumperCar.BumpHard"
    "BumperCar.BumpIntoAir"
    "BumperCar.SpeedBoostStart"
    "BumperCar.SpeedBoostStop"
    "BumperCar.Jump"
    "BumperCar.JumpLand"
	"sf14.Merasmus.DuckHunt.BonusDucks"
]
foreach (sound in KART_SOUNDS) 
	PrecacheScriptSound(sound)

