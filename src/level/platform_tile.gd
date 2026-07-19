extends StaticBody2D
## Solid platform tile. Pulses subtly to the beat like an audio visualizer.

var _pulse := 0.0

@onready var visual: ColorRect = $Visual


func _ready() -> void:
	AudioDirector.beat.connect(_on_beat)


func _exit_tree() -> void:
	if AudioDirector.beat.is_connected(_on_beat):
		AudioDirector.beat.disconnect(_on_beat)


func _on_beat(_count: int) -> void:
	_pulse = 1.0


func _process(delta: float) -> void:
	if _pulse <= 0.0:
		return
	_pulse = maxf(0.0, _pulse - delta * 3.0)
	# REPLACE ART: swap ColorRect for a tile sprite; keep or drop the pulse.
	visual.modulate = Color(1, 1, 1).lerp(Color(1.0, 0.6, 0.8), _pulse * 0.35)
