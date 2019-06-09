Deadlock’s Stacking Beltboxes & Compact Loaders
==========================

**DSB** is a Factorio mod which adds small 1x1 loaders and beltboxes. These can be used to stack items from a belt, in-line,
greatly increasing belt throughput.

If you are a Factorio modder, you can get DSB to automatically
generate stacked versions of items from your own mods. A description of the DSB API is below.

Step 1
------

Add “?deadlock-beltboxes-loaders” as an optional dependency in your mod’s **info.json**.
For example:

~~~~
{
  "name": "DeadlockTweaks",
  "version": "0.1.0",
  "title": "Deadlock's Tweaks",
  "author": "Deadlock989",
  "contact": "",
  "homepage": "",
  "dependencies": ["base \>= 0.17.0", "?deadlock-beltboxes-loaders],
  "description": "Some small quality of life adjustments.",
  "factorio_version": "0.17"
}
~~~~

Step 2
------

DSB exposes a set of functions which handle stack creation (and optionally
beltbox and loader tier creation) for you. You should call these functions from your mod’s
**data-final-fixes.lua**. Check that **deadlock** exists before you try
and call any of the functions, so that your mod will still run without errors if
DSB isn’t installed. For example:

~~~~
-- [data-final-fixes.lua]
-- this mod makes diamonds. don’t dig straight down
-- we already created our items earlier on

-- get DSB to stack my itamz
if deadlock then
  -- repeat this for every item you want crated
  deadlock.add_stack("deadlock-uber-diamond", "__DeadlockTweaks__/graphics/icons/stacked-diamond.png", "deadlock-stacking-1", 64)
end
~~~~

Alternatively, if you have a long list of items which you want to insert into
different technologies, you could put them into some kind of array or table and
then loop through them.

This is the simplest use case. Several more functions are provided: these are
described on the following pages.

deadlock.add_stack()
----------------------------

This is the function used to crate things that DSB doesn’t handle by default. It
can take up to six parameters. A full call looks like this:
**deadlock.add_stack(item_name, graphic_path, target_tech, icon_size, item_type, mipmap_levels)**

| **Parameter**    | **Optional / Mandatory?** | **Explanation**                                                                                                                                                                                                                                                                                                     |
|------------------|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **item_name**    | Mandatory                 | String. The name of the item you want crated, e.g. “iron-plate”.                                                                                                                                                                                                                                                            |
| **graphic_path** | Optional                  | String. The path to an icon for your stacked item. Can be omitted, but this is bad for performance (see "More Details" below).                                                                                                                                                                                                                                                            |
| **target_tech**  | Optional                  | String. The technology name (e.g. “deadlock-stacking-1”) that the crating recipe unlocks will be inserted into. If specified, the technology **must already exist** as a prototype in data.raw. If omitted or nil, the mod won’t update any technologies, and you’ll have to handle gaining access to the recipes yourself. |
| **icon_size**    | Optional                  | Integer. The size of your custom icon in pixels. Defaults to 64. Not used if no icon is supplied.                                                                                                                                                                                                                                                          |
| **item_type**    | Optional                  | String. The type of item, e.g. "item", "ammo", "repair-tool" etc. Defaults to "item".                                                                                                                                                                                                                                                           |
| **mipmap_levels**| Optional                  | Integer. The mipmap levels of your custom icon. Defaults to nil. Not used if no icon is supplied.                                                                                                                                                                                                                                                            |

You can omit an optional parameter or specify nil to use the defaults.

Note that if you specify an item which has already been stacked, you may get unwanted results.
Consider using destroy_stack(), described below, to remove the item before you overwrite
it.

deadlock.destroy_stack()
--------------------------------

This takes one parameter, the item name:
**deadlock.destroy_stack(item_name)**

Calling this function will destroy the stacked version of the item, **all**
recipes which include the stack as an ingredient or result
(i.e. the stacking and unstacking recipes at minimum, but could in theory include
any other modded recipe that has used a stack as an ingredient), and removes
**all** references to the deleted recipes from **all** technologies.

Bear in mind that there could be other mods which expect any given stack to
exist. If you destroy them and don’t re-create them, you’re responsible for
sorting out any issues that causes. You can also use this function to clear a
stacked item and then rebuild it with add_stack(), for example to resolve
conflicts between two overhaul mods.

deadlock.destroy_vanilla_stacks()
-----------------------------------------

This takes no parameters and removes all of the vanilla stacked items and recipes
that DSB creates by default. Effectively it calls destroy_stack() on every item
the mod sets up in the early data stage. Use this if you want to wipe the slate
clean and rebuild from scratch.

deadlock.add_tier()
---------------------------

By default, DSB creates three tiers of beltboxes and loaders, which correspond
to yellow, red and blue belts in vanilla; it also creates three tiers of
technology which each unlock the machines and a collection of stacking recipes. You
can use this function to create new tiers of machine unlocked by new
technologies which correspond to belts that are provided by other mods (or have
some other reason for existing). Or you can use it to replace the default tiers
with different settings.

The function takes a table as its single parameter. The table can have the
following key/value pairs:

| **Parameter**       | **Optional / Mandatory?**   | **Explanation**                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
|---------------------|-----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **transport_belt**  | Mandatory                   | String. The prefix of the corresponding transport belt, e.g. "uber-". Used to calculate speeds. |
| **underground_belt**| Optional if beltbox_ingredients and loader_ingredients are specified | String. The name of the corresponding underground belt. By default, DSB bases beltbox and loader recipes on underground recipes. You can omit this parameter but you must then specify your own ingredients. |
| **splitter**        | Optional                    | String. Currently unused in this mod, but passed to styling mods if present. |
| **colour**          | Optional                    | Colour table. The tint colour for the machines. Defaults to pink.                                                                                                                                     |
| **technology**      | Recommended                 | String. The name of the corresponding logistics technology. Used to unlock loaders. Stacking recipes will not be unlocked if this is not defined.                                                                                                                                     |
| **order**           | Recommended                 | String. Order string for beltboxes and loaders.                                                                                                                                                                                                                                                                                                                     |
| **beltbox**          | Optional                    | String. Name of the beltbox prototype that will be created. Defaults to transport_belt.."-beltbox".                                                                                                                                                       |
| **beltbox_technology**| Optional                    | String. Name of the technology that unlocks the beltboxes and stacked items in the same tier. Defaults to beltbox_name but can be overridden - vanilla tiers use "deadlock-stacking-[1-3]" for legacy compatability.                                                                                                                                                      |
| **beltbox_ingredients**| Optional if underground_belt is specified | Table of IngredientPrototypes. The ingredients for the beltbox's recipe. Defaults to a formula based on underground_belt.                                                                                                                                                                                                                                                                                                                                                                          |
| **beltbox_recipe**   | Optional                    | String. Can be used to override the beltbox recipe prototype name.                                                                                                                                                                                            |
| **beltbox_item**     | Optional                    | String. Can be used to override the beltbox item prototype name.                                                                                                                                                                                            |
| **beltbox_category** | Optional                    | String. The crafting category for the beltbox. Defaults to "crafting". Use "crafting-with-fluid" if there is fluid in the recipe.                                                                                                                                                                                            |
| **loader**          | Optional                    | String. Name of the loader prototype that will be created. Defaults to transport_belt.."-loader".                                                                                                                                                       |
| **loader_ingredients**| Optional if underground_belt is specified | Table of IngredientPrototypes. The ingredients for the loader's recipe. Defaults to a formula based on underground_belt.                                                                                                                                                                                                                                                                                                                                                                          |
| **loader_recipe**   | Optional                    | String. Can be used to override the loader recipe prototype name.                                                                                                                                                                                            |
| **loader_item**     | Optional                    | String. Can be used to override the loader item prototype name.                                                                                                                                                                                            |
| **loader_category** | Optional                    | String. The crafting category for the loader. Defaults to "crafting". Use "crafting-with-fluid" if there is fluid in the recipe.                                                                                                                                                                                            |

Here is an example from the Integrations mod which adds support for a tier 4 beltbox and loader: 

~~~~
deadlock.add_tier({
	transport_belt      = "rapid-transport-belt-mk1",
	colour              = {r=10, g=225, b=25},
	underground_belt    = "rapid-transport-belt-to-ground-mk1",
	splitter            = "rapid-splitter-mk1",
	technology          = "logistics-4",
	order               = "d",
	loader_ingredients  = {
		{"express-transport-belt-loader",1},
		{"iron-gear-wheel",20},
		{amount = 40,name = "lubricant",type = "fluid"},
	},
	loader_category     = "crafting-with-fluid",
	beltbox_ingredients = {
		{"express-transport-belt-beltbox",1},
		{"iron-plate",40},
		{"iron-gear-wheel",40},
		{"processing-unit",5},
	},
	beltbox_technology  = "deadlock-stacking-4",
})
~~~~

More details
------------

**Data stages.** When should you call these functions? In
**data-final-fixes.lua**. Some functions may work before that in some
situations, but no guarantees. There is something of an arms race going on
between mods using data.lua, data-updates.lua and data-final-fixes.lua to do
different things with vanilla recipes, their own, and to make changes to other
mods. The general tendency is for things to happen later and later as mods try
to catch and/or prevent each other’s changes. There isn’t really much we can do
about that.

**Automatic icons.** When using add_stack(), if you specify the icon path and icon size as nil,
then DSB will create a triple-layered icon from the base item's icon automatically. There are two
issues with doing this: it won't necessarily look very good, and it is bad for rendering
performance. Remember that thousands of these items can be on the screen at once. Rendering
performance will be taxed by a minimum of 4x the rendering effort if you used stacked icons, more
if the base item itself already has layers. Try and supply your own stacked item icons wherever possible,
or people trying to use your mod on a low-spec GPU may suffer for it. The feature is only
included for legacy mod support: the standard game log will be spammed with warnings when
layered icons are created.

**Tech/migration.** If you add stacks to DSB technologies and then change them later, or
remove anything that they provide, **you are responsible for your own
migrations**. See DSB’s migrations folders for an example.

**Errors.** In some cases, you can call the API functions to create an item or a
tier with parameters which would not allow the game to load at all. In those
cases, the loading process will halt with an error message. **Please read it.**
In other cases, you can specify things that would allow the game to load but
just don’t make much sense. In those cases, the game will continue to load but
the function call may be skipped and an error or warning will be printed in the
default game log. So if your crates or machines are missing, check the log.

**“Helper” or “bridge” mods.** If your favourite modder doesn’t want to / have
time to provide support for stacking/crating, you could make your own mini
“helper” mod which simply bridges the gap. In this case you would require both
their mod and DSB as compulsory dependencies, not optional, and then all
your mini-mod does is loop through some items and maybe create a new tier if the
target mod provides different belts.

If you run into problems and have tried to solve them yourself but are stuck,
use the [Factorio forums
thread](https://forums.factorio.com/viewtopic.php?f=94&t=57264) to contact us.
Provide any error messages and show your code – we can’t guess from a vague
description.

This mod was originally authored by Deadlock989. It was ported to 0.17 and is
maintained by shanemadden with contributions from Deadlock989.
