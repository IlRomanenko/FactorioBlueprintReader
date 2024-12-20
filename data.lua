local config = require('config')

local combinator = table.deepcopy(data.raw['constant-combinator']['constant-combinator'])

combinator.name = config.COMBINATOR_NAME
combinator.minable.result = combinator.name
combinator.item_slot_count = 100
combinator.se_allow_in_space = true
combinator.icon = '__blueprint_reader__/graphics/blueprint-combinator-icon.png'
table.insert(combinator.flags, 'not-deconstructable')

for _, image in pairs(combinator.sprites) do
    local im = image.layers[1]
    im.filename = '__blueprint_reader__/graphics/blueprint-combinator.png'
end


local item = table.deepcopy(data.raw['item']['constant-combinator'])
item.name = combinator.name
item.icon = combinator.icon
item.place_result = combinator.name
item.subgroup = 'circuit-network'
item.order = 'd[other]-d[blueprint-combinator]'

local recipe = table.deepcopy(data.raw["recipe"]["constant-combinator"])
recipe.name = combinator.name
recipe.results = {
    {
        type = 'item',
        name = combinator.name,
        amount = 1,
    }
}
table.insert(data.raw['technology']['circuit-network'].effects, { type = 'unlock-recipe', recipe = combinator.name })

local trans = {
    filename = '__blueprint_reader__/graphics/trans.png',
    width = 1,
    height = 1,
}

data:extend {
    combinator, item, recipe,
    {
        type = 'item',
        name = config.MODULE_CHEST_NAME,
        hidden = true,
        stack_size = 1,
        place_result = config.MODULE_CHEST_NAME,
        icon = combinator.icon,
        selection_priority = 0,
    },
    {
        type = 'container',
        name = config.MODULE_CHEST_NAME,
        hidden = true,
        -- flags = { 'placeable-off-grid', 'not-blueprintable', 'not-upgradable', 'player-creation', 'not-deconstructable' },
        flags = { 'placeable-off-grid', 'not-blueprintable', 'not-upgradable', 'player-creation' },
        collision_mask = nil,
        collision_box = nil,
        selection_box = nil,
        inventory_size = 1,
        se_allow_in_space = true,
        picture = trans,
        minable = { mining_time = 0.2, result = combinator.name },
        -- Disguise the chest as the combinator itself, so it looks right in deconstruction planner filters
        localised_name = { 'entity-name.' .. combinator.name },
        icon = combinator.icon,
        subgroup = item.subgroup,
        order = 'z-' .. item.order, -- For some reason the z- prefix is added to auto-generated order strings
        selection_priority = 0,
    },
}
