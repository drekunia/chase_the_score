class_name Projectile
extends Area2D
## Generic bullet used by every weapon and by enemies.
## Configure via setup() before adding to the tree.

const EXPLOSION := preload("res://src/projectiles/explosion.tscn")

var dir := Vector2.UP
var speed := 900.0
var damage := 1
var hostile := false        # true = enemy shot, hurts the player
var lifetime := 1.4
var aoe := 0.0              # >0 = explodes on impact (rocket)
var deflects := false       # true = destroys hostile projectiles
var homing := 0.0           # steering strength (Hook Weaver tracking shots)

var _age := 0.0


func setup(p_dir: Vector2, p_speed: float, p_damage: int, p_hostile: bool = false) -> Projectile:
	dir = p_dir.normalized()
	speed = p_speed
	damage = p_damage
	hostile = p_hostile
	return self


func _ready() -> void:
	collision_layer = 16 if hostile else 8
	# World (1) always stops shots. Player shots hit enemy hurtboxes (4);
	# hostile shots hit the player body (2); deflectors also eat hostile shots (16).
	collision_mask = 1 | (2 if hostile else 4)
	if deflects:
		collision_mask |= 16
	if hostile:
		add_to_group("hostile_projectiles")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	rotation = dir.angle() + PI / 2.0
	var visual: ColorRect = get_node_or_null("Visual")
	if visual:
		visual.color = Color("f2f2f2") if hostile else Color("ff2e88")


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > lifetime:
		if aoe > 0.0:
			_explode()
		queue_free()
		return
	if homing > 0.0:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			var to_player: Vector2 = (players[0].global_position - global_position).normalized()
			dir = dir.lerp(to_player, homing * delta).normalized()
			rotation = dir.angle() + PI / 2.0
	global_position += dir * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if hostile and body is Player:
		body.take_hit(damage, global_position)
		queue_free()
		return
	# World / breakable blocks.
	if body.has_method("take_damage") and not hostile:
		body.take_damage(damage)
	_impact()


func _on_area_entered(area: Area2D) -> void:
	if deflects and area.is_in_group("hostile_projectiles"):
		area.queue_free()
		GameState.add_score(5.0)
		return
	if not hostile:
		var enemy := area.get_parent()
		if enemy and enemy.has_method("take_damage"):
			enemy.take_damage(damage, global_position)
			_impact()


func _impact() -> void:
	if aoe > 0.0:
		_explode()
	if not deflects:  # barrier pulse pierces
		queue_free()


func _explode() -> void:
	var ex := EXPLOSION.instantiate()
	ex.position = global_position
	ex.radius = aoe
	ex.friendly = not hostile
	# Deferred: _explode can run inside a physics signal callback, where
	# modifying the tree is blocked.
	get_tree().current_scene.add_child.call_deferred(ex)
	aoe = 0.0
