extends EnemyBase
## The Hopper (⧈) — small blob hopping rhythmically between platforms.
## Checks for ground before each hop so it patrols its platform instead of
## tumbling off the edge. On narrow strips it simply hops in place.
## Guaranteed drop: PITCH (Handgun / Double Jump).

const HOP_VX := 100.0
const HOP_VY := -430.0

var _dir := 1
var _hop_timer := 0.0


func _ready() -> void:
	super()
	_dir = 1 if randf() < 0.5 else -1
	_hop_timer = randf_range(0.3, 1.0)


func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + 1600.0 * delta, 900.0)
	if is_on_floor():
		velocity.x = 0.0
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			_hop_timer = randf_range(0.9, 1.5)
			if not _ground_ahead(_dir):
				_dir *= -1
			# Hop along the platform if there's a landing spot, else in place.
			velocity.x = _dir * HOP_VX if _ground_ahead(_dir) else 0.0
			velocity.y = HOP_VY
	elif is_on_wall():
		_dir *= -1
		velocity.x = _dir * HOP_VX * 0.5
	move_and_slide()


## Is there floor to land on, one hop-length ahead?
func _ground_ahead(dir: int) -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(dir * 52.0, -4.0)
	var hit := space.intersect_ray(
		PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 94.0), 1))
	return not hit.is_empty()
