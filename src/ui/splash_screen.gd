extends Control
## Studio splash — fades the logo in and out, then goes to the title screen.
## Any key or click skips it.

const TITLE_SCENE := "res://src/ui/title_screen.tscn"
const LOGO := "res://drekunia-logo.png"

var _leaving := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var logo := TextureRect.new()
	logo.texture = load(LOGO)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(300, 300)
	logo.modulate.a = 0.0
	center.add_child(logo)

	var tween := create_tween()
	tween.tween_property(logo, "modulate:a", 1.0, 0.7)
	tween.tween_interval(1.2)
	tween.tween_property(logo, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_go_to_title)


func _unhandled_input(event: InputEvent) -> void:
	# Skip with a mouse click only (keyboard doesn't skip).
	if event is InputEventMouseButton and event.pressed:
		_go_to_title()


func _go_to_title() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file(TITLE_SCENE)
