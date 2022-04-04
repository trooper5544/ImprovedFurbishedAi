-- Local functions and vars that are strewn around the PD2 source, why don't they just use these normally?
local mvec3_add = mvector3.add
local mvec3_cpy = mvector3.copy
local mvec3_dir = mvector3.direction
local mvec3_dis = mvector3.distance
local mvec3_mul = mvector3.multiply
local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_sub = mvector3.subtract
local mvec3_z = mvector3.z
local tmp_vec = Vector3()
local tmp_vec2 = Vector3()

-- BetterJokers' version of Goonmod's old waypoint binds
if not BJCustomWaypoints then
    _G.BJCustomWaypoints = {}

    BJCustomWaypoints.peer_waypoints = {}
    BJCustomWaypoints.own_waypoint = nil

    local function GetCrosshairRay(from, to, slot_mask)
        local viewport = managers.viewport
        if not viewport:get_current_camera() then
            return false
        end
    
        slot_mask = slot_mask or 'bullet_impact_targets'
    
        from = from or viewport:get_current_camera_position()
    
        if not to then
            to = tmp_vec1
            mvec3_set(to, viewport:get_current_camera_rotation():y())
            mvec3_mul(to, 20000)
            mvec3_add(to, from)
        end
    
        local col_ray = World:raycast('ray', from, to, 'slot_mask', managers.slot:get_mask(slot_mask))
        return col_ray
    end

    function BJCustomWaypoints:GetMyAimPos()
        local viewport = managers.viewport
        local camera_rot = viewport:get_current_camera_rotation()
        if not camera_rot then
            return false
        end
    
        local from = tmp_vec2
        mvec3_set(from, camera_rot:y())
        mvec3_mul(from, 20)
        mvec3_add(from, viewport:get_current_camera_position())
    
        local ray = Utils:GetCrosshairRay(from, nil, 'player_ground_check')
        if not ray or not ray.hit_position then
            return false
        end
    
        return ray.hit_position, ray
    end

    function BJCustomWaypoints:SetMyWaypoint()

        -- If we already have a waypoint set, remove it first and don't sync the removal to clients.
        -- When we set our new waypoint, other clients will automatically remove the old one.
        if self.own_waypoint then
            self:RemoveMyWaypointUnsynced()
        end

        local my_peer_id = LuaNetworking:LocalPeerID()

        local pos, ray = self:GetMyAimPos()

        if not pos or not ray then
            return
        end

        -- Sometimes pos components are nil, no idea why
        if not pos.x or not pos.y or not pos.z then
            return
        end

        if managers.hud then
            local data = {
                position = pos,
                icon = 'infamy_icon',
                distance = true,
                no_sync = false,
                present_timer = 0,
                state = 'present',
                radius = 50,
                color = tweak_data.preplanning_peer_colors[my_peer_id ~= 0 and my_peer_id or 1],
                blend_mode = 'add'
            }
            managers.hud:add_waypoint("BJ_CWP_" .. my_peer_id, data)
            LuaNetworking:SendToPeers("BJ_CWP_setwaypoint", Vector3.ToString(pos))
            self.own_waypoint = pos
        end
    end

    function BJCustomWaypoints:RemoveMyWaypoint()
        local my_peer_id = LuaNetworking:LocalPeerID()
        managers.hud:remove_waypoint("BJ_CWP_" .. my_peer_id)
        LuaNetworking:SendToPeers("BJ_CWP_removewaypoint", "removewaypoint")
        self.own_waypoint = nil
    end

    -- Unsynced version of remove own waypoint, used locally for when you add a new waypoint.
    -- This function is only called when you set a new waypoint, after which the other clients already remove it on their own.
    function BJCustomWaypoints:RemoveMyWaypointUnsynced()
        local my_peer_id = LuaNetworking:LocalPeerID()
        managers.hud:remove_waypoint("BJ_CWP_" .. my_peer_id)
        self.own_waypoint = nil
    end

    function BJCustomWaypoints:SetPeerWaypoint(peer_id, pos)

        if self.peer_waypoints[peer_id] then
            self:RemovePeerWaypoint(peer_id)
        end

        -- Sometimes pos is nil, no idea why
        if not pos.x or not pos.y or not pos.z then
            return
        end

        if managers.hud then
            local data = {
                position = pos,
                icon = 'infamy_icon',
                distance = true,
                no_sync = false,
                present_timer = 0,
                state = 'present',
                radius = 50,
                color = tweak_data.preplanning_peer_colors[peer_id ~= 0 and peer_id or 1],
                blend_mode = 'add'
            }
            if BetterJokers and not BetterJokers.settings.waypoint_show_others then
                -- Do nothing
            else
                managers.hud:add_waypoint("BJ_CWP_" .. peer_id, data)
            end
            self.peer_waypoints[peer_id] = pos
        end
    end

    function BJCustomWaypoints:RemovePeerWaypoint(peer_id)
        if BetterJokers and not BetterJokers.settings.waypoint_show_others then
            -- Do nothing
        else
            managers.hud:remove_waypoint("BJ_CWP_" .. peer_id)
        end
        self.peer_waypoints[peer_id] = nil
    end

    -- Triggered by a keybind, this function will *visually* remove all received peer waypoints in case they get stuck or someone won't remove theirs
    -- The waypoints should still be kept internally, in case clients want to use those to commandeer their jokers. They're just not shown.
    function BJCustomWaypoints:HideAllPeerWaypoints()
        for peer_id, pos in pairs(self.peer_waypoints) do
            if peer_id and pos then
                managers.hud:remove_waypoint("BJ_CWP_" .. peer_id)
            end
        end
    end

    -- Network functions
    -- If a peer leaves, remove their waypoint
    Hooks:Add('BaseNetworkSessionOnPeerRemoved', 'BaseNetworkSessionOnPeerRemoved_BJ_CWP', function(peer, peer_id, reason)
        if BJCustomWaypoints.peer_waypoints[peer_id] then
            BJCustomWaypoints:RemovePeerWaypoint(peer_id)
        end
    end)

    -- Data receive function
    Hooks:Add('NetworkReceivedData', 'NetworkReceivedData_BJ_CWP', function(sender, messageType, data)
        -- Set waypoint
        if messageType == "BJ_CWP_setwaypoint" then
            local pos = string.ToVector3(data)
            BJCustomWaypoints:SetPeerWaypoint(sender, pos)
        end

        -- Remove waypoint
        if messageType == "BJ_CWP_removewaypoint" then
            BJCustomWaypoints:RemovePeerWaypoint(sender)
        end
    end)
