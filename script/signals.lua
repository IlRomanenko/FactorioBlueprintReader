local Signals = {}
Signals.mt = {__index = Signals}

local signals_cache = {}

function Signals.get_signal_id(name)
    local item_name = name
    local signal = signals_cache[name]
    if not signal then
        local type = (game.item_prototypes[name] and 'item') or (game.fluid_prototypes[name] and 'fluid')
        if not type and game.entity_prototypes[name] then
            local prototype = game.entity_prototypes[name]
            if #prototype.items_to_place_this > 0 then
                item_name = game.entity_prototypes[name].items_to_place_this[1].name
                type = 'item'
            else
                type = 'virtual'
                item_name = 'signal-red'
            end
        end
        signal = {
            name = item_name,
            type = type
        }
        signals_cache[name] = signal
    end
    return signal
end

function Signals.create_signals(entities)
    local signals = {}
    local index = 1
    for name, count in pairs(entities) do
        table.insert(signals, {
            signal = Signals.get_signal_id(name),
            count = count,
            index = index
        })
        index = index + 1
    end
    return signals
end

function Signals.collect_blueprint_entities(stack, entities)
    if not stack.valid_for_read then
        return
    end
    if stack.is_blueprint_book then
        local inventory = stack.get_inventory(defines.inventory.item_main)
        if not inventory or not inventory.valid or inventory.is_empty() then
            return
        end
        for i = 1, #inventory do
            local cur_stack = inventory[i]
            Signals.collect_blueprint_entities(cur_stack, entities)
        end
    elseif stack.is_blueprint then
        for key, count in pairs(stack.cost_to_build) do
            entities[key] = entities[key] + count
        end
    end
end

local function get_entities_table()
    local res = {}
    setmetatable(res, {__index = function() return 0; end})
    return res
end

function Signals.collect_blueprint_signals(inventory)
    local entities = get_entities_table()
    for i = 1, #inventory do
        local stack = inventory[i]
        Signals.collect_blueprint_entities(stack, entities)
    end
    return Signals.create_signals(entities)
end

return Signals