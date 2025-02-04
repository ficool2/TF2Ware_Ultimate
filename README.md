# TF2Ware Ultimate
This repository contains the source code and assets for TF2Ware Ultimate.

<p align="center">
	<img src="materialsrc/__logo.png" width="500">
</p>

## Dedicated Server Setup

### Background
`host_timescale` requires the use of `sv_cheats` on dedicated servers, which is obviously problematic.

To workaround this, the plugin will block all cheat commands while the map is active (unless `ware_cheats` convar is set to 1).

Optionally, the plugin will also partially strip cosmetics/non-melee weapons (`loadoutwhitelister_enable` convar) by default.
This is used as an optimization for high player servers, as constantly loading all cosmetics and weapons causes heavy lag.
The whitelister will only allow hat cosmetics, which is a good middleground for allowing some player customization while preventing big stutters.

### Installation
Make sure you have SourceMod installed. This is not covered here, there are plenty of guides online.

Download the [latest release](https://github.com/ficool2/TF2Ware_Ultimate/releases). Extract it into your `addons` folder.

The plugin will automatically enable and disable itself when it detects the map name contains `tf2ware_ultimate`.

### Configuration
TF2Ware Ultimate loads its settings from the `tf/scriptdata/tf2ware_ultimate` folder. These settings will be generated on first launch of the map, if not present already.

Admin commands are supported (see: `!ware_help` in chat for commands). Listen server hosts can also use these commands.

### Events
The following events are sent by the gamemode if you would like to catch them. 
The unused event `player_rematch_change` is repurposed to allow VScript -> SourceMod communication, please see `ListenerVScript` in `tf2ware_ultimate.sp` for an example.

`minigame_start` 
* `name`          : english name of the minigame (can change depending on submode)
* `file_name`     : internal minigame file name (doesn't change)
* `players_valid` : string with list of player indices that are participating. each byte is the player index
* `is_boss`       : true if boss, false otherwise

`minigame_end`
* `name`          : english name of the minigame (can change depending on submode)
* `file_name`     : internal minigame file name (doesn't change)
* `players_passed`: string with list of player indices that won the minigame. each byte is the player index
* `players_valid` : string with list of player indices that are participating. each byte is the player index
* `is_boss`       : true if boss, false otherwise

`game_over`
* `players_won`             : string with list of player indices that won the game. each byte is the player index
* `players_score`           : string with a list of all player's score (sorted by their entity index). each byte is the player's score, including bonus. length is `MaxClients`
* `players_bonus`           : same as above but each byte is the bonus score. length is `MaxClients`
* `max_possible_score`      : maximum possible score to achieve, not including bonuses
* `special_round_name`      : english name of the special round (can change depending on submode), blank if no special round
* `special_round_file_name` : internal special round file name (doesn't change), blank if no special round

`bonus_points`
* `minigame_name`           : english name of the minigame this was awarded in (could be blank)
* `minigame_file_name `     : internal file name of the minigame this was awarded in (could be blank)
* `players_awarded`         : string with list of player indices that were given the bonus

## Contributing

Pull requests to add new minigames, bossgames, special rounds or themes are welcome.
Getting started with creating a new one is easy.

### Getting started
To get started, you will need to load the unpacked map of TF2Ware Ultimate, so you can modify assets and scripts easily.

First, download this repository into your TF2's `custom` folder. 

The repo comes with a built BSP without packed content. Type `map tf2ware_ultimate` in console to load this.

Now, go into `scripts/vscripts/tf2ware_ultimate` and then pick either `minigames`, `bossgames` or `specialrounds`.
Create a new .nut file there.

Next, for a minigame/bossgame (note that TF2Ware stores them in the same way), create a `Ware_MinigameData` definition. If making a special round, create a `Ware_SpecialRoundData` definition instead. Look at the other scripts in the same folder for plenty of examples.

Most of the documentation is in the .nut files themselves. All the settings and functions allowed for usage are documented in the `api` folder.

Once you are done, add the file's name to the `minigames.cfg`/`bossgames.cfg`/`specialrounds.cfg` in the `tf/scriptdata/tf2ware_ultimate` folder. 

Note that minigames, bossgames  and special rounds are hot loaded, therefore changes will be effective immediately. Use the `!ware_force` series of chat commands to force a specific one (type `!ware_help` in chat).

The text overlays for minigames and bossgames are static images. To generate one, run the `generate_text` Python script in the `tools` folder. This will automatically place all the materials and textures in the correct folder. Note if you are not using custom_overlay, the overlay must have the same file name as the minigame/bossgame .nut. There are also some common overlays in materials/hud/tf2ware_ultimate (such as get_end for any "course" minigames).

Mapping changes are also welcome, but please be descriptive about changes made, and test your compile before submitting a PR. Note when compiling, please add the following parameters to VRAD: `-noskyboxrecurse -staticproppolys -textureshadows`. If using the Hammer/Hammer++ compiler, this is in Expert under $light.exe. If using CompilePal, you can add these parameters inidividually under VRAD.

## Credits
Type `!ware_credits` in chat for a list of contributors in console.
