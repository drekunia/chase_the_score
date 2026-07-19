class_name KillLine
extends Area2D
## The rising hazard chasing the player from below. Touch = instant death.

const BASE_SPEED := 38.0
const MAX_GAP := 550.0  # stays just below the screen edge — visible when you stall

var player: Player
var _time := 0.0
var _beat_pulse := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000.0, 2000.0)
	shape.shape = rect
	shape.position = Vector2(0, 1000.0)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	AudioDirector.beat.connect(func(_c: int) -> void: _beat_pulse = 1.0)


func _physics_process(delta: float) -> void:
	if player == null or player.dead:
		return
	_time += delta
	_beat_pulse = maxf(0.0, _beat_pulse - delta * 3.0)
	var speed := BASE_SPEED + _time * 0.35
	position.y -= speed * delta
	position.y = minf(position.y, player.global_position.y + MAX_GAP)
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.kill()


func _draw() -> void:
	# REPLACE ART: static-noise wave placeholder — swap for an animated hazard.
	var pulse := 1.0 + 0.6 * _beat_pulse
	draw_rect(Rect2(-1000.0, 0.0, 2480.0, 2000.0), Color(0.04, 0.04, 0.05, 0.96))
	draw_rect(Rect2(-1000.0, -6.0 * pulse, 2480.0, 12.0 * pulse), Color("ff2e88"))
	for i in 12:
		var x := -100.0 + i * 60.0
		var h := 14.0 + 18.0 * absf(sin(_time * 3.0 + i * 1.7)) * pulse
		draw_rect(Rect2(x, -h, 26.0, h), Color("ff2e88", 0.7))
