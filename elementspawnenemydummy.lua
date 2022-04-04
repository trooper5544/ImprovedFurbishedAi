-- Prevent jokers from being killed off in beneath the mountain (and others)
-- Sadly the whole function has to be replaced
local current_level_id = Global.game_settings and Global.game_settings.level_id

if not current_level_id then
	return
end

-- List of heists that should simply not kill off the jokers.
-- They can figure it out for themselves here, either they take a shortcut or an alternative route that the bots also take
local levels_intercept_jokers = {
	hox_1 = true, -- Hoxton Breakout Day 1 garage door
	pbr = true, -- Beneath The Mountain first airlock
	Berry = true -- Probably also beneath the mountain, I'm not sure which one to take
}

-- List of heists that should warp the jokers towards the player.
local levels_warp_jokers = {
	mex = true -- Border Crossing
}

if levels_intercept_jokers[current_level_id] then
	function ElementSpawnEnemyDummy:unspawn_all_units()
		for _, unit in ipairs(self._units) do
			-- Don't kill jokers on these heists
			if alive(unit) and not unit:base().is_convert then
				unit:brain():set_active(false)
				unit:base():set_slot(unit, 0)
			end
		end
	end
elseif levels_warp_jokers[current_level_id] then
	function ElementSpawnEnemyDummy:unspawn_all_units()
		for _, unit in ipairs(self._units) do
			if alive(unit) then
				if unit:base().is_convert then
					-- Warp joker to player
					local player_unit = managers.player and managers.player:player_unit()
					if player_unit and unit:movement() then
						unit:movement():set_position(player_unit:position())
					end
				else
					unit:brain():set_active(false)
					unit:base():set_slot(unit, 0)
				end
			end
		end
	end
end