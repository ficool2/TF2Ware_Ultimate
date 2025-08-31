function OnUpdate(bot)
{
    local botOrigin = bot.GetOrigin()
    local loco = bot.GetLocomotionInterface()
    local data = Ware_GetPlayerMiniData(bot)

    // --- 1. Group pipes into walls and find the next wall ---
    local walls = {} // map of y_coord -> array of pipes
    for (local pipe; pipe = FindByName(pipe, "floppy_pipe");) 
    {
        local pipe_y_key = Round(pipe.GetOrigin().y / 100.0) * 100
        if (!(pipe_y_key in walls))
        {
            walls[pipe_y_key] <- []
        }
        walls[pipe_y_key].append(pipe)
    }

    local next_wall_y_actual = 99999 // Store the actual detected wall Y
    foreach (wall_y, pipes in walls)
    {
        // Shift detection backwards by 150 units (i.e., remove the forward shift)
        if (wall_y > botOrigin.y - 150 && wall_y < next_wall_y_actual)
        {
            next_wall_y_actual = wall_y
        }
    }

    // --- Apply user's offset: Pretend the pipes are 150y ahead ---
    // Now, next_wall_y is just the actual detected wall, as the shift is in detection.
    local next_wall_y = next_wall_y_actual 


    // --- 2. Restore dynamic gap_center_z and subtract 65 ---
    local gap_center_z = botOrigin.z // Default to current height
    if (next_wall_y_actual < 99999) // Use actual wall for gap calculation
    {
        local wall_pipes = walls[next_wall_y_actual] // Use actual wall for gap calculation
        wall_pipes.sort(@(a, b) a.GetOrigin().z <=> b.GetOrigin().z)
        
        if (wall_pipes.len() > 0)
        {
            local max_gap_size = 0
            local gap_z = (wall_pipes[0].GetOrigin().z + wall_pipes[wall_pipes.len() - 1].GetOrigin().z) / 2.0

            for (local i = 0; i < wall_pipes.len() - 1; i++)
            {
                local p1_z = wall_pipes[i].GetOrigin().z
                local p2_z = wall_pipes[i+1].GetOrigin().z
                local gap = p2_z - p1_z
                if (gap > max_gap_size)
                {
                    max_gap_size = gap
                    gap_z = p1_z + gap / 2.0
                }
            }
            gap_center_z = gap_z - 65.0 // Subtract 65 here
        }
    }

    // --- 3. Jump Logic ---
    // No grace period, jump always active if conditions met
    if (botOrigin.z < gap_center_z)
    {
        if (!("last_jump_time" in data) || Time() > data.last_jump_time + 0.4)
        {
            loco.Jump()
            data.last_jump_time <- Time()
        }
    }

    // --- 4. Debugging ---
    // Debug line should point to the *pretended* wall location
    DebugDrawLine(botOrigin, Vector(botOrigin.x, next_wall_y, gap_center_z), 0, 255, 0, true, 0.1)
    //if (!("last_debug_print" in data) || Time() > data.last_debug_print + 1.0)
    //{
        //Ware_ChatPrint(null, "Bot " + GetPlayerName(bot) + " | Pretend Y: " + next_wall_y + " | Actual Y: " + next_wall_y_actual + " | Gap Z: " + gap_center_z + " | Current Z: " + botOrigin.z)
    //    data.last_debug_print <- Time()
    //}
}