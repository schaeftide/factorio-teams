
function registerChooseTeam()
    local s = game.surfaces.nauvis;
    table.each(global.forcesData, function(data)
        Gui.on_click('choose_team_' .. data.name,
            function(event)
                local player = game.players[event.player_index]
                player.teleport(game.forces[data.cName].get_spawn_position(s), s)
                player.color = data.color
                player.force = game.forces[data.cName]
                player.gui.left.choose_team.destroy()
                player.insert { name = "iron-plate", count = 8 }
                player.insert { name = "pistol", count = 1 }
                player.insert { name = "firearm-magazine", count = 10 }
                player.insert { name = "burner-mining-drill", count = 1 }
                player.insert { name = "stone-furnace", count = 1 }
                make_alliance_overlay_button(player);
                make_team_chat_button(player);
                PrintToAllPlayers({ 'teams.player-msg-team-join', player.name, data.title })
            end);
    end);

    Gui.on_click('team_number_check',function(event)
        local player = game.players[event.player_index]
        table.each(global.forcesData, function(data)
            local c = 0;
            table.each(game.players, function(p)
                if data.cName == p.force.name then c = c + 1 end
            end)
            player.print({'teams.player-msg-team-number',data.title,c})
        end)
    end);
end