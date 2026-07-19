extends Node2D
## Game loop: chunk streaming, proximity scoring, multiplier decay, game over.

const SCORE_RATE := 60.0        # max points/sec when hugging the music source
const STALL_GRACE := 1.5        # seconds without upward progress before decay
const MULT_DECAY := 0.5         # multiplier lost per second while stalled

var gen: ChunkGenerator
var game_over := false
var _stall_time := 0.0

@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var kill_line: KillLine = $KillLine
@onready var music_source: MusicSource = $MusicSource
@onready var hud: HUD = $HUD


func _ready() -> void:
	GameState.reset_run()
	gen = ChunkGenerator.new(self, player)
	gen.generate_start()
	kill_line.player = player
	music_source.player = player
	hud.setup(player, music_source)
	player.died.connect(_on_player_died)
	camera.position = Vector2(240, player.position.y - 110.0)


func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return

	# R mid-run = give up instantly; routes through the normal death flow,
	# so the next R press restarts.
	if Input.is_action_just_pressed("restart"):
		player.kill()
		return

	var py := player.global_position.y
	gen.ensure_generated(py)
	gen.cleanup(kill_line.global_position.y)
	gen.update_softlock(delta)

	# Proximity-Based Scoring: the closer to the source, the faster the
	# baseline score accumulates (add_score applies the multiplier).
	var closeness := music_source.get_closeness(py)
	GameState.add_score(closeness * closeness * SCORE_RATE * delta)
	AudioDirector.set_proximity(1.0 - closeness)

	# Multiplier: grows with climbing, decays when stalling or falling behind.
	var height := -py
	if height > GameState.best_height + 1.0:
		GameState.raise_multiplier((height - GameState.best_height) * 0.0015)
		GameState.best_height = height
		_stall_time = 0.0
	else:
		_stall_time += delta
		if _stall_time > STALL_GRACE:
			GameState.decay_multiplier(MULT_DECAY * delta)

	# Camera chases the climber (x locked to the tower center).
	camera.position = Vector2(240, py - 110.0)


func _on_player_died() -> void:
	game_over = true
	GameState.end_run()
	hud.show_game_over()
	$Crosshair.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
