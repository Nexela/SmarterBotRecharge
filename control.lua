--[[
    Newly placed roboports attempt to force waiting to charge robots to find a better option
--]]
local function expand_to_area(pos, radius)
    return {
        left_top = {x = pos.x - radius, y = pos.y - radius},
        right_bottom = {x = pos.x + radius, y = pos.y + radius}
    }
end

-- Inventories should be identical so 1 to 1 swapping should work
local function swap_inventory(src, dst)
    for i = 1, #src do
        local from, to = src[i], dst[i]
        to.swap_stack(from)
    end
end

local function on_built_roboport(event)
    local entity = event.created_entity
    if entity.type == 'roboport' and not event.ignore then
        local cell = entity.logistic_cell
        local area = expand_to_area(entity.position, 150)
        for _, old_roboport in pairs(entity.surface.find_entities_filtered {area = area, type = 'roboport', force = entity.force, limit = 30}) do
            if old_roboport ~= entity then
                local old_cell = old_roboport.logistic_cell
                if cell and old_cell and (cell.is_neighbour_with(old_cell) or old_roboport.name:find('robo%-charge%-port')) and old_cell.to_charge_robot_count >= 10 then
                    local new_roboport =
                        old_roboport.surface.create_entity {
                        name = old_roboport.name,
                        position = old_roboport.position,
                        direction = old_roboport.direction,
                        force = old_roboport.force
                    }
                    new_roboport.last_user = old_roboport.last_user
                    new_roboport.energy = old_roboport.energy
                    local new_event = {
                        created_entity = new_roboport,
                        robot = event.robot,
                        player_index = event.player_index,
                        ignore = true
                    }
                    script.raise_event(event.robot and defines.events.on_robot_built_entity or defines.events.on_built_entity, new_event)

                    if old_roboport.has_items_inside() then
                        for _, inv in pairs(defines.inventory) do
                            local old_inventory = old_roboport.get_inventory(inv)
                            if old_inventory and old_inventory.valid and old_inventory.get_item_count() > 0 then
                                local new_inventory = new_roboport.get_inventory(inv)
                                swap_inventory(old_inventory, new_inventory)
                            end
                        end
                    end

                    old_roboport.surface.create_entity {
                        name = 'flying-text',
                        text = {'smarter-bots.force-recharge'},
                        position = old_roboport.position,
                        color = {g = 1}
                    }
                    script.raise_event(defines.events.on_entity_died, {entity = old_roboport})
                    old_roboport.destroy()
                end
            end
        end
    end
end
local events = {defines.events.on_built_entity, defines.events.on_robot_built_entity}
script.on_event(events, on_built_roboport)
