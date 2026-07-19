class_name Butterfly
extends Area2D
## The Dynamic Fallback Drop — a tiny harmless pixel butterfly carrying the
## missing required card. Flutters down toward the player; collecting it
## resets the score multiplier (the softlock-escape penalty).

var card_id: CardData.Card = CardData.Card.PITCH

var _time := 0.0

@onready var glyph: TextureRect = $Visual/Glyph


func _ready() -> void:
	collision_layer = 32
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	glyph.texture = load(CardData.get_def(card_id)["icon"])


func _process(delta: float) -> void:
	_time += delta
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node2D = players[0]
	var target := p.global_position + Vector2(0, -20)
	global_position = global_position.move_toward(target, 130.0 * delta)
	global_position.x += sin(_time * 6.0) * 40.0 * delta
	$Visual.scale.y = 0.6 + 0.4 * absf(sin(_time * 10.0))  # wing flap


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not body.dead:
		body.give_card(card_id)
		GameState.reset_multiplier()  # escape hatch costs your multiplier
		AudioDirector.play_fill("pickup")
		queue_free()
