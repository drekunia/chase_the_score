class_name CardPickup
extends Area2D
## A dropped Sound Card. Bobs in place, magnets to the player when close.

var card_id: CardData.Card = CardData.Card.PITCH

const MAGNET_RANGE := 110.0
const MAGNET_SPEED := 520.0

var _time := 0.0
var _base_y := 0.0
var _beat_pulse := 0.0

@onready var visual: Node2D = $Visual
@onready var glyph: TextureRect = $Visual/Glyph


func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	AudioDirector.beat.connect(_on_beat)
	_base_y = global_position.y
	glyph.texture = load(CardData.get_def(card_id)["icon"])


func _exit_tree() -> void:
	if AudioDirector.beat.is_connected(_on_beat):
		AudioDirector.beat.disconnect(_on_beat)


func _on_beat(_count: int) -> void:
	_beat_pulse = 1.0


func _process(delta: float) -> void:
	_time += delta
	_beat_pulse = maxf(0.0, _beat_pulse - delta * 4.0)
	visual.scale = Vector2.ONE * (1.0 + 0.15 * _beat_pulse)
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var p: Node2D = players[0]
		if global_position.distance_to(p.global_position) < MAGNET_RANGE:
			global_position = global_position.move_toward(p.global_position, MAGNET_SPEED * delta)
			return
	global_position.y = _base_y + sin(_time * 3.0) * 4.0


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player) or body.dead:
		return
	if card_id == CardData.Card.REST:
		# REST is not a card — it heals 1 HP dot instantly on touch.
		body.heal(1)
		GameState.add_score(25.0)
		AudioDirector.play_fill("shield")
	else:
		body.give_card(card_id)
		GameState.add_score(10.0)
		AudioDirector.play_fill("pickup")
	queue_free()
