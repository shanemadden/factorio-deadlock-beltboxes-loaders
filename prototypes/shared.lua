-- internal module table
local DBL = {}

function DBL.debug(message)
	---- DEBUG LOGGING ----
	-- set below false to true for debug logging during the data phase to factorio's log file
	if false then
		log(string.format("DBL: %s", message))
	end
end

function DBL.log_error(message)
	log(string.format("DBL: Error: %s", message))
end

function DBL.log_warning(message)
	log(string.format("DBL: Warning: %s", message))
end

DBL.STACK_SIZE = settings.startup["deadlock-stack-size"].value
DBL.CRAFT_TIME = DBL.STACK_SIZE / 15

DBL.VANILLA_ITEMS = {
	[1] = { "wood", "iron-ore", "copper-ore", "stone", "coal", "iron-plate", "copper-plate", "steel-plate", "stone-brick", "tungsten-ore" },
	[2] = { "copper-cable", "iron-gear-wheel", "iron-stick", "sulfur", "plastic-bar", "solid-fuel", "electronic-circuit", "advanced-circuit" },
	[3] = { "processing-unit", "battery", "uranium-ore", "uranium-235", "uranium-238" },
	[4] = { "scrap" },
}
DBL.VANILLA_ICON_SIZE = 32

if settings.startup["deadlock-stacking-batch-stacking"].value then
	DBL.RECIPE_MULTIPLIER = 4
else
	DBL.RECIPE_MULTIPLIER = 1
end
DBL.BELT_COMPONENTS = {
	"animations",
	"belt_horizontal",
	"belt_vertical",
	"ending_top",
	"ending_bottom",
	"ending_side",
	"starting_top",
	"starting_bottom",
	"starting_side",
}
DBL.BELTBOX_TECHS = {}

if not data.raw["item-subgroup"]["beltboxes"] then
	data:extend({
		{
			type = "item-subgroup",
			name = "loaders",
			group = "logistics",
			order = "bb",
		},
		{
			type = "item-subgroup",
			name = "beltboxes",
			group = "logistics",
			order = "bba",
		},
		{
			type = "recipe-category",
			name = "stacking",
		},
		{
			type = "recipe-category",
			name = "unstacking",
		},
	})
end

-- make a subgroup at the bottom of each crafting tab
for _, group in pairs(data.raw["item-group"]) do
	data:extend({
		{
			type = "item-subgroup",
			name = string.format("stacks-%s", group.name),
			group = group.name,
			order = "zzzzz",
		},
	})
end

-- meta-tables for item/recipe order
-- assign a order for the stacked items based on the order in which they're created,
-- remembering the assigned order for any items that get stacking applied multiple times
DBL.item_order = {}
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
	DBL.item_order = setmetatable(DBL.item_order, item_order_metatable)
end
DBL.recipe_order = {}
do
	local recipe_increment = 1
	local recipe_order_metatable = {
		__index = function(table, key)
			table[key] = string.format("%03d", recipe_increment)
			recipe_increment = recipe_increment + 1
			return table[key]
		end
	}
	DBL.recipe_order = setmetatable(DBL.recipe_order, recipe_order_metatable)
end

return DBL
