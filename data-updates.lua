-- create vanilla stacks
require("prototypes.vanilla_stacks")

-- hit the subgroups again to cover any added since data.lua load
for _, group in pairs(data.raw["item-group"]) do
	if not data.raw["item-subgroup"][string.format("stacks-%s", group.name)] then
		data:extend({
			{
				type = "item-subgroup",
				name = string.format("stacks-%s", group.name),
				group = group.name,
				order = "zzzzz",
			},
		})
	end
end
