require "util"
require("m_defines")
mConfig = global.mConfig or require("config")
if global.mConfig == nil then
    global.mConfig = mConfig;
end
require("helpers.gui")
require("helpers.math")
require("helpers.tick_helper")
require("helpers.misc_helpers")
require("helpers.map_helpers")

require("stdlib.area.position")
require("stdlib.table")


require("helpers.alliance");
require("helpers.team_chat");
require("helpers.configuration_gui");

Logger = require('stdlib.log.logger').new('teams', 'main', true);

d = mConfig.d
bd = mConfig.bd

function areTeamsEnabled()
    return global.TEAMS_ENABLED or false;
end

function setTeamsEnabled()
    global.TEAMS_ENABLED = true;
end

function isConfigWritten()
    return global.CONFIG_WRITTEN or false;
end

function setConfigWritten()
    if isConfigWritten() == false then
        global.CONFIG_WRITTEN_TIME = game.tick
    end
    global.CONFIG_WRITTEN = true;
end


normal_attack_sent_event = script.generate_event_name()
landing_attack_sent_event = script.generate_event_name()
remote.add_interface("freeplay",
    {
        set_attack_data = function(data)
            global.attack_data = data
        end,
        get_attack_data = function()
            return global.attack_data
        end,
        get_normal_attack_sent_event = function()
            return normal_attack_sent_event
        end,
    })


init_attack_data = function()
    global.attack_data = {
        -- whether all attacks are enabled
        enabled = true,
        -- this script is allowed to change the attack values attack_count and until_next_attack
        change_values = true,
        -- what distracts the creepers during the attack
        distraction = defines.distraction.byenemy,
        -- number of units in the next attack
        attack_count = 5,
        -- time to the next attack
        until_next_attack = 60 * 60 * 60,
    }
end


if global.forcesData == nil then
    global.forcesData = mConfig.forcesData;
end

function make_forces()
    local last_point
    local used_points = {}
    local s = game.surfaces["nauvis"]
    table.each(global.forcesData, function(data, k)
        if data.cords == nil then
            local random_point = MM_get_random_point(used_points, last_point);
            last_point = random_point;

            global.forcesData[k].team_x = random_point.x
            global.forcesData[k].team_y = random_point.y
            global.forcesData[k].team_position = { global.forcesData[k].team_x, global.forcesData[k].team_y }
            global.forcesData[k].cords = { x = global.forcesData[k].team_x, y = global.forcesData[k].team_y }
            global.forcesData[k].team_area = { { global.forcesData[k].team_x - d, global.forcesData[k].team_y - d }, { global.forcesData[k].team_x + d, global.forcesData[k].team_y + d } }
            last_point = global.forcesData[k].cords
            table.insert(used_points, last_point)
            --        logTable(global.forcesData[k],k);
        end
        MM_create_force(data);
    end);
end

function set_spawns()
    local s = game.surfaces["nauvis"]
    game.daytime = 0.9

    table.each(global.forcesData, function(data)
        MM_set_spawns(data);
    end)
end

function make_lobby()
    game.create_surface("Lobby", { width = 96, height = 32, starting_area = "big", water = "none" })
end


function set_starting_areas()
    local s = game.surfaces.nauvis

    table.each(global.forcesData, function(data)
        MM_set_starting_area(data);
    end)
end

function make_alliance_overlay_button(player)
    Alliance:make_alliance_overlay_button(player);
end

function make_alliance_overlay(player)
    Alliance:make_alliance_overlay(player);
end

function init_alliance_overlay()
    Alliance:init_overlay();
end

function make_team_chat_button(player)
    TeamChat:make_team_chat_button(player);
end


function make_team_option(player)
    if player.gui.left.choose_team == nil then
        local frame = player.gui.left.add { name = "choose_team", type = "frame", direction = "vertical", caption = { "teams.team-choose" } }

        table.each(global.forcesData, function(data)
            frame.add { type = "button", caption = { 'teams.team-join', data.title }, name = 'choose_team_' .. data.name }.style.font_color = data.color
        end)
        frame.add { type = "button", caption = { "teams.team-auto-assign"}, name = "autoAssign" }
        frame.add { type = "button", caption = { "teams.team-check-number" }, name = "team_number_check" }.style.font_color = { r = 0.9, g = 0.9, b = 0.9 }
    end
