local Area = require('stdlib.area.area')
function ModuloTimer(ticks)
    return (game.tick % ticks) == 0
end

function PrintToAllPlayers(text)
    for playerIndex = 1, #game.players do
        if game.players[playerIndex] ~= nil then
            game.players[playerIndex].print(text)
        end
    end
end

function SquareArea(origin, radius)
    return {
        { origin.x - radius, origin.y - radius },
        { origin.x + radius, origin.y + radius }
    }
end

function PrettyNumber(number)
    if number < 1000 then
        return string.format("%i", number)
    elseif number < 1000000 then
        return string.format("%.1fk", (number / 1000))
    else
        return string.format("%.1fm", (number / 1000000))
    end
end


function DistanceSqr(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    return dx * dx + dy * dy
end

function is_area_charted(area, surface, force)
    if not force then
        force = 'player';
    end
    for k,chunk in pairs(area_to_chunks(area)) do
        if game.forces[force].is_chunk_charted(surface, chunk) == false then
            return false;
        end
    end;
    return true;
end
function area_to_chunks(area)
    local chunks = {};

    local a = Area.to_table(area);

    local first = {x= math.floor(a.left_top.x / 32),y=math.floor(a.left_top.y / 32) }
    local final = {x= math.floor(a.right_bottom.x / 32),y=math.floor(a.right_bottom.y / 32) }

    for x = first.x, final.x, 1 do
        for y = first.y, final.y ,1 do
            table.insert(chunks, {x,y})
        end
    end

    return chunks;
end

function round_area_to_chunk_save(area)
    local a = Area.to_table(area);

    return {
        {
            math.floor(a.left_top.x / 32) * 32,
            math.floor(a.left_top.y / 32) * 32
        },
        {
            math.floor((a.right_bottom.x+1) / 32) * 32,
            math.floor((a.right_bottom.y+1) / 32) * 32
        }
    }

end

function table.val_to_str ( v )
    if "string" == type( v ) then
        v = string.gsub( v, "\n", "\\n" )
        if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
    else
        return "table" == type( v ) and table.tostring( v ) or
                tostring( v )
    end
end

function table.key_to_str ( k )
    if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
        return k
    else
        return "[" .. table.val_to_str( k ) .. "]"
    end
end

function table.tostring( tbl )
    local result, done = {}, {}
    for k, v in ipairs( tbl ) do
        table.insert( result, table.val_to_str( v ) )
        done[ k ] = true
    end
    for k, v in pairs( tbl ) do
        if not done[ k ] then
            table.insert( result,
                table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
        end
    end
    return "{" .. table.concat( result, "," ) .. "}"
end

function table.length (tbl)
    local c = 0;
    for _ in pairs(tbl) do c = c + 1 end
    return c;
end

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end