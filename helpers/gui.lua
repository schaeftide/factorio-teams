
MMGui = {}

MMGui.clicker = {}

MMGui.trigger = function(event)
    table.each(MMGui.clicker, function(data)
        local gui_element = event.element
        if gui_element and gui_element.valid then
            local match_str = string.match(gui_element.name, data.match)
            if match_str ~= nil then
--                local new_event = { tick = event.tick, name = event.name, _handler = handler, match = match_str, element = gui_element, player_index = event.player_index }
                local success, err = pcall(data.handler, event)
                if not success then
                    Game.print_all(err)
                    return err
                end
                -- if success, err is the std return result
                return err
            end
        end
    end)
end

MMGui.on_click = function(match, handler)
    table.insert(MMGui.clicker, {
        match = match,
        handler = handler
    });
    return MMGui;
end