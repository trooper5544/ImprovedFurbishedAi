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
	function ElementAIRemove:on_executed(instigator)
		if not self._values.enabled then
			return
		end

		if self._values.use_instigator then
			if alive(instigator) then
				if self._values.force_ragdoll and instigator:movement() then
					if instigator:character_damage().damage_mission then
						local backup_so = self._values.backup_so and self:get_mission_element(self._values.backup_so)

						instigator:character_damage():damage_mission({
							forced = true,
							damage = 1000,
							col_ray = {},
							backup_so = backup_so
						})
					end

					if instigator:movement()._active_actions and instigator:movement()._active_actions[1] and instigator:movement()._active_actions[1]:type() == "hurt" then
						instigator:movement()._active_actions[1]:force_ragdoll(true)
					end
				elseif self._values.true_death then
					if instigator:character_damage().damage_mission then
						local backup_so = self._values.backup_so and self:get_mission_element(self._values.backup_so)

						instigator:character_damage():damage_mission({
							forced = true,
							damage = 1000,
							col_ray = {},
							backup_so = backup_so
						})
					end
				else
					-- Prevent killing off jokers
					if not instigator:base().is_convert then
						instigator:brain():set_active(false)
						instigator:base():set_slot(instigator, 0)
					end
				end
			end
		else
			for _, id in ipairs(self._values.elements) do
				local element = self:get_mission_element(id)

				if self._values.true_death then
					element:kill_all_units()
				else
					element:unspawn_all_units()
				end
			end
		end

		ElementAIRemove.super.on_executed(self, instigator)
	end
elseif levels_warp_jokers[current_level_id] then
	function ElementAIRemove:on_executed(instigator)
		if not self._values.enabled then
			return
		end

		if self._values.use_instigator then
			if alive(instigator) then
				if self._values.force_ragdoll and instigator:movement() then
					if instigator:character_damage().damage_mission then
						local backup_so = self._values.backup_so and self:get_mission_element(self._values.backup_so)

						instigator:character_damage():damage_mission({
							forced = true,
							damage = 1000,
							col_ray = {},
							backup_so = backup_so
						})
					end

					if instigator:movement()._active_actions and instigator:movement()._active_actions[1] and instigator:movement()._active_actions[1]:type() == "hurt" then
						instigator:movement()._active_actions[1]:force_ragdoll(true)
					end
				elseif self._values.true_death then
					if instigator:character_damage().damage_mission then
						local backup_so = self._values.backup_so and self:get_mission_element(self._values.backup_so)

						instigator:character_damage():damage_mission({
							forced = true,
							damage = 1000,
							col_ray = {},
							backup_so = backup_so
						})
					end
				else
					-- Warp jokers
					if instigator:base().is_convert then
						local player_unit = managers.player and managers.player:player_unit()
						if player_unit and instigator:movement() then
							instigator:movement():set_position(player_unit:position())
						end
					else
						instigator:brain():set_active(false)
						instigator:base():set_slot(instigator, 0)
					end
				end
			end
		else
			for _, id in ipairs(self._values.elements) do
				local element = self:get_mission_element(id)

				if self._values.true_death then
					element:kill_all_units()
				else
					element:unspawn_all_units()
				end
			end
		end

		ElementAIRemove.super.on_executed(self, instigator)
	end
end