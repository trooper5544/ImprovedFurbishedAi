dofile(ModPath .. "core.lua")

-- Call jokers

local unit_type_minion = 22

local function state_is_bleedout(state_name)
    return state_name == "bleed_out" or state_name == "arrested" or state_name == "incapacitated" or state_name == "fatal"
end

local playerstandard_getinteractiontarget_orig = PlayerStandard._get_interaction_target
function PlayerStandard:_get_interaction_target(char_table, my_head_pos, cam_fwd)
    if not BetterJokers:HostHasMod() then
        return playerstandard_getinteractiontarget_orig(self, char_table, my_head_pos, cam_fwd)
    end

    -- If in bleedout, don't call jokers over
    local current_state_name = self._unit:movement():current_state_name()
    if state_is_bleedout(current_state_name) then
        return playerstandard_getinteractiontarget_orig(self, char_table, my_head_pos, cam_fwd)
    end

    local my_peer_id = managers.network:session():local_peer():id()
    for key, unit in pairs(managers.groupai:state():all_converted_enemies()) do
        if alive(unit) and (not unit:base().exclusive_owner_peer_id or unit:base().exclusive_owner_peer_id == my_peer_id) and not unit:character_damage():dead() then
            self:_add_unit_to_char_table(char_table, unit, unit_type_minion, 100000, true, true, 0.01, my_head_pos, cam_fwd)
        end
    end

	return playerstandard_getinteractiontarget_orig(self, char_table, my_head_pos, cam_fwd)
end

local playerstandard_getintimidationaction_orig = PlayerStandard._get_intimidation_action
function PlayerStandard:_get_intimidation_action(prime_target, char_table, amount, primary_only, detect_only, secondary)
    if not BetterJokers:HostHasMod() then
        return playerstandard_getintimidationaction_orig(self, prime_target, char_table, amount, primary_only, detect_only, secondary)
    end

    local current_state_name = self._unit:movement():current_state_name()
    if state_is_bleedout(current_state_name) then
        return playerstandard_getintimidationaction_orig(self, prime_target, char_table, amount, primary_only, detect_only, secondary)
    end

    if not prime_target or not prime_target.unit:base().is_convert then
        return playerstandard_getintimidationaction_orig(self, prime_target, char_table, amount, primary_only, detect_only, secondary)
    end

    local my_peer_id = managers.network:session():local_peer():id()
    if prime_target.unit:base().exclusive_owner_peer_id and prime_target.unit:base().exclusive_owner_peer_id ~= my_peer_id then
        return playerstandard_getintimidationaction_orig(self, prime_target, char_table, amount, primary_only, detect_only, secondary)
    end

    if secondary then
        BetterJokers:CallJokerHold(prime_target.unit)
        return "ai_stay", false, prime_target
    else
        BetterJokers:CallJokerOver(prime_target.unit)
        return "come", false, prime_target
    end
end
