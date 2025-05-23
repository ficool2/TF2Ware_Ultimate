
// Constants
const GRENADE_SPEED = 1216.6;    // hammer units/s
const GRAVITY = 800.0;           // hammer units/s²
const ITERATIONS = 5;            // Number of prediction refinements

function CalculateAimPosition(demomanOrigin, targetOrigin, targetVelocity) {
    local predictedPosition = targetOrigin;
    local timeOfFlight = 0.0;
    
    // Iteratively refine prediction
    for (local i = 0; i < ITERATIONS; i++) {
        local delta = predictedPosition - demomanOrigin;
        local horizontalDistance = Vector(delta.x, delta.y, 0).Length();
        
        // Calculate required pitch angle
        timeOfFlight = horizontalDistance / GRENADE_SPEED;
        local verticalOffset = delta.z + targetVelocity.z * timeOfFlight;
        
        // Solve vertical motion equation: verticalOffset = v0*sinθ*t - 0.5*g*t²
        local sinTheta = (verticalOffset + 0.5 * GRAVITY * timeOfFlight * timeOfFlight) / (GRENADE_SPEED * timeOfFlight);
        sinTheta = Clamp(sinTheta, -1.0, 1.0);
        
        // Update prediction with new time of flight
        timeOfFlight = horizontalDistance / (GRENADE_SPEED * cos(asin(sinTheta)));
        predictedPosition = targetOrigin + targetVelocity * timeOfFlight;
    }
    
    return predictedPosition;
}
/*
// Search for angle to land grenade near target
function FindGrenadeAim( me, target )
{
    local aimYaw
    local aimPitch
	local toTarget = target.GetCenter() - me.EyePosition()

	local anglesToTarget
	anglesToTarget = VectorAngles( toTarget )

	// start with current aim, in case we're already on target
	local eyeAngles = me.EyeAngles();
	local yaw = eyeAngles.y
	local pitch = eyeAngles.x

	local trials = 10;
	for( local t=0; t<trials; ++t )
	{
		// estimate impact spot
		local pipebombInitVel = 900.0
		local impactSpot = EstimateProjectileImpactPosition( me.EyePosition(), pitch, yaw, pipebombInitVel );

		// check if impactSpot landed near sentry
		local explosionRadius = 75.0
		if ( ( target.GetCenter() - impactSpot ).LengthSqr() < explosionRadius*explosionRadius )
		{
            local trace = 
			{
				start      = target.GetCenter()
				end        = impactSpot
				mask       = MASK_PLAYERSOLID_BRUSHONLY
				startsolid = false
			}	
			TraceLineEx(trace)	

			if ( trace.hit )
			{
                return [aimYaw, aimPitch]
			}
		}

		yaw = anglesToTarget.y + RandomFloat( -30.0, 30.0 );
		pitch = RandomFloat( -85.0, 85.0 );
	}
    
	return false;
}

function AngleVectors(angles) {
    // Assuming angles is an array [pitch, yaw, roll] and forward is a table {x, y, z}
    local forward = Vector()
        local right = Vector()
            local up = Vector()
    local pitch = angles.Pitch();
    local yaw = angles.Yaw();

    local yawRad = yaw * (3.14159265358979323846 / 180.0);
    local sy = sin(yawRad);
    local cy = cos(yawRad);

    local pitchRad = pitch * (3.14159265358979323846 / 180.0);
    local sp = sin(pitchRad);
    local cp = cos(pitchRad);

    local rollRad = pitch * (3.14159265358979323846 / 180.0);
    local sr = sin(rollRad);
    local cr = cos(rollRad);

	if (forward)
	{
		forward.x = cp*cy;
		forward.y = cp*sy;
		forward.z = -sp;
	}

	if (right)
	{
		right.x = (-1*sr*sp*cy+-1*cr*-sy);
		right.y = (-1*sr*sp*sy+-1*cr*cy);
		right.z = -1*sr*cp;
	}

	if (up)
	{
		up.x = (cr*sp*cy+-sr*-sy);
		up.y = (cr*sp*sy+-sr*cy);
		up.z = cr*cp;
	}

    return [forward, right, up]
}

function EstimateProjectileImpactPosition( eyepos, pitch, yaw, initVel )
{
	// copied from CTFWeaponBaseGun::FirePipeBomb()
	local vecForward, vecRight, vecUp
	local angles = QAngle( pitch, yaw, 0.0 );
	local arr = AngleVectors( angles )
    vecForward = arr[0]
    vecRight = arr[1]
    vecUp = arr[2]

	// we will assume bots never flip viewmodels
	local fRight = 8;
	local vecSrc = eyepos
	vecSrc += vecForward * 16.0 + vecRight * fRight + vecUp * -6.0

	local initVelScale = 0.9
	local vecVelocity = ( ( vecForward * initVel ) + ( vecUp * 200.0 ) ) * initVelScale

	local timeStep = 0.01
	local maxTime = 5.0
								 
	local pos = vecSrc;
	local lastPos = pos;
	local g = Convars.GetFloat("sv_gravity")


	// compute forward facing unit vector in horiz plane
	local alongDir = vecForward;
	alongDir.z = 0.0
	alongDir.Norm();

	local alongVel = sqrt( vecVelocity.x * vecVelocity.x + vecVelocity.y * vecVelocity.y );


    local trace
	for( local t = 0.0; t < maxTime; t += timeStep )
	{
		local along = alongVel * t;
		local height = vecVelocity.z * t - 0.5 * g * t * t;

		pos.x = vecSrc.x + alongDir.x * along;
		pos.y = vecSrc.y + alongDir.y * along;
		pos.z = vecSrc.z + height;

	    // do a trace to see if they're stuck at all
	    trace = 
	    {
	    	start      = lastPos
	    	end        = pos
	    	hullmin    = Vector(-8,-8,-8)
	    	hullmax    = Vector(8,8,8)
	    	mask       = MASK_PLAYERSOLID_BRUSHONLY
	    	startsolid = false
	    }

        TraceHull(trace)

		if ( trace.hit )
		{
			break;
		}

		lastPos = pos;
	}

	return trace.endpos;
}
*/
function OnUpdate(bot)
{
    local prop1 = FindByName(null, "boss4_goal")
    local prop2 = FindByName(null, "boss4_goal2")

    local y = bot.GetOrigin().y

    local dist1 = fabs(prop1.GetOrigin().y - y)
    local dist2 = fabs(prop2.GetOrigin().y - y)


    local prop
    prop = dist1 < dist2 ? prop1 : prop2
    //if(prop.GetOrigin)
    //local prop = FindByClassnameNearest("trigger_multiple", bot.GetOrigin(), 1500)
    if(prop)
    {
        //Ware_ChatPrint(null, "{int}", VectorDistance(prop.GetOrigin(), bot.GetOrigin()))
        //SetPropInt(bot, "m_nButtons", IN_FORWARD)

        local demomanPos = bot.EyePosition();
        local hoopPos = prop.GetCenter() + Vector(0,0,142.5);
        local hoopVelocity = prop.GetAbsVelocity();  // Adjust based on actual hoop movement

        //local dest = CalculateAimPosition(demomanPos, hoopPos, hoopVelocity)
        local z = VectorDistance(prop.GetCenter(), bot.EyePosition())
        local dest = prop.GetCenter() + Vector((prop.GetAbsVelocity().x * 1.1), 0, z/5.4)

        //local lol = FindGrenadeAim(bot, prop)
        //if(lol)
        //    bot.SetAbsAngles(QAngle(lol[1], lol[0], 0)); // 30° pitch, 180° yaw
        LookAt(bot, dest, 2000, 99999)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(dest)
        loco.Approach(prop.GetCenter(), 999.0);
        bot.PressFireButton(-1)

        //if (RandomInt(0,50) == 0)
        //    loco.Jump()
    }
}
function NormalizeAngle(target)
{
	target %= 360.0;
	if (target > 180.0)
		target -= 360.0;
	else if (target < -180.0)
		target += 360.0;
	return target;
}

