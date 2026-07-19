class_name Explosion
extends Area2D
## Expanding AoE blast. Damages enemies + breakables (friendly) or the player
## (hostile). Placeholder art: a drawn ring in the accent color.

var radius := 90.0
var friendly := true
var damage := 3

var _life := 0.35
var _age := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = (1 | 4) if friendly else 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	# Let the physics server register overlaps for one frame, then damage.
	_apply_damage.call_deferred()


func _apply_damage() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	if friendly:
		for area in get_overlapping_areas():
			var enemy := area.get_parent()
			if enemy and enemy.has_method("take_damage"):
				enemy.take_damage(damage, global_position)
		for body in get_overlapping_bodies():
			if body.has_method("take_damage"):
				body.take_damage(damage)
	else:
		for body in get_overlapping_bodies():
			if body is Player:
				body.take_hit(1, global_position)


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= _life:
		queue_free()


func _draw() -> void:
	# REPLACE ART: swap this drawn ring for an explosion sprite/particles.
	var t := _age / _life
	var col := Color("ff2e88") if friendly else Color("f2f2f2")
	col.a = 1.0 - t
	draw_arc(Vector2.ZERO, radius * (0.3 + 0.7 * t), 0.0, TAU, 24, col, 6.0)
	draw_circle(Vector2.ZERO, radius * 0.25 * (1.0 - t), col)
