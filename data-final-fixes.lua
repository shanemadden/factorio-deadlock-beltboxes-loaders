-- compat: a stacks-<group> subgroup is left pointing at a deleted item-group when a later mod removes that group
-- (Krastorio2-spaced-out deletes "kr-smelting-crafting" and moves its subgroup to "intermediate-products").
-- Follow the group's same-named subgroup if one survives, otherwise fall back to intermediate-products.
for name, subgroup in pairs(data.raw["item-subgroup"]) do
	local group_name = string.match(name, "^stacks%-(.+)$")
	if group_name and not data.raw["item-group"][subgroup.group] then
		local moved = data.raw["item-subgroup"][group_name]
		subgroup.group = (moved and data.raw["item-group"][moved.group]) and moved.group or "intermediate-products"
	end
end

-- run late stack updates for changes to stack sizes, fuel values, etc
deadlock.deferred_stacked_item_updates()

-- update the character prototype to allow "hand-unstacking"
table.insert(data.raw["character"]["character"].crafting_categories, "unstacking")
