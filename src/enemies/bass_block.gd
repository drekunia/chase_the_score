extends EnemyBase
## The Bass Block (█) — massive armored block clinging to the ceiling; slams
## straight down like a thwomp when the player passes beneath.
## Guaranteed drop: FORTE (Shotgun / Meteor Launch).

enum State { WAIT, SLAM, REST, RISE }

var _state := State.WAIT
var _origin := Vector2.ZERO
var _rest_timer := 0.0


func _ready() -> void:
	super()
	_origin = global_position


func _physics_process(delta: float) -> void:
	match _state:
		State.WAIT:
			var players := get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				var p: Node2D = players[0]
				if absf(p.global_position.x - global_position.x) < 44.0 \
						and p.global_position.y > global_position.y \
						and p.global_position.y < global_position.y + 480.0:
					_state = State.SLAM
					velocity = Vector2.ZERO
		State.SLAM:
			velocity.y = minf(velocity.y + 3200.0 * delta, 1200.0)
			move_and_slide()
			if is_on_floor():
				_state = State.REST
				_rest_timer = 0.7
		State.REST:
			_rest_timer -= delta
			if _rest_timer <= 0.0:
				_state = State.RISE
		State.RISE:
			velocity.y = -120.0
			move_and_slide()
			if global_position.y <= _origin.y:
				global_position.y = _origin.y
				_state = State.WAIT
