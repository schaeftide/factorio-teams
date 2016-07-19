

function registerTeamChat()
    local function make_team_chat_gui(player)
        if player.gui.center.team_chat == nil then
            local f = player.gui.center.add { name = "team_chat", type = "frame", direction = "vertical", caption = {"teams.team-chat-caption"} }
            f.add{type="textfield", name="team_chat_message", caption ={"teams.team-chat-message"}}
            f.add{type="button", name="team_chat_message_send", caption ={"teams.team-chat-send"}}
            f.add{type="button", name="team_chat_message_close", caption ={"teams.team-chat-close"}}
        end
    end
    Gui.on_click('team_chat_button', function(event)
        local player = game.players[event.player_index];
        make_team_chat_gui(player);
    end).on_click('team_chat_message_send', function(event)
        local player = game.players[event.player_index];
        for k,p in pairs(player.force.players) do
            p.print({'teams.team-msg', player.name,player.gui.center.team_chat.team_chat_message.text})
            --                p.print('Team message from '..player.name..': '..player.gui.center.team_chat.team_chat_message.text);
        end
        player.gui.center.team_chat.team_chat_message.text = ''
    end).on_click('team_chat_message_close', function(event)
        local player = game.players[event.player_index];
        player.gui.center.team_chat.destroy()
    end)
end