end

function on_player_created(event)
    local player = game.players[event.player_index]
    player.teleport({ 0, 8 }, game.surfaces["Lobby"])

    PrintToAllPlayers(event.player_index);

    if isConfigWritten() then
        PrintToAllPlayers('config written');
    else
        PrintToAllPlayers('config not written');
    end

    if event.player_index == 1 and isConfigWritten() == false then
        PrintToAllPlayers('Create configuration gui');
        ConfigurationGui:createConfigurationGui(player);
    end


    if areTeamsEnabled() then
        player.print({ "teams.lobby-msg-select-team" })
        --        player.print("You are currently in the Lobby area, please select a team you will play in")
        make_team_option(player)
    elseif isConfigWritten() == false then
        player.print({ "teams.lobby-msg-wait-for-config", game.players[1].name })
    else
        player.print({ "teams.lobby-msg-wait-for-unlock" })
        --        player.print("You are currently in the Lobby area, please wait for teams to be unlocked")
    end

    player.get_inventory(defines.inventory.player_ammo).clear();
    player.get_inventory(defines.inventory.chest).clear();
    player.get_inventory(defines.inventory.player_guns).clear();
    player.get_inventory(defines.inventory.player_main).clear();
    player.get_inventory(defines.inventory.player_quickbar).clear();
end


function on_init(event)
    init_attack_data()
    make_lobby()
    ConfigurationGui:registerClick();
end

function on_load(event)
end


script.on_init(on_init);
script.on_load(on_load);
script.on_event(defines.events.on_player_created, on_player_created)

function after_lobby_tick(event)
    tick_all_helper(event.tick);
    tick_all_helper_if_valid(event.tick);
end

function triggerTeamsEnabling()
    local seconds = 10;
    local tick_interval = seconds * SECONDS;
    PrintToAllPlayers({ "teams.teams-enable-wait-to-be-charted" })
    --        PrintToAllPlayers('Wait for team areas to be charted');
    local checked_teams = {};
    local if_valid = function(tick)
        local s = game.surfaces['nauvis'];
        for _, data in pairs(global.forcesData) do
            if checked_teams[data.name] == nil then
                -- TODO CHECK IF WE NEED THIS ;)
                --                    if tick % 30 * SECONDS == 0 then
                --                        MM_chart(data);
                --                    end
                if is_area_charted(round_area_to_chunk_save(SquareArea(data.cords, bd)), s) == false then
                    PrintToAllPlayers({ 'teams.teams-enable-not-charted-yet', data.title, seconds })
                    return false;
                end
                PrintToAllPlayers({ 'teams.team-area-charted', data.title })
                checked_teams[data.name] = true;
            end
        end
        return true;
    end

    local tick_helper = function(tick)
        table.each(global.forcesData, function(data)
            MM_set_spawns(data);
            MM_set_starting_area(data);
        end)
        setTeamsEnabled();
        table.each(game.players, function(p)
            make_team_option(p);
        end)
    end
    register_tick_helper_if_valid('CREATE_TEAMS', tick_helper, tick_interval, if_valid);
end

function putPlayerInTeam(player, forceData)
    local s = game.surfaces.nauvis;
    player.teleport(game.forces[forceData.cName].get_spawn_position(s), s)
    player.color = forceData.color
    player.force = game.forces[forceData.cName]
    player.gui.left.choose_team.destroy()
    player.insert { name = "iron-plate", count = 8 }
    player.insert { name = "pistol", count = 1 }
    player.insert { name = "firearm-magazine", count = 10 }
    player.insert { name = "burner-mining-drill", count = 1 }
    player.insert { name = "stone-furnace", count = 1 }
    Alliance:make_alliance_overlay_button(player);
    TeamChat:make_team_chat_button(player);
    PrintToAllPlayers({ 'teams.player-msg-team-join', player.name, forceData.title })