function ApproachAngle(target, value, speed)
{
	target = NormalizeAngle(target);
	value = NormalizeAngle(value);
	local delta = NormalizeAngle(target - value);
	if (delta > speed)
		return value + speed;
	else if (delta < -speed)
		return value - speed;
	return target;
}

function LookAt(bot, target_pos, min_rate, max_rate)
{
    local cur_pos = bot.GetOrigin();
    local cur_vel = bot.GetAbsVelocity();
    local cur_speed = cur_vel.Length();
    local cur_eye_pos = bot.EyePosition();
    local cur_eye_ang = bot.EyeAngles();
    local cur_eye_fwd = cur_eye_ang.Forward();

    local dt = FrameTime();
    local dir = target_pos - cur_eye_pos;
    dir.Norm();
    local dot = cur_eye_fwd.Dot(dir);
    
    local desired_angles = VectorAngles(dir);	
    
    local rate_x = RemapValClamped(fabs(NormalizeAngle(cur_eye_ang.x) - NormalizeAngle(desired_angles.x)), 0.0, 180.0, min_rate, max_rate);
    local rate_y = RemapValClamped(fabs(NormalizeAngle(cur_eye_ang.y) - NormalizeAngle(desired_angles.y)), 0.0, 180.0, min_rate, max_rate);

    if (dot > 0.7)
    {
        local t = RemapValClamped(dot, 0.7, 1.0, 1.0, 0.05);
        local d = sin(1.57 * t); // pi/2
        rate_x *= d;
        rate_y *= d;
    }

    cur_eye_ang.x = NormalizeAngle(ApproachAngle(desired_angles.x, cur_eye_ang.x, rate_x * dt));
    cur_eye_ang.y = NormalizeAngle(ApproachAngle(desired_angles.y, cur_eye_ang.y, rate_y * dt));
        
    bot.SnapEyeAngles(cur_eye_ang);
}