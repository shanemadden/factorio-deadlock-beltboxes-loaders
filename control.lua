local STACK_SIZE = 5

-- work with directions
local opposite = {
	[defines.direction.north] = defines.direction.south,
	[defines.direction.south] = defines.direction.north,
	[defines.direction.east] = defines.direction.west,
	[defines.direction.west] = defines.direction.east,
}
local dir2vector = {
	[defines.direction.north] = {x=0, y=-1},
	[defines.direction.south] = {x=0, y=1},
	[defines.direction.east] = {x=1, y=0},
	[defines.direction.west] = {x=-1, y=0},
}

-- add vectors
local function add_vectors(v1, v2)
	return {v1.x + v2.x, v1.y + v2.y}
end

-- return all entities 1 tile away in specified direction
local function get_neighbour_entities(entity, direction)
	return entity.surface.find_entities_filtered{ position = add_vectors(entity.position, dir2vector[direction]) }
end

-- does any entity in list have an inventory we can work with
local function are_loadable(entities)
	for _,entity in pairs(entities) do
		if entity.get_inventory(defines.inventory.chest) or
			entity.get_inventory(defines.inventory.furnace_source) or
			entity.get_inventory(defines.inventory.assembling_machine_input) or
			entity.get_inventory(defines.inventory.lab_input) or
			entity.get_inventory(defines.inventory.rocket_silo_rocket)
		then return true end
	end
	return false
end

-- belt facing detection
local function are_belt_facing(entities, direction)
	for _,entity in pairs(entities) do
		if (entity.type == "transport-belt" or
			entity.type == "underground-belt" or
			entity.type == "splitter") and
			entity.direction == direction
		then return true end
	end
	return false
end

-- if there's a belt behind, mode follows the direction of the belt
-- else if there's a belt ahead, stop
-- else if there's an inventory behind but not ahead, turn around
-- else if there's an inventory ahead but not behind, turn around and switch mode
-- else if no inventories and a belt ahead, turn around; also switch mode if belt is facing towards
local function on_built_entity(event)
	local built = event.created_entity
	-- invalid build or fake player build from pseudo-bot mods?
	if not built or not built.valid or event.revived or built.type ~= "loader" then
		return
	end
	local snap2inv = settings.get_player_settings(game.players[event.player_index])["deadlock-loaders-snap-to-inventories"].value
	local snap2belt = settings.get_player_settings(game.players[event.player_index])["deadlock-loaders-snap-to-belts"].value
	-- no need to check anything if configs are off
	if not snap2inv and not snap2belt then
		return
	end
	-- get the entities from both ends
	local belt_end = get_neighbour_entities(built, built.direction)
	local loading_end = get_neighbour_entities(built, opposite[built.direction])
	
	if snap2belt and are_belt_facing(belt_end, opposite[built.direction]) then
		-- there's a belt facing toward the belt-side of the loader, so we want to be in input mode
		built.rotate( {by_player = event.player_index} )
	elseif snap2belt and are_belt_facing(belt_end, built.direction) then
		-- there's a belt facing away from the belt-side of the loader, so we want to be certain to stay in output mode, stop further checks
		return
	elseif snap2inv and are_loadable(loading_end) then
		-- there's a loadable entity on the loader end, flip into input mode to load it up
		built.rotate( {by_player = event.player_index} )
	elseif are_loadable(belt_end) then
		-- there's a loadable entity on the belt end but not on the loader end, flip around and go into input mode to load it up
		built.direction = opposite[built.direction]
		-- unless there's a belt facing away, then stay in output mode
		if not are_belt_facing(loading_end, built.direction) then
			-- that wasn't the case so we're safe to go into input mode
			built.rotate( {by_player = event.player_index} )
		end
	elseif snap2belt and are_belt_facing(loading_end, built.direction) then
		-- there's a belt facing into the loader end, switch into input mode and flip
		built.direction = opposite[built.direction]
		built.rotate( {by_player = event.player_index} )
	elseif snap2belt and are_belt_facing(loading_end, opposite[built.direction]) then
		-- there's a belt facing away from the loader end, flip
		built.direction = opposite[built.direction]
	end
end
script.on_event(defines.events.on_built_entity, on_built_entity)

-- auto-unstacking by ownlyme
local function on_picked_up_item(event)
	if string.sub(event.item_stack.name, 1, 15) == "deadlock-stack-" then
		-- attempt to auto-unstack
		local player = game.players[event.player_index]
		-- remove a stack
		player.remove_item({
			name = event.item_stack.name,
			count = 1,
		})
		-- try to add a stack worth of the source item to the inventory
		local inserted = player.insert({
			name = string.sub(event.item_stack.name, 16),
			count = STACK_SIZE,
		})
		if inserted == 0 then
			-- the item couldn't insert for whatever reason, put the stacked version back
			player.insert({
				name = event.item_stack.name,
				count = 1,
			})
		end
	end
end

-- conditionally register based on the state of the setting so it's not costing any performance when disabled
local function on_load(event)
	if settings.startup["deadlock-stacking-auto-unstack"].value then
		script.on_event(defines.events.on_picked_up_item, on_picked_up_item)
	else
		script.on_event(defines.events.on_picked_up_item, nil)
	end
end
script.on_load(on_load)
script.on_init(on_load)
