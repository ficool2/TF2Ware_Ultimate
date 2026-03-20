spots <- 
[
    {
        name = "Waluigi",
        origin = Vector(11491, 28, 8544),
        angles = QAngle(0, 0, 0)
    },
    {
        name = "Cow",
        origin = Vector(4779, -2721, -4439),
        angles = QAngle(1, 58, 0)
    },
    {
        name = "Planet",
        origin = Vector(5468, -636, 2052),
        angles = QAngle(6, 171, 0)
    },
    {
        name = "Koopa",
        origin = Vector(2755, -3921, -3624),
        angles = QAngle(0, 0, 0)
    },
    {
        name = "Bowser",
        origin = Vector(-3783, -4659, -4942),
        angles = QAngle(0, -90, 0)
    },
	{
        name = "Cactus",
        origin = Vector(2416, -2488, -394),
        angles = QAngle(12, -40, 0)
    },
	{
        name = "Palm Tree",
        origin = Vector(-407, -1407, -4808),
        angles = QAngle(12, -127, 0)
    },
	{
        name = "Mandrill",
        origin = Vector(-4378, -11625, -5254),
        angles = QAngle(1, 134, 0)
    },
	{
        name = "Aku Aku",
        origin = Vector(-4595, -9485, -5500),
        angles = QAngle(90, 90, 0)
    },
	{
        name = "Lava",
        origin = Vector(-6509, 104, -6213),
        angles = QAngle(90, -180, 0)
    },
	{
        name = "Containers",
        origin = Vector(-2901, 3691, -6450),
        angles = QAngle(16, 142, 0)
    },
	{
        name = "Toxic Water",
        origin = Vector(1313, 4420, -6410),
        angles = QAngle(28, 126, 0)
    },
	{
        name = "Room of Hearts",
        origin = Vector(4458, -2434, -5593),
        angles = QAngle(7, 44, 0)
    },
	{
        name = "Boxing Ring",
        origin = Vector(-453, -131, -5462),
        angles = QAngle(8, -147, 0)
    },
	{
        name = "ROBOTS!",
        origin = Vector(-293, 3782, -11552),
        angles = QAngle(14, 42, 0)
    },
	{
        name = "Payload",
        origin = Vector(1288, 12963, -4118),
        angles = QAngle(-7, 138, 0)
    },
	{
        name = "Gargoyle",
        origin = Vector(-1791, 7387, -6531),
        angles = QAngle(-31, -90, 0)
    },
	{
        name = "Mushroom",
        origin = Vector(-1788, 8189, -6813),
        angles = QAngle(90, 90, 0)
    },
	{
        name = "Beach",
        origin = Vector(5154, 5953, -3751),
        angles = QAngle(6, 123, 0)
    },
	{
        name = "Candle",
        origin = Vector(7900, -5636, -3558),
        angles = QAngle(15, -52, 0)
    },
	{
        name = "Trees",
        origin = Vector(11275, -6256, -6204),
        angles = QAngle(0, -30, 0)
    },
	{
        name = "Doog",
        origin = Vector(2096, 5765, -3429),
        angles = QAngle(11, -169, 0)
    },
	{
        name = "Cone",
        origin = Vector(1629, 4924, -3485),
        angles = QAngle(10, 56, 0)
    },
	{
        name = "Truck",
        origin = Vector(1538, 3545, -3430),
        angles = QAngle(2, -54, 0)
    },
	{
        name = "Saws",
        origin = Vector(4180, -3230, -4410),
        angles = QAngle(12, -43, 0)
    },
	{
        name = "Blueprint",
        origin = Vector(-8874, 7132, -10013),
        angles = QAngle(4, -115, 0)
    },
	{
        name = "A B C",
        origin = Vector(1815, 4353, -11483),
        angles = QAngle(3, -20, 0)
    },
	{
        name = "Upgrade Station",
        origin = Vector(2281, 2645, -11555),
        angles = QAngle(-3, -120, 0)
    },
	{
        name = "Box",
        origin = Vector(6592, 2647, -6329),
        angles = QAngle(3, 178, 0)
    },
	{
        name = "Witch",
        origin = Vector(7779, 2858, -6350),
        angles = QAngle(53, -8, 0)
    },
	{
        name = "Chimney",
        origin = Vector(8401, -6321, -3758),
        angles = QAngle(7, -28, 0)
    },
	{
        name = "Water Lily",
        origin = Vector(10769, -2508, -6435),
        angles = QAngle(23, -104, 0)
    }
]

selected_spot <- RandomElement(spots)

minigame <- Ware_MinigameData
({
	name           = "Go and Spectate"
	author         = ["PedritoGMG"]
	description    = format("Change the Camera to %s!", selected_spot.name)
	music          = "digging"
	duration       = 11.0
	end_delay      = 1.0
    location       = "home"
})

function OnStart()
{
	foreach (spot in Shuffle(spots))
	{
		spot.camera <- Ware_SpawnEntity("info_observer_point",
		{
			origin = spot.origin
			angles = spot.angles
			fov    = 90
		})
	}

	foreach (player in Ware_Players)
    {
		Ware_ChatPrint(player, "{color}HINT:{color} Use MOUSE1 and MOUSE2 to cycle cameras!", COLOR_GREEN, TF_COLOR_DEFAULT)
        KillPlayerSilently(player)
    }

	//Fix | the text disappears when KillPlayerSilently
	local spot_name = format(" %s ", selected_spot.name)
	Ware_CreateTimer(@() Ware_ShowMinigameText(null, spot_name, "255 255 0"), 0.1)
}

function OnEnd()
{
	local spot_camera = selected_spot.camera
	foreach (player in Ware_Players)
	{
		if (GetPropEntity(player, "m_hObserverTarget") == spot_camera)
			Ware_PassPlayer(player, true)
	}
}