local DBL = require("prototypes.shared")

local function get_group(item, item_type)
	local g = data.raw["item-group"][data.raw["item-subgroup"][data.raw[item_type][item].subgroup].group].name
	if not g then
		g = "intermediate-products"
	end
	return g
end

-- assign a order for the stacked items based on the order in which they're created,
-- remembering the assigned order for any items that get stacking applied multiple times
local item_order = {}
do
	-- when this table is checked (during stack creation), the first check for an item in the table will fail
	-- and the __index function will be called, assigning an order, storing and returning it
	-- for later checks of the same key (item name), the stored order string will be in the table and __index won't be hit.
	local item_increment = 1
	local item_order_metatable = {
		__index = function(table, key)
			table[key] = string.format("%03d", item_increment)
			item_increment = item_increment + 1
			return table[key]
		end
	}
	item_order = setmetatable(item_order, item_order_metatable)
end

-- and the same as above for recipes
local recipe_order = {}
do
	local recipe_increment = 1
	local recipe_order_metatable = {
		__index = function(table, key)
			table[key] = string.format("%03d", recipe_increment)
			recipe_increment = recipe_increment + 1
			return table[key]
		end
	}
	recipe_order = setmetatable(recipe_order, recipe_order_metatable)
end


local items_to_update = {}
function DBL.create_stacked_item(item_name, item_type, graphic_path, icon_size)
	DBL.debug(string.format("Creating stacked item: %s", item_name))
	local temp_icons, stacked_icons, this_fuel_category, this_fuel_acceleration_multiplier, this_fuel_top_speed_multiplier, this_fuel_value, this_fuel_emissions_multiplier
	if graphic_path then
		stacked_icons = { { icon = graphic_path, icon_size = icon_size } }
	else
		if data.raw[item_type][item_name].icon then
			temp_icons = { { icon = data.raw[item_type][item_name].icon, icon_size = icon_size } }
			DBL.log_warning(string.format("creating layered stack icon (%s), this is 4x more rendering effort than a custom icon", item_name))
		elseif data.raw[item_type][item_name].icons then
			temp_icons = data.raw[item_type][item_name].icons
			DBL.log_warning(string.format("creating layers-of-layers stack icon (%s), this is %dx more rendering effort than a custom icon!", item_name, 1+(#temp_icons*3)))
		else
			DBL.log_error(string.format("Can't create stacks for item with no icon properties %s", item_name))
			return
		end
		stacked_icons = { { icon = "__deadlock-beltboxes-loaders__/graphics/icons/blank.png", scale = 1, icon_size = 32 } }
		for i = 1, -1, -1 do
			for _,layer in pairs(temp_icons) do
				layer.shift = {0, i*3}
				layer.scale = 0.85 * 32/icon_size
				layer.icon_size = icon_size
				table.insert(stacked_icons, table.deepcopy(layer))
			end
		end
	end
	data:extend({
		{
			type = "item",
			name = string.format("deadlock-stack-%s", item_name),
			localised_name = {"item-name.deadlock-stacking-stack", {"item-name."..item_name}, DBL.STACK_SIZE},
			icons = stacked_icons,
			icon_size = icon_size,
			stack_size = math.floor(data.raw[item_type][item_name].stack_size/DBL.STACK_SIZE),
			flags = {},
			subgroup = string.format("stacks-%s", get_group(item_name, item_type)),
			order = item_order[item_name],
			allow_decomposition = false,
		}
	})
	items_to_update[string.format("deadlock-stack-%s", item_name)] = {
		item_name = item_name,
		item_type = item_type,
	}
	DBL.debug(string.format("Created stacked item: %s", item_name))
end

function DBL.deferred_stacked_item_updates()
	for stacked_item_name, item_table in pairs(items_to_update) do
		local item_name = item_table.item_name
		local item_type = item_table.item_type
		data.raw.item[stacked_item_name].subgroup = string.format("stacks-%s", get_group(item_name, item_type))
		data.raw.item[stacked_item_name].stack_size = math.floor(data.raw[item_type][item_name].stack_size/DBL.STACK_SIZE)
		if data.raw[item_type][item_name].fuel_value then
			data.raw.item[stacked_item_name].fuel_category = data.raw[item_type][item_name].fuel_category
			data.raw.item[stacked_item_name].fuel_acceleration_multiplier = data.raw[item_type][item_name].fuel_acceleration_multiplier
			data.raw.item[stacked_item_name].fuel_top_speed_multiplier = data.raw[item_type][item_name].fuel_top_speed_multiplier
			data.raw.item[stacked_item_name].fuel_emissions_multiplier = data.raw[item_type][item_name].fuel_emissions_multiplier
			-- great, the fuel value is a string, with SI units. how very easy to work with
			data.raw.item[stacked_item_name].fuel_value = (tonumber(string.match(data.raw[item_type][item_name].fuel_value, "%d+")) * DBL.STACK_SIZE) .. string.match(data.raw[item_type][item_name].fuel_value, "%a+")
		end
	end
end

-- make stacking/unstacking recipes for a base item
function DBL.create_stacking_recipes(item_name, item_type, icon_size)
	DBL.debug(string.format("Creating recipes: %s", item_name))
	-- TODO use a smaller multiplier if the item won't fit at current multiplier
	local base_icon = data.raw.item[string.format("deadlock-stack-%s", item_name)].icon
	local base_icons = data.raw.item[string.format("deadlock-stack-%s", item_name)].icons
	if not base_icons then
		base_icons = { { icon = base_icon } }
	end
	-- stacking
	local stack_icons = table.deepcopy(base_icons)
	table.insert(stack_icons, 
		{
			icon = string.format("__deadlock-beltboxes-loaders__/graphics/icons/arrow-d-%d.png", icon_size),
			scale = 0.5 * 32 / icon_size,
			icon_size = icon_size,
		}
	)
	data:extend({
		{
			type = "recipe",
			name = string.format("deadlock-stacks-stack-%s", item_name),
			localised_name = {"recipe-name.deadlock-stacking-stack", {"item-name."..item_name}},
			category = "stacking",
			group = "intermediate-products",
			subgroup = data.raw.item[string.format("deadlock-stack-%s", item_name)].subgroup,
			order = recipe_order[item_name].."[a]",
			enabled = false,
			allow_decomposition = false,
			ingredients = { {item_name, DBL.STACK_SIZE * DBL.RECIPE_MULTIPLIER} },
			result = string.format("deadlock-stack-%s", item_name),
			result_count = DBL.RECIPE_MULTIPLIER,
			energy_required = DBL.CRAFT_TIME * DBL.RECIPE_MULTIPLIER,
			icons = stack_icons,
			icon_size = icon_size, 
			hidden = true,
			allow_as_intermediate = false,
			hide_from_stats = true,
		}
	})
	-- unstacking
	local unstack_icons = table.deepcopy(base_icons)
	table.insert(unstack_icons, 
		{
			icon = string.format("__deadlock-beltboxes-loaders__/graphics/icons/arrow-u-%d.png", icon_size),
			scale = 0.5 * 32 / icon_size,
		}
	)
	data:extend({
		{
			type = "recipe",
			name = string.format("deadlock-stacks-unstack-%s", item_name),
			localised_name = {"recipe-name.deadlock-stacking-unstack", {"item-name."..item_name}},
			category = "unstacking",
			group = "intermediate-products",
			subgroup = data.raw.item[string.format("deadlock-stack-%s", item_name)].subgroup,
			order = recipe_order[item_name].."[b]",
			enabled = false,
			allow_decomposition = false,
			ingredients = { {string.format("deadlock-stack-%s", item_name), DBL.RECIPE_MULTIPLIER} },
			result = item_name,
			result_count = DBL.STACK_SIZE * DBL.RECIPE_MULTIPLIER,
			energy_required = DBL.CRAFT_TIME * DBL.RECIPE_MULTIPLIER,
			icons = unstack_icons,
			icon_size = icon_size,
			hidden = settings.startup["deadlock-stacking-hide-unstacking"].value,
			allow_as_intermediate = false,
			hide_from_stats = true,
		}
	})
	DBL.debug(string.format("Created recipes: %s", item_name))
end

-- make the stacking recipes depend on a technology
function DBL.add_stacks_to_tech(item_name, target_technology)
	-- gather what recipes this tech currently unlocks to avoid adding duplicates
	local recipes = {}
	for _, effect in pairs(data.raw.technology[target_technology].effects) do
		if effect.type == "unlock-recipe" then
			recipes[effect.recipe] = true
		end
	end
	-- insert stacking recipe
	if recipes[string.format("deadlock-stacks-stack-%s", item_name)] then
		DBL.log_warning(string.format("Skipping already added tech effect for stacking %s", item_name))
	else
		table.insert(data.raw.technology[target_technology].effects,
			{
				type = "unlock-recipe",
				recipe = string.format("deadlock-stacks-stack-%s", item_name),
			}
		)
	end
	-- insert unstacking recipe
	if recipes[string.format("deadlock-stacks-stack-%s", item_name)] then
		DBL.log_warning(string.format("Skipping already added tech effect for unstacking %s", item_name))
	else
		table.insert(data.raw.technology[target_technology].effects,
			{
				type = "unlock-recipe",
				recipe = string.format("deadlock-stacks-unstack-%s", item_name),
			}
		)
	end
	DBL.debug(string.format("Added stacks for %s to tech %s", item_name, target_technology))
end
