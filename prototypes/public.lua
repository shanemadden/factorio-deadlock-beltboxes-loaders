------------------------------------------------------------------------------------------------------------------------------------------------------

local DBL = require("prototypes.shared")

------------------------------------------------------------------------------------------------------------------------------------------------------

-- table for main public interface
deadlock = {}

------------------------------------------------------------------------------------------------------------------------------------------------------

function deadlock.add_tier(tier_table)
	-- {
	--  transport_belt      = string, -- mandatory, used for speed etc
	--  colour              = table,  -- recommended, default to pink
	--  underground_belt    = string, -- mandatory unless loader_ingredients and beltbox_ingredients specified, used for recipe cost and styling if present
	--  splitter            = string, -- optional, styling only, unused in this mod but passed through to the styling mod if it's present
	--  technology          = string, -- recommended, logistics tech for this tier, defaults to unlocking the recipes right away (also, there will be no beltbox tech to point stacking recipes at)
	--  order               = string, -- recommended, order string for loaders and beltboxes
	--  loader              = string, -- optional, prototype string for the loader that'll be created, defaults to transport_belt.."-loader"
	--  loader_ingredients  = table,  -- mandatory unless underground_belt specified, used for loader recipe cost
	--  loader_recipe       = string, -- optional, only if you need to override the recipe name (for legacy compatibility)
	--  loader_item         = string, -- optional, only if you need to override the item name (for legacy compatibility)
	--  loader_category     = string, -- optional, default to "crafting" but use "crafting-with-fluid" if there's fluid in the recipe
	--  beltbox             = string, -- optional, prototype string for the beltbox that'll be created, defaults to transport_belt.."-beltbox"
	--  beltbox_ingredients = table,  -- mandatory unless underground_belt specified, used for loader recipe cost
	--  beltbox_technology  = string, -- optional, defaults to beltbox_name but can be overridden (vanilla use "deadlock-stacking-[1-3]" for legacy compatibility, since other mods' create() functions for stackable items likely point at these)
	--  beltbox_recipe      = string, -- optional, only if you need to override the recipe name (for legacy compatibility)
	--  beltbox_item        = string, -- optional, only if you need to override the item name (for legacy compatibility)
	--  beltbox_category    = string, -- optional, default to "crafting" but use "crafting-with-fluid" if there's fluid in the recipe
	-- }
	---- validation ----
	DBL.debug("Beginning data validation for new tier")
	-- parent table
	if not tier_table then
		DBL.log_error("Nothing passed, a table is required")
		return
	end
	if type(tier_table) ~= "table" then
		DBL.log_error("Non-table passed, a table is required")
		return
	end
	-- check transport belt
	if not tier_table.transport_belt then
		DBL.log_error("Transport belt entity not specified.")
		return
	end
	if not data.raw["transport-belt"][tier_table.transport_belt] then
		DBL.log_error(string.format("Transport belt entity %s doesn't exist", tier_table.transport_belt))
		return
	end
	-- check colour
	if not (tier_table.colour and tier_table.colour.r and tier_table.colour.g and tier_table.colour.b) then
		tier_table.colour = {r=1,g=0.8,b=0.8}
	end
	-- check underground_belt
	if tier_table.underground_belt and not data.raw["underground-belt"][tier_table.underground_belt] then
		DBL.log_error(string.format("Underground belt entity %s doesn't exist", tier_table.underground_belt))
		return
	end
	-- check splitter
	if tier_table.splitter and not data.raw["splitter"][tier_table.splitter] then
		DBL.log_error(string.format("Splitter entity %s doesn't exist", tier_table.splitter))
		return
	end

	-- check ingredients
	if not tier_table.underground_belt then
		if not tier_table.loader_ingredients then
			DBL.log_error(string.format("Missing ingredients table for loader for %s", tier_table.transport_belt))
			return
		elseif type(tier_table.loader_ingredients) ~= "table" then
			DBL.log_error(string.format("Bad ingredients table for loader for %s", tier_table.transport_belt))
			return
		end
		if not tier_table.beltbox_ingredients then
			DBL.log_error(string.format("Missing ingredients table for beltbox for %s", tier_table.transport_belt))
			return
		elseif type(tier_table.beltbox_ingredients) ~= "table" then
			DBL.log_error(string.format("Bad ingredients table for beltbox for %s", tier_table.transport_belt))
			return
		end
	end
	DBL.debug(string.format("Data validation completed for tier for %s", tier_table.transport_belt))

	-- defaults
	if not tier_table.loader_ingredients then
		tier_table.loader_ingredients = data.raw.recipe[tier_table.underground_belt].ingredients
	end
	if not tier_table.loader_category then
		if data.raw.recipe[tier_table.underground_belt] then
			tier_table.loader_category = data.raw.recipe[tier_table.underground_belt].category
		else
			tier_table.loader_category = "crafting"
		end
	end
	if not tier_table.loader then
		tier_table.loader = string.format("%s-loader", tier_table.transport_belt)
	end

	if not tier_table.beltbox_ingredients then
		tier_table.beltbox_ingredients = data.raw.recipe[tier_table.underground_belt].ingredients
	end
	if not tier_table.beltbox_category then
		if data.raw.recipe[tier_table.underground_belt] then
			tier_table.beltbox_category = data.raw.recipe[tier_table.underground_belt].category
		else
			tier_table.beltbox_category = "crafting"
		end
	end
	if not tier_table.beltbox then
		tier_table.beltbox = string.format("%s-beltbox", tier_table.transport_belt)
	end
	if not tier_table.beltbox_technology then
		tier_table.beltbox_technology = tier_table.beltbox
	end
	
	-- pass to styling if present
	if deadlock_belt_styling then
		deadlock_belt_styling.add_tier(tier_table)
	end

	if settings.startup["deadlock-enable-loaders"].value then
		DBL.create_loader(tier_table)
	end
	if settings.startup["deadlock-enable-beltboxes"].value then
		DBL.create_beltbox(tier_table)
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------

-- return the effective stack density of an item, exposed publicly for other mods if they need in recipes etc
function deadlock.get_item_stack_density(item_name, item_type)
	-- This depends on two things - the stack size startup setting (defaulting to 5)
	-- as well as the stack size of the item
	-- For instance if a mod adds an item whose stacks only go to 5 but the startup setting
	-- is for items to stack to 10, most items will be stacking to 10 but that specific item will only stack to 5
	local stack_size = DBL.STACK_SIZE
	if data.raw[item_type] and data.raw[item_type][item_name] then
		if data.raw[item_type][item_name].stack_size < stack_size then
			stack_size = data.raw[item_type][item_name].stack_size
		end
	end
	return stack_size
end

------------------------------------------------------------------------------------------------------------------------------------------------------

local allowed_item_types = {
	["item"] = true,
	["ammo"] = true,
	["gun"] = true,
	["tool"] = true,
	["repair-tool"] = true,
	["module"] = true,
	["item-with-label"] = true,
	["item-with-tags"] = true,
	["capsule"] = true,
}

function deadlock.add_stack(item_name, graphic_path, target_tech, icon_size, item_type, mipmap_levels)
	-- item_name    	-- required, item to stack
	-- graphic_path 	-- recommended, path to icon to use for dynamic icon generation
	-- target_tech  	-- optional, the tech to unlock this stacking recipe with, often deadlock-stacking-[1-3] (if not provided, you must unlock in a tech in your own mod)
	-- icon_size    	-- optional, defaults to 64
	-- item_type    	-- optional, defaults to "item"
	-- mipmap_levels	-- optional, defaults to nil, only ever used if graphic_path is also provided

	---- validation ----
	DBL.debug("Beginning data validation for new stacked item")
	if not item_type then
		item_type = "item"
	end
	if not allowed_item_types[item_type] then
		DBL.log_error(string.format("Item type not allowed for %s", item_name))
		return
	end
	if not data.raw[item_type][item_name] then
		DBL.log_error(string.format("Can't create stacks for item that doesn't exist %s", item_name))
		return
	end
	if icon_size and (icon_size ~= 32 and icon_size ~= 64 and icon_size ~= 128) then
		DBL.log_error(string.format("Invalid icon_size for %s", item_name))
		return
	end
	if not icon_size then
		icon_size = 64
	end
	DBL.debug(string.format("Data validation completed for stacked item %s", item_name))
	if settings.startup["deadlock-enable-beltboxes"].value then
		local stack_size = deadlock.get_item_stack_density(item_name, item_type)
		DBL.create_stacked_item(item_name, item_type, graphic_path, icon_size, stack_size, mipmap_levels)
		DBL.create_stacking_recipes(item_name, item_type, stack_size)
		if target_tech then
			DBL.add_stacks_to_tech(item_name, target_tech)
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------

function deadlock.deferred_stacked_item_updates()
	DBL.deferred_stacked_item_updates()
end

------------------------------------------------------------------------------------------------------------------------------------------------------

local function product_prototype_uses_item(proto, item)
	for _,p in pairs(proto) do
		if p.name and p.name == item then return true
		elseif p[1] == item then return true end
	end
	return false
end

local function uses_item_as_ingredient(recipe, item)
	if recipe.ingredients and product_prototype_uses_item(recipe.ingredients, item) then return true end
	if recipe.normal and recipe.normal.ingredients and product_prototype_uses_item(recipe.normal.ingredients, item) then return true end
	if recipe.expensive and recipe.expensive.ingredients and product_prototype_uses_item(recipe.expensive.ingredients, item) then return true end
	return false
end

local function uses_item_as_result(recipe, item)
	if recipe.result == item then return true end
	if recipe.normal and recipe.normal.result == item then return true end
	if recipe.expensive and recipe.expensive.result == item then return true end
	if recipe.results and product_prototype_uses_item(recipe.results, item) then return true end
	if recipe.normal and recipe.normal.results and product_prototype_uses_item(recipe.normal.results, item) then return true end
	if recipe.expensive and recipe.expensive.results and product_prototype_uses_item(recipe.expensive.results, item) then return true end
	return false
end

local function is_value_in_table(t, value)
	if not t or not value then return false end
	for k,v in pairs(t) do
		if value == v then return true end
	end 
	return false
end

-- destroy_stack() - removes a stacked item and any recipe/tech references to it
-- item_name    -- required, the base item name
function deadlock.destroy_stack(base_item_name)
	local item_name = "deadlock-stack-"..base_item_name
	local stack_recipe_name = "deadlock-stacks-stack-"..base_item_name
	local unstack_recipe_name = "deadlock-stacks-unstack-"..base_item_name
	local item_name = "deadlock-stack-"..base_item_name
	-- remove the item
	if data.raw.item[item_name] then
		DBL.debug("Removed item "..item_name)
		data.raw.item[item_name] = nil
	end
	-- remove all recipes that use stacks as either ingredient or result
	-- we don't only target stack and unstack recipes because other mods may have used stacks as ingredients by now
	-- keep a list of which recipes got removed, so we can search tech unlocks
	local dead_recipes = {}
	for _,recipe in pairs(data.raw.recipe) do
		if uses_item_as_ingredient(recipe, item_name) or uses_item_as_result(recipe, item_name) then
			DBL.debug("Removed recipe "..recipe.name)
			data.raw.recipe[recipe.name] = nil
			table.insert(dead_recipes, recipe.name)
		end
	end
	-- remove all the removed recipe tech unlocks
	for _,tech in pairs(data.raw.technology) do
		if tech.effects then
			local temp = {}
			local found = false
			for _,effect in pairs(tech.effects) do
				if effect.type ~= "unlock-recipe" or not is_value_in_table(dead_recipes, effect.recipe) then
					table.insert(temp,effect)
				else found = true end
			end
			if found then DBL.debug("Removed unlocks from "..tech.name) end
			tech.effects = table.deepcopy(temp)
		end
	end
	-- remove item order
	DBL.item_order[base_item_name] = nil
	DBL.recipe_order[base_item_name] = nil
end

------------------------------------------------------------------------------------------------------------------------------------------------------

-- deadlock.destroy_vanilla_stacks()
-- This is the same as calling destroy_crate() on every vanilla item the mod creates by default
function deadlock.destroy_vanilla_stacks()
	for tier,items in ipairs(DBL.VANILLA_ITEMS) do
		for _,item in pairs(items) do
			deadlock.destroy_stack(item)
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------

-- tables for legacy interfaces from early 0.16 versions
deadlock_loaders = {}
deadlock_stacking = {}

------------------------------------------------------------------------------------------------------------------------------------------------------

function deadlock_loaders.create(tier_table)
	DBL.log_warning("deadlock_loaders.create() - this function is deprecated, consider using deadlock.add_tier() instead")
	if not tier_table then
		DBL.log_error("Nothing passed, a table is required")
		return
	end
	if type(tier_table) ~= "table" then
		DBL.log_error("Non-table passed, a table is required")
		return
	end
	-- translate the legacy table to one that the add_tier function accepts and matching entity names that the old version created
	tier_table.loader = string.format("deadlock-loader-%d", tier_table.tier)
	tier_table.loader_ingredients = tier_table.ingredients
	tier_table.ingredients = nil
	tier_table.loader_recipe = string.format("deadlock-loader-%d", tier_table.tier)
	tier_table.loader_item = string.format("deadlock-loader-%d", tier_table.tier)
	tier_table.loader_category = tier_table.crafting_category
	tier_table.crafting_category = nil
	tier_table.beltbox = string.format("deadlock-beltbox-entity-%d", tier_table.tier)
	tier_table.beltbox_recipe = string.format("deadlock-beltbox-recipe-%d", tier_table.tier)
	tier_table.beltbox_item = string.format("deadlock-beltbox-item-%d", tier_table.tier)
	tier_table.beltbox_technology = string.format("deadlock-stacking-%d", tier_table.tier)

	DBL.debug(string.format("Calling add_tier for legacy tier %d", tier_table.tier))
	deadlock.add_tier(tier_table)
end

function deadlock_stacking.create(item_name, graphic_path, target_tech, icon_size)
	DBL.log_warning("deadlock_stacking.create() - this function is deprecated, consider using deadlock.add_stack() instead")
	deadlock.add_stack(item_name, graphic_path, target_tech, icon_size)
end

function deadlock_stacking.create_stack(item_name, graphic_path, target_tech, icon_size)
	DBL.log_warning("deadlock_stacking.create_stack() - this function is deprecated, consider using deadlock.add_stack() instead")
	deadlock.add_stack(item_name, graphic_path, target_tech, icon_size)
end

function deadlock_stacking.reset()
	DBL.log_warning("deadlock_stacking.reset() - this function is deprecated, consider using deadlock.destroy_vanilla_stacks() instead")
	for tech_name, technology in pairs(DBL.BELTBOX_TECHS) do
		-- iterate in reverse, clear all stack items but leave beltboxes
		for i = #technology.effects, 1, -1 do
			if technology.effects[i].type == "unlock-recipe" and string.find(technology.effects[i].recipe, "deadlock%-stacks%-") then
				table.remove(technology.effects, i)
			end
		end
	end
	DBL.debug("Technologies cleared.")
end

function deadlock_stacking.remove(target_tech)
	DBL.log_warning("deadlock_stacking.remove() - this function is deprecated, consider using deadlock.destroy_stack() instead")
	for tech_name, technology in pairs(DBL.BELTBOX_TECHS) do
		-- iterate in reverse, clear all matching items
		for i = #technology.effects, 1, -1 do
			if technology.effects[i].type == "unlock-recipe" and string.find(technology.effects[i].recipe, target_tech, 1, true) then
				DBL.debug(string.format("Removing recipe %s from technology %s", technology.effects[i].recipe, tech_name))
				table.remove(technology.effects, i)
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------

