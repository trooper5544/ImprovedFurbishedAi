dofile(ModPath .. "core.lua")

local criminalsmanager_charactercolorid_byunit_orig = CriminalsManager.character_color_id_by_unit
function CriminalsManager:character_color_id_by_unit(unit)
    local peer_id = unit:base() and unit:base().joker_owner_peer_id
	return peer_id or criminalsmanager_charactercolorid_byunit_orig(self, unit) or 5
end
