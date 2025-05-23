
function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("prop_physics", bot.GetOrigin(), 1000)
    if(prop)
    {
        //Ware_ChatPrint(null, "aaa")
        SetPropInt(bot, "m_nButtons", IN_FORWARD)
        LookAt(bot, prop.GetOrigin(), 350.0, 600.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(prop.GetOrigin())
        loco.Approach(prop.GetOrigin(), 999.0);
        if (RandomInt(0,50) == 0)
            loco.Jump()
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