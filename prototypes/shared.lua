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

DBL.STACK_SIZE = 5
DBL.CRAFT_TIME = 3 * DBL.STACK_SIZE / 80
DBL.ITEM_ORDER = 1
DBL.RECIPE_ORDER = 1

if settings.startup["deadlock-stacking-batch-stacking"].value then
	DBL.RECIPE_MULTIPLIER = 4
else
	DBL.RECIPE_MULTIPLIER = 1
end

DBL.BELTBOX_TECHS = {}

if not data.raw["item-subgroup"]["beltboxes"] then
	data:extend({
		{
			type = "item-subgroup",
			name = "beltboxes",
			group = "logistics",
			order = "bb",
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

-- update the player prototype to allow the unstacking category by hand
table.insert(data.raw["player"]["player"].crafting_categories, "unstacking")

return DBL
