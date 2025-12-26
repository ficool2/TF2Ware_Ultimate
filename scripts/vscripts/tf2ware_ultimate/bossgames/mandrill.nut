minigame <- Ware_MinigameData
({
	name          = "Mandrill Maze"
	author        = ["Mecha the Slag", "ficool2"]
	description   = "Escape the Mandrill Maze!"
	duration      = 83.0
	end_delay     = 1.5
	location      = "mandrill"
	music         = "mandrill"
	start_pass    = false
})

banana_model <- "models/tf2ware_ultimate/banana.mdl"

first <- true

function OnPrecache()
{
	PrecacheModel(banana_model)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_HEAVYWEAPONS, null)
	
	foreach (player in Ware_MinigamePlayers)
	{
		player.SetCustomModel(banana_model)
		Ware_TogglePlayerWearables(player, false)
	}
	
	EntFire("mandrill_train", "StartForward")
	
	local block = FindByName(null, "mandrill_block")
	local block_model = block.GetModelName()
	local block_size = 256.0
	
	local maze = GenerateMaze(21, 13, 4, 10)
	local maze_origin = Ware_MinigameLocation.maze * 1.0
	maze_origin.x += block_size * 0.5
	maze_origin.y += block_size * 0.5

	foreach (y, row in maze)
	{
		foreach (x, cell in row)
		{
			//print(cell.tochar() + " ")	
			if (cell == '#')
			{
				local block_pos = maze_origin * 1.0
				block_pos.x += block_size * x
				block_pos.y += block_size * y
				
				Ware_SpawnEntity("func_brush",
				{
					origin         = block_pos
					model          = block_model
					disableshadows = true
					disablereceiveshadows = true
				})
			}
		}
		//print("\n")
	}
}

// wilson's algorithm
function GenerateMaze(width, height, start_y, end_y) 
{
	// S start
	// E end
	// # wall
	// . empty
	
	local maze = array(height)
	for (local y = 0; y < height; y++) 
		maze[y] = array(width, '#')

	local directions = 
	[
		{x = 0,	 y = -1}, // up
		{x = 0,	 y =  1}, // down
		{x = -1, y =  0}, // left
		{x = 1,	 y =  0}  // right
	]

	local start_x = width - 1
	maze[start_y][start_x] = '.'
	
	// all possible 2x2 cells
	local unvisited = []
	for (local y = 0; y < height; y += 2) 
	{
		for (local x = 0; x < width; x += 2) 
		{
			if (!(x == start_x && y == start_y)) 
				unvisited.append({x = x, y = y})
		}
	}
	
	// wilson's
	while (0 in unvisited)
	{
		local current = unvisited[0]
		local path = [{x = current.x, y = current.y}]
		while (maze[current.y][current.x] != '.') 
		{
			local dir = directions[RandomInt(0, 3)]
			local nx = current.x + dir.x * 2
			local ny = current.y + dir.y * 2	
			if (nx >= 0 && ny >= 0 && nx < width && ny < height) 
			{
				current = {x = nx, y = ny}
				
				// prevent loops
				local loop = -1
				foreach (i, p in path)
				{
					if (p.x == current.x && p.y == current.y) 
					{
						loop = i
						break
					}
				}
				
				if (loop != -1) 
					path.resize(loop + 1)
				else 
					path.append(current)
			}
		}
		
		// carve
		local path_end_len = path.len() - 1
		for (local i = 0; i < path_end_len; i++) 
		{
			local x = path[i].x
			local y = path[i].y
			local nx = path[i + 1].x
			local ny = path[i + 1].y
			
			maze[y][x] = '.'
			maze[ny][nx] = '.'
			maze[y + (ny - y) / 2][x + (nx - x) / 2] = '.'
			
			foreach (j, u in unvisited)
			{
				if (u.x == x && u.y == y) 
				{
					unvisited.remove(j)
					break
				}
			}
		}
	}

	// mark start/end points
	maze[start_y][start_x] = 'S'
	maze[end_y][0] = 'E'
	
	return maze
}

function OnUpdate()
{
	local threshold = Ware_MinigameLocation.start.x - 6144.0
	foreach (player in Ware_MinigamePlayers)
	{
		if (player.IsAlive() && player.GetOrigin().x < threshold)
		{
			Ware_PassPlayer(player, true)					
			if (first)
			{
				Ware_ChatPrint(null, "{player} {color}made it to the goal first!", player, TF_COLOR_DEFAULT)
				Ware_GiveBonusPoints(player)
				first = false
			}
		}
	}
}

function OnEnd()
{
	EntFire("mandrill_train", "TeleportToPathTrack", "camp_move1")
	EntFire("mandrill_train", "Stop", "")
}

function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
	{
		player.SetCustomModel("")
		Ware_TogglePlayerWearables(player, true)
	}
}

function OnCheckEnd()
{
	return Ware_GetPassedPlayers(false, true).len() == 0
}