end

-- BetterJokers mod
if not BetterJokers then
    _G.BetterJokers = {}

    BetterJokers.ModPath = ModPath
    BetterJokers.SavePath = SavePath .. "betterjokers.json"
    BetterJokers.settings = {
        disable_incompatibility_warnings = false, -- If true, players will not be notified of possible mod incompatibilities.
        joker_exclusive_access = false, -- If true, jokers can only be controlled by their owner.
        joker_my_contours = true, -- Whether your own jokers should take on your own color.
        joker_other_contours = true, -- Whether other people's jokers should take on their color.
        waypoint_show_others = true, -- Whether other people's waypoints should be shown.
        joker_show_health = true -- Whether joker health should be displayed
    }

    BetterJokers.converts = {}
    
    BetterJokers.peersWithMod = {}

    BetterJokers.activeContours = {}

    -- List of peers whose jokers should only be controllable by themselves.
    BetterJokers.exclusiveAccessPeers = {}

    local session_types = {
        server = 1,
        client = 2,
        offline = 3
    }

    -- Check whether we're hosting or a client
    local current_session_type
    if LuaNetworking:IsHost() then
        log("Current session type: Server")
        current_session_type = session_types.server
    elseif LuaNetworking:IsClient() then
        log("Current session type: Client")
        current_session_type = session_types.client
    else
        log("Current session type: Offline") -- This probably never happens, even in offline the network type will just be server regardless of what the BLT docs say
        current_session_type = session_types.offline
    end

    -- Load menu settings
    function BetterJokers:Load()
        local file = io.open(self.SavePath, 'r')
        if file then
            for k, v in pairs(json.decode(file:read('*all')) or {}) do
                self.settings[k] = v
            end
            file:close()
        end
    end

    -- Save current menu settings
    function BetterJokers:Save()
        local file = io.open(self.SavePath, 'w+')
        if file then
            file:write(json.encode(self.settings))
            file:close()
        end
    end

    -- Immediately load/save settings to write a file and to load the settings early
    -- The settings loading is quarantined to a different file so that if the settings file is corrupt,
    -- it won't abort execution of this file. It will then overwrite the corrupt settings with fresh defaults.
    --BetterJokers:Load()
    dofile(ModPath .. "loadsettings.lua")
    BetterJokers:Save()

    -- Call over a joker.
    -- When hosting this will call the joker, as client this asks the host to do it instead.
    function BetterJokers:CallJokerOver(called_unit)
        if current_session_type == session_types.client then
            self:AskHostCallJoker(called_unit)
        else
            local caller_unit = managers.player:player_unit()
            self:SendJokerToPlayer(called_unit, caller_unit, LuaNetworking and LuaNetworking:LocalPeerID() or 1)
        end

        -- Refresh the contour because this sometimes goes oof
        self:ApplyConvertedContour(called_unit, true)
        self:UpdateHoldIcon(called_unit)
    end

    function BetterJokers:CallJokerHold(called_unit)
        if current_session_type == session_types.client then
            self:AskHostHoldJoker(called_unit)
        else
            self:HoldJokerPosition(called_unit, LuaNetworking:LocalPeerID())
        end

        self:ApplyConvertedContour(called_unit, true)
        self:UpdateHoldIcon(called_unit)
    end

    -- Send a joker to a player.
    function BetterJokers:SendJokerToPlayer(called_unit, target_unit, requester_peer_id)
        if not called_unit or not target_unit then
            log("[BetterJokers] Joker unit or Target unit was nil")
            return 
        end

        -- Prevent possible cheat attempts from peers or other weirdness caused by bugs
        if not called_unit:base().is_convert then
            log("[BetterJokers] Joker unit was not a convert")
            return
        end

        -- Only allow this action if the joker isn't exclusively owned by someone else.
        if called_unit:base().exclusive_owner_peer_id and called_unit:base().exclusive_owner_peer_id ~= requester_peer_id then
            log("[BetterJokers] Disallowing action, requester was not the joker's owner")
            return
        end

        local joker_brain = called_unit:brain()

        local follow_objective = self:GetFollowObjectiveToUnit(target_unit)

        -- If the joker was holding, notify peers that the hold icon should be removed
        if joker_brain.is_holding then
            LuaNetworking:SendToPeers("betterjokers_convertstoppedholding", tostring(called_unit:id()))
        end

        joker_brain.is_holding = false
        joker_brain:set_objective(follow_objective)
        joker_brain:set_logic("travel") -- And make it snappy
        called_unit:movement():action_request({
            type = "idle",
            body_part = 1,
            sync = true
        })
    end

    -- Make the specified joker unit hold position
    function BetterJokers:HoldJokerPosition(called_unit, requester_peer_id)
        if not called_unit then
            log("[BetterJokers] Target unit was nil")
            return 
        end

        if not called_unit:base().is_convert then
            log("[BetterJokers] Joker unit was not a convert")
            return
        end

        if called_unit:base().exclusive_owner_peer_id and called_unit:base().exclusive_owner_peer_id ~= requester_peer_id then
            log("[BetterJokers] Disallowing action, requester was not the joker's owner")
            return
        end

        local joker_brain = called_unit:brain()

        -- Custom Waypoints compatibility, joker will hold on the waypoint location instead of its current position
        if BJCustomWaypoints then
            if requester_peer_id == LuaNetworking:LocalPeerID() and BJCustomWaypoints.own_waypoint then
                joker_brain.hold_pos = BJCustomWaypoints.own_waypoint
            elseif BJCustomWaypoints.peer_waypoints[requester_peer_id] then
                joker_brain.hold_pos = BJCustomWaypoints.peer_waypoints[requester_peer_id]
            else
                joker_brain.hold_pos = called_unit:position()
            end
        else
            joker_brain.hold_pos = called_unit:position()
        end        

        local stay_objective = self:GetHoldObjectiveForUnit(called_unit)
        
        joker_brain:set_objective(stay_objective)
        joker_brain:set_logic("travel")
        called_unit:movement():action_request({
            type = "idle",
            body_part = 1,
            sync = true
        })
    end

    -- Get follow objective for a unit
    function BetterJokers:GetFollowObjectiveToUnit(target_unit)
        return {
            type = 'follow',
            follow_unit = target_unit,
            scan = true,
            nav_seg = target_unit:movement():nav_tracker():nav_segment(),
            called = true,
            pos = target_unit:movement():nav_tracker():field_position(),
            forced = true
        }
    end

    -- Get a hold objective for a unit
    function BetterJokers:GetHoldObjectiveForUnit(unit)

        local clbk_data = {}
        clbk_data.unit = unit

        -- Move towards destination first
        return {
            type = "free",
            haste = "run",
            pose = "stand",
            nav_seg = managers.navigation:get_nav_seg_from_pos(unit:brain().hold_pos or unit:position(), true),
            pos = mvec3_cpy(unit:brain().hold_pos or unit:position()),
            forced = true,
            complete_clbk = callback(self, self, 'JokerArrivedAtHoldPosClbk', clbk_data)
        }
    end

    -- Callback function, forces the converted cop to hold at their waypoint position when they arrive
    function BetterJokers:JokerArrivedAtHoldPosClbk(clbk_data)
        local unit = clbk_data.unit

        local objective = {
            type = "stop",
            nav_seg = managers.navigation:get_nav_seg_from_pos(unit:brain().hold_pos or unit:position(), true),
            pos = mvec3_cpy(unit:brain().hold_pos or unit:position()),
            in_place = true,
            forced = true,
            scan = true
        }

        unit:brain():set_objective(objective)
        unit:brain().is_holding = true
        self:UpdateHoldIcon(unit)

        LuaNetworking:SendToPeers("betterjokers_convertarrivedatholdpos", tostring(unit:id()))
    end    

    -- Ask the host to send us the requested joker
    function BetterJokers:AskHostCallJoker(unit)
        local key = unit and unit:id()
        if not key then
            log("[BetterJokers] Unit or unit key was nil")
            return
        end
        LuaNetworking:SendToPeer(1, "betterjokers_calljoker", tostring(key))
    end

    -- Ask the host to make the joker hold
    function BetterJokers:AskHostHoldJoker(unit)
        local key = unit and unit:id()
        if not key then
            log("[BetterJokers] Unit or unit key was nil")
            return
        end
        LuaNetworking:SendToPeer(1, "betterjokers_holdjoker", tostring(key))
    end

    -- Get the joker unit from a unit key
    function BetterJokers:GetJokerUnitFromKey(unit_id)
        local converted_cops = managers.groupai:state():all_converted_enemies()
        for i, unit in pairs(converted_cops) do
            if unit and unit.alive and alive(unit) and unit.id and tostring(unit:id()) == unit_id then
                return unit
            end
        end
        return nil
    end

    -- Get the player unit from their peer ID
    function BetterJokers:GetUnitFromPeerId(id)
        local peer = managers.network:session():peer(id)
        return peer and peer:unit()
    end

    -- Check if the host has the mod. If we're hosting then this is always true
    function BetterJokers:HostHasMod()
        if current_session_type ~= session_types.client then
            return true
        else
            return self.peersWithMod[1] and true or false
        end
    end

    -- Add a contour to the joker unit
    function BetterJokers:ApplyConvertedContour(unit, is_refresh)

        -- Check if contours are enabled for this joker
        local should_show_contours = false
        local my_peer_id = LuaNetworking:LocalPeerID()
        if unit:base().joker_owner_peer_id == my_peer_id and self.settings.joker_my_contours then
            should_show_contours = true
        elseif unit:base().joker_owner_peer_id ~= my_peer_id and self.settings.joker_other_contours then
            should_show_contours = true
        end

        if not should_show_contours then
            return
        end

        -- This function might be called several times, but should only be run once per unit.
        -- *Unless* we're dealing with a "contour refresh" (sometimes the contours revert and have to be re-applied).
        local key = unit:key()
        if not is_refresh and (not key or self.activeContours[key] or not unit:base().joker_owner_peer_id) then
            return
        end

        local color_id = managers.criminals:character_color_id_by_unit(unit)

        local contour = unit:contour()
        -- Change contour color
        contour:change_color("friendly", tweak_data.peer_vector_colors[color_id])

        -- Dumb race conditions require this to be done again on a delayedcall
        DelayedCalls:Add("betterjokers_set_contour_clientdelayed", 0.5, function()
            contour:change_color("friendly", tweak_data.peer_vector_colors[color_id])
        end)

        self.activeContours[key] = true

        self:AddHealthCircle(unit)
    end

    -- Add health circle
    function BetterJokers:AddHealthCircle(unit)
        if unit:base().infobar or not self.settings.joker_show_health then
            return
        end

        -- The weird square is unicode, it's a skull icon ingame
        local label_data = { unit = unit, name = "0" }
        panel_id = managers.hud:_add_name_label(label_data)
        unit:base().infobar = panel_id
        
        local label = managers.hud:_get_name_label(panel_id)
        if not label then
            log("[BetterJokers] Unable to fetch name label for joker unit")
            return
        end

        local radial_health = label.panel:bitmap({
            name = 'bag',
            texture = 'guis/textures/pd2/hud_health',
            render_template = 'VertexColorTexturedRadial',
            blend_mode = 'add',
            alpha = 1,
            w = 16,
            h = 16,
            layer = 0
        })
        label.bag = radial_health
        local txt = label.panel:child('text')
        radial_health:set_center_y(txt:center_y())
        local l, r, w, h = txt:text_rect()
        radial_health:set_left(txt:left() - w)
        radial_health:set_visible(self.settings.joker_show_health and true or false)

        -- Set the hold icon
        local hold_icon = label.panel:bitmap({
            name = 'infamy',
            texture = 'guis/textures/pd2/stophand_symbol',
            blend_mode = 'add',
            alpha = 1,
            w = 8,
            h = 16,
            layer = 0,
            visible = false
        })
        label.infamy = hold_icon
        hold_icon:set_center_y(txt:center_y())
        hold_icon:set_left(txt:left() + w + 10)
        hold_icon:set_visible(false)

        unit:base().bj_healthbar = radial_health
        unit:base().bj_textpanel = txt
        unit:base().bj_holdicon = hold_icon
        unit:base().bj_kills = 0

        self:UpdateKillCounter(unit)
    end

    -- Remove health circle from unit
    function BetterJokers:RemoveHealthCircle(unit)
        if not unit or not alive(unit) or not unit:base().infobar then
            return
        end

        managers.hud:_remove_name_label(unit:base().infobar)
        unit:base().infobar = nil
        unit:base().bj_healthbar = nil
        unit:base().bj_textpanel = nil
        unit:base().bj_holdicon = nil
        unit:base().bj_kills = nil
    end

    -- Update text label killcount on joker
    function BetterJokers:UpdateKillCounter(unit)
        if not unit or not unit:base().bj_textpanel or not unit:base().bj_kills then
            return
        end

        -- The weird character below is unicode, translates to a skull ingame
        unit:base().bj_textpanel:set_text("" .. tostring(unit:base().bj_kills))
    end

    -- Update their "is holding" icon
    function BetterJokers:UpdateHoldIcon(unit)
        if not unit or not unit:base().bj_textpanel or not unit:base().bj_holdicon then
            log("[BetterJokers] Unit had no hold icon variable set, cannot enable/disable icon")
            return
        end

        if unit:brain().is_holding then
            unit:base().bj_holdicon:set_visible(true)
        else
            unit:base().bj_holdicon:set_visible(false)
        end
    end

    -- Always enable their "is holding" icon, this happens as a client if the host tells us that the joker arrived at their hold pos
    function BetterJokers:EnableHoldIcon(unit)
        if not unit or not unit:base().bj_textpanel or not unit:base().bj_holdicon then
            log("[BetterJokers] Unit had no hold icon variable set, cannot enable icon")
            return
        end

        unit:base().bj_holdicon:set_visible(true)
    end

    -- Ditto, but for disabling the icon
    function BetterJokers:DisableHoldIcon(unit)
        if not unit or not unit:base().bj_textpanel or not unit:base().bj_holdicon then
            log("[BetterJokers] Unit had no hold icon variable set, cannot enable icon")
            return
        end

        unit:base().bj_holdicon:set_visible(false)
    end

    -- Networking functions
    -- On network load complete, tell peers that you have Better Jokers installed.
    Hooks:Add('BaseNetworkSessionOnLoadComplete', 'BaseNetworkSessionOnLoadComplete_BetterJokers', function(local_peer, id)
        LuaNetworking:SendToPeers("betterjokers_hello", BetterJokers.settings.joker_exclusive_access and "mine" or "ours")
    end)

    -- Same as above, if a single peer joins then tell them you've got it installed
    Hooks:Add('BaseNetworkSessionOnPeerEnteredLobby', 'BaseNetworkSessionOnPeerEnteredLobby_BetterJokers', function(peer, peer_id)
        LuaNetworking:SendToPeer(peer_id, "betterjokers_hello", BetterJokers.settings.joker_exclusive_access and "mine" or "ours")
    end)

    -- If a peer leaves, remove them from the list
    Hooks:Add('BaseNetworkSessionOnPeerRemoved', 'BaseNetworkSessionOnPeerRemoved_BetterJokers', function(peer, peer_id, reason)
        BetterJokers.peersWithMod[peer_id] = nil
        BetterJokers.exclusiveAccessPeers[peer_id] = nil
    end)

    -- Data receive function
    Hooks:Add('NetworkReceivedData', 'NetworkReceivedData_BetterJokers', function(sender, messageType, data)

        -- Peer notified us that they have the mod installed too
        if messageType == "betterjokers_hello" then
            BetterJokers.peersWithMod[sender] = true
            if data == "mine" then
                BetterJokers.exclusiveAccessPeers[sender] = true
            end
        end

        -- Peer notified us that a joker successfully arrived at their hold position
        if messageType == "betterjokers_convertarrivedatholdpos" then
            local joker_unit = BetterJokers:GetJokerUnitFromKey(data)
            BetterJokers:EnableHoldIcon(joker_unit)
        end

        -- Ditto, but they got called away instead
        if messageType == "betterjokers_convertstoppedholding" then
            local joker_unit = BetterJokers:GetJokerUnitFromKey(data)
            BetterJokers:DisableHoldIcon(joker_unit)
        end

        -- The following messages can only be handled by the host
        if current_session_type == session_types.server then
            -- Respond to a player asking for a joker to come over
            if messageType == "betterjokers_calljoker" then
                local joker_unit = BetterJokers:GetJokerUnitFromKey(data)
                local target_unit = BetterJokers:GetUnitFromPeerId(sender)
                BetterJokers:SendJokerToPlayer(joker_unit, target_unit, sender)
            end
            -- Respond to a player asking for a joker to hold position
            if messageType == "betterjokers_holdjoker" then
                local joker_unit = BetterJokers:GetJokerUnitFromKey(data)
                BetterJokers:HoldJokerPosition(joker_unit, sender)
            end
        end
    end)

end
