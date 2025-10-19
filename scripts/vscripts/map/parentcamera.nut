// hack to allow parented point_viewcontrols in typing boss 
// (can't place these from Hammer)

function Precache()
{
	// this is needed to prevent SourceTV crashing!!!
	// it does not check if info_observer_points get deleted
	self.KeyValueFromString("classname", "ware_observerpoint")
}

function OnPostSpawn()
{
	local camera = SpawnEntityFromTableSafe("point_viewcontrol",
	{
		classname  = "ware_viewcontrol" // don't preserve
		targetname = self.GetName()
		origin     = self.GetOrigin()
		angles     = self.GetAbsAngles()
		spawnflags = 8
	})
	camera.SetMoveType(0, 0)
	
	local parent = self.GetMoveParent()
	if (parent)
		SetEntityParent(camera, parent)	

	self.Kill()
}