-- stack vanilla items

local DBL = require("prototypes.shared")

for tier,items in ipairs(DBL.VANILLA_ITEMS) do
	for _,item in pairs(items) do
		deadlock.add_stack(item, string.format("__deadlock-beltboxes-loaders__/graphics/icons/square/stacked-%s.png", item), string.format("deadlock-stacking-%d", tier), DBL.VANILLA_ICON_SIZE)
	end
end