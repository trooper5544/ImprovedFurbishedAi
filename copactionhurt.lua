dofile(ModPath .. "core.lua")

-- After getting hurt, return to hold position
Hooks:PostHook(CopActionHurt, "on_exit", "betterjokers_copactionhurt_onexit_holdposition", function(self)
    if Network:is_client() or not alive(self._unit) or not self._unit:brain().is_holding or not self._unit:brain().hold_pos then
        return
    end

    self._unit:brain().is_holding = false
    local objective = BetterJokers:GetHoldObjectiveForUnit(self._unit)
    self._unit:brain():set_objective(objective)
end)
