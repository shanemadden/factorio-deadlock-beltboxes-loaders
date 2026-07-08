Deadlock's Stacking Beltboxes & Compact Loaders Continued
==========================

Community-maintained continuation of **Deadlock's Stacking Beltboxes & Compact Loaders**, updated for Factorio 2.1.

This mod adds small 1x1 loaders and beltboxes. These can be used to stack items from a belt, in-line, greatly increasing belt throughput.

Status
------

This continuation currently focuses on keeping the original mod working on newer Factorio versions.

Tested with:

- Factorio 2.1
- Basic loaders
- Beltboxes
- Stacking and unstacking recipes

Credits
-------

Original authors:

- Deadlock989
- Shane Madden
- MasterBuilder

Continuation maintainer:

- goakiller900

All credit for the original mod, concept, graphics, and implementation belongs to the original authors.

Unofficial continuation notice
------------------------------

This is not an official release from the original maintainers. It exists to keep the mod usable on newer Factorio versions.

If one of the original maintainers returns and wishes to resume maintenance, this continuation can be archived, redirected, or transferred as appropriate.

License
-------

This project remains licensed under the GNU General Public License version 3, as required by the original license.

Modding API
-----------

If you are a Factorio modder, you can get DSB to automatically generate stacked versions of items from your own mods. A description of the DSB API is below.

Step 1
------

Add `?deadlock-beltboxes-loaders` as an optional dependency in your mod's **info.json**.

For example:

~~~~
{
  "name": "DeadlockTweaks",
  "version": "0.1.0",
  "title": "Deadlock's Tweaks",
  "author": "Deadlock989",
  "contact": "",
  "homepage": "",
  "dependencies": ["base >= 2.1", "?deadlock-beltboxes-loaders"],
  "description": "Some small quality of life adjustments.",
  "factorio_version": "2.1"
}
~~~~

Step 2
------

DSB exposes a set of functions which handle stack creation, and optionally beltbox and loader tier creation, for you. You should call these functions from your mod's **data-final-fixes.lua**. Check that **deadlock** exists before you try and call any of the functions, so that your mod will still run without errors if DSB is not installed.

For example:

~~~~
-- [data-final-fixes.lua]
-- this mod makes diamonds. don't dig straight down
-- we already created our items earlier on

if deadlock then
  -- repeat this for every item you want crated
  deadlock.add_stack("deadlock-uber-diamond", "__DeadlockTweaks__/graphics/icons/stacked-diamond.png", "deadlock-stacking-1", 64)
end
~~~~

Alternatively, if you have a long list of items which you want to insert into different technologies, you could put them into an array/table and loop through them.

This is the simplest use case. Several more functions are provided below.

deadlock.add_stack()
--------------------

This is the function used to create stacked variants for things that DSB does not handle by default.

Full call:

**deadlock.add_stack(item_name, graphic_path, target_tech, icon_size, item_type, mipmap_levels)**

| Parameter | Optional / Mandatory? | Explanation |
|---|---|---|
| **item_name** | Mandatory | String. The name of the item you want crated, e.g. `iron-plate`. |
| **graphic_path** | Optional | String. The path to an icon for your stacked item. Can be omitted, but this is bad for performance. |
| **target_tech** | Optional | String. The technology name, e.g. `deadlock-stacking-1`, that the crating recipe unlock will be inserted into. If specified, the technology must already exist as a prototype in `data.raw`. |
| **icon_size** | Optional | Integer. The size of your custom icon in pixels. Defaults to 64. Not used if no icon is supplied. |
| **item_type** | Optional | String. The type of item, e.g. `item`, `ammo`, `repair-tool`. Defaults to `item`. |
| **mipmap_levels** | Optional | Integer. The mipmap levels of your custom icon. Defaults to nil. Not used if no icon is supplied. |

You can omit an optional parameter or specify nil to use the defaults.

Note that if you specify an item which has already been stacked, you may get unwanted results. Consider using `destroy_stack()` to remove the item before you overwrite it.

deadlock.destroy_stack()
------------------------

This takes one parameter, the item name:

**deadlock.destroy_stack(item_name)**

Calling this function will destroy the stacked version of the item, all recipes which include the stack as an ingredient or result, and remove all references to the deleted recipes from all technologies.

Bear in mind that other mods may expect a given stack to exist. If you destroy it and do not re-create it, you are responsible for sorting out any issues that causes.

deadlock.destroy_vanilla_stacks()
---------------------------------

This takes no parameters and removes all of the vanilla stacked items and recipes that DSB creates by default. Effectively it calls `destroy_stack()` on every item the mod sets up in the early data stage.

deadlock.add_tier()
-------------------

By default, DSB creates tiers of beltboxes and loaders matching the vanilla belt tiers, with Space Age turbo support when Space Age is present.

You can use this function to create new tiers of machines unlocked by new technologies which correspond to belts provided by other mods.

The function takes a table as its single parameter. The table can have the following key/value pairs:

| Parameter | Optional / Mandatory? | Explanation |
|---|---|---|
| **transport_belt** | Mandatory | String. The name of the corresponding transport belt. Used to calculate speeds. |
| **underground_belt** | Optional if ingredients are specified | String. The name of the corresponding underground belt. By default, DSB bases beltbox and loader recipes on underground recipes. |
| **splitter** | Optional | String. Currently unused in this mod, but passed to styling mods if present. |
| **colour** | Optional | Colour table. The tint colour for the machines. Defaults to pink. |
| **technology** | Recommended | String. The name of the corresponding logistics technology. Used to unlock loaders. |
| **order** | Recommended | String. Order string for beltboxes and loaders. |
| **beltbox** | Optional | String. Name of the beltbox prototype that will be created. Defaults to `transport_belt .. "-beltbox"`. |
| **beltbox_technology** | Optional | String. Name of the technology that unlocks the beltboxes and stacked items in the same tier. |
| **beltbox_ingredients** | Optional if underground_belt is specified | Table of IngredientPrototypes. Ingredients for the beltbox recipe. |
| **beltbox_recipe** | Optional | String. Can be used to override the beltbox recipe prototype name. |
| **beltbox_item** | Optional | String. Can be used to override the beltbox item prototype name. |
| **beltbox_category** | Optional | String. The crafting category for the beltbox. Defaults to `crafting`. |
| **loader** | Optional | String. Name of the loader prototype that will be created. Defaults to `transport_belt .. "-loader"`. |
| **loader_ingredients** | Optional if underground_belt is specified | Table of IngredientPrototypes. Ingredients for the loader recipe. |
| **loader_recipe** | Optional | String. Can be used to override the loader recipe prototype name. |
| **loader_item** | Optional | String. Can be used to override the loader item prototype name. |
| **loader_category** | Optional | String. The crafting category for the loader. Defaults to `crafting`. |

More details
------------

**Data stages.** These functions are intended to be called in **data-final-fixes.lua**. Some functions may work earlier in some situations, but there are no guarantees.

**Automatic icons.** When using `add_stack()`, if you omit the icon path and icon size, DSB will create a layered icon from the base item's icon automatically. This is convenient but may not look as good and is worse for rendering performance than supplying custom stacked icons.

**Tech/migration.** If you add stacks to DSB technologies and then change them later, or remove anything that they provide, you are responsible for your own migrations.

**Errors.** In some cases, invalid API calls can stop the game from loading. In other cases, the game may continue to load but the function call may be skipped and an error or warning printed to the log.

This mod was originally authored by Deadlock989. It was ported to 0.17 and later maintained by shanemadden with contributions from Deadlock989 and MasterBuilder.
