class_name EnemyBase
extends CharacterBody2D
## Base enemy. Every enemy guarantees a drop of its Sound Card on death.
## Scene contract: child Area2D named "Hurtbox" (layer 3, mask 2) and a
## Node2D/ColorRect named "Visual" (placeholder art — replace freely).

const CARD_PICKUP := preload("res://src/pickups/card_pickup.tscn")

@export var max_hp := 2
@export var card_drop: CardData.Card = CardData.Card.PITCH
@export var stompable := true
@export var contact_damage := 1
@export var score_value := 50.0

var hp: int
var _flash := 0.0
var _beat_pulse := 0.0

@onready var visual: Node2D = get_node_or_null("Visual")


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	var hurtbox: Area2D = $Hurtbox
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	AudioDirector.beat.connect(_on_beat)


func _exit_tree() -> void:
	if AudioDirector.beat.is_connected(_on_beat):
		AudioDirector.beat.disconnect(_on_beat)


func _on_beat(_count: int) -> void:
	_beat_pulse = 1.0


func _process(delta: float) -> void:
	# Placeholder "audio visualizer" pulse + damage flash.
	_beat_pulse = maxf(0.0, _beat_pulse - delta * 4.0)
	_flash = maxf(0.0, _flash - delta * 6.0)
	if visual:
		visual.scale = Vector2.ONE * (1.0 + 0.08 * _beat_pulse)
		visual.modulate = Color(1, 1, 1).lerp(Color("ff2e88"), _flash)


func take_damage(amount: int, _from := Vector2.ZERO) -> void:
	hp -= amount
	_flash = 1.0
	if hp <= 0:
		die()


func die(stomped := false) -> void:
	GameState.add_score(score_value)
	if stomped:
		GameState.raise_multiplier(0.25)
	AudioDirector.play_fill("kill")
	_drop_card()
	queue_free()


func _drop_card() -> void:
	var pickup := CARD_PICKUP.instantiate()
	pickup.card_id = card_drop
	pickup.global_position = global_position
	get_tree().current_scene.add_child.call_deferred(pickup)


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if not body is Player or body.dead:
		return
	# Falling onto the enemy's head = Downwell-style stomp.
	if stompable and body.velocity.y > 40.0 and body.global_position.y < global_position.y - 4.0:
		body.bounce()
		die(true)
	else:
		body.take_hit(contact_damage, global_position)
