local config = require 'config'
local Combinator = require 'script.combinator'

refresh_rate = 1
quality_enabled = true

local function enable_recipes()
    for _, force in pairs(game.forces) do
        if force.technologies['circuit-network'].researched then
            force.recipes[config.COMBINATOR_NAME].enabled = true
        end
    end
end

local function on_mod_setting_changed(event)
    refresh_rate = settings.global[config.REFRESH_RATE_NAME].value
    quality_enabled = settings.global[config.QUALITY_ENABLED_NAME].value
end

local function on_load()
    Combinator.on_load()

    refresh_rate = settings.global[config.REFRESH_RATE_NAME].value
    quality_enabled = settings.global[config.QUALITY_ENABLED_NAME].value

    if remote.interfaces['PickerDollies'] then
        script.on_event(
            remote.call('PickerDollies', 'dolly_moved_entity_id'),
            function(event)
                local entity = event.moved_entity
                if entity and entity.name == config.COMBINATOR_NAME then
                    Combinator.update_inner_positions(entity)
                end
            end
        )
    end
end

local function on_init()
    Combinator.init_storage()
    on_load()
end

local function on_configuration_changed(event)
    on_load()
    enable_recipes()
end

local function on_built(event)
    local entity = event.created_entity or event.entity or event.destination
    if not entity or not entity.valid then return end
    if entity.name == config.COMBINATOR_NAME then
        Combinator.create(entity)
    end
end

local function on_destroyed(event)
    local entity = event.entity
    if not entity then return end
    if entity.name == config.COMBINATOR_NAME then
        Combinator.destroy(entity)
    elseif entity.name == config.MODULE_CHEST_NAME then
        Combinator.destroy(entity)
    end
end

local function on_mined_entity(event)
    local entity = event.entity
    if entity and entity.name == config.COMBINATOR_NAME then
        Combinator.on_mined_entity(entity, event.buffer)
    end
end

local function on_tick(event)
    Combinator.on_tick(event.tick, refresh_rate, quality_enabled)
end

local function on_entity_settings_pasted(event)
    if event.source.name == config.COMBINATOR_NAME and event.destination.name == config.COMBINATOR_NAME then
        Combinator.copy_inventory(event.source, event.destination)
    end
end

local function on_gui_opened(event)
    local entity = event.entity
    if entity and entity.name == config.COMBINATOR_NAME then
        Combinator.open(entity, event.player_index)
    end
end

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)
script.on_event(defines.events.on_runtime_mod_setting_changed, on_mod_setting_changed)

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)
script.on_event(defines.events.script_raised_revive, on_built)

script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)

script.on_event(defines.events.on_object_destroyed, on_destroyed)
script.on_event(defines.events.on_robot_pre_mined, on_destroyed)
script.on_event(defines.events.on_entity_died, on_destroyed)
script.on_event(defines.events.script_raised_destroy, on_destroyed)

script.on_event(defines.events.on_player_mined_entity, on_mined_entity)

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_tick, on_tick)
