
_tick_helper = {};
_tick_helper_v = {};

function register_tick_helper(f, name)
    _tick_helper[name] = f;
end

function destroy_tick_helper(name)
    _tick_helper[name] = nil;
end

function tick_all_helper(tick)
    for k,f in pairs(_tick_helper) do
        pcall(f,tick);
    end
end

function tick_all_helper_if_valid(tick)
    for k,data in pairs(_tick_helper_v) do
        if data.next_tick == tick then
            if data.running == false then
                _tick_helper_v[k].running = true;
                local status, r = pcall(data.if_valid, tick);
                if status and r then
                    pcall(data.tick_helper,tick);
                    _tick_helper_v[k].running = false;
                    destroy_tick_helper_if_valid(k);
                else
                    _tick_helper_v[k].next_tick = tick + data.tick_interval
                    _tick_helper_v[k].running = false;
                end
            end
        end
    end
end

function register_tick_helper_if_valid(name, tick_helper, tick_interval, if_valid)
    _tick_helper_v[name] = {
        tick_helper=tick_helper,
        name = name,
        if_valid = if_valid,
        tick_interval = tick_interval,
        next_tick = game.tick + tick_interval,
        running = false
    }
end
function destroy_tick_helper_if_valid(name)
    _tick_helper_v[name] = nil;
end