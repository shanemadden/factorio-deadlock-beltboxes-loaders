![beltbox](https://i.imgur.com/JoFG35F.gif)

# Deadlock's Stacking Beltboxes and Compact Loaders

[Deadlock's Stacking Beltboxes](https://mods.factorio.com/mod/DeadlockStacking) and [Deadlock's Compact Loaders](https://mods.factorio.com/mod/DeadlockLoaders) are now combined into one mod.

For existing saves, the updated versions of the existing Deadlock mod(s) you were using must be loaded to migrate your existing loaders and beltboxes to this new mod - see those mods' pages for more details on how to migrate those saves.

The integration with Bob's Logistics, Factorio Extended (and Extended Plus), and Xander Mod has been moved to a separate mod - if you're using loaders or beltboxes with their belt tiers, also [get the integrations mod](https://mods.factorio.com/mod/deadlock-integrations).

Note that the belt reskin and map recolor options are not yet implemented.

Any issues with the new version? Let us know in the [forum thread.](https://forums.factorio.com/viewtopic.php?f=94&t=57264)

# Credits

* Concept, graphics, and originally authored by [Deadlock989](https://mods.factorio.com/user/deadlock989).
* Maintained by [shanemadden](https://mods.factorio.com/user/shanemadden).

# Inter-mod support

The modding API available in the new version should be almost completely unchanged from the previous versions. An updated dedicated document is coming soon for the modding API, but here's what you need to know:

 - The default icon_size has changed to 64x64 for the API calls to add stacked items, since your icons are likely still 32x32 you'll need to pass an icon size. (Vanilla icons are still 32x32, per fff-277 we can expect the new ones sometime during 0.17 experimental)

A call that looked like this:

    deadlock_stacking.create("raw-wood", icon_path, "deadlock-stacking-1")

with a 32x32 icon will need to be changed to this for 0.17:

    deadlock_stacking.create("raw-wood", icon_path, "deadlock-stacking-1", 32)

 - A new API function is available to create loaders and beltboxes to match any tier of belt. Full documentation coming soon, but intrepid modders will find [parameter details in the comments](https://github.com/shanemadden/factorio-deadlock-beltboxes-loaders/blob/master/prototypes/public.lua#L5) and [examples in the base code](https://github.com/shanemadden/factorio-deadlock-beltboxes-loaders/blob/master/prototypes/vanilla_tiers.lua).
