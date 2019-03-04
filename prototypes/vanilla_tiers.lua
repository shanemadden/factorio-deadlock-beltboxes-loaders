-- tier 1
deadlock.add_tier({
	transport_belt      = "transport-belt",
	colour              = {r=225, g=165, b=10},
	underground_belt    = "underground-belt",
	splitter            = "splitter",
	technology          = "logistics",
	order               = "a",
	loader_ingredients  = {
		{"transport-belt", 1},
		{"iron-plate", 5},
	},
	beltbox_ingredients = {
		{"transport-belt", 4},
		{"iron-plate", 10},
		{"iron-gear-wheel", 10},
		{"electronic-circuit", 4},
	},
	beltbox_technology  = "deadlock-stacking-1",
})

-- tier 2
deadlock.add_tier({
	transport_belt      = "fast-transport-belt",
	colour              = {r=225, g=10, b=10},
	underground_belt    = "fast-underground-belt",
	splitter            = "fast-splitter",
	technology          = "logistics-2",
	order               = "b",
	loader_ingredients  = {
		{"transport-belt-loader", 1},
		{"iron-gear-wheel", 20},
	},
	beltbox_ingredients = {
		{"transport-belt-beltbox", 1},
		{"iron-plate", 20},
		{"iron-gear-wheel", 20},
		{"advanced-circuit", 2},
	},
	beltbox_technology  = "deadlock-stacking-2",
})
if data.raw.technology["deadlock-stacking-2"] then
	table.insert(data.raw.technology["deadlock-stacking-2"].prerequisites, "deadlock-stacking-1")
end

-- tier 3
deadlock.add_tier({
	transport_belt      = "express-transport-belt",
	colour              = {r=10, g=165, b=225},
	underground_belt    = "express-underground-belt",
	splitter            = "express-splitter",
	technology          = "logistics-3",
	order               = "c",
	loader_ingredients  = {
		{"fast-transport-belt-loader", 1},
		{"iron-gear-wheel", 40},
		{name = "lubricant", type = "fluid", amount = 20},
	},
	loader_category     = "crafting-with-fluid",
	beltbox_ingredients = {
		{"fast-transport-belt-beltbox", 1},
		{"iron-plate", 30},
		{"iron-gear-wheel", 30},
		{name = "lubricant", type = "fluid", amount = 100},
	},
	beltbox_category    = "crafting-with-fluid",
	beltbox_technology  = "deadlock-stacking-3",
})
if data.raw.technology["deadlock-stacking-3"] then
	table.insert(data.raw.technology["deadlock-stacking-3"].prerequisites, "deadlock-stacking-2")
end
