dofile(ModPath .. "core.lua")

-- If a converted cop dies, unregister them from the converts list.
Hooks:PostHook(CopDamage, "_on_death", "BetterJokers_RemoveJokerOnDeath", function(self)
    if self._unit:base().is_convert and BetterJokers.converts then
        for i, unit in pairs(BetterJokers.converts) do
            if unit == self._unit then
                table.remove(BetterJokers.converts, i)
            end
        end
    end
end)

if BetterJokers.settings.joker_show_health then
    -- On damage received, update their health bar
    Hooks:PostHook(CopDamage, "_on_damage_received", "betterjokers_copdamaged_updatehealthbar", function(self)
        if not self._unit:base().infobar then
            return
        end

        local healthbar = self._unit:base().bj_healthbar
        if healthbar and alive(healthbar) then
            healthbar:set_color(Color(1, self._health_ratio, 1, 1))
        end
    end)

    -- Whenever a cop is killed, check if the cop was a joker. If so, increment their killcounter
    Hooks:PostHook(CopDamage, "chk_killshot", "betterjokers_copdamage_killshot_incrementkills", function(self, attacker_unit)
        if not attacker_unit or not alive(attacker_unit) or not attacker_unit:base() or not attacker_unit:base().is_convert or not attacker_unit:base().bj_kills then
            return
        end

        attacker_unit:base().bj_kills = attacker_unit:base().bj_kills + 1
        BetterJokers:UpdateKillCounter(attacker_unit)
    end)
end
