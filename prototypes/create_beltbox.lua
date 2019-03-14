local DBL = require("prototypes.shared")

local function create_beltbox_entity(tier_table)
	local entity = {
		type = "furnace",
		name = tier_table.beltbox,
		localised_description = {"entity-description.deadlock-beltbox"},
		icons = {
			{ icon = "__deadlock-beltboxes-loaders__/graphics/beltbox-icon-base.png" },
			{ icon = "__deadlock-beltboxes-loaders__/graphics/beltbox-icon-mask.png", tint = tier_table.colour },
		},
		icon_size = 32,
		flags = { "placeable-neutral", "placeable-player", "player-creation" },
		fast_replaceable_group = "transport-belt",
		animation = {
			layers = {
				{
					draw_as_shadow = true,
					hr_version = {
						draw_as_shadow = true,
						filename = "__deadlock-beltboxes-loaders__/graphics/hr-beltbox-shadow.png",
						frame_count = 8,
						height = 64,
						priority = "high",
						scale = 0.5,
						shift = {0.25, 0},
						width = 64
					},
					filename = "__deadlock-beltboxes-loaders__/graphics/lr-beltbox-shadow.png",
					frame_count = 8,
					height = 32,
					priority = "high",
					scale = 1,
					shift = {0.25, 0},
					width = 32	
				},
				{
					hr_version = {
						filename = "__deadlock-beltboxes-loaders__/graphics/hr-beltbox-base.png",
						frame_count = 8,
						height = 64,
						width = 64,
						priority = "extra-high",
						scale = 0.5,
					},
					filename = "__deadlock-beltboxes-loaders__/graphics/lr-beltbox-base.png",
					frame_count = 8,
					height = 32,
					width = 32,
					priority = "extra-high",
					scale = 1,
				},
				{
					hr_version = {
						filename = "__deadlock-beltboxes-loaders__/graphics/hr-beltbox-mask.png",
						frame_count = 8,
						height = 64,
						width = 64,
						priority = "high",
						scale = 0.5,
						tint = tier_table.colour,
					},
					filename = "__deadlock-beltboxes-loaders__/graphics/lr-beltbox-mask.png",
					frame_count = 8,
					height = 32,
					width = 32,
					priority = "high",
					scale = 1,
					tint = tier_table.colour,
				},
			},
		},
		dying_explosion = "explosion",
		corpse = "small-remnants",
		minable = {hardness = 0.2, mining_time = 0.5, result = tier_table.beltbox_item or tier_table.beltbox},
		module_specification = { module_slots = 0, module_info_icon_shift = {0,0.25} },
		allowed_effects = { "consumption" },
		max_health = 180,
		corpse = "small-remnants",
		collision_box = {{-0.2, -0.2}, {0.2, 0.2}},
		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
		drawing_box = {{-0.5, -0.5}, {0.5, 0.5}},
		result_inventory_size = 1,
		source_inventory_size = 1,
		crafting_categories = {"stacking", "unstacking"},
		crafting_speed = data.raw["transport-belt"][tier_table.transport_belt].speed * 18,
		energy_source = {
			type = "electric",
			emissions_per_second_per_watt = 0.000025 / (data.raw["transport-belt"][tier_table.transport_belt].speed * 18) ^ 2,
			usage_priority = "secondary-input",
			drain = "15kW",
		},
		-- 90kW for tier 1, base the rest on relative speed
		energy_usage = string.format("%dkW", math.floor((data.raw["transport-belt"][tier_table.transport_belt].speed / 0.03125) * 90)),
		resistances = {
			{
				type = "fire",
				percent = 50
			},
		},
		vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 1.0 },	
		working_sound = {
			match_speed_to_activity = true,
			idle_sound = {
			  filename = "__base__/sound/idle1.ogg",
			  volume = 0.6
			},
			sound = {
			  filename = "__deadlock-beltboxes-loaders__/sounds/fan.ogg",
			  volume = 1.0
			},
			max_sounds_per_type = 3,
		},
	}
	return entity
end

local function create_beltbox_item(tier_table)
	local item = {
		type = "item",
		name = tier_table.beltbox_item or tier_table.beltbox,
		localised_description = {"entity-description.deadlock-beltbox"},
		icons = {
			{ icon = "__deadlock-beltboxes-loaders__/graphics/beltbox-icon-base.png" },
			{ icon = "__deadlock-beltboxes-loaders__/graphics/beltbox-icon-mask.png", tint = tier_table.colour },
		},
		icon_size = 32,
		stack_size = 50,
		flags = {},
		place_result = tier_table.beltbox,
		group = "logistics",
		subgroup = "beltboxes",
		order = "b"..(tier_table.order or tier_table.beltbox),
	}
	return item
end

local function create_beltbox_recipe(tier_table)
	local recipe = {
		type = "recipe",
		name = tier_table.beltbox_recipe or tier_table.beltbox,
		localised_description = {"entity-description.deadlock-beltbox"},
		category = tier_table.beltbox_category,
		group = "logistics",
		subgroup = "beltboxes",
		order = "b"..(tier_table.order or tier_table.beltbox),
		enabled = false,
		ingredients = tier_table.beltbox_ingredients,
		result = tier_table.beltbox_item or tier_table.beltbox,
		energy_required = 3.0,
	}
	if not tier_table.beltbox_technology then
		recipe.enabled = true
	end
	return recipe
end

local function create_beltbox_technology(tier_table)
	local tech = table.deepcopy(data.raw.technology[tier_table.technology])
	tech.effects = {
		{
			type = "unlock-recipe",
			recipe = tier_table.beltbox_recipe or tier_table.beltbox,
		}
	}
	tech.icon = "__deadlock-beltboxes-loaders__/graphics/deadlock-stacking.png"
	tech.name = tier_table.beltbox_technology
	tech.unit.count = tech.unit.count * 1.5
	tech.prerequisites = {tier_table.technology}
	tech.upgrade = false
	return tech
end

function DBL.create_beltbox(tier_table)
	DBL.debug(string.format("Generating beltbox for tier %s", tier_table.transport_belt))
	data:extend({
		create_beltbox_entity(tier_table),
		create_beltbox_item(tier_table),
		create_beltbox_recipe(tier_table),
	})
	if tier_table.technology and tier_table.beltbox_technology then
		DBL.debug(string.format("Creating beltbox tech %s", tier_table.beltbox_technology))
		if data.raw.technology[tier_table.beltbox_technology] then
			table.insert(data.raw.technology[tier_table.beltbox_technology].effects, 2, {
				type = "unlock-recipe",
				recipe = tier_table.beltbox_recipe or tier_table.beltbox,
			})
		else
			data:extend({
				create_beltbox_technology(tier_table)
			})
			DBL.BELTBOX_TECHS[tier_table.beltbox_technology] = data.raw.technology[tier_table.beltbox_technology]
		end
	end
end
