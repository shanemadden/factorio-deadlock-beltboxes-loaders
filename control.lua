local STACK_SIZE = settings.startup["deadlock-stack-size"].value

local created_loader = {}
do
	-- Need to determine if each loader was created by this mod to determine if we should snap for it.
	-- Because this is a smidge expensive, we don't want to check every time
	-- lazily cache for each loader whether it's ours and should be snapped
	local loader_check_metatable = {
		__index = function(table, key)
			if string.match(game.item_prototypes[key].order, "deadlock%-loader") then
				table[key] = true
				return true
			else
				table[key] = false
				return false
			end
		end
	}
	created_loader = setmetatable(created_loader, loader_check_metatable)
end

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
	if not built or not built.valid or event.revived or built.type ~= "loader" or not created_loader[built.name] then
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
local function auto_unstack(item_name, item_count, sending_inventory, receiving_inventory)
	-- item_name: The name of the stacked item which should be unstacked
	-- item_count: The number of items that should be unstacked
	-- sending_inventory: the inventory that contains the stacked item
	-- receiving_inventory: the inventory that receives the unstacked items
	if string.sub(item_name, 1, 15) == "deadlock-stack-" then
		-- attempt to auto-unstack
		-- try to add a stack worth of the source item to the inventory
		local add_count = STACK_SIZE
		-- if the base item's stack size is lower than the configured STACK_SIZE then
		-- this should reward the lower of the two
		local prototype = game.item_prototypes[string.sub(item_name, 16)]
		if STACK_SIZE > prototype.stack_size then
			add_count = prototype.stack_size
		end
		local inserted = receiving_inventory.insert({
			name = string.sub(item_name, 16),
			count = add_count * item_count,
		})
		
		partial_inserted = inserted % add_count 
		-- if player inventory is nearly full it may happen that just 8 items are inserted with add_count==5
		-- partial inserted then will be 3
		if partial_inserted > 0 then
			receiving_inventory.remove({
				name = string.sub(item_name, 16),
				count = partial_inserted,
			})
		end
		-- now remove the inserted items in their stacked variant. With the example above this is 1 stacked item
		full_stack_inserted = math.floor(inserted / add_count)
		if full_stack_inserted > 0 then
			sending_inventory.remove({
				name = item_name,
				count = full_stack_inserted,
			})
		end
	end
end
local function on_picked_up_item(event)
	player_inventory = game.players[event.player_index].get_main_inventory()
	
	auto_unstack(event.item_stack.name, event.item_stack.count, player_inventory, player_inventory)
end
local function on_player_mined_entity(event)
	player_inventory = game.players[event.player_index].get_main_inventory()
	for item_name, item_count in pairs(event.buffer.get_contents()) do
		auto_unstack(item_name, item_count, event.buffer, player_inventory)
	end
end

-- conditionally register based on the state of the setting so it's not costing any performance when disabled
local function on_load(event)
	if settings.startup["deadlock-stacking-auto-unstack"].value then
		script.on_event(defines.events.on_picked_up_item, on_picked_up_item)
		script.on_event(defines.events.on_player_mined_item, on_picked_up_item)
		script.on_event(defines.events.on_player_mined_entity, on_player_mined_entity)
	else
		script.on_event(defines.events.on_picked_up_item, nil)
	end
end
script.on_load(on_load)
script.on_init(on_load)

local function on_configuration_changed(config)
	-- scan the forces' technologies for any of our loaders or beltboxes that should be
	-- unlocked but aren't, likely due to the mod adding them just being added to the save
	for _, force in pairs(game.forces) do
		for tech_name, tech_table in pairs(force.technologies) do
			if tech_table.researched then
				-- find any beltboxes or loaders or stacks in effects and unlock
				for _, effect_table in ipairs(tech_table.effects) do
					if effect_table.type == "unlock-recipe" and (string.find(game.recipe_prototypes[effect_table.recipe].order, "%-deadlock%-") or string.find(game.recipe_prototypes[effect_table.recipe].name, "deadlock%-")) then
						force.recipes[effect_table.recipe].enabled = true
					end
				end
			end
		end
	end
end
script.on_configuration_changed(on_configuration_changed)