end

function couldJoinIntoForce(forceName)
    if mConfig.teamBalance.enabled == false then
        return true;
    end

    local check = {}
    local lastValue = 0;
    local onlyOne = false;
    table.each(global.forcesData, function(data)
        local c = 0;
        table.each(game.players, function(p)
            if data.cName == p.force.name then c = c + 1 end
        end)
        check[data.cName] = c;
        if lastValue == c then -- check if all teams have the same amount of players
            onlyOne = true;
        else
            onlyOne = false;
        end
        lastValue = c
    end)
    if onlyOne == true then -- if all teams have the same amount of players, then it is possible to join this team
        return true;
    end
    for k,v in spairs(check) do
        return check[forceName] < v -- only join, if wanted force has fewer amount of players as the largest team
    end

    return true;
end

local teamsEnablingStarted = false

function lobby_tick(event)
    tick_all_helper(event.tick);
    tick_all_helper_if_valid(event.tick);


    if game.tick >= global.CONFIG_WRITTEN_TIME + mConfig.enableTeams.after then
        -- fix if game is saved and reload during generation
        if teamsEnablingStarted == false then
            teamsEnablingStarted = true;
            triggerTeamsEnabling();
        end
    elseif game.tick <= global.CONFIG_WRITTEN_TIME + mConfig.enableTeams.after and game.tick % mConfig.enableTeams.messageInterval == 0 then
        local enableTick = (global.CONFIG_WRITTEN_TIME + mConfig.enableTeams.after) - game.tick;
        local seconds = Math.round(enableTick / SECONDS);
        PrintToAllPlayers({ 'teams.teams-enable-in', seconds })
    end


    if (areTeamsEnabled()) then
        script.on_event(defines.events.on_tick, nil)
        script.on_event(defines.events.on_tick, after_lobby_tick)
    end
end



