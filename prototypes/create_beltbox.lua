local DBL = require("prototypes.shared")

-- average a colour with off-white, to get a brighter contrast colour for lamps and lights
local function brighter_colour(c)
	local w = 240
	return { r = math.floor((c.r + w)/2), g = math.floor((c.g + w)/2), b = math.floor((c.b + w)/2) }
end

local function create_beltbox_entity(tier_table)
	local crafting_speed = data.raw["transport-belt"][tier_table.transport_belt].speed * 32
	local entity = {
		type = "furnace",
		name = tier_table.beltbox,
		localised_description = {"entity-description.deadlock-beltbox"},
		icons = {
			{ icon = "__deadlock-beltboxes-loaders__/graphics/icons/mipmaps/beltbox-icon-base.png" },
			{ icon = "__deadlock-beltboxes-loaders__/graphics/icons/mipmaps/beltbox-icon-mask.png", tint = tier_table.colour },
		},
		icon_size = 64,
		icon_mipmaps = 4,
		flags = { "placeable-neutral", "placeable-player", "player-creation" },
        graphics_set = {
            animation = {
                layers = {
                    {
                        filename = "__deadlock-beltboxes-loaders__/graphics/entities/high/beltbox-base.png",
                        animation_speed = 1 / crafting_speed,
                        priority = "high",
                        frame_count = 60,
                        line_length = 10,
                        height = 96,
                        scale = 0.5,
                        shift = {0, 0},
                        width = 96
                    },
                    {
                        filename = "__deadlock-beltboxes-loaders__/graphics/entities/high/beltbox-mask.png",
                        animation_speed = 1 / crafting_speed,
                        priority = "high",
                        repeat_count = 60,
                        height = 96,
                        scale = 0.5,
                        shift = {0, 0},
                        width = 96,
                        tint = tier_table.colour,
                    },
                    {
                        draw_as_shadow = true,
                        filename = "__deadlock-beltboxes-loaders__/graphics/entities/high/beltbox-shadow.png",
                        animation_speed = 1 / crafting_speed,
                        frame_count = 60,
                        line_length = 10,
                        height = 96,
                        scale = 0.5,
                        shift = {0.5, 0},
                        width = 144
                    },
                },
            },
            working_visualisations = {
                {
                    animation = {
                        animation_speed = 1 / crafting_speed,
                        blend_mode = "additive",
                        filename = "__deadlock-beltboxes-loaders__/graphics/entities/high/beltbox-working.png",
                        frame_count = 30,
                        line_length = 10,
                        height = 96,
                        priority = "high",
                        scale = 0.5,
                        tint = brighter_colour(tier_table.colour),
                        width = 96
                    },
                    light = {
                        color = brighter_colour(tier_table.colour),
                        intensity = 0.4,
                        size = 3,
                        shift = {0, 0.25},
                    },
                },
            }
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
		crafting_speed = crafting_speed,
		energy_source = {
			type = "electric",
			emissions_per_minute = {pollution = 3 * 0.03125 / data.raw["transport-belt"][tier_table.transport_belt].speed},
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
		show_recipe_icon = settings.startup["deadlock-stacking-show-alt-info"].value,
	}
	if settings.startup["deadlock-strict-fast-replace-beltboxes"].value then
		entity.fast_replaceable_group = "deadlock-beltbox"
	else
		entity.fast_replaceable_group = "transport-belt"
	end
	return entity
end

local function create_beltbox_item(tier_table)
	local item = {
		type = "item",
		name = tier_table.beltbox_item or tier_table.beltbox,
		localised_description = {"entity-description.deadlock-beltbox"},
		icons = {
			{ icon = "__deadlock-beltboxes-loaders__/graphics/icons/mipmaps/beltbox-icon-base.png" },
			{ icon = "__deadlock-beltboxes-loaders__/graphics/icons/mipmaps/beltbox-icon-mask.png", tint = tier_table.colour },
		},
		icon_size = 64,
		icon_mipmaps = 4,
		stack_size = 50,
		flags = {},
		place_result = tier_table.beltbox,
		group = "logistics",
		subgroup = "beltboxes",
		order = string.format("b%s%s", (tier_table.order or tier_table.loader), "-deadlock-beltbox"),
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
		order = string.format("b%s%s", (tier_table.order or tier_table.loader), "-deadlock-beltbox"),
		enabled = false,
		ingredients = tier_table.beltbox_ingredients,
		results = {{type = "item", name = tier_table.beltbox_item or tier_table.beltbox, amount = 1}},
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
	tech.icons = {
		{ icon = "__deadlock-beltboxes-loaders__/graphics/icons/square/beltbox-icon-base-128.png", icon_size = 128 },  -- 1.1 appears to be defaulting to 256
		{ icon = "__deadlock-beltboxes-loaders__/graphics/icons/square/beltbox-icon-mask-128.png", icon_size = 128, tint = tier_table.colour },  -- 1.1 appears to be defaulting to 256
	}
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
