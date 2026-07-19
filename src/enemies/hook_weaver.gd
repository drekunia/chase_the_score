extends EnemyBase
## The Hook Weaver (⧩) — spider-like cluster clinging to walls/ceilings,
## dropping small tracking projectiles.
## Guaranteed drop: CHORD (Rocket Launcher / Grapple Hook).

const PROJECTILE := preload("res://src/projectiles/projectile.tscn")

var _shot_timer := 1.5


func _physics_process(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node2D = players[0]
	if global_position.distance_to(p.global_position) > 620.0:
		return
	_shot_timer -= delta
	if _shot_timer <= 0.0:
		_shot_timer = randf_range(1.8, 2.6)
		var dir := (p.global_position - global_position).normalized()
		var shot: Projectile = PROJECTILE.instantiate().setup(dir, 210.0, 1, true)
		shot.homing = 1.6
		shot.lifetime = 3.0
		shot.global_position = global_position
		get_tree().current_scene.add_child(shot)
