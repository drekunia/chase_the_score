class_name MeleeSlash
extends Area2D
## Default melee — always available when the active slot has no usable card
## (Neon White style). Short arc toward the crosshair; also cuts down
## hostile projectiles and breakable blocks.

var damage := 2

var _life := 0.14
var _age := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 4 | 16  # world/breakables, enemy hurtboxes, enemy shots
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("hostile_projectiles"):
		area.queue_free()  # parried!
		GameState.add_score(5.0)
		return
	var enemy := area.get_parent()
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(damage, global_position)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= _life:
		queue_free()


func _draw() -> void:
	# REPLACE ART: placeholder sword swipe — swap for an AnimatedSprite2D.
	var t := _age / _life
	var sweep := -0.9 + t * 1.1
	var white := Color("f2f2f2")
	white.a = 1.0 - t * 0.6
	draw_arc(Vector2.ZERO, 36.0, sweep - 0.9, sweep + 0.9, 14, white, 6.0)
	draw_arc(Vector2.ZERO, 25.0, sweep - 0.7, sweep + 0.7, 10, Color("ff2e88", 0.9 - t * 0.6), 3.0)
