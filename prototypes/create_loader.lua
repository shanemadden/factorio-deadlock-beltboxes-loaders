local DBL = require("prototypes.shared")

local function create_loader_belt_component(source)
	local component = {
		filename    = source.filename,
		width       = source.width,
		height      = source.height,
		line_length = source.line_length,
		frame_count = source.frame_count,
		y           = source.y,
		scale       = source.scale,
		priority    = "extra-high",
		flags       = { "no-crop", "low-object" },
	}
	if source.hr_version then
		component.hr_version = {
			filename    = source.hr_version.filename,
			width       = source.hr_version.width,
			height      = source.hr_version.height,
			line_length = source.hr_version.line_length,
			frame_count = source.hr_version.frame_count,
			y           = source.hr_version.y,
			scale       = source.hr_version.scale,
			priority    = "extra-high",
			flags       = { "no-crop", "low-object" },
		}
	end
	return component
end

local function create_loader_entity(tier_table)
	local entity = {}
	entity.type = "loader"
	entity.name = tier_table.loader
	entity.localised_description = {"entity-description.deadlock-loader"}
	entity.icons = {
		{ icon = "__deadlock-beltboxes-loaders__/graphics/loader-icon-base.png" },
		{ icon = "__deadlock-beltboxes-loaders__/graphics/loader-icon-mask.png", tint = tier_table.colour },
	}
	entity.icon_size = 32
	entity.flags = {"placeable-neutral", "player-creation"}
	entity.vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 1.0 }
	entity.open_sound = { filename = "__base__/sound/wooden-chest-open.ogg", volume = 1.0 }
	entity.close_sound = { filename = "__base__/sound/wooden-chest-close.ogg", volume = 1.0 }
	entity.corpse = "small-remnants"
	entity.collision_box = { {-0.2, -0.2}, {0.2, 0.2} }
	entity.collision_mask = {"item-layer", "object-layer", "player-layer", "water-tile"}
	entity.selection_box = { {-0.5, -0.5}, {0.5, 0.5} }
	entity.minable = { hardness = 0.2, mining_time = 0.5, result = tier_table.loader_item or tier_table.loader }
	entity.max_health = 170
	entity.resistances = {{type = "fire", percent = 60 }}
	entity.belt_distance = 0
	entity.container_distance = 1.0
	entity.belt_length = 0.5
	entity.filter_count = 5
	entity.animation_speed_coefficient = 32
	if settings.startup["deadlock-strict-fast-replace-loaders"].value then
		entity.fast_replaceable_group = "deadlock-loader"
	else
		entity.fast_replaceable_group = "transport-belt"
	end
	entity.speed = data.raw["transport-belt"][tier_table.transport_belt].speed
	entity.structure = {
		direction_in = {
			sheets = {
				{
					hr_version = {
						filename = "__deadlock-beltboxes-loaders__/graphics/hr-loader-base.png",
						height = 64,
						priority = "extra-high",
						width = 80,
						scale = 0.5,
						shift = { 0.125, 0 },
					},
					filename = "__deadlock-beltboxes-loaders__/graphics/lr-loader-base.png",
					height = 32,
					priority = "extra-high",
					width = 40,
					scale = 1,
					shift = { 0.125, 0 },
				},
				{
					hr_version = {
						filename = "__deadlock-beltboxes-loaders__/graphics/hr-loader-mask.png",
						height = 64,
						priority = "extra-high",
						width = 80,
						scale = 0.5,
						tint = tier_table.colour,
						shift = { 0.125, 0 },
					},
					filename = "__deadlock-beltboxes-loaders__/graphics/lr-loader-mask.png",
					height = 32,
					priority = "extra-high",
					width = 40,
					scale = 1,
					tint = tier_table.colour,
					shift = { 0.125, 0 },
				},
			},
		},
		direction_out = {
			sheets = {
				{
					hr_version = {
						filename = "__deadlock-beltboxes-loaders__/graphics/hr-loader-base.png",
						height = 64,
						priority = "extra-high",
						width = 80,
						scale = 0.5,
						shift = { 0.125, 0 },
					},
					filename = "__deadlock-beltboxes-loaders__/graphics/lr-loader-base.png",
					height = 32,
					priority = "extra-high",
					width = 40,
					scale = 1,
					shift = { 0.125, 0 },
				},
				{
					hr_version = {
						filename = "__deadlock-beltboxes-loaders__/graphics/hr-loader-mask.png",
						height = 64,
						priority = "extra-high",
						width = 80,
						scale = 0.5,
						tint = tier_table.colour,
						shift = { 0.125, 0 },
						y = 64
					},
					filename = "__deadlock-beltboxes-loaders__/graphics/lr-loader-mask.png",
					height = 32,
					priority = "extra-high",
					width = 40,
					scale = 1,
					tint = tier_table.colour,
					shift = { 0.125, 0 },
					y = 32
				},
			},
		}
	}
	-- copy belt textures from the belt, not the loader
	if data.raw["transport-belt"][tier_table.transport_belt].belt_animation_set then
		-- new style animation set
		entity.belt_animation_set = data.raw["transport-belt"][tier_table.transport_belt].belt_animation_set
	else
		-- old style, copy components
		for _, bc in ipairs(DBL.BELT_COMPONENTS) do
			if entity[bc] and data.raw["transport-belt"][tier_table.transport_belt][bc] then
				entity[bc] = create_loader_belt_component(data.raw["transport-belt"][tier_table.transport_belt][bc])
			end
		end
	end
	entity.structure_render_layer = "transport-belt-circuit-connector"
	return entity
end

local function create_loader_item(tier_table)
	local item = {
		type = "item",
		name = tier_table.loader_item or tier_table.loader,
		localised_description = {"entity-description.deadlock-loader"},
		icons = {
			{ icon = "__deadlock-beltboxes-loaders__/graphics/loader-icon-base.png" },
			{ icon = "__deadlock-beltboxes-loaders__/graphics/loader-icon-mask.png", tint = tier_table.colour },
		},
		icon_size = 32,
		stack_size = 50,
		flags = {},
		place_result = tier_table.loader,
		group = "logistics",
		subgroup = "loaders",
		order = string.format("a%s%s", (tier_table.order or tier_table.loader), "-deadlock-loader"),
	}
	return item
end

local function create_loader_recipe(tier_table)
	local recipe = {
		type = "recipe",
		name = tier_table.loader_recipe or tier_table.loader,
		localised_description = {"entity-description.deadlock-loader"},
		category = tier_table.loader_category,
		group = "logistics",
		subgroup = "loaders",
		order = "a"..(tier_table.order or tier_table.loader),
		enabled = false,
		ingredients = tier_table.loader_ingredients,
		result = tier_table.loader_item or tier_table.loader,
		energy_required = 2.0,
	}
	if not tier_table.technology then
		recipe.enabled = true
	end
	return recipe
end

function DBL.create_loader(tier_table)
	DBL.debug(string.format("Generating loader for tier %s", tier_table.transport_belt))
	data:extend({
		create_loader_item(tier_table),
		create_loader_entity(tier_table),
		create_loader_recipe(tier_table),
	})
	-- insert the loader recipe into logistics unlock
	if tier_table.technology then
		local tech = data.raw.technology[tier_table.technology]
		if not tech then
			DBL.log_error(string.format("Bad tech specified for loader, %s", tier_table.technology))
			return
		end
		DBL.debug(string.format("Adding loader to tech %s", tier_table.technology))
		table.insert(tech.effects,
			{
				type = "unlock-recipe",
				recipe = tier_table.loader_recipe or tier_table.loader,
			}
		)
	end
end
