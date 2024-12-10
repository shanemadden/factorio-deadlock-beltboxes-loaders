-- tier 1
deadlock.add_tier({
	transport_belt      = "transport-belt",
	colour              = {r=210, g=180, b=80},
	underground_belt    = "underground-belt",
	splitter            = "splitter",
	technology          = "logistics",
	order               = "a",
	loader_ingredients  = {
		{name = "transport-belt", type = "item", amount = 1},
		{name = "iron-plate", type = "item", amount = 5},
	},
	beltbox_ingredients = {
		{name = "transport-belt", type = "item", amount = 4},
		{name = "iron-plate", type = "item", amount = 10},
		{name = "iron-gear-wheel", type = "item", amount = 10},
		{name = "electronic-circuit", type = "item", amount = 4},
	},
	beltbox_technology  = "deadlock-stacking-1",
})
if data.raw["loader-1x1"]["transport-belt-loader"] then
	data.raw["loader-1x1"]["transport-belt-loader"].next_upgrade = "fast-transport-belt-loader"
end
if data.raw.furnace["transport-belt-beltbox"] then
	data.raw.furnace["transport-belt-beltbox"].next_upgrade = "fast-transport-belt-beltbox"
end

-- tier 2
deadlock.add_tier({
	transport_belt      = "fast-transport-belt",
	colour              = {r=210, g=60, b=60},
	underground_belt    = "fast-underground-belt",
	splitter            = "fast-splitter",
	technology          = "logistics-2",
	order               = "b",
	loader_ingredients  = {
		{name = "transport-belt-loader", type = "item", amount = 1},
		{name = "iron-gear-wheel", type = "item", amount = 20},
	},
	beltbox_ingredients = {
		{name = "transport-belt-beltbox", type = "item", amount = 1},
		{name = "iron-plate", type = "item", amount = 20},
		{name = "iron-gear-wheel", type = "item", amount = 20},
		{name = "advanced-circuit", type = "item", amount = 2},
	},
	beltbox_technology  = "deadlock-stacking-2",
})
if data.raw.technology["deadlock-stacking-2"] then
	table.insert(data.raw.technology["deadlock-stacking-2"].prerequisites, "deadlock-stacking-1")
end
if data.raw["loader-1x1"]["fast-transport-belt-loader"] then
	data.raw["loader-1x1"]["fast-transport-belt-loader"].next_upgrade = "express-transport-belt-loader"
end
if data.raw.furnace["fast-transport-belt-beltbox"] then
	data.raw.furnace["fast-transport-belt-beltbox"].next_upgrade = "express-transport-belt-beltbox"
end

-- tier 3
deadlock.add_tier({
	transport_belt      = "express-transport-belt",
	colour              = {r=80, g=180, b=210},
	underground_belt    = "express-underground-belt",
	splitter            = "express-splitter",
	technology          = "logistics-3",
	order               = "c",
	loader_ingredients  = {
		{name = "fast-transport-belt-loader", type = "item", amount = 1},
		{name = "iron-gear-wheel", type = "item", amount = 40},
		{name = "lubricant", type = "fluid", amount = 20},
	},
	loader_category     = "crafting-with-fluid-or-metallurgy",
	beltbox_ingredients = {
		{name = "fast-transport-belt-beltbox", type = "item", amount = 1},
		{name = "iron-plate", type = "item", amount = 30},
		{name = "iron-gear-wheel", type = "item", amount = 30},
		{name = "lubricant", type = "fluid", amount = 100},
	},
	beltbox_category    = "crafting-with-fluid-or-metallurgy",
	beltbox_technology  = "deadlock-stacking-3",
})
if data.raw.technology["deadlock-stacking-3"] then
	table.insert(data.raw.technology["deadlock-stacking-3"].prerequisites, "deadlock-stacking-2")
end
if data.raw["loader-1x1"]["express-transport-belt-loader"] then
	data.raw["loader-1x1"]["express-transport-belt-loader"].next_upgrade = "turbo-transport-belt-loader"
end
if data.raw.furnace["express-transport-belt-beltbox"] then
	data.raw.furnace["express-transport-belt-beltbox"].next_upgrade = "turbo-transport-belt-beltbox"
end

if mods["space-age"] then
    -- tier 4
    deadlock.add_tier({
        transport_belt      = "turbo-transport-belt",
        colour              = {r=160, g=190, b=80},
        underground_belt    = "turbo-underground-belt",
        splitter            = "turbo-splitter",
        technology          = "turbo-transport-belt",
        order               = "d",
        loader_ingredients  = {
            {name = "express-transport-belt-loader", type = "item", amount = 1},
            {name = "tungsten-plate", type = "item", amount = 20},
            {name = "lubricant", type = "fluid", amount = 20},
        },
        loader_category     = "crafting-with-fluid-or-metallurgy",
        beltbox_ingredients = {
            {name = "express-transport-belt-beltbox", type = "item", amount = 1},
            {name = "tungsten-plate", type = "item", amount = 15},
            {name = "iron-gear-wheel", type = "item", amount = 15},
            {name = "lubricant", type = "fluid", amount = 100},
        },
        beltbox_category    = "crafting-with-fluid-or-metallurgy",
        beltbox_technology  = "deadlock-stacking-4",
    })
    if data.raw.technology["deadlock-stacking-4"] then
        table.insert(data.raw.technology["deadlock-stacking-4"].prerequisites, "deadlock-stacking-3")
    end
end
