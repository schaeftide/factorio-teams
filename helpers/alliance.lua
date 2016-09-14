Alliance = {};

_requestedAlliances =  {};
_nextChangeAble = {};

function Alliance:isAllianceRequested(forceOne, forceTwo)
    for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
        if _requestedAlliances[key] ~= nil then
            return true;
        end
    end
    return false;
end

function Alliance:requestAlliance(forceOne, forceTwo)
    for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
        _requestedAlliances[key] = forceOne;
    end
end

function Alliance:deleteRequest(forceOne, forceTwo)
    for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
        _requestedAlliances[key] = nil;
    end
end

function Alliance:isAcceptable(forceOne, forceTwo)
    for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
        if _requestedAlliances[key] == forceTwo then
            return true;
        end
    end
    return false;
end

function Alliance:isChangeable(forceOne, forceTwo)
    local valid = false
    for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
        if _nextChangeAble[key] == nil or _nextChangeAble[key] <= game.tick then
            valid = true
        end
    end
    return valid;
end

function Alliance:updateChangeable(forceOne, forceTwo)
    for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
        _nextChangeAble[key] = game.tick + global.mConfig.allianceGui.changeAbleTick;
    end
end

function Alliance:getChangeableTime(forceOne, forceTwo)
    for _, key in pairs({ forceOne .. '_' .. forceTwo, forceTwo .. '_' .. forceOne }) do
        if _nextChangeAble[key] ~= nil and _nextChangeAble[key] >= game.tick then
            return _nextChangeAble[key] - game.tick
        end
    end
    return 0;
end

function Alliance:buildAllianceGui(player)

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
        if Alliance:isChangeable(forceOne, forceTwo) then
            if Alliance:isAllianceRequested(forceOne, forceTwo) then
                if Alliance:isAcceptable(forceOne, forceTwo) then
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
            local changeAbleIn = Alliance:getChangeableTime(forceOne, forceTwo) / SECONDS;
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

function Alliance:updateGuis()
    table.each(game.players, function(player)
        if player.gui.center.alliance ~= nil then
            player.gui.center.alliance.destroy();
            Alliance:buildAllianceGui(player);
        end
    end)
end

function Alliance:init_overlay()
    table.each(game.players, function(p)
        Alliance:make_alliance_overlay(p);
    end)
end

function Alliance:make_alliance_overlay_button(player)
    if player.gui.left.alliance == nil and global.mConfig.allianceGui.enabled then
        player.gui.left.add { name = "alliance_button", type = "button", caption = "A" }
    end
end

function Alliance:make_alliance_overlay(player)
    if player.gui.center.alliance == nil then
        local frame = player.gui.center.add { name = "alliance", type = "frame", direction = "vertical" }

        table.each(global.forcesData, function(data)
            if data.cName ~= player.force.name then
                frame.add { type = "button", caption = { "teamsstart-alliance", data.title }, name = "alliance_" .. data.name }.style.font_color = data.color
            end
        end)

        frame.add { type = "button", caption = { "teams.alliance-close" }, name = "alliance_close" }
    end
end