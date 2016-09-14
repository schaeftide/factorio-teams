function registerAllianceClick()
    local requestedAlliances = {}

    local nextChangeable = {}
    local function isAllianceRequested(forceOne, forceTwo)
        for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
            if requestedAlliances[key] ~= nil then
                return true;
            end
        end
        return false;
    end

    local function requestAlliance(forceOne, forceTwo)
        for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
            requestedAlliances[key] = forceOne;
        end
    end

    local function deleteRequest(forceOne, forceTwo)
        for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
            requestedAlliances[key] = nil;
        end
    end

    local function isAcceptable(forceOne, forceTwo)
        for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
            if requestedAlliances[key] == forceTwo then
                return true;
            end
        end
        return false;
    end

    local function isChangeable(forceOne, forceTwo)
        local valid = false
        for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
            if nextChangeable[key] == nil or nextChangeable[key] <= game.tick then
                valid = true
            end
        end
        return valid;
    end

    local function updateChangeable(forceOne, forceTwo)
        for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
            nextChangeable[key] = game.tick + global.mConfig.allianceGui.changeAbleTick;
        end
    end

    local function getChangeableTime(forceOne, forceTwo)
        for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
            if nextChangeable[key] ~= nil and nextChangeable[key] >= game.tick then
                return nextChangeable[key] - game.tick
            end
        end
        return 0;
    end

    local function buildAllianceGui(player)

        local frame = player.gui.center.add {
            type = 'frame',
            name = 'alliance',
            caption = { 'alliance-gui.caption' },
            direction = 'vertical'
        }
        local forceOne = player.force.name;
        table.each(global.forcesData, function(forceData)
            local forceTwo = forceData.cName
            if forceOne == forceTwo then
                return;
            end
            local flow = frame.add {
                type = 'flow',
                name = forceData.name,
                direction = 'horizontal'
            }
            flow.add {
                type = 'label',
                caption = forceData.title
            }.style.font_color = forceData.color
            if isChangeable(forceOne, forceTwo) then
                if isAllianceRequested(forceOne, forceTwo) then
                    if isAcceptable(forceOne, forceTwo) then
                        flow.add {
                            type = 'button',
                            caption = { 'alliance-gui.accept' },
                            name = 'make_alliance_' .. forceTwo
                        }
                        flow.add {
                            type = 'button',
                            caption = { 'alliance-gui.deny' },
                            name = 'alliance_deny_' .. forceTwo
                        }
                    else
                        flow.add {
                            type = 'button',
                            caption = { 'alliance-gui.abort' },
                            name = 'alliance_abort_' .. forceTwo
                        }
                    end
                elseif game.forces[forceOne].get_cease_fire(forceTwo) and game.forces[forceTwo].get_cease_fire(forceOne) then
                    flow.add {
                        type = 'button',
                        caption = { 'alliance-gui.terminate' },
                        name = 'make_alliance_' .. forceTwo
                    }
                else
                    flow.add {
                        type = 'button',
                        caption = { 'alliance-gui.request' },
                        name = 'make_alliance_' .. forceTwo
                    }
                end
            else
                local changeAbleIn = getChangeableTime(forceOne, forceTwo) / SECONDS;
                flow.add {
                    type = 'label',
                    caption = { 'alliance-gui.not-changeable', Math.round(changeAbleIn) }
                }
            end
        end)
        frame.add {
            type = 'button',
            name = 'alliance_close',
            caption = { 'alliance-gui.close' }
        }
    end

    local function updateGuis()
        table.each(game.players, function(player)
            if player.gui.center.alliance ~= nil then
                player.gui.center.alliance.destroy();
                buildAllianceGui(player);
            end
        end)
    end

    MMGui.on_click('alliance_button', function(event)
        local player = game.players[event.player_index]
        buildAllianceGui(player)
    end).on_click('alliance_close', function(event)
        local player = game.players[event.player_index]
        if player.gui.center.alliance ~= nil then
            player.gui.center.alliance.destroy();
        end
    end).on_click('make_alliance_.*', function(event)
        local player = game.players[event.player_index];
        local forceTwo = string.sub(event.element.name, 15);
        local forceOne = player.force.name;
        if isAllianceRequested(forceOne, forceTwo) then
            deleteRequest(forceOne, forceTwo);
            game.forces[forceOne].set_cease_fire(forceTwo, true)
            game.forces[forceTwo].set_cease_fire(forceOne, true)
            updateChangeable(forceOne, forceTwo);
            updateGuis()
            PrintToAllPlayers({ 'teams.alliance-accept', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        elseif game.forces[forceOne].get_cease_fire(forceTwo) and game.forces[forceTwo].get_cease_fire(forceOne) then
            game.forces[forceOne].set_cease_fire(forceTwo, false)
            game.forces[forceTwo].set_cease_fire(forceOne, false)
            updateChangeable(forceOne, forceTwo);
            updateGuis()
            PrintToAllPlayers({ 'teams.alliance-terminated', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        else
            requestAlliance(forceOne, forceTwo);
            updateGuis()
            PrintToAllPlayers({ 'teams.alliance-request', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        end
    end).on_click('alliance_deny_.*', function(event)
        local player = game.players[event.player_index];
        local forceTwo = string.sub(event.element.name, 15);
        local forceOne = player.force.name;
        if isAllianceRequested(forceOne, forceTwo) then
            deleteRequest(forceOne, forceTwo);
            updateGuis()
            game.forces[forceOne].set_cease_fire(forceTwo, false)
            game.forces[forceTwo].set_cease_fire(forceOne, false)
            PrintToAllPlayers({ 'teams.alliance-denied', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        end
    end).on_click('alliance_abort_.*', function(event)
        local player = game.players[event.player_index];
        local forceTwo = string.sub(event.element.name, 16);
        local forceOne = player.force.name;
        if isAllianceRequested(forceOne, forceTwo) then
            deleteRequest(forceOne, forceTwo);
            updateGuis()
            PrintToAllPlayers({ 'teams.alliance-abort', player.name, global.forcesData[forceTwo].title, global.forcesData[forceOne].title })
        end
    end)
end