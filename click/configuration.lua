ConfigurationGui = {}

function ConfigurationGui:createConfigurationGui(player)

    local steps = {};
    local currentStep = 'teams';

    local function createNextAndPrev(gui)
        local f = gui.add {
            type = 'flow',
            direction = 'horizontal'
        }
        local s = steps[currentStep];

        if s.prevStep ~= nil then
            f.add {
                type = 'button',
                name = 'prev_step',
                caption = {'','< ', steps[s.prevStep].caption}
            }
        end

        if s.nextStep == nil then
            if global.forcesData ~= nil and table.length(global.forcesData) > 0 then
                f.add {
                    type = 'button',
                    name = 'start_game',
                    caption = { 'config-gui.start' }
                }
            else
                f.add {
                    type = 'label',
                    caption = { 'config-gui.min-one-team' }
                }
            end
        else
            f.add {
                type = 'button',
                name = 'next_step',
                caption = {'',steps[s.nextStep].caption, ' >'}
            }
        end
    end
    steps.teams = {
        prevStep = nil,
        nextStep = 'enable',
        caption = {'teams-gui.forces-gui-caption'},
        createStep = function(player)
            local function createForceGuiWithData(player, forceData)
                if player.gui.center.create_force ~= nil then
                    player.gui.center.create_force.destry();
                end
                local frame = ConfigurationGui:createFrame(player.gui.center, 'create_force', { 'teams-gui.create-gui-caption' });
                if forceData.cName ~= '' then
                    frame.caption = forceData.cName;
                end
                for k, v in pairs({
                    'name',
                    'title',
                    'cName'
                }) do
                    local flow = frame.add {
                        type = 'flow',
                        name = "force_" .. v,
                        direction = 'vertical'
                    }
                    flow.add {
                        type = "label",
                        caption = { 'teams-gui.force-' .. v .. '-caption' }
                    }
                    flow.add {
                        name = "textfield",
                        type = "textfield",
                        text = forceData[v],
                    }
                end
                local color = frame.add {
                    type = 'frame',
                    direction = 'vertical',
                    name = 'color',
                    caption = { 'teams-gui.force-color-caption' }
                }

                local forceColor = ConfigurationGui:colorToRgb(forceData.color)
                for k, v in pairs(forceColor) do
                    local flow = color.add {
                        type = 'flow',
                        direction = 'horizontal',
                        name = k
                    }
                    flow.add {
                        type = "label",
                        caption = { 'teams-gui.force-color-' .. k .. '-caption' }
                    }
                    flow.add {
                        name = "textfield",
                        text = v,
                        type = "textfield",
                    }
                end

                frame.add {
                    type = 'button',
                    name = 'force_cancel',
                    caption = { 'teams-gui.force-cancel-caption' }
                }

                frame.add {
                    type = 'button',
                    name = 'force_save',
                    caption = { 'teams-gui.force-save-caption' }
                }
            end
            local function createForceGui()
                local forceData = {
                    name = "",
                    title = "",
                    cName = '',
                    color = { r = 1, g = 1, b = 1, a = 1 }
                }
                createForceGuiWithData(player, forceData);
            end
            local function getForceData(frame)
                return {
                    name = frame.force_name.textfield.text,
                    title = frame.force_title.textfield.text,
                    cName = frame.force_cName.textfield.text,
                    color = ConfigurationGui:rgbToColor({
                        r = frame.color.r.textfield.text,
                        g = frame.color.g.textfield.text,
                        b = frame.color.b.textfield.text,
                        a = frame.color.a.textfield.text
                    })
                }
            end

            local function createFrame(player)
                if player.gui.center.teams_gui ~= nil then
                    player.gui.center.teams_gui.destroy();
                end
                local frame = ConfigurationGui:createFrame(player.gui.center, 'teams_gui', {'teams-gui.forces-gui-caption'});
                table.each(global.forcesData, function(forceData)
                    local forceFrame = frame.add {
                        name = 'force_frame_' .. forceData.name,
                        type = 'flow',
                        direction = 'horizontal'
                    }
                    forceFrame.add {
                        type = 'label',
                        name = 'name',
                        caption = forceData.title
                    }.style.font_color = forceData.color
                    forceFrame.add {
                        type = 'button',
                        name = 'force_edit_'..forceData.name,
                        caption = { 'teams-gui.force-edit-caption' }
                    }
                    if game.forces[forceData.name] == nil then
                        forceFrame.add {
                            type = 'button',
                            name = 'force_remove',
                            caption = {'teams-gui.force-remove-caption'}
                        }
                    end
                end)
                frame.add {
                    type = 'button',
                    name = 'force_new',
                    caption = { 'teams-gui.force-new-caption' }
                }
                return frame;
            end
            Gui.on_click('force_cancel', function(event)
                local p = game.players[event.player_index];
                if p.gui.center.create_force ~= nil and p.gui.center.create_force.valid then
                    p.gui.center.create_force.destroy();
                end
                createNextAndPrev(createFrame(p));
            end)

            Gui.on_click('force_save', function(event)
                local p = game.players[event.player_index];
                if p.gui.center.create_force ~= nil and p.gui.center.create_force.valid then
                    if p.gui.center.create_force.caption ~= nil then
                        global.forcesData[p.gui.center.create_force.caption] = nil;
                    end
                    local forceData = getForceData(p.gui.center.create_force);
                    if forceData.cName ~= '' then
                        global.forcesData[forceData.cName] = forceData;
                        p.gui.center.create_force.destroy();
                    end
                end
                createNextAndPrev(createFrame(p));
            end)

            Gui.on_click('force_edit_(.*)', function(event)
                local element = event.element;
                local p = game.players[event.player_index];
                table.each(global.forcesData, function(forceData)
                    if element.valid and element.name == 'force_edit_' .. forceData.name then
                        if player.gui.center.teams_gui ~= nil then
                            player.gui.center.teams_gui.destroy();
                        end
                        createForceGuiWithData(p, forceData);
                        return;
                    end
                end)
            end)

            Gui.on_click('force_remove', function(event)
                local element = event.element;
                local p = game.players[event.player_index];
                local parent = element.parent;
                table.each(global.forcesData, function(forceData, k)
                    if parent.name == 'force_frame_' .. forceData.name then
                        global.forcesData[k] = nil;
                    end
                end)
                createNextAndPrev(createFrame(p));
            end)

            Gui.on_click('force_new', function(event)
                local p = game.players[event.player_index];
                if player.gui.center.teams_gui ~= nil then
                    player.gui.center.teams_gui.destroy();
                end
                createForceGui(p);
            end)

            return createFrame(player);
        end,
        saveStep = function(player) end,
        destroyStep = function(player)
            if player.gui.center.teams_gui ~= nil then
                player.gui.center.teams_gui.destroy();
            end
        end
    }
    steps.enable = {
        prevStep = 'teams',
        nextStep = 'points',
        caption = {'enable-gui.caption'},
        createStep = function(player)
            local frame = ConfigurationGui:createFrame(player.gui.center, 'enable_gui', {'enable-gui.caption'});
            table.each(
                {
                    "attackMessage",
                    "researchMessage",
                    "teamMessageGui",
                    "allianceGui"
                },
                function(name)
                    ConfigurationGui:createCheckboxFlow(frame,name,{'enable-gui.label-'..name},global.mConfig[name].enabled)
                end
            )
            return frame
        end,
        saveStep = function(player)
            table.each(
                {
                    "attackMessage",
                    "researchMessage",
                    "teamMessageGui",
                    "allianceGui"
                },
                function(name)
                    global.mConfig[name].enabled = player.gui.center.enable_gui[name].checkbox.state -- TODO CHECK IF THIS WORKS
                end
            )
--            global.mConfig.researchMessage.enabled = gui.enable_gui.researchMessage.checkbox.state;
--            global.mConfig.attackMessage.enabled = gui.enable_gui.attackMessage.checkbox.state;
--            global.mConfig.teamMessageUi.enabled = gui.enable_gui.teamMessageUi.checkbox.state;
--            global.mConfig.allianceGui.enabled = gui.enable_gui.allianceGui.checkbox.state;
        end,
        destroyStep = function(player)
            if player.gui.center.enable_gui ~= nil then
                player.gui.center.enable_gui.destroy();
            end
        end
    }

    steps.points = {
        prevStep = 'enable',
        nextStep = nil,
        caption = {'point-gui.caption'},
        createStep = function(player)
            local frame = ConfigurationGui:createFrame(player.gui.center, 'point_gui', {'point-gui.caption'});

            ConfigurationGui:createTextFieldFlow(frame, 'startingAreaRadius',{ 'point-gui.label-startingAreaRadius' }, global.mConfig.points.startingAreaRadius);
            ConfigurationGui:createTextFieldFlow(frame, 'pointsMin',{ 'point-gui.label-distance-min' }, global.mConfig.points.distance.min);
            ConfigurationGui:createTextFieldFlow(frame, 'pointsMax',{ 'point-gui.label-distance-max' }, global.mConfig.points.distance.max);
            ConfigurationGui:createTextFieldFlow(frame, 'd',{ 'point-gui.label-d' }, global.mConfig.d);
            ConfigurationGui:createTextFieldFlow(frame, 'bd',{ 'point-gui.label-bd' }, global.mConfig.bd);

            return frame;
        end,
        saveStep = function(player)
            local gui = player.gui.center.point_gui;
            global.mConfig.d = tonumber(gui.d.textfield.text);
            global.mConfig.bd  = tonumber(gui.bd.textfield.text);
            global.mConfig.points.startingAreaRadius = tonumber(gui.startingAreaRadius.textfield.text);
            global.mConfig.points.distance.min = tonumber(gui.pointsMin.textfield.text);
            global.mConfig.points.distance.max = tonumber(gui.pointsMax.textfield.text);
        end,
        destroyStep = function(player)
            if player.gui.center.point_gui ~= nil then
                player.gui.center.point_gui.destroy();
            end
        end
    }

    Gui.on_click('next_step', function(event)
        local p = game.players[event.player_index];
        ConfigurationGui:try(steps[currentStep].saveStep,p);
        ConfigurationGui:try(steps[currentStep].destroyStep,p);
        currentStep = steps[currentStep].nextStep;
        local g = ConfigurationGui:try(steps[currentStep].createStep,p);
        createNextAndPrev(g);
    end)
    Gui.on_click('prev_step', function(event)
        local p = game.players[event.player_index];
        ConfigurationGui:try(steps[currentStep].saveStep,p);
        ConfigurationGui:try(steps[currentStep].destroyStep,p);
        currentStep = steps[currentStep].prevStep;
        local g = ConfigurationGui:try(steps[currentStep].createStep,p);
        createNextAndPrev(g);
    end)
    Gui.on_click('start_game', function(event)
        local p = game.players[event.player_index];
        ConfigurationGui:try(steps[currentStep].saveStep,p);
        ConfigurationGui:try(steps[currentStep].destroyStep,p);
        PrintToAllPlayers({"teams.lobby-msg-config-finished", game.players[1].name})
        make_forces()
        setConfigWritten();
    end)

    -- init first step ;)
    local g = ConfigurationGui:try(steps[currentStep].createStep,player);
