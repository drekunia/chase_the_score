extends EnemyBase
## The Glitch Shell (⋇) — floating stationary spiky ball. Explodes into a
## glitch cluster if the player gets too close. Kill it from range!
## Guaranteed drop: TEMPO (Burst Rifle / Sound Bomb).

const PROJECTILE := preload("res://src/projectiles/projectile.tscn")
const EXPLOSION := preload("res://src/projectiles/explosion.tscn")

const TRIGGER_RANGE := 96.0
const FUSE := 0.6

var _fuse := -1.0


func _physics_process(delta: float) -> void:
	if _fuse >= 0.0:
		_fuse -= delta
		_flash = 1.0 if int(_fuse * 14.0) % 2 == 0 else 0.0  # armed blink
		if _fuse <= 0.0:
			_detonate()
		return
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and global_position.distance_to(players[0].global_position) < TRIGGER_RANGE:
		_fuse = FUSE


func _detonate() -> void:
	var ex := EXPLOSION.instantiate()
	ex.global_position = global_position
	ex.radius = 70.0
	ex.friendly = false
	get_tree().current_scene.add_child(ex)
	for i in 4:
		var shard: Projectile = PROJECTILE.instantiate().setup(
			Vector2.from_angle(TAU * i / 4.0 + PI / 4.0), 260.0, 1, true)
		shard.lifetime = 0.8
		shard.global_position = global_position
		get_tree().current_scene.add_child(shard)
	die()
