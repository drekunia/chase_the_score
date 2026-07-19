class_name Crosshair
extends Node2D
## Mouse crosshair driven by a virtual cursor. During gameplay the mouse is
## CAPTURED (Pointer Lock on web — the OS cursor physically cannot leave the
## game), and relative motion moves this crosshair, clamped to the screen.
## Fire and directional discard skills aim from the player toward this node
## (see Player.aim_dir(), which reads the "crosshair" group).

## Extra sensitivity multiplier on top of 1:1 raw movement, if ever wanted.
const SENSITIVITY := 1.0

var _beat_pulse := 0.0
var _screen_pos := Vector2.ZERO  # virtual cursor in viewport coordinates


func _ready() -> void:
	add_to_group("crosshair")
	z_index = 100
	_screen_pos = get_viewport().get_visible_rect().size / 2.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioDirector.beat.connect(func(_c: int) -> void: _beat_pulse = 1.0)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			# screen_relative = raw physical pixels, unaffected by viewport
			# stretch or the browser's devicePixelRatio. Mapping it through
			# window->viewport scale gives 1:1 feel with a real OS cursor.
			_screen_pos += event.screen_relative * _motion_scale() * SENSITIVITY
		else:
			_screen_pos = event.position  # not locked (yet) — follow directly
		_screen_pos = _screen_pos.clamp(
			Vector2.ZERO, get_viewport().get_visible_rect().size)
	elif event is InputEventMouseButton and event.pressed and visible \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# Browsers only grant / re-grant Pointer Lock on a user gesture —
		# re-engage capture on click if it was refused or dropped (e.g. Esc).
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Physical window pixels -> viewport coordinates.
func _motion_scale() -> Vector2:
	var win := Vector2(DisplayServer.window_get_size())
	var vp := get_viewport().get_visible_rect().size
	if win.x <= 0.0 or win.y <= 0.0:
		return Vector2.ONE
	return vp / win


func _process(delta: float) -> void:
	_beat_pulse = maxf(0.0, _beat_pulse - delta * 4.0)
	# Screen -> world through the camera, so the crosshair rides the scroll.
	global_position = get_canvas_transform().affine_inverse() * _screen_pos
	queue_redraw()


func _draw() -> void:
	# REPLACE ART: swap for a crosshair sprite.
	var r := 9.0 + 2.0 * _beat_pulse
	var accent := Color("ff2e88")
	for i in 4:
		var dir := Vector2.RIGHT.rotated(i * TAU / 4.0)
		draw_line(dir * (r - 5.0), dir * r, accent, 2.0)
	draw_circle(Vector2.ZERO, 1.8, Color("f2f2f2"))
	draw_arc(Vector2.ZERO, r * 0.62, 0.0, TAU, 16, Color("f2f2f2", 0.35), 1.0)
