dofile(ModPath .. "core.lua")

Hooks:PostHook(UnitNetworkHandler, "mark_minion", "betterjokers_unitnetwork_markminion_applycontours", function(self, unit, minion_owner_peer_id)

    -- I'm not paranoid, this really did happen
    if not unit or not alive(unit) then
        return
    end

    unit:base().joker_owner_peer_id = minion_owner_peer_id
    unit:brain().joker_owner_peer_id = minion_owner_peer_id
    unit:base().is_convert = true
    BetterJokers:ApplyConvertedContour(unit)

    -- Set exclusive access ID
    local my_peer_id = LuaNetworking:LocalPeerID()
    if minion_owner_peer_id == my_peer_id and BetterJokers.settings.joker_exclusive_access then
        unit:base().exclusive_owner_peer_id = my_peer_id
    elseif minion_owner_peer_id ~= my_peer_id and BetterJokers.exclusiveAccessPeers[minion_owner_peer_id] then
        unit:base().exclusive_owner_peer_id = minion_owner_peer_id
    end
end)
