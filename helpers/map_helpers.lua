function MM_set_spawns(data, message)
    local s = game.surfaces["nauvis"]
    -- kill trees and enemy units
    if message then
        PrintToAllPlayers('kill enemy');
    end

    for _, enemyName in ipairs({"spitter-spawner","biter-spawner","small-worm-turret","medium-worm-turret","big-worm-turret"}) do
        for _, entity in ipairs(s.find_entities_filtered({area = SquareArea( data.cords, bd), name = enemyName})) do
            entity.destroy()
        end
    end
    for k, entity in pairs(s.find_enemy_units(data.cords, bd)) do
        entity.destroy()
    end

    if message then
        PrintToAllPlayers('kill trees');
    end
    for _, enemyName in ipairs({"dead-dry-hairy-tree","dead-grey-trunk","dead-tree","dry-hairy-tree","dry-tree","green-coral","tree-01","tree-02","tree-02-red","tree-03","tree-04","tree-05","tree-06","tree-06-brown","tree-07","tree-08","tree-08-brown","tree-08-red","tree-09","tree-09-brown","tree-09-red"}) do
        for _, entity in ipairs(s.find_entities_filtered({area = SquareArea( data.cords, math.floor(mConfig.points.startingAreaRadius*1.25)), name = enemyName})) do
            entity.destroy()
        end
    end
    local attemps = 0
    local non_colliding
    non_colliding = nil;
    repeat
        non_colliding = s.find_non_colliding_position('player',data.cords, mConfig.points.startingAreaRadius, 4)
        attemps = attemps + 1
    until (attemps == 20 or non_colliding ~= nil)
    if non_colliding == nil then
        PrintToAllPlayers("Map unsutitable, please restart ("..data.title..")")
        game.forces[data.cName].set_spawn_position({ data.cords.x, data.cords.y }, s);
    else
        game.forces[data.cName].set_spawn_position({ non_colliding.x, non_colliding.y }, s);
    end

    if non_colliding ~= nil then
        if message then
            PrintToAllPlayers('kill more enemies');
        end

        -- destroy enemy buildings
        for _, enemyName in ipairs({"spitter-spawner","biter-spawner","small-worm-turret","medium-worm-turret","big-worm-turret"}) do
            for _, entity in ipairs(s.find_entities_filtered({area = SquareArea( non_colliding, bd), name = enemyName})) do
                entity.destroy()
            end
        end
        -- destroy enemy units
        for k, entity in pairs(s.find_enemy_units(non_colliding, bd)) do
            entity.destroy()
        end
    end
end

function MM_set_starting_area(data)

    local s = game.surfaces["nauvis"]
    s.set_tiles {
        { name = "water", position = { data.cords.x + 16, data.cords.y + 16 } },
        { name = "water", position = { data.cords.x + 17, data.cords.y + 16 } },
        { name = "water", position = { data.cords.x + 16, data.cords.y + 17 } },
        { name = "water", position = { data.cords.x + 17, data.cords.y + 17 } }
    }

    for k, pr in pairs(s.find_entities_filtered { area = { { data.cords.x - 128, data.cords.y - 128 }, { data.cords.x + 128, data.cords.y + 128 } }, type = "resource" }) do
        pr.destroy()
    end

    for k, r in pairs(s.find_entities_filtered { area = { { -128, -128 }, { 128, 128 } }, type = "resource" }) do
        local prx = r.position.x
        local pry = r.position.y
        local force_prx = prx + data.team_x
        local force_pry = pry + data.team_y
        local tile = s.get_tile(force_prx, force_pry)
        if tile ~= nil and tile.valid then
            if tile.name ~= "water" and tile.name ~= "deepwater" then
                s.create_entity { name = r.name, position = { force_prx, force_pry }, force = r.force, amount = r.amount }
            end
        end
    end
end


function MM_create_force(data)
    game.create_force(data.cName);
    MM_chart(data);
end

function MM_chart(data)
    local areaBd = round_area_to_chunk_save(SquareArea(data.cords, bd));
    game.forces["player"].chart('nauvis', areaBd)
    game.forces[data.cName].chart('nauvis', areaBd)
end


function MM_get_random_point(used_points, last_point)
    local valid = true
    local random_point = {x = 0, y = 0 }
    local attemps = 0
    repeat
        valid = true
        if last_point ~= nil then
            local factor = 1.5
            if attemps > ( mConfig.points.numberOfTrysBeforeError / 2) then
                factor = math.floor(attemps / 2)
            end
            local random_dis = math.floor(math.random(mConfig.points.distance.min, mConfig.points.distance.max) * factor)
            if math.random(0,1) == 1 then
                random_point.y = last_point.y + random_dis
            else
                random_point.y = last_point.y - random_dis
            end
            if math.random(0,1) == 1 then
                random_point.x = last_point.x + random_dis
            else
                random_point.x = last_point.x - random_dis
            end
            for point_index = 1, #used_points do
                local p = used_points[point_index]
                local x = (p.x - random_point.x) ^ 2
                local y = (p.y - random_point.y) ^ 2
                local dis = math.sqrt(x+y);
                if dis < mConfig.points.distance.min then
                    valid = false
                end
            end
        else
            random_point = mConfig.points.start
            last_point = random_point
        end
        attemps = attemps + 1
        if attemps > mConfig.points.numberOfTrysBeforeError then
            error('ERROR: try to locate team position. Number of attemps '..mConfig.points.numberOfTrysBeforeError..' exceded ' ..data.title..' ' ..attemps)
        end
    until valid == true

    return random_point;
end

