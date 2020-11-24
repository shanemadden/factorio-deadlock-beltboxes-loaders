local DBL = require("prototypes.shared")

-- multiply a number with a unit (kJ, kW etc) at the end
local function multiply_number_unit(property, mult)
    local value, unit
    value = string.match(property, "%d+")
    if string.match(property, "%d+%.%d+") then -- catch floats
        value = string.match(property, "%d+%.%d+")
    end
    unit = string.match(property, "%a+")
    if unit == nil then
        return value * mult
    else
        return ((value * mult) .. unit)
    end
end

local function get_group(item, item_type)
	local g = data.raw["item-group"][data.raw["item-subgroup"][data.raw[item_type][item].subgroup].group].name
	if not g then
		g = "intermediate-products"
	end
	return g
end

local function get_localised_name(item_name)
	if data.raw.item[item_name] and data.raw.item[item_name].localised_name then
		return data.raw.item[item_name].localised_name
	else
		return {"item-name."..item_name}
	end
end

local items_to_update = {}
function DBL.create_stacked_item(item_name, item_type, graphic_path, icon_size, stack_size, mipmap_levels)
	DBL.debug(string.format("Creating stacked item: %s", item_name))
	local temp_icons, stacked_icons --, this_fuel_category, this_fuel_acceleration_multiplier, this_fuel_top_speed_multiplier, this_fuel_value, this_fuel_emissions_multiplier
	if graphic_path then
		stacked_icons = { { icon = graphic_path, icon_size = icon_size, icon_mipmaps = mipmap_levels } }
	else
		local base_item = data.raw[item_type][item_name]
		-- Icons has priority over icon, check for icons definition first
		if base_item.icons then 
			temp_icons = table.deepcopy(base_item.icons)
			-- We've fetched the icons, check icon_size is present in each layer, and if not, assign it
			-- No need to check if base_item.icon_size exists, because if it's not defined there and not defined here, Factorio itself will not start
			for _, icons_layer in pairs(temp_icons) do
				if not icons_layer.icon_size then icons_layer.icon_size = base_item.icon_size end
			end
		-- If no icons field, look for icon definition
		elseif base_item.icon then
			if not base_item.icon_size then
				DBL.log_error(string.format("Can't create layered icon for item (%s), base item defines icon but no icon_size", item_name))
				return
			end
			temp_icons = { { icon = base_item.icon, icon_size = base_item.icon_size, icon_mipmaps = base_item.icon_mipmaps } }
		else
			DBL.log_error(string.format("Can't create stacks for item with no icon properties (%s)", item_name))
			return
		end
		DBL.log_warning(string.format("creating layered stack icon (%s), this is %dx more rendering effort than a custom icon!", item_name, 1+(#temp_icons*3)))
		stacked_icons = { { icon = "__deadlock-beltboxes-loaders__/graphics/icons/square/blank.png", scale = 1, icon_size = 32 } }
		for i = 1, -1, -1 do
			for _,layer in pairs(temp_icons) do
				layer.scale = 0.85 * 32/layer.icon_size
				layer.shift = {0, i*3}
				table.insert(stacked_icons, table.deepcopy(layer))
			end
		end
	end
	data:extend({
		{
			type = "item",
			name = string.format("deadlock-stack-%s", item_name),
			localised_name = {"item-name.deadlock-stacking-stack", get_localised_name(item_name), stack_size},
			icons = stacked_icons,
			stack_size = math.floor(data.raw[item_type][item_name].stack_size/stack_size),
			flags = {},
			subgroup = string.format("stacks-%s", get_group(item_name, item_type)),
			order = DBL.item_order[item_name],
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
		if data.raw[item_type][item_name] then
			local stack_size = deadlock.get_item_stack_density(item_name, item_type)
			data.raw.item[stacked_item_name].subgroup = string.format("stacks-%s", get_group(item_name, item_type))
			data.raw.item[stacked_item_name].stack_size = math.floor(data.raw[item_type][item_name].stack_size/stack_size)
			data.raw.item[stacked_item_name].localised_name = {"item-name.deadlock-stacking-stack", get_localised_name(item_name), stack_size}
			-- warn when the current stack size causes a loss in inventory density for this item
			if data.raw[item_type][item_name].stack_size % stack_size > 0 then
				DBL.log_warning(string.format("Full stack density for %s is reduced to %d from source stack size %d, doesn't divide cleanly by %d", stacked_item_name, (data.raw.item[stacked_item_name].stack_size * stack_size), data.raw[item_type][item_name].stack_size, stack_size))
			end
			if data.raw[item_type][item_name].fuel_value then
				data.raw.item[stacked_item_name].fuel_category = data.raw[item_type][item_name].fuel_category
				data.raw.item[stacked_item_name].fuel_acceleration_multiplier = data.raw[item_type][item_name].fuel_acceleration_multiplier
				data.raw.item[stacked_item_name].fuel_top_speed_multiplier = data.raw[item_type][item_name].fuel_top_speed_multiplier
				data.raw.item[stacked_item_name].fuel_emissions_multiplier = data.raw[item_type][item_name].fuel_emissions_multiplier
				-- great, the fuel value is a string, with SI units. how very easy to work with
				-- now works with fuel values that have a decimal place
				data.raw.item[stacked_item_name].fuel_value = multiply_number_unit(data.raw[item_type][item_name].fuel_value, stack_size)
			end
		else
			DBL.log_warning("Item \""..item_name.."\" appears to have been deleted since it was added to the deferred item updates list, skipping it.")
		end
	end
end

-- make stacking/unstacking recipes for a base item
-- Deadlock 8.6.19: no need to pass icon parameters, can be extracted from item
function DBL.create_stacking_recipes(item_name, item_type, stack_size)
	DBL.debug(string.format("Creating recipes: %s", item_name))
	local base_item = data.raw.item[string.format("deadlock-stack-%s", item_name)]
	local base_icons = data.raw.item[string.format("deadlock-stack-%s", item_name)].icons
	if not base_icons then
		base_icons = { { icon = base_item.icon, icon_size = base_item.icon_size, icon_mipmaps = base_item.icon_mipmaps } }
	end
	local stack_speed_modifier = stack_size / DBL.STACK_SIZE
	-- stacking
	local stack_icons = table.deepcopy(base_icons)
	table.insert(stack_icons, 
		{
			icon = "__deadlock-beltboxes-loaders__/graphics/icons/square/arrow-d-64.png",
			scale = 0.25,
			icon_size = 64,
		}
	)
	data:extend({
		{
			type = "recipe",
			name = string.format("deadlock-stacks-stack-%s", item_name),
			localised_name = {"recipe-name.deadlock-stacking-stack", get_localised_name(item_name)},
			category = "stacking",
			group = "intermediate-products",
			subgroup = data.raw.item[string.format("deadlock-stack-%s", item_name)].subgroup,
			order = DBL.recipe_order[item_name].."[a]",
			enabled = false,
			allow_decomposition = false,
			ingredients = { {item_name, stack_size * DBL.RECIPE_MULTIPLIER} },
			result = string.format("deadlock-stack-%s", item_name),
			result_count = DBL.RECIPE_MULTIPLIER,
			energy_required = DBL.CRAFT_TIME * DBL.RECIPE_MULTIPLIER * stack_speed_modifier,
			icons = stack_icons,
			hidden = true,
			allow_as_intermediate = false,
			hide_from_stats = true,
		}
	})
	-- unstacking
	local unstack_icons = table.deepcopy(base_icons)
	table.insert(unstack_icons, 
		{
			icon = "__deadlock-beltboxes-loaders__/graphics/icons/square/arrow-u-64.png",
			scale = 0.25,
			icon_size = 64,
		}
	)
	data:extend({
		{
			type = "recipe",
			name = string.format("deadlock-stacks-unstack-%s", item_name),
			localised_name = {"recipe-name.deadlock-stacking-unstack", get_localised_name(item_name)},
			category = "unstacking",
			group = "intermediate-products",
			subgroup = data.raw.item[string.format("deadlock-stack-%s", item_name)].subgroup,
			order = DBL.recipe_order[item_name].."[b]",
			enabled = false,
			allow_decomposition = false,
			ingredients = { {string.format("deadlock-stack-%s", item_name), DBL.RECIPE_MULTIPLIER} },
			result = item_name,
			result_count = stack_size * DBL.RECIPE_MULTIPLIER,
			energy_required = DBL.CRAFT_TIME * DBL.RECIPE_MULTIPLIER * stack_speed_modifier,
			icons = unstack_icons,
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
