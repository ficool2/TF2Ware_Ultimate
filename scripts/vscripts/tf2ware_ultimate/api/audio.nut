// by ficool2 and pokemonpasta

// Returns the pitch factor (multiplier) for sounds given the current timescale
function Ware_GetPitchFactor()
{
	// TODO change to 0.5 factor but use 0.4 for themes
	return 1.0 + (Ware_PitchScale - 1.0) * 0.4
}

// Plays a sound on a specific client, with pitch scaling from timescale included
function Ware_PlaySoundOnClient(player, name, volume = 1.0, pitch = 100, flags = 0)
{
	PlaySoundOnClient(player, name, volume, pitch * Ware_GetPitchFactor(), flags)
}

// Plays a sound on all clients, with pitch scaling from timescale included
function Ware_PlaySoundOnAllClients(name, volume = 1.0, pitch = 100, flags = 0)
{
	PlaySoundOnAllClients(name, volume, pitch * Ware_GetPitchFactor(), flags)
}

// Plays a gameplay sound to the target player
// If player is null, the sound is played for everyone
// The sound that gets played will use the current theme's sound
// See _default under Ware_Themes in the config for a list of gameplay sounds
// Gameplay sounds are the sounds played for various events such as "You Win" or "Speed Up"
function Ware_PlayGameSound(player, name, flags = 0, volume = 1.0)
{
	local path
	
	if (name in Ware_CurrentThemeSounds)
	{
		local theme_sound = Ware_CurrentThemeSounds[name]
		path = format("%s/%s", theme_sound.theme_name, theme_sound.sound_name)
	}
	else
	{
		path = format("%s/%s", Ware_Themes[0].theme_name, name)
	}
	
	if (player)
		Ware_PlaySoundOnClient(player, format("tf2ware_ultimate/v%d/music_game/%s.mp3", WARE_MP3_VERSION, path), volume, 100, flags)
	else
	{
		// Temporary workaround to fix channel volume difference in RECIPIENT_FILTER_SINGLE_PLAYER vs RECIPIENT_FILTER_GLOBAL
		foreach(target in Ware_Players)
			Ware_PlaySoundOnClient(target, format("tf2ware_ultimate/v%d/music_game/%s.mp3", WARE_MP3_VERSION, path), volume, 100, flags)
			
		// Ware_PlaySoundOnAllClients(format("tf2ware_ultimate/v%d/music_game/%s.mp3", WARE_MP3_VERSION, path), volume, 100, flags)
	}
}

// Plays minigame music to the target player
// If player is null, the music is played for everyone
// This function is useful to change the volume/pitch of already playing music or to stop it
// This can be done by passing SND_CHANGE_VOL/SND_CHANGE_PITCH/SND_STOP flag respectively
function Ware_PlayMinigameMusic(player, name, flags = 0, volume = 1.0)
{
	local gametype = Ware_Minigame.boss ? "bossgame" : "minigame"
	if (player)
		Ware_PlaySoundOnClient(player, format("tf2ware_ultimate/v%d/music_%s/%s.mp3", WARE_MP3_VERSION, gametype, name), volume, 100, flags)
	else
		Ware_PlaySoundOnAllClients(format("tf2ware_ultimate/v%d/music_%s/%s.mp3", WARE_MP3_VERSION, gametype, name), volume, 100, flags)
}

// Gets the duration of a sound under the given theme, and also compensating for timescale
function Ware_GetThemeSoundDuration(sound)
{
	if (sound in Ware_CurrentThemeSounds)
		return Ware_CurrentThemeSounds[sound].duration * Ware_GetPitchFactor()
	else
		return Ware_Themes[0].sounds[sound] * Ware_GetPitchFactor()
}

// Helper version to resolve version for MP3 files
// See comment above WARE_MP3_VERSION for why this is necessary
function Ware_FixupMP3(name)
{
	return format(name, WARE_MP3_VERSION)
}