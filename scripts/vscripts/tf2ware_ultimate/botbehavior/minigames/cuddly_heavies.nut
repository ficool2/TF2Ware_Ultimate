// This function calculates the closest point on an Oriented Bounding Box (OBB) to a given point.
// -- NO CHANGES NEEDED IN THIS FUNCTION --
function ClosestPointOnOBB(point, origin, angles, mins, maxs)
{
    local forward = angles.Forward()
    local right = angles.Left()
    local up = angles.Up()
    
    local localPoint = point - origin
    local localX = localPoint.Dot(forward)
    local localY = localPoint.Dot(right)
    local localZ = localPoint.Dot(up)
    
    localX = Clamp(localX, mins.x, maxs.x)
    localY = Clamp(localY, mins.y, maxs.y)
    localZ = Clamp(localZ, mins.z, maxs.z)
    
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
                local dist = VectorDistance2D(botOrigin, other.GetOrigin())
                if (dist < lowest_dist)
                {
                    lowest_dist = dist
                    prop = other
                }
            }
        }
    }
    else
    {
        // Simple fleeing logic for Mission 1
        if (!("prop" in data) || data.prop == null || !data.prop.IsAlive())
        {
            local arr = Shuffle(Ware_MinigamePlayers)
            foreach (other in arr)
            {
                if (other != bot && other.IsValid() && other.IsAlive() && other.GetTeam() != bot.GetTeam())
                {
                    data.prop <- other; break;
                }
            }
        }
        prop = data.prop
        if (prop && prop.IsValid() && bot.IsAlive()) {
            local loco = bot.GetLocomotionInterface()
            local dest = prop.GetOrigin() + (prop.GetAbsVelocity() * 0.5)
            loco.Approach(dest, 999.9)
            loco.FaceTowards(dest)
        }
        return // Exit early for mission 1
    }

    if (prop && bot.IsAlive())
    {
        // --- CONFIGURATION ---
        local combatDist = 500.0, personalSpace = 350.0, wallAvoidanceDist = 150.0
        local orbitWeight = 1.0, retreatWeight = 3.0, wallAvoidanceWeight = 5.0

        // --- 1. CALCULATE CONTEXT ---
        local toEnemy = prop.GetOrigin() - botOrigin; toEnemy.z = 0
        local distToEnemy = toEnemy.Length()
        local dirToEnemy = (distToEnemy > 0) ? toEnemy * (1.0 / distToEnemy) : Vector(1,0,0)

        // --- 2. CALCULATE STEERING FORCES ---
        local totalForce = Vector(0,0,0)
        
        // A. Orbit Force
        if (!("strafeTimer" in data)) data.strafeTimer <- 0
        if (!("strafeDir" in data)) data.strafeDir <- (bot.GetEntityIndex() % 2 == 0) ? 1.0 : -1.0
        if (Time() > data.strafeTimer) { data.strafeDir *= -1.0; data.strafeTimer = Time() + RandomFloat(2.0, 4.0); }
        local orbitDir = Vector(dirToEnemy.y, -dirToEnemy.x, 0) * data.strafeDir
        local distCorrection = (distToEnemy - combatDist) / combatDist
        local orbitForce = (orbitDir - (dirToEnemy * distCorrection)); orbitForce.Norm()
        totalForce += orbitForce * orbitWeight
        
        // B. Retreat Force
        if (distToEnemy < personalSpace)
        {
            local retreatStrength = (1.0 - (distToEnemy / personalSpace))
            totalForce += (dirToEnemy * -1.0) * retreatWeight * retreatStrength
        }

        // C. Wall Avoidance Force
        local walls = Ware_MinigameLocation.walls
        local wallRepulsion = Vector(0,0,0)
        foreach (wall in walls)
        {
            if (!wall.IsValid()) continue
            local closestPoint = ClosestPointOnOBB(botOrigin, wall.GetOrigin(), wall.GetAbsAngles(), wall.GetBoundingMinsOriented(), wall.GetBoundingMaxsOriented())
            local distToWall = VectorDistance(botOrigin, closestPoint)
            if (distToWall < wallAvoidanceDist)
            {
                local repulsionStrength = (1.0 - (distToWall / wallAvoidanceDist))
                local repulsionDir = botOrigin - closestPoint; repulsionDir.z = 0; repulsionDir.Norm()
                wallRepulsion += repulsionDir * repulsionStrength
            }
        }
        if (wallRepulsion.LengthSqr() > 0.1) { wallRepulsion.Norm(); totalForce += wallRepulsion * wallAvoidanceWeight; }
       
        // --- 3. FINALIZE MOVEMENT DIRECTION ---
        local finalMoveDir
        if (totalForce.LengthSqr() > 0.1) { totalForce.Norm(); finalMoveDir = totalForce; }
        else { finalMoveDir = Vector(0,0,0); } // Set to zero if forces are balanced

        // --- 4. *** NEW: UNSTUCK LOGIC *** ---
        // This overrides the forces if the bot stops moving.
        if (!("stuckFrames" in data)) data.stuckFrames <- 0
        
        if (bot.GetAbsVelocity().LengthSqr() < 100) { // 10 units/sec is very slow
             data.stuckFrames++
        } else {
             data.stuckFrames = 0
        }

        if (data.stuckFrames > 15) // If stuck for ~1/4 second
        {
            // Find the closest wall to slide along
            local closestWall = null
            local minWallDist = 9999
            foreach(wall in walls) {
                if (!wall.IsValid()) continue
                local dist = VectorDistance(botOrigin, wall.GetOrigin())
                if (dist < minWallDist) { minWallDist = dist; closestWall = wall; }
            }
            
            if (closestWall) {
                // Calculate a direction parallel to the wall
                local wall = closestWall
                local wallAngles = wall.GetAbsAngles()
                local wallSize = wall.GetBoundingMaxsOriented() - wall.GetBoundingMinsOriented()
                local wallParallelDir = (wallSize.x > wallSize.y) ? wallAngles.Forward() : wallAngles.Left()
                wallParallelDir.z = 0; wallParallelDir.Norm()
                
                // Choose the slide direction that leads away from the enemy
                if (wallParallelDir.Dot(dirToEnemy) > 0) { wallParallelDir *= -1.0; }
                
                finalMoveDir = wallParallelDir // OVERRIDE the force-based direction
                data.stuckFrames = 0 // Reset counter after we've made a decision
            }
        }
        
        if (finalMoveDir.LengthSqr() < 0.1) return // No valid movement, do nothing.

        // Apply momentum for smoother movement
        local scope = bot.GetScriptScope()
        if (!("lastMoveDir" in scope)) scope.lastMoveDir <- finalMoveDir
        finalMoveDir = (finalMoveDir * 0.6) + (scope.lastMoveDir * 0.4)
        finalMoveDir.Norm()
        scope.lastMoveDir = finalMoveDir

        // --- 5. SET AND VALIDATE DESTINATION ---
        local move_dist = 650
        local idealDest = botOrigin + finalMoveDir * move_dist
        local finalDest = idealDest
        local safetyMargin = 32.0

        foreach (wall in walls)
        {
            if (!wall.IsValid()) continue
            local closestPointOnWall = ClosestPointOnOBB(finalDest, wall.GetOrigin(), wall.GetAbsAngles(), wall.GetBoundingMinsOriented(), wall.GetBoundingMaxsOriented())
            if (VectorDistance(finalDest, closestPointOnWall) < 1.0)
            {
                local pushoutNormal = botOrigin - closestPointOnWall
                pushoutNormal.z = 0; pushoutNormal.Norm()
                finalDest = closestPointOnWall + pushoutNormal * safetyMargin
            }
        }
        
        // --- 6. EXECUTE ---
        local loco = bot.GetLocomotionInterface()
        BotLookAt(bot, finalDest, 9999.0, 9999.0)
        loco.FaceTowards(finalDest)
        DebugDrawLine(botOrigin, finalDest, 0, 255, 0, true, 0.125)
        loco.Approach(finalDest, 999.9);
    }
}