script.on_event(defines.events.on_tick, function(event)
    if isConfigWritten() then
        script.on_event(defines.events.on_tick, lobby_tick);
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    local s = game.surfaces.nauvis;
    local element = event.element
    if element.valid ~= true then
        return;
    end

    local eventName = element.name;

    if eventName == 'team_chat_button' then
        local player = game.players[event.player_index];
        TeamChat:make_team_chat_gui(player);
    elseif eventName == 'team_chat_message_close' then
        local player = game.players[event.player_index];
        player.gui.center.team_chat.destroy()
    elseif eventName == 'team_chat_message_send' then
        local player = game.players[event.player_index];
        for k,p in pairs(player.force.players) do
            p.print({'teams.team-msg', player.name,player.gui.center.team_chat.team_chat_message.text})
        end
        player.gui.center.team_chat.team_chat_message.text = ''
    elseif eventName == 'team_number_check' then
        local player = game.players[event.player_index]
        table.each(global.forcesData, function(data)
            local c = 0;
            table.each(game.players, function(p)
                if data.cName == p.force.name then c = c + 1 end
            end)
            player.print({ 'teams.player-msg-team-number', data.title, c })
        end)
    elseif eventName == 'autoAssign' then
        local check = {}
        table.each(global.forcesData, function(data)
            local c = 0;
            table.each(game.players, function(p)
                if data.cName == p.force.name then c = c + 1 end
            end)
            check[data.cName] = c;
        end)
        for k,v in spairs(check, function (t,a,b) return t[a] < t[b] end) do
            local player = game.players[event.player_index]
            putPlayerInTeam(player, global.forcesData[k]);
            break
        end
    elseif string.match(eventName, 'choose_team_.*') ~= nil then
        table.each(global.forcesData, function(data)
            if eventName == 'choose_team_' .. data.name then
                local player = game.players[event.player_index]
                if couldJoinIntoForce(data.cName) then
                    putPlayerInTeam(player, data);
                else
                    player.print( { 'teams.player-msg-could-not-join', data.title } )
                end
            end
        end)
    elseif eventName == 'alliance_button' then
        local player = game.players[event.player_index]
        Alliance:buildAllianceGui(player)
    elseif eventName == 'alliance_close' then
        local player = game.players[event.player_index]
        if player.gui.center.alliance ~= nil then
            player.gui.center.alliance.destroy();
        end
    elseif string.match(eventName, 'make_alliance_.*') ~= nil then
        local player = game.players[event.player_index];
        local forceTwo = string.sub(event.element.name, 15);
        local forceOne = player.force.name;
        if Alliance:isAllianceRequested(forceOne, forceTwo) then
            Alliance:deleteRequest(forceOne, forceTwo);
            game.forces[forceOne].set_cease_fire(forceTwo, true)
            game.forces[forceTwo].set_cease_fire(forceOne, true)
            Alliance:updateChangeable(forceOne, forceTwo);
            Alliance:updateGuis()
            PrintToAllPlayers({ 'teams.alliance-accept', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        elseif game.forces[forceOne].get_cease_fire(forceTwo) and game.forces[forceTwo].get_cease_fire(forceOne) then
            game.forces[forceOne].set_cease_fire(forceTwo, false)
            game.forces[forceTwo].set_cease_fire(forceOne, false)
            Alliance:updateChangeable(forceOne, forceTwo);
            Alliance:updateGuis()
            PrintToAllPlayers({ 'teams.alliance-terminated', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        else
            Alliance:requestAlliance(forceOne, forceTwo);
            Alliance:updateGuis()
            PrintToAllPlayers({ 'teams.alliance-request', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        end
    elseif string.match(eventName, 'alliance_deny_.*') ~= nil then
        local player = game.players[event.player_index];
        local forceTwo = string.sub(event.element.name, 15);
        local forceOne = player.force.name;
        if Alliance:isAllianceRequested(forceOne, forceTwo) then
            Alliance:deleteRequest(forceOne, forceTwo);
            Alliance:updateGuis()
            game.forces[forceOne].set_cease_fire(forceTwo, false)
            game.forces[forceTwo].set_cease_fire(forceOne, false)
            PrintToAllPlayers({ 'teams.alliance-denied', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        end
    elseif string.match(eventName, 'alliance_abort_.*') ~= nil then
        local player = game.players[event.player_index];
        local forceTwo = string.sub(event.element.name, 16);
        local forceOne = player.force.name;
        if Alliance:isAllianceRequested(forceOne, forceTwo) then
            Alliance:deleteRequest(forceOne, forceTwo);
            Alliance:updateGuis()
            PrintToAllPlayers({ 'teams.alliance-abort', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        end
    elseif string.match(eventName, 'make_alliance_.*') ~= nil then
        local player = game.players[event.player_index];
        local forceTwo = string.sub(event.element.name, 15);
        local forceOne = player.force.name;
        if Alliance:isAllianceRequested(forceOne, forceTwo) then
            Alliance:deleteRequest(forceOne, forceTwo);
            game.forces[forceOne].set_cease_fire(forceTwo, true)
            game.forces[forceTwo].set_cease_fire(forceOne, true)
            Alliance:updateChangeable(forceOne, forceTwo);
            Alliance:updateGuis()
            PrintToAllPlayers({ 'teams.alliance-accept', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        elseif game.forces[forceOne].get_cease_fire(forceTwo) and game.forces[forceTwo].get_cease_fire(forceOne) then
            game.forces[forceOne].set_cease_fire(forceTwo, false)
            game.forces[forceTwo].set_cease_fire(forceOne, false)
            Alliance:updateChangeable(forceOne, forceTwo);
            Alliance:updateGuis()
            PrintToAllPlayers({ 'teams.alliance-terminated', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        else
            Alliance:requestAlliance(forceOne, forceTwo);
            Alliance:updateGuis()
            PrintToAllPlayers({ 'teams.alliance-request', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        end
    elseif eventName == 'next_step' then
        local p = game.players[event.player_index];
        ConfigurationGui:try(ConfigurationGui.steps[ConfigurationGui.currentStep].saveStep, p);
        ConfigurationGui:try(ConfigurationGui.steps[ConfigurationGui.currentStep].destroyStep, p);
        ConfigurationGui.currentStep = ConfigurationGui.steps[ConfigurationGui.currentStep].nextStep;
        local g = ConfigurationGui:try(ConfigurationGui.steps[ConfigurationGui.currentStep].createStep, p);
        ConfigurationGui:createNextAndPrev(g);
    elseif eventName == 'prev_step' then
        local p = game.players[event.player_index];
        ConfigurationGui:try(ConfigurationGui.steps[ConfigurationGui.currentStep].saveStep, p);
        ConfigurationGui:try(ConfigurationGui.steps[ConfigurationGui.currentStep].destroyStep, p);
        ConfigurationGui.currentStep = ConfigurationGui.steps[ConfigurationGui.currentStep].prevStep;
        local g = ConfigurationGui:try(ConfigurationGui.steps[ConfigurationGui.currentStep].createStep, p);
        ConfigurationGui:createNextAndPrev(g);
    elseif eventName == 'start_game' then
        local p = game.players[event.player_index];
        ConfigurationGui:try(ConfigurationGui.steps[ConfigurationGui.currentStep].saveStep, p);
        ConfigurationGui:try(ConfigurationGui.steps[ConfigurationGui.currentStep].destroyStep, p);
        PrintToAllPlayers({ "teams.lobby-msg-config-finished", game.players[1].name })
        make_forces()
        setConfigWritten();
    elseif eventName == 'force_cancel' then
        local p = game.players[event.player_index];
        if p.gui.center.create_force ~= nil and p.gui.center.create_force.valid then
            p.gui.center.create_force.destroy();
        end
        ConfigurationGui:createNextAndPrev(ConfigurationGui.steps.teams.createFrame(p));
    elseif eventName == 'force_save' then
        local p = game.players[event.player_index];
        if p.gui.center.create_force ~= nil and p.gui.center.create_force.valid then
            if p.gui.center.create_force.caption ~= nil then
                global.forcesData[p.gui.center.create_force.caption] = nil;
            end
            local forceData = ConfigurationGui.steps.teams.getForceData(p.gui.center.create_force);
            if forceData.cName ~= '' then
                global.forcesData[forceData.cName] = forceData;
                p.gui.center.create_force.destroy();
            end
        end
        ConfigurationGui:createNextAndPrev(ConfigurationGui.steps.teams.createFrame(p));
    elseif eventName == 'force_remove' then
        local element = event.element;
        local p = game.players[event.player_index];
        local parent = element.parent;
        table.each(global.forcesData, function(forceData, k)
            if parent.name == 'force_frame_' .. forceData.name then
                global.forcesData[k] = nil;
            end
        end)
        ConfigurationGui:createNextAndPrev(ConfigurationGui.steps.teams.createFrame(p));
    elseif string.match(eventName,'force_edit_(.*)') ~= nil then
        local element = event.element;
        local p = game.players[event.player_index];
        table.each(global.forcesData, function(forceData)
            if element.valid and element.name == 'force_edit_' .. forceData.name then
                if p.gui.center.teams_gui ~= nil then
                    p.gui.center.teams_gui.destroy();
                end
                ConfigurationGui.steps.teams.createForceGuiWithData(p, forceData);
                return;
            end
        end)
    elseif eventName == 'force_new' then
        local p = game.players[event.player_index];
        if p.gui.center.teams_gui ~= nil then
            p.gui.center.teams_gui.destroy();
        end
        ConfigurationGui.steps.teams.createForceGui(p);
    end
end)

-- for backwards compatibility
script.on_configuration_changed(function(data)
    if global.attack_data == nil then
        init_attack_data()
        if global.attack_count ~= nil then global.attack_data.attack_count = global.attack_count end
        if global.until_next_attacknormal ~= nil then global.attack_data.until_next_attack = global.until_next_attacknormal end
    end
    if global.attack_data.distraction == nil then global.attack_data.distraction = defines.distraction.byenemy end
end)

script.on_event(defines.events.on_rocket_launched, function(event)
    local force = event.rocket.force
    if event.rocket.get_item_count("satellite") > 0 then
        if global.satellite_sent == nil then
            global.satellite_sent = {}
        end
        if global.satellite_sent[force.name] == nil then
            game.set_game_state { game_finished = true, player_won = true, can_continue = true }
            global.satellite_sent[force.name] = 1
        else
            global.satellite_sent[force.name] = global.satellite_sent[force.name] + 1
        end
        for index, player in pairs(force.players) do
            if player.gui.left.rocket_score == nil then
                local frame = player.gui.left.add { name = "rocket_score", type = "frame", direction = "horizontal", caption = { "score" } }
                frame.add { name = "rocket_count_label", type = "label", caption = { "", { "rockets-sent" }, "" } }
                frame.add { name = "rocket_count", type = "label", caption = "1" }
            else
                player.gui.left.rocket_score.rocket_count.caption = tostring(global.satellite_sent[force.name])
            end
        end
    else
        if (#game.players <= 1) then
            game.show_message_dialog { text = { "gui-rocket-silo.rocket-launched-without-satellite" } }
        else
            for index, player in pairs(force.players) do
                player.print({ "gui-rocket-silo.rocket-launched-without-satellite" })
            end
        end
    end
end)

script.on_event(defines.events.on_research_started, function(event)
    if mConfig.researchMessage.enabled then
        local force = event.research.force
        PrintToAllPlayers({ 'teams.team-research-start', global.forcesData[force.name].title, { 'research-name' .. event.research.name } })
        --    ResearchNotification.log('Team ' .. force.name .. ' has starting research ' .. event.research.name, force.name);
    end
end)
script.on_event(defines.events.on_research_finished, function(event)
    if mConfig.researchMessage.enabled then
        local force = event.research.force
        PrintToAllPlayers({ 'teams.team-research-end', global.forcesData[force.name].title, { 'research-name' .. event.research.name } })
    end
end)


script.on_event(defines.events.on_entity_died, function(event)
    if mConfig.attackMessage.enabled then
        local entity = event.entity;
        local force = event.force;
        if force ~= nil and entity.force.name ~= 'neutral' then
            if entity.force.name == 'enemy' then
                if entity.name ~= "spitter-spawner"
                        and entity.name ~= "biter-spawner"
                        and entity.name ~= "small-worm-turret"
                        and entity.name ~= "medium-worm-turret"
                        and entity.name ~= "big-worm-turret"
                then
                    return
                end
            end
            if entity.force ~= nil and entity.force ~= force then
                local attacked = entity.force.name;
                local attackedFrom = force.name;
                if attacked == 'enemy' then
                    attacked = 'Aliens'
                end
                if attackedFrom == 'enemy' then
                    attackedFrom = 'Aliens';
                end
                PrintToAllPlayers({ 'teams.team-attacked-by-team', attacked, attackedFrom })
            end
        end
    end
end)

remote.add_interface('teams',
    {
        getForceData = function() return global.forcesData end,
        spawnToForce = function(player_index, force_name)
            local player = game.players[player_index];
            if player.surface.name ~= 'nauvis' then
                player.teleport(game.forces[force_name].get_spawn_position('nauvis'), 'nauvis')
            else
                player.teleport(game.forces[force_name].get_spawn_position('nauvis'))
            end
        end,
        createForce = function(name, cname, title, color)
            PrintToAllPlayers('we try to create a new force');
            local data = {
                name = name,
                title = title,
                cName = cname,
                color = color
            }
            global.forcesData[name] = data;

            -- find spawn position
            local last_point
            local used_points = {}

            local s = game.surfaces["nauvis"]
            for k, data in pairs(global.forcesData) do
                if global.forcesData[k].cords ~= nil then
                    last_point = global.forcesData[k].cords
                    table.insert(used_points, last_point)
                end
            end

            local random_point = MM_get_random_point(used_points, last_point);

            local k = name;

            global.forcesData[name].team_x = random_point.x
            global.forcesData[name].team_y = random_point.y
            global.forcesData[name].team_position = { global.forcesData[k].team_x, global.forcesData[k].team_y }
            global.forcesData[name].cords = { x = global.forcesData[k].team_x, y = global.forcesData[k].team_y }
            global.forcesData[name].team_area = { { global.forcesData[k].team_x - d, global.forcesData[k].team_y - d }, { global.forcesData[k].team_x + d, global.forcesData[k].team_y + d } }


            data = global.forcesData[name];

            MM_create_force(data);


            PrintToAllPlayers('successfully created Force: ' .. cname);

            local seconds = 10;
            local tick_interval = seconds * SECONDS;
            PrintToAllPlayers('Wait for team area to be charted');
            local checked_teams = {};
            local if_valid = function(tick)
                local s = game.surfaces['nauvis'];
                if is_area_charted(round_area_to_chunk_save(SquareArea(data.cords, bd)), s) == false then
                    PrintToAllPlayers('Team area for ' .. data.title .. ' is not charted yet, wait another ' .. seconds .. ' seconds');
                    return false;
                end
                return true;
            end

            local tick_helper = function(tick)
                PrintToAllPlayers('create spawn area for ' .. data.title);
                MM_set_spawns(data);
                MM_set_starting_area(data);
                PrintToAllPlayers(data.title .. ' successfully created and spawn area finished');
            end
            register_tick_helper_if_valid('CREATE_TEAM', tick_helper, tick_interval, if_valid);
        end,
        changeForce = function(player_index, force_name)
            local p = game.players[player_index];
            p.force = game.forces[force_name];
            PrintToAllPlayers({ 'teams.player-is-now-in-force', p.name, global.forcesData[force_name].title })
            for k, v in pairs(global.forcesData) do
                if v.cName == force_name then
                    p.color = v.color;
                    break;
                end
            end
            remote.call('teams', 'spawnToForce', player_index, force_name);
        end,
        fixResearch = function(research_name)
            for k, f in pairs(game.forces) do
                if f.technologies[research_name] == nil then
                    PrintToAllPlayers('research ' .. research_name .. ' does not exist');
                    break;
                end
                if f.technologies[research_name].researched then
                    PrintToAllPlayers('fixing research ' .. research_name .. ' for force ' .. f.name);
                    f.technologies[research_name].researched = false;
                    f.technologies[research_name].researched = true;
                end
            end
        end,
        getColorOfForce = function(force_name)
            if global.forcesData[force_name] ~= nil then
                return global.forcesData[force_name].color
            end
            return { r = 1, g = 1, b = 1, a = 1 }
        end,
    })

-- /c remote.call('multiplayermod','createForce','alex','Alex','Alex Force', { b = 0, r = 0.58, g = 0.93, a = 0.8 })

-- script.on_event(defines.events.on_sector_scanned, function(event)
-- local force = event.research.force
-- for k, p in pairs (game.players) do
-- if p.force ~= force then
-- p.print("Team "..force.name.." has scanned a sector, be careful ")
-- end
-- end
-- end)

function getEventName(event)
    if event == nil then
        return 'event is kind of nil :O';
    end
    if event == defines.events.on_built_entity then
        return 'on_built_entity';
    elseif event == defines.events.on_canceled_deconstruction then
        return 'on_canceled_deconstruction';
    elseif event == defines.events.on_chunk_generated then
        return 'on_chunk_generated';
    elseif event == defines.events.on_entity_died then
        return 'on_entity_died';
    elseif event == defines.events.on_entity_settings_pasted then
        return 'on_entity_settings_pasted';
    elseif event == defines.events.on_force_created then
        return 'on_force_created';
    elseif event == defines.events.on_forces_merging then
        return 'on_forces_merging';
    elseif event == defines.events.on_gui_checked_state_changed then
        return 'on_gui_checked_state_changed';
    elseif event == defines.events.on_gui_click then
        return 'on_gui_click';
    elseif event == defines.events.on_gui_text_changed then
        return 'on_gui_text_changed';
    elseif event == defines.events.on_marked_for_deconstruction then
        return 'on_marked_for_deconstruction';
    elseif event == defines.events.on_picked_up_item then
        return 'on_picked_up_item';
    elseif event == defines.events.on_player_alt_selected_area then
        return 'on_player_alt_selected_area';
    elseif event == defines.events.on_player_ammo_inventory_changed then
        return 'on_player_ammo_inventory_changed';
    elseif event == defines.events.on_player_armor_inventory_changed then
        return 'on_player_armor_inventory_changed';
    elseif event == defines.events.on_player_built_tile then
        return 'on_player_built_tile';
    elseif event == defines.events.on_player_crafted_item then
        return 'on_player_crafted_item';
    elseif event == defines.events.on_player_created then
        return 'on_player_created';
    elseif event == defines.events.on_player_cursor_stack_changed then
        return 'on_player_cursor_stack_changed';
    elseif event == defines.events.on_player_died then
        return 'on_player_died';
    elseif event == defines.events.on_player_driving_changed_state then
        return 'on_player_driving_changed_state';
    elseif event == defines.events.on_player_gun_inventory_changed then
        return 'on_player_gun_inventory_changed';
    elseif event == defines.events.on_player_joined_game then
        return 'on_player_joined_game';
    elseif event == defines.events.on_player_left_game then
        return 'on_player_left_game';
    elseif event == defines.events.on_player_main_inventory_changed then
        return 'on_player_main_inventory_changed';
    elseif event == defines.events.on_player_mined_item then
        return 'on_player_mined_item';
    elseif event == defines.events.on_player_mined_tile then
        return 'on_player_mined_tile';
    elseif event == defines.events.on_player_placed_equipment then
        return 'on_player_placed_equipment';
    elseif event == defines.events.on_player_quickbar_inventory_changed then
        return 'on_player_quickbar_inventory_changed';
    elseif event == defines.events.on_player_removed_equipment then
        return 'on_player_removed_equipment';
    elseif event == defines.events.on_player_respawned then
        return 'on_player_respawned';
    elseif event == defines.events.on_player_rotated_entity then
        return 'on_player_rotated_entity';
    elseif event == defines.events.on_player_selected_area then
        return 'on_player_selected_area';
    elseif event == defines.events.on_player_tool_inventory_changed then
        return 'on_player_tool_inventory_changed';
    elseif event == defines.events.on_pre_entity_settings_pasted then
        return 'on_pre_entity_settings_pasted';
    elseif event == defines.events.on_pre_player_died then
        return 'on_pre_player_died';
    elseif event == defines.events.on_preplayer_mined_item then
        return 'on_preplayer_mined_item';
    elseif event == defines.events.on_put_item then
        return 'on_put_item';
    elseif event == defines.events.on_research_finished then
        return 'on_research_finished';
    elseif event == defines.events.on_research_started then
        return 'on_research_started';
    elseif event == defines.events.on_resource_depleted then
        return 'on_resource_depleted';
    elseif event == defines.events.on_robot_built_entity then
        return 'on_robot_built_entity';
    elseif event == defines.events.on_robot_built_tile then
        return 'on_robot_built_tile';
    elseif event == defines.events.on_robot_mined then
        return 'on_robot_mined';
    elseif event == defines.events.on_robot_mined_tile then
        return 'on_robot_mined_tile';
    elseif event == defines.events.on_robot_pre_mined then
        return 'on_robot_pre_mined';
    elseif event == defines.events.on_rocket_launched then
        return 'on_rocket_launched';
    elseif event == defines.events.on_sector_scanned then
        return 'on_sector_scanned';
    elseif event == defines.events.on_tick then
        return 'on_tick';
    elseif event == defines.events.on_train_changed_state then
        return 'on_train_changed_state';
    elseif event == defines.events.on_trigger_created_entity then
        return 'on_trigger_created_entity';
    else
        return 'unknown event';
    end
end