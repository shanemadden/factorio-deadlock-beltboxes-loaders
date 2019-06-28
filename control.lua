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

local opposite_type = {
	["input"] = "output",
	["output"] = "input",
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

-- check if it is neighbour of entity in given direction 
local function get_the_neighbour(entity, neighbour, direction)
	local entities = entity.surface.find_entities_filtered{type = neighbour.type,  position = add_vectors(entity.position, dir2vector[direction])}
	for _, item in pairs(entities) do
		if item == neighbour then return {neighbour} end
	end
	return {}
end

-- return all entities 1 tile away in specified direction
local function get_neighbour_entities(entity, direction)
	return entity.surface.find_entities_filtered{ position = add_vectors(entity.position, dir2vector[direction]) }
end

local function get_neighbour_loaders_for_entity(entity)
	local position = entity.position
	local box = entity.prototype.selection_box
	local area = {
	  {position.x + box.left_top.x-1, position.y + box.left_top.y-1},
	  {position.x + box.right_bottom.x + 1, position.y + box.right_bottom.y + 1}
	}
	return entity.surface.find_entities_filtered{type="loader", area=area, force=entity.force}
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
			entity.type == "splitter" or
			entity.type == "loader") and
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

	if built and built.valid and not event.revived and built.type == "loader" and created_loader[built.name] then
		local snap2inv = settings.get_player_settings(game.players[event.player_index])["deadlock-loaders-snap-to-inventories"].value
		local snap2belt = settings.get_player_settings(game.players[event.player_index])["deadlock-loaders-snap-to-belts"].value
		-- no need to check anything if configs are off
		if not snap2inv and not snap2belt then
			return
		end

		local loader = built;
		local belt_side_direction = loader.direction
		-- if loader in input mode, switch
		if loader.loader_type == "input" then belt_side_direction = opposite[loader.direction] end

		local belt_end = get_neighbour_entities(loader, belt_side_direction)
		local loading_end = get_neighbour_entities(loader, opposite[belt_side_direction])

		-- note: loader mode won't change when snapped to inventory
		if snap2belt and are_belt_facing(belt_end, loader.direction) then
			-- belt on belt side, same direction
		elseif snap2belt and are_belt_facing(belt_end, opposite[loader.direction]) then
			-- belt on belt side, opposite direction
			loader.rotate( {by_player = event.player_index} )
		elseif snap2inv and are_loadable(loading_end) then
			-- inventory on loading side
		elseif snap2inv and are_loadable(belt_end) then
			-- inventory on belt side
			loader.direction = opposite[loader.direction]
		elseif snap2belt and are_belt_facing(loading_end, loader.direction) then
			-- belt on loading on belt side, same direction
			loader.direction = opposite[loader.direction]
			loader.rotate( {by_player = event.player_index} )
		elseif snap2belt and are_belt_facing(loading_end, opposite[loader.direction]) then
			-- belt on loading on belt side, opposite direction
			loader.direction = opposite[loader.direction]
		end
		--loader.surface.create_entity{name="flying-text", position={loader.position.x-.25, loader.position.y-.5}, text = "^", color = {g=1}}
	
	elseif built and built.valid and not event.revived and built.type ~= "loader" then
		-- todo: maybe filter only for belt-like and entities with inventories
		
		local snap2inv = settings.get_player_settings(game.players[event.player_index])["deadlock-loaders-snap-to-inventories"].value
		local snap2belt = settings.get_player_settings(game.players[event.player_index])["deadlock-loaders-snap-to-belts"].value
		if not snap2inv and not snap2belt then
			return
		end

		local loaders = get_neighbour_loaders_for_entity(built)
		for _, loader in pairs(loaders) do
			if created_loader[loader.name] then

				local belt_side_direction = loader.direction
				-- if loader in input mode, switch
				if loader.loader_type == "input" then belt_side_direction = opposite[loader.direction] end

				local belt_end = get_the_neighbour(loader, built, belt_side_direction)
				local loading_end = get_the_neighbour(loader, built, opposite[belt_side_direction])

				-- note: loader mode won't change when snapped to inventory

				if snap2belt and are_belt_facing(belt_end, loader.direction) then
					-- belt on belt side, same direction
				elseif snap2belt and are_belt_facing(belt_end, opposite[loader.direction]) then
					-- belt on belt side, opposite direction
					loader.rotate( {by_player = event.player_index} )
				elseif snap2inv and are_loadable(loading_end) then
					-- inventory on loading side
				elseif snap2inv and are_loadable(belt_end) then
					-- inventory on belt side
					loader.direction = opposite[loader.direction]
				elseif snap2belt and are_belt_facing(loading_end, loader.direction) then
					-- belt on loading on belt side, same direction
					loader.direction = opposite[loader.direction]
					loader.rotate( {by_player = event.player_index} )
				elseif snap2belt and are_belt_facing(loading_end, opposite[loader.direction]) then
					-- belt on loading on belt side, opposite direction
					loader.direction = opposite[loader.direction]
				end
				--loader.surface.create_entity{name="flying-text", position={loader.position.x-.25, loader.position.y-.5}, text = "*", color = {r=1}}
			end
		end	
	end
end
script.on_event({defines.events.on_built_entity}, on_built_entity)


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
		local add_count = STACK_SIZE
		-- if the base item's stack size is lower than the configured STACK_SIZE then
		-- this should reward the lower of the two
		local prototype = game.item_prototypes[string.sub(event.item_stack.name, 16)]
		if STACK_SIZE > prototype.stack_size then
			add_count = prototype.stack_size
		end
		local inserted = player.insert({
			name = string.sub(event.item_stack.name, 16),
			count = add_count,
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
