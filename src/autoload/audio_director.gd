extends Node
## Autoload: dynamic soundtrack layers + global beat clock.
##
## AUDIO PLACEHOLDERS — no audio files ship with this prototype.
## To add real music, drop loopable stems into res://assets/audio/ and assign
## them in _ready() below (see the commented lines). Layer volumes are already
## driven by proximity to the music source, so stems will "duck" automatically
## when the player falls behind, exactly as described in the GDD.

signal beat(count: int)

const BPM := 120.0
const AUDIO_DIR := "res://assets/audio/"
const SETTINGS_PATH := "user://settings.cfg"

## Settings key -> audio bus name. Music stems play on Music, fills on SFX.
const BUSES := {"master": "Master", "music": "Music", "sfx": "SFX"}

## Layer name -> AudioStreamPlayer. "bass" stays audible far away; "lead" and
## "drums" fade in as you approach the music source.
var layers: Dictionary = {}

## Fill name -> AudioStreamPlayer for one-shot musical stingers.
var fills: Dictionary = {}

var _beat_count := 0
var _music_lowpass: AudioEffectLowPassFilter


func _ready() -> void:
	_setup_buses()
	_load_settings()

	# Web audio: the project forces Stream playback on web (see [audio] in
	# project.godot) — streamed audio works on non-threaded web exports and
	# keeps the full dynamic mix: runtime loops, layer ducking, lowpass muffle.

	# REPLACE AUDIO: drop differently-named files into assets/audio/ and adjust
	# the paths below. Current files are CC0 — see CREDITS.md.
	for layer_name: String in ["bass", "drums", "lead", "pads"]:
		var p := AudioStreamPlayer.new()
		p.name = layer_name.capitalize()
		p.bus = "Music"
		p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		var path := AUDIO_DIR + "%s_loop.ogg" % layer_name
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream is AudioStreamOggVorbis:
				stream.loop = true  # belt & braces — loop is also baked at import
			p.stream = stream
		add_child(p)
		layers[layer_name] = p
	# Browsers block audio until the first user gesture, so on web the stems
	# start from _input instead. Desktop starts immediately.
	if not OS.has_feature("web"):
		_start_stems()

	for fill_name: String in ["double_jump", "bass_drop", "meteor", "grapple", "shield", "kill", "hit", "pickup", "death", "slash", "fire_pitch", "fire_tempo", "fire_forte", "fire_chord", "fire_rest"]:
		var p := AudioStreamPlayer.new()
		p.name = "Fill_" + fill_name
		p.bus = "SFX"
		p.volume_db = -6.0
		p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		var path := AUDIO_DIR + "fill_%s.ogg" % fill_name
		if ResourceLoader.exists(path):
			p.stream = load(path)
		add_child(p)
		fills[fill_name] = p

	var timer := Timer.new()
	timer.wait_time = 60.0 / BPM
	timer.autostart = true
	timer.timeout.connect(_on_beat)
	add_child(timer)


var _stems_started := false


func _start_stems() -> void:
	if _stems_started:
		return
	_stems_started = true
	# Start every stem on the same frame so the layers stay phase-locked.
	for p: AudioStreamPlayer in layers.values():
		if p.stream:
			p.play()


func _input(event: InputEvent) -> void:
	# Web autoplay unlock: begin the soundtrack on the first real gesture.
	if not _stems_started and (event is InputEventMouseButton or event is InputEventKey) \
			and event.pressed:
		_start_stems()


func _on_beat() -> void:
	_beat_count += 1
	beat.emit(_beat_count)


## t: 0.0 = right next to the music source, 1.0 = far behind.
func set_proximity(t: float) -> void:
	t = clampf(t, 0.0, 1.0)
	_set_layer_db("bass", lerpf(0.0, -10.0, t))
	_set_layer_db("pads", lerpf(0.0, -20.0, t))
	# Drums and lead fade fast — effectively gone past two-thirds distance.
	var dl := clampf(t * 1.5, 0.0, 1.0)
	_set_layer_db("drums", lerpf(0.0, -50.0, dl))
	_set_layer_db("lead", lerpf(0.0, -50.0, dl))
	# Exponential cutoff sweep 18 kHz -> 500 Hz: the real "falling behind" feel.
	if _music_lowpass:
		_music_lowpass.cutoff_hz = 18000.0 * pow(500.0 / 18000.0, pow(t, 0.85))


func _set_layer_db(layer_name: String, db: float) -> void:
	var p: AudioStreamPlayer = layers.get(layer_name)
	if p and p.stream:
		p.volume_db = db


## Punchy one-off musical fill (bass drop on launch, glitch on warp, etc.).
func play_fill(fill_name: String) -> void:
	var p: AudioStreamPlayer = fills.get(fill_name)
	if p and p.stream:
		p.play()


# ------------------------------------------------------- volume settings

func _setup_buses() -> void:
	for bus_name: String in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	# Lowpass on the Music bus — proximity sweeps its cutoff so the track
	# audibly muffles as you fall behind ("distant / underground" per the GDD).
	var midx := AudioServer.get_bus_index("Music")
	if AudioServer.get_bus_effect_count(midx) == 0:
		_music_lowpass = AudioEffectLowPassFilter.new()
		_music_lowpass.cutoff_hz = 18000.0
		AudioServer.add_bus_effect(midx, _music_lowpass)
	else:
		_music_lowpass = AudioServer.get_bus_effect(midx, 0)


## key: "master" / "music" / "sfx"; linear volume 0..1.
func set_volume(key: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(BUSES[key])
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))


func get_volume(key: String) -> float:
	var idx := AudioServer.get_bus_index(BUSES[key])
	if AudioServer.is_bus_mute(idx):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(idx)), 0.0, 1.0)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key: String in BUSES:
		cfg.set_value("audio", key, get_volume(key))
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for key: String in BUSES:
		set_volume(key, clampf(float(cfg.get_value("audio", key, 1.0)), 0.0, 1.0))
