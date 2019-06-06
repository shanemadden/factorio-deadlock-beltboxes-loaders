-- run late stack updates for changes to stack sizes, fuel values, etc
deadlock.deferred_stacked_item_updates()

-- update the character prototype to allow "hand-unstacking"
table.insert(data.raw["character"]["character"].crafting_categories, "unstacking")
