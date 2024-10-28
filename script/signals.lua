local Signals = {}
Signals.mt = {__index = Signals}

local signals_cache = {}

local QualityItem = {}
QualityItem.mt = {__index = QualityItem}

function QualityItem.new(entity)
    return setmetatable({ name = entity.name, quality = entity.quality }, QualityItem)
end

function Signals.get_signal_id(quality_item)
    local item_name = quality_item.name
    local signal = signals_cache[quality_item]
    if not signal then
        local type = (prototypes.item[item_name] and 'item') or (prototypes.fluid[item_name] and 'fluid')
        if not type and prototypes.entity[item_name] then
            local prototype = prototypes.entity[item_name]
            if #prototype.items_to_place_this > 0 then
                item_name = prototype.items_to_place_this[1].name
                type = 'item'
            else
                type = 'virtual'
                item_name = 'signal-red'
            end
        end
        signal = {
            name = item_name,
            type = type,
            quality = quality_item.quality,
        }
        signals_cache[quality_item] = signal
    end
    return signal
end

function Signals.create_signals(entities)
    local signals = {}
    for quality_item, count in pairs(entities) do
        table.insert(signals, {
            value = Signals.get_signal_id(quality_item),
            min = count,
        })
    end
    return signals
end

function Signals.collect_blueprint_entities(stack, entities, quality_enabled)
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
        for _, items in pairs(stack.cost_to_build) do
            local quality_item = QualityItem.new(items)
            if not quality_enabled then
                quality_item.quality = 'normal'
            end
            entities[quality_item] = entities[quality_item] + items.count
        end
    end
end

local function get_entities_table()
    local res = {}
    setmetatable(res, {__index = function() return 0; end})
    return res
end

function Signals.collect_blueprint_signals(inventory, quality_enabled)
    local entities = get_entities_table()
    for i = 1, #inventory do
        local stack = inventory[i]
        Signals.collect_blueprint_entities(stack, entities, quality_enabled)
    end
    return Signals.create_signals(entities)
end

return Signals