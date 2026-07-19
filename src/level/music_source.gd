class_name MusicSource
extends Node2D
## The literal source of the Score — a glowing emitter that keeps climbing.
## The Proximity Meter measures the distance between the player and this node.

const MIN_LEAD := 260.0    # the source never lets you actually touch it
# Tight enough that drifting for a few seconds audibly matters.
const MAX_LEAD := 950.0    # ...and never fully abandons you
const BASE_CLIMB := 55.0

var player: Player
var _time := 0.0
var _beat_pulse := 0.0


func _ready() -> void:
	AudioDirector.beat.connect(func(_c: int) -> void: _beat_pulse = 1.0)


func _process(delta: float) -> void:
	_time += delta
	_beat_pulse = maxf(0.0, _beat_pulse - delta * 3.0)
	if player and not player.dead:
		var climb := BASE_CLIMB + _time * 0.6  # slowly ramps up the chase
		position.y -= climb * delta
		position.y = clampf(position.y,
			player.global_position.y - MAX_LEAD,
			player.global_position.y - MIN_LEAD)
		position.x = 240.0 + sin(_time * 0.7) * 140.0
	queue_redraw()


## 1.0 = right on top of the source, 0.0 = max distance behind.
func get_closeness(player_y: float) -> float:
	var dist := player_y - position.y
	return 1.0 - clampf(inverse_lerp(MIN_LEAD, MAX_LEAD, dist), 0.0, 1.0)


func _draw() -> void:
	# REPLACE ART: placeholder speaker-orb — swap for a sprite + particles.
	var pulse := 1.0 + 0.25 * _beat_pulse
	draw_circle(Vector2.ZERO, 18.0 * pulse, Color("ff2e88"))
	draw_circle(Vector2.ZERO, 10.0 * pulse, Color("f2f2f2"))
	for i in 3:
		var ring_r := (34.0 + i * 16.0) * pulse
		var col := Color("ff2e88")
		col.a = 0.5 - i * 0.14
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 32, col, 3.0)
