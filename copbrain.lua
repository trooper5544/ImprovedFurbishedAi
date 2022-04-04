dofile(ModPath .. "core.lua")

-- On convert, register the unit as a joker
Hooks:PostHook(CopBrain, "convert_to_criminal", "betterjokers_registerjoker", function(self, mastermind_criminal)
    self._unit:base().is_convert = true
    self.is_convert = true

    table.insert(BetterJokers.converts, self._unit)

    -- Give jokers the same access type and movement speed as bots
    local chartweak = deep_clone(self._logic_data.char_tweak)
    chartweak.access = 'teamAI1'
    chartweak.crouch_move = false
    chartweak.move_speed = tweak_data.character.american.move_speed
    chartweak.suppression = tweak_data.character.american.suppression
    self._logic_data.char_tweak = chartweak
    self._logic_data.important = true

    self._unit:character_damage()._char_tweak = chartweak
    self._unit:movement()._tweak_data = chartweak
    if self._unit:movement()._action_common_data then
        self._unit:movement()._action_common_data.char_tweak = chartweak
    end

    -- Assign the converter's peer ID as owner
    if alive(mastermind_criminal) then
        local peer_id = managers.network:session():peer_by_unit(mastermind_criminal):id() or 1
        self.joker_owner_peer_id = peer_id
        self._unit:base().joker_owner_peer_id = peer_id
        BetterJokers:ApplyConvertedContour(self._unit)

        -- Set exclusive access ID
        local my_peer_id = LuaNetworking:LocalPeerID()
        if peer_id == my_peer_id and BetterJokers.settings.joker_exclusive_access then
            self._unit:base().exclusive_owner_peer_id = my_peer_id
        elseif peer_id ~= my_peer_id and BetterJokers.exclusiveAccessPeers[peer_id] then
            self._unit:base().exclusive_owner_peer_id = peer_id
        end
    end
end)

-- Not *exactly* sure what importance is for.
-- I initially thought it made them not killed by map elements but now it seems it's more closely related to their objectives.
local copbrain_setimportant_orig = CopBrain.set_important
function CopBrain:set_important(state)
	if self.is_convert then
		state = true
    end

	return copbrain_setimportant_orig(self, state)
end
