-- Make joker objectives higher priority
local coplogictravel_pathingpriority_orig = CopLogicTravel.get_pathing_prio
function CopLogicTravel.get_pathing_prio(data)
    local priority = coplogictravel_pathingpriority_orig(data)

	if priority and data.unit and data.unit:base().is_convert then
		priority = priority + 1
	end
	return priority
end

-- Disallow strafing when they're too far from their objective
local coplogictravel_check_request_action_walk_to_advance_pos_orig = CopLogicTravel._chk_request_action_walk_to_advance_pos
function CopLogicTravel._chk_request_action_walk_to_advance_pos(data, my_data, speed, end_rot, no_strafe, pose, end_pose)
	if data.unit:base().is_convert then
		local objective = data.unit:brain():objective()
		if not objective then
            return coplogictravel_check_request_action_walk_to_advance_pos_orig(data, my_data, speed, end_rot, no_strafe, pose, end_pose)
        end

		if data.unit:brain().hold_pos then
			no_strafe = mvector3.distance(data.unit:position(), data.unit:brain().hold_pos) > 3000
		elseif objective.type == "follow" then
			no_strafe = mvector3.distance(data.unit:position(), objective.follow_unit:position()) > 3000
		end
	end

	return coplogictravel_check_request_action_walk_to_advance_pos_orig(data, my_data, speed, end_rot, no_strafe, pose, end_pose)
end
