dofile(ModPath .. "core.lua")

Hooks:PostHook(HuskCopBrain, "clbk_death", "betterjokers_huskcopbrain_clbkdeath_removelabel", function(self, my_unit, damage_info)
    if my_unit:base().infobar then
        BetterJokers:RemoveHealthCircle(my_unit)
    end
end)
