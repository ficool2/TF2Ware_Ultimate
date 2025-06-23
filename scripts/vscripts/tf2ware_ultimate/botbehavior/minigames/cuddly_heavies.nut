

function ClosestPointOnOBB(point, origin, angles, mins, maxs)
{
    // Get orthogonal basis vectors from wall angles
    local forward = angles.Forward()
    local right = angles.Left()
    local up = angles.Up()
    
    // Transform point to wall's local space
    local localPoint = point - origin
    local localX = localPoint.Dot(forward)
    local localY = localPoint.Dot(right)
    local localZ = localPoint.Dot(up)
    
    // Clamp local coordinates to OBB bounds
    localX = Clamp(localX, mins.x, maxs.x)
    localY = Clamp(localY, mins.y, maxs.y)
    localZ = Clamp(localZ, mins.z, maxs.z)
    
    // Transform clamped point back to world space
    return origin + forward * localX + right * localY + up * localZ
}

function OnUpdate(bot)
{
    local prop
    local lowest_dist = 999999
    local botOrigin = bot.GetOrigin()
    local mission = Ware_GetPlayerMission(bot)

    local data = Ware_GetPlayerMiniData(bot)

    // Find nearest enemy player
    if (mission == 0)
    {
        for (local other; other = FindByClassnameWithin(other, "player", bot.GetOrigin(), 4000);)
        {
            if (other != bot && other.IsValid() && other.IsAlive() && other.GetTeam() != bot.GetTeam())
            {
                local otherOrigin = other.GetOrigin()
                local dist = VectorDistance2D(botOrigin, otherOrigin)
                if (dist < lowest_dist)
                {
                    lowest_dist = dist
                    prop = other
                    data.corner <- 0
                }
            }
        }
    }
    else
    {
        if((!("prop" in data) || data.prop == null))
        {
            local arr = Shuffle(Ware_MinigamePlayers)
            foreach (other in arr)
            {
                if (other != bot && other.IsValid() && other.IsAlive() && other.GetTeam() != bot.GetTeam())
                {
                    data.prop <- other
                }
            }
        }
        prop = data.prop
    }


  
    if (prop && bot.IsAlive())
    {
        local propOrigin = prop.GetOrigin()
        local escape_dist = 650
        local escapeDir = botOrigin - propOrigin
        escapeDir.z = 0
        escapeDir.Norm()

        local dest = botOrigin
        local walls = Ware_MinigameLocation.walls  // Access wall array
        local closestWall = null
        local minWallDist = 200  // Distance threshold for wall following

        local propOrigin = prop.GetOrigin()
        local approachDist = 650
        local dest = botOrigin

        // Calculate approach vector to enemy
        local approachVec = propOrigin - botOrigin
        approachVec.z = 0
        
        // Initialize dodge direction if not set
        if (!("dodgeSide" in data))
            data.dodgeSide <- (bot.GetEntityIndex() % 2 == 0) ? 1 : -1

        // Calculate dodge angle (30 degrees)
        local angle = 120 * data.dodgeSide * (3.14159 / 180.0)
        local cosA = cos(angle)
        local sinA = sin(angle)
        
        // Rotate approach vector to create dodge direction
        local dodgeDir = Vector(
            approachVec.x * cosA - approachVec.y * sinA,
            approachVec.x * sinA + approachVec.y * cosA,
            0
        )
        dodgeDir.Norm()

        // Mission-specific movement
        if (mission == 0)
        {
            // Set destination using dodge direction
            dest = botOrigin + dodgeDir * approachDist
            
            local repulsion = Vector(0, 0, 0)
            local closestPointOnWall = null
            local nearWalls = []
            local repulsionNorm = null
            local repulsionStrength = 0

            foreach (wall in walls)
            {
                if (!wall.IsValid()) continue

                // Get wall properties for OBB calculation
                local wallOrigin = wall.GetOrigin()
                local wallAngles = wall.GetAbsAngles()
                local wallMins = wall.GetBoundingMinsOriented()
                local wallMaxs = wall.GetBoundingMaxsOriented()

                // Calculate closest point on wall's OBB to bot
                local closestPoint = ClosestPointOnOBB(botOrigin, wallOrigin, wallAngles, wallMins, wallMaxs)
                local wallDist = VectorDistance2D(botOrigin, closestPoint)


                // Apply repulsion if bot is near the wall
                if (wallDist < 100)
                {
                    local dir = botOrigin - closestPoint
                    dir.z = 0
                    if (dir.LengthSqr() > 0.001) {
                        dir.Norm()
                        repulsion += dir * (100 - wallDist)
                        nearWalls.append({wall = wall, point = closestPoint, normal = dir})
                    }
                }

                // Update closest wall for wall-following
                if (wallDist < minWallDist)
                {
                    minWallDist = wallDist
                    closestWall = wall
                    closestPointOnWall = closestPoint
                }
            }
            repulsionStrength = repulsion.Length()
            if (repulsionStrength > 0) {
                repulsionNorm = repulsion * (1.0 / repulsionStrength)
            }

            // Calculate movement direction if near a wall
            if (closestWall && minWallDist < 200)
            {
                DebugDrawLine(botOrigin, closestPointOnWall, 0, 255, 0, true, 0.125)
                // Get wall's actual orientation vectors
                local wallAngles = closestWall.GetAbsAngles()
                local wallForward = wallAngles.Forward()
                local wallRight = wallAngles.Left()
    
                // Determine primary wall axis (longest dimension)
                local wallMins = closestWall.GetBoundingMinsOriented()
                local wallMaxs = closestWall.GetBoundingMaxsOriented()
                local wallSize = wallMaxs - wallMins
    
                // Use longest axis for wall-following direction
                local wallParallel = wallSize.x > wallSize.y ? wallForward : wallRight
    
                // Flatten to horizontal and normalize
                wallParallel = Vector(wallParallel.x, wallParallel.y, 0)
                if (wallParallel.LengthSqr() > 0.0001) {
                    wallParallel.Norm()
                } else {
                    wallParallel = Vector(1, 0, 0)  // Fallback if invalid vector
                }
    
                // Choose direction away from enemy
                if (escapeDir.Dot(wallParallel) < 0) {
                    wallParallel = wallParallel.Scale(-1)  // Invert direction if needed
                }
    
                // DECISIVE CORNER ESCAPE - PHYSICS BASED
    
                local moveDir = null
                local cornerEscapeVec = Vector(0,0,0)
    
                // 1. Detect corner situations (2+ walls close together)
                if (nearWalls.len() >= 2) 
                {
                    data.corner += 2
    
                    // Calculate combined escape direction from all nearby walls
                    foreach (wallData in nearWalls) 
                    {
                        // Get wall's forward vector (long axis)
                        local wallAng = wallData.wall.GetAbsAngles()
                        local wallForward = wallAng.Forward()
                        wallForward.z = 0
                        if (wallForward.LengthSqr() > 0.001) wallForward.Norm()
    
                        // Add perpendicular to wall normal (tangential escape)
                        local tangent = Vector(-wallData.normal.y, wallData.normal.x, 0)
                        cornerEscapeVec += tangent
                    }
    
                    // Choose direction away from enemy
                    if (cornerEscapeVec.Dot(escapeDir) < 0) {
                        cornerEscapeVec = cornerEscapeVec.Scale(-1)
                    }
    
                    cornerEscapeVec.Norm()
                }
                else
                {
                    if(data.corner > 0)
                        data.corner--
                }
    
                // 2. DECISIVE CORNER ESCAPE
                if (data.corner > 0 && cornerEscapeVec.LengthSqr() > 0.1) 
                {
                    // Use corner escape vector
                    moveDir = cornerEscapeVec
                    DebugDrawLine(botOrigin, botOrigin + moveDir.Scale(150), 255, 0, 0, true, 0.125)
                }
                else 
                {
                    // WALL FOLLOWING: Use wall-parallel direction
                    moveDir = wallParallel
                    DebugDrawLine(botOrigin, botOrigin + moveDir.Scale(150), 0, 0, 255, true, 0.125)
                }
                // 3. Apply minimum repulsion nudge to prevent wall sticking
                if (repulsionStrength > 1) {
                    local repulsionNorm = repulsion * 1
                    repulsionNorm.Norm()
                    moveDir = (moveDir * 0.9) + (repulsionNorm * 0.1)
                    moveDir.Norm()
                }
    
                // 4. SIMPLE MOMENTUM SYSTEM (only for non-repulsion moves)
                if (repulsionStrength <= 50) {
                    if (!("lastMoveDir" in bot.GetScriptScope())) {
                        bot.GetScriptScope().lastMoveDir <- moveDir
                    }
                    local lastMoveDir = bot.GetScriptScope().lastMoveDir
    
                    // Strong momentum blend
                    moveDir = (moveDir * 0.6) + (lastMoveDir * 0.4)
                    moveDir.Norm()
    
                    // Store for next frame
                    bot.GetScriptScope().lastMoveDir = moveDir
                } else {
                    // Reset momentum during repulsion escape
                    if ("lastMoveDir" in bot.GetScriptScope()) {
                        bot.GetScriptScope().lastMoveDir = moveDir
                    }
                }
    
                // 5. SET DESTINATION
                if (nearWalls.len() == 1)
                    dest = botOrigin + moveDir.Scale(escape_dist)
                DebugDrawLine(botOrigin, dest, 255, 165, 0, true, 0.125) // Orange: Final path
    
                // 6. IMPROVED STUCK ESCAPE WITH CORNER DETECTION
                local velocity = bot.GetAbsVelocity().Length2D()
                if (data.corner > 0) 
                {
                    local escapeVec = null
    
                    if (data.corner > 0) {
                        // Use pre-calculated corner escape vector
                        escapeVec = cornerEscapeVec
                    }
                    else if (nearWalls.len() > 0) {
                        // Single wall escape - use tangent to closest wall
                        local closestWallData = nearWalls[0]
                        escapeVec = Vector(-closestWallData.normal.y, closestWallData.normal.x, 0)
    
                        // Ensure escape points away from walls
                        if ((botOrigin + escapeVec*50 - closestWallData.point).Length2D() < 40) {
                            escapeVec = escapeVec.Scale(-1)
                        }
                    }
                    else {
                        // Fallback: use enemy escape direction
                        escapeVec = escapeDir
                    }
    
                    escapeVec.Norm()
                    dest = botOrigin + escapeVec * (escape_dist * 1.5)
                    DebugDrawLine(botOrigin, dest, 255, 255, 0, true, 0.125)
    
                    // Add jump to escape
                    if (RandomInt(0,3) == 0) {
                    //    bot.PressJumpButton(0.1)
                    }
    
                }
    
                }
                else 
                {
                    // Reset direction memory when not near walls
                    if ("lastMoveDir" in bot.GetScriptScope()) {
                        bot.GetScriptScope().lastMoveDir = escapeDir
                    }
                    //dest = botOrigin + escapeDir.Scale(escape_dist)
                }
        }
        // Mission 1: Maintain original fleeing behavior
        else if (mission == 1)
        {
            dest = propOrigin + (prop.GetAbsVelocity() * 0.5)

            if (!prop.IsValid() || !prop.IsAlive())
            {
                data.prop = null
            }
        }

        // Execute movement and aiming
        BotLookAt(bot, dest, 100.0, 100.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(dest)
        DebugDrawLine(botOrigin, dest, 0, 0, 255, true, 0.125)  // Blue: Default path

        // Movement conditions
        if (mission == 1 || (mission == 0 && VectorDistance2D(botOrigin, propOrigin) < escape_dist))
            loco.Approach(dest, 999.0)

        // Occasional attack
        if (RandomInt(0,10) == 0)
            bot.PressFireButton(-1)
    }
}