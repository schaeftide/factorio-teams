TeamChat = {};

function TeamChat:make_team_chat_gui(player)
    if player.gui.center.team_chat == nil then
        local f = player.gui.center.add { name = "team_chat", type = "frame", direction = "vertical", caption = {"teams.team-chat-caption"} }
        f.add{type="textfield", name="team_chat_message", caption ={"teams.team-chat-message"}}
        f.add{type="button", name="team_chat_message_send", caption ={"teams.team-chat-send"}}
        f.add{type="button", name="team_chat_message_close", caption ={"teams.team-chat-close"}}
    end
end

function TeamChat:make_team_chat_button(player)
    if player.gui.left.team_chat_button == nil and global.mConfig.teamMessageGui.enabled then
        player.gui.left.add { name = "team_chat_button", type = "button", caption = "C", direction = "horizontal" }
    end
end