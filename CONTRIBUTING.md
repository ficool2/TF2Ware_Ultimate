# Contributing
We welcome any contributions to minigames, bossgames, special rounds, themes, or to the map itself!

## Style
Please follow the codebase's style when making contributions:
* No semicolons in VScript contributions. Semicolons are optional in Squirrel and TF2Ware Ultimate does *not* use them.
* Do not define constants or global variables within a minigame/bossgame/specialround scope.
* When iterating through arrays and tables, use `foreach` instead of `for` where possible.
  * Note iterating through tables uses slightly different syntax `foreach(k,v in table)` to account for keys and values, this is mandatory even if you are only accessing the key or the value.
* Please use CRLF for line breaks.
* Indents should be 4 spaces.


If in doubt, there are plenty of examples for each type of contribution - try to match how they are laid out.

## Getting started
To get started, you will need to load the unpacked map of TF2Ware Ultimate, so you can modify assets and scripts easily.

First, download this repository into your TF2's `custom` folder. 

The repo comes with a built BSP without packed content. Type `map tf2ware_ultimate` in console to load this.

For all VScript contributions, there are some common functions available at [`util.nut`](scripts/vscripts/tf2ware_ultimate/util.nut). Note that some of these are wrapped internally - e.g. `Ware_CreateTimer` is preferred over `CreateTimer` for use in minigames.

## Minigames / Bossgames
The logic for minigames and bossgames in TF2Ware Ultimate is the same, they just are just stored in different locations. Go into [`scripts/vscripts/tf2ware_ultimate`](scripts/vscripts/tf2ware_ultimate/) and pick either `minigames` or `bossgames`.
Create a new .nut file there.

Next, create a `Ware_MinigameData` definition. Look at the other scripts in the same folder for plenty of examples.

All the settings and functions allowed for usage are documented in the [`api`](scripts/vscripts/tf2ware_ultimate/api/) folder. Note that many common minigame features such as thirdperson (`thirdperson`), starting all players passed (`start_pass`), min/max players (`min_players`/`max_players`), etc. are available as parameters in `Ware_MinigameData`. Common callbacks are also documented in this class, see [the minigame API](scripts/vscripts/tf2ware_ultimate/api/minigame.nut) for full documentation.

### Overlays
The text overlays for minigames and bossgames are static images. To generate one, run the `generate_text` Python script in the `tools` folder. If you are on Linux you must have `wine` installed as this script runs a `.exe` file.

This script will automatically place all the materials and textures in the correct folder. The overlay file name must be the same as the minigame/bossgame file name (without the `.nut`). This can be overrided with the `custom_overlay` parameter, but this is only intended for minigames with separate missions, modes, or commonly used overlays (such as `get_end`).

For the overlay text, try be as concise as possible - remember most minigames are only a few seconds long, even before speedup. For example **GET TO THE END!** is better than **GET TO THE END OF THE COURSE!**. The convention is white text with an exclamation mark at the end, though exceptions can be made for emphasis. Any "failure" overlays, such as the one used in [Double Jump](scripts/vscripts/tf2ware_ultimate/minigames/double_jump.nut) are typically red and in brackets.

Longer overlays will need to have a line break to prevent going off the screen, ex. `GET TO\nTHE END!`.

