extends EnemyBase
## The Metronome (𝄾) — a floating pendulum that swings side to side in time
## with the soundtrack. Doesn't attack; contact still hurts. Stomp or shoot
## it for a guaranteed heal.
## Guaranteed drop: REST (heals 1 HP instantly on pickup).

const SWING_AMP := 56.0
const SWING_PERIOD := 2.0  # one full swing = 4 beats at 120 BPM

var _origin := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	super()
	_origin = global_position
	_time = randf_range(0.0, SWING_PERIOD)


func _physics_process(delta: float) -> void:
	_time += delta
	var phase := _time * TAU / SWING_PERIOD
	global_position.x = _origin.x + sin(phase) * SWING_AMP
	global_position.y = _origin.y + absf(cos(phase)) * -10.0  # slight arc lift
	if visual:
		visual.rotation = sin(phase) * 0.35  # pendulum tilt
