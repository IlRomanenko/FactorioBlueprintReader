local List = require 'linked_list'
local config = require 'config'
local Signals = require 'signals'

local Combinator = {
    data = {},
    ordered = nil,
    total_combinators = 0
}
Combinator.mt = {__index = Combinator}


function Combinator.init_storage()
    storage.combinators = storage.combinators or {}
end

function Combinator.on_load()
    Combinator.data = storage.combinators
    Combinator.ordered = nil
    for _, comb in pairs(Combinator.data) do
        setmetatable(comb, Combinator.mt);
        Combinator.ordered = List.append(Combinator.ordered, List.create(comb))
        Combinator.total_combinators = Combinator.total_combinators + 1
    end
end


function Combinator.create(entity)
    local comb = setmetatable({
        entity = entity,
        unit_number = entity.unit_number,
        control_behavior = entity.get_or_create_control_behavior(),
        chest = entity.surface.create_entity {
            name = config.MODULE_CHEST_NAME,
            position = entity.position,
            force = entity.force,
            create_build_effect_smoke = false,
        },
        inventory = nil,
        tick = 0,
        destroyed = false
    }, Combinator.mt)
    comb.chest.destructible = false
    comb.inventory = comb.chest.get_inventory(defines.inventory.chest)

    Combinator.data[comb.unit_number] = comb
    Combinator.ordered = List.append(Combinator.ordered, List.create(comb))
    Combinator.total_combinators = Combinator.total_combinators + 1
    return comb
end

function Combinator.destroy(entity)
    local combinator_entity = entity.surface.find_entity(config.COMBINATOR_NAME, entity.position)
    if not combinator_entity then return; end
    local comb = Combinator.data[combinator_entity.unit_number]
    if not comb then return; end
    comb.destroyed = true
    comb.unit_number = combinator_entity.unit_number
    if entity.name == config.COMBINATOR_NAME  then
        comb.chest.destroy()
    elseif entity.name == config.MODULE_CHEST_NAME then
        comb.entity.destroy()
    end
end

function Combinator.on_mined_entity(entity, buffer)
    local combinator_entity = entity.surface.find_entity(config.COMBINATOR_NAME, entity.position)
    if not combinator_entity then return; end
    local comb = Combinator.data[combinator_entity.unit_number]
    if not comb then return; end
    for i = 1, #comb.inventory do
        buffer.insert(comb.inventory[i])
    end
    Combinator.destroy(entity)
end

function Combinator.on_tick(tick, refresh_rate)
    local total_checked = 0
    local max_checked = (Combinator.total_combinators + refresh_rate - 1) / refresh_rate
    while Combinator.ordered ~= nil and tick > Combinator.ordered.value.tick + refresh_rate and total_checked < max_checked do
        if Combinator.ordered.value.destroyed then
            Combinator.data[Combinator.ordered.value.unit_number] = nil
            Combinator.ordered = Combinator.ordered:remove()
            Combinator.total_combinators = Combinator.total_combinators - 1
        else
            Combinator.ordered.value:update(tick)
            Combinator.ordered = Combinator.ordered.next
        end
        total_checked = total_checked + 1
    end
end

function Combinator:update(tick)
    if self.destroyed then
        assert(false, "Update on destroyed object")
    end
    self.tick = tick
    if not self.entity.valid or not self.chest.valid then
        self.destroyed = true
        if self.chest.valid then
            self.chest.destroy()
        end
        if self.entity.valid then
            self.entity.destroy()
        end
        return
    end
    self.control_behavior.sections[1].filters = self:update_signals()
end

function Combinator:update_signals()
    local inventory = self.inventory
    if not inventory or not inventory.valid or inventory.is_empty() then
        return {}
    end
    return Signals.collect_blueprint_signals(inventory)
end

function Combinator.open(entity, player_index)
    local comb = Combinator.data[entity.unit_number]
    if not comb or comb.destroyed then return; end
    game.get_player(player_index).opened = comb.chest
end

function Combinator.update_inner_positions(entity)
    local comb = Combinator.data[entity.unit_number]
    if not comb then return; end
    comb.chest.teleport(comb.entity.position)
end

return Combinator