-- Factorio 2.1 merged RecipePrototype.category and additional_categories into categories.
-- Keep compatibility for recipes created by this mod/API and by older bridge mods.
for _, recipe in pairs(data.raw.recipe) do
	if recipe.category then
		recipe.categories = recipe.categories or { recipe.category }
		recipe.category = nil
	end
	if recipe.additional_categories then
		recipe.categories = recipe.categories or {}
		for _, category in pairs(recipe.additional_categories) do
			table.insert(recipe.categories, category)
		end
		recipe.additional_categories = nil
	end
end

-- run late stack updates for changes to stack sizes, fuel values, etc
deadlock.deferred_stacked_item_updates()

-- update the character prototype to allow "hand-unstacking"
table.insert(data.raw["character"]["character"].crafting_categories, "unstacking")
