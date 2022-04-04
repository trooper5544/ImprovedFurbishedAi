-- Don't allow cops to walk anywhere if they're being told to hold position
local copmovement_checkactionforbidden_orig = CopMovement.chk_action_forbidden
function CopMovement:chk_action_forbidden(action_type)

    if action_type == "walk" and self._unit:brain().is_holding then
        return true
    end

    return copmovement_checkactionforbidden_orig(self, action_type)
end
