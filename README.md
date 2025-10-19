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
* `players_score`           : string with a list of all player's score, in entity index order. each score is a decimal number in string form, separated by a space. there is always `MaxClients` number of entries. e.g. for 3 players `12 0 25`. 
* `players_bonus`           : same as above but each number is the bonus score

**note**: the format of `players_score` and `players_bonus` was changed on 19/10/25, due to a SourceMod bug which terminated the string early if a player had 0 score. Previously, it was a byte list of scores
* `max_possible_score`      : maximum possible score to achieve, not including bonuses
* `special_round_name`      : english name of the special round (can change depending on submode), blank if no special round
* `special_round_file_name` : internal special round file name (doesn't change), blank if no special round

`bonus_points`
* `minigame_name`           : english name of the minigame this was awarded in (could be blank)
* `minigame_file_name `     : internal file name of the minigame this was awarded in (could be blank)
* `players_awarded`         : string with list of player indices that were given the bonus

## Contributing

Pull requests to add new minigames, bossgames, special rounds or themes are welcome.
Getting started with contributing is easy - see [here](CONTRIBUTING.md) for more information.

## Credits

* ficool2 - Lead programmer and map porting
* pokemonPasta - Programmer, themes, map porting, trailer
* OctatonicSunrise - Logo, trailer renders

Type `!ware_credits` in chat for a full list of contributors in console.