For overlays using multiple colours, manual editing is required - To achieve this, comment out the lines `os.remove(name1)` and `os.remove(name2)` in the python script. This will preserve the created `.png` files, which can be processed in any graphics editor such as [GIMP](https://www.gimp.org/). Make sure to uncomment these lines again before submitting a PR.

The processed files can then be converted using VTFEdit and manually imported into the repo. One of the generated `.png`s is a reversed text version which must be added to the VTF as a separate frame by importing both into VTFEdit simultaneously.

A list of commonly used overlays can be seen below. The intention for these is to avoid any duplicate overlays with identical text. These can be used by simply setting the minigame data parameter `custom_overlay = "<overlay_name>"`.

| Overlay Name | Overlay Text |
| --- | --- |
| `fight` | **FIGHT AND STAY ALIVE!** |
| `get_end` | **GET TO THE END!** |
| `kill_player` | **KILL A PLAYER!** |
| `push_enemy` | **PUSH AWAY THE ENEMIES!** |
| `survive` | **SURVIVE!** |

### Music
All minigames and bossgames require minigame music. This music must be at least the same duration as the minigame, though it can be longer - if so it will be stopped automatically. It's not uncommon for minigame duration to be based on the music's duration, though gameplay should still be the main consideration.

For minigames, you are welcome to use existing minigame music, but for bossgames new music is typically expected. See [here](#contributing-audio) for guidelines on contributing audio.

## Special Rounds
The process is similar for Special Rounds, though with some small differences. To get started, create a .nut file in [`scripts/vscripts/tf2ware_ultimate/specialrounds`](scripts/vscripts/tf2ware_ultimate/specialrounds/)

Special Rounds use a distinct `Ware_SpecialRoundData` class, make a definition for this. Look in other Special Rounds for plenty of examples. Note that some parameters that share a name with minigame data parameters are used slightly differently - please read [the special round API](scripts/vscripts/tf2ware_ultimate/api/specialround.nut) carefully to ensure you use them correctly.

Special Rounds have some unique parameters and callbacks that minigames don't have (such as `OnMinigameStart()` and `OnMinigameEnd()`) which may be useful too.

Unlike minigames, special rounds do *not* require music or overlays and neither are expected in the code, though you may still choose to use them.

## Testing
Once you are done, add the file's name to the `minigames.cfg`/`bossgames.cfg`/`specialrounds.cfg` in the `tf/scriptdata/tf2ware_ultimate` folder. 

Minigames, bossgames and special rounds are hot loaded, therefore changes will be effective immediately. Use the `!ware_force` series of chat commands to force a specific one. `!ware_nextspecial` needs a restart (`!ware_restart`) before it loads. Type `!ware_help` in chat for a full list of commands.

## Themes
Theme contributions are very welcome, but work a bit differently to everything else. A "Theme" is a set of sounds related to a specific character or mode from a WarioWare game. A list of replaceable sounds is given in the `_default` entry under `sounds` in the [theme configuration file](cfg/tf2ware_ultimate/themes.cfg). To create a theme, make a new entry in this file following the formatting of other themes. If you're not familiar with Squirrel syntax, each of these entries is an element of an [array](http://squirrel-lang.org/squirreldoc/reference/language/arrays.html), with each entry itself being a [table](http://squirrel-lang.org/squirreldoc/reference/language/tables.html).

Each table has the following slots:
* `theme_name` is the internal theme name. Note this follows a specific structure of `<plat>_<game>_<character/mode>`, with the game being omitted if there's only one game on that platform. For example, the Wii only has one WarioWare game so the theme is `wii_mona`, but the DS has two so we do `ds_diy_orbulon` or `ds_touched_warioman`. This naming system is mandatory, as TF2Ware uses this to set themes up correctly.
* `visual_name` is the name displayed to players, this follows the format `<Char/Mode> (<Plat> - <Game>)`, again omitting the game if only one exists.
* `internal` (optional) tells the config if the theme is [internal](#internal-themes). Set to 1 if it is, otherwise you can omit it.
* `author` is your username to be placed in the credits - please format your username the same across all contributions of any type.
* `sounds` is itself a table with each key being a sound name found in `_default`, and each value being that sound's duration. Only include sounds in this table that you are replacing. Any sound with a value of `0.0` in `_default` (e.g. `results`) doesn't need a duration in other themes either as the sound is manually stopped by TF2Ware.

### Internal Themes
Many themes will have some shared sounds due to being from the same game. To prevent having duplicate audio files across such themes, we instead use "Internal Themes" to store shared theme sounds. Each internal theme is for a specific game, and is considered a "parent theme" to all themes from that game.

Once again if only one game exists for a platform we omit the game name from the theme_name; e.g. `3ds` vs `ds_touched`.

When TF2Ware is setting up the internal list of theme sounds it's going to actually play (`Ware_CurrentThemeSounds`), it first checks the theme itself for sounds, then its parent (if it exists), then finally the default theme. Therefore, if there are any conflicting sounds between a theme and its parent, it will prioritise the child theme, and any missing sounds will be easily replaced.

Note that no `wii` internal theme exists, as the default sounds used by TF2Ware *are* the sounds from Smooth Moves.

### Contributing Audio
When adding audio to the repo, a certain level of quality is expected. Audio should be sourced from a high-quality archive such as [KHInsider](https://downloads.khinsider.com/) or [Zophar's Domain](https://www.zophar.net/), ideally first as a FLAC or WAV.

Any required cuts should be made, with at most a small gap at the start. This should then be loudness normalised to -9 LUFS; this can easily be done in Audacity. Finally this should be exported as a 44.1kHz MP3 using the Standard Audacity preset for bitrate.

For longer music that goes beyond the duration of a minigame/bossgame, the cut should be a few seconds longer than the minigame with a short fade at the end.

Note: If you are editing existing audio within the versioned folder in [`sound/tf2ware_ultimate`](sound/tf2ware_ultimate/), you MUST bump the version number in the directory name, as well as WARE_MUSICVERSION in [`config.nut`](scripts/vscripts/tf2ware_ultimate/config.nut). This is due to audio with identical paths not being updated if it's already cached.

## Mapping
Mapping changes are welcome, however VMF changes are more involved to merge (especially if the map has been changed in the meantime). To help with this, please be descriptive about changes made, and test your compile before submitting a PR.

Note when compiling, add the following parameters to VRAD: `-noskyboxrecurse -staticproppolys -textureshadows`. If using the Hammer/Hammer++ compiler, this is in Expert under $light.exe. If using CompilePal, you can add these parameters inidividually under VRAD. In addition, compile LDR and do not pack the map during development.
