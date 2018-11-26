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

-- shanemadden's additional belt-facing detection
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
	-- check neighbours and snap if necessary
	local belt_end = get_neighbour_entities(built, built.direction)
	local loading_end = get_neighbour_entities(built, opposite[built.direction])
	-- belt-end detection by shanemadden
	if snap2belt and are_belt_facing(belt_end, opposite[built.direction]) then
		built.rotate( {by_player = event.player_index} )
	elseif snap2belt and are_belt_facing(belt_end, built.direction) then
		return
	-- no belts detected, check for adjacent inventories
	elseif snap2inv and not are_loadable(belt_end) and are_loadable(loading_end) then
		built.rotate( {by_player = event.player_index} )
	elseif snap2inv and are_loadable(belt_end) and not are_loadable(loading_end) then
		built.direction = opposite[built.direction]
		if not snap2belt or not are_belt_facing(loading_end, built.direction) then
			built.rotate( {by_player = event.player_index} )
		end
	-- no inventories, check for inventory-end belts
	elseif snap2belt and are_belt_facing(loading_end, built.direction) then
		built.direction = opposite[built.direction]
		built.rotate( {by_player = event.player_index} )
	elseif snap2belt and are_belt_facing(loading_end, opposite[built.direction]) then
		built.direction = opposite[built.direction]
	end
end
script.on_event(defines.events.on_built_entity, on_built_entity)