--    PrintToAllPlayers(type(g));
--    PrintToAllPlayers(type(err));
--    PrintToAllPlayers(err);
    createNextAndPrev(g);

end

function ConfigurationGui:try(f,...)
    local status, r = pcall(f,...);
    if not status then
        PrintToAllPlayers(r);
    end
    return r;
end

function ConfigurationGui:createFrame(parent, name, caption)
    return parent.add {
        type = 'frame',
        name = name,
        direction = 'vertical',
        caption = caption
    }
end


function ConfigurationGui:createTextFieldFlow(gui, name, caption, value)
    local flow = gui.add {
        type = 'flow',
        direction = 'horizontal',
        name = name
    }
    flow.add {
        type = "label",
        caption = caption
    }
    flow.add {
        name = "textfield",
        type = "textfield",
        text = value,
    }
end
function ConfigurationGui:createCheckboxFlow(gui, name, caption, value)
    local flow = gui.add {
        type = 'flow',
        direction = 'horizontal',
        name = name
    }
    flow.add {
        type = "label",
        caption = caption
    }
    flow.add {
        name = "checkbox",
        type = "checkbox",
        state = value,
    }
end

function ConfigurationGui:colorToRgb(color)
    return {
        r = color.r * 255,
        g = color.g * 255,
        b = color.b * 255,
        a = color.a
    }
end

function ConfigurationGui:rgbToColor(rgb)
    return {
        r = rgb.r / 255,
        g = rgb.g / 255,
        b = rgb.b / 255,
        a = rgb.a
    }
end