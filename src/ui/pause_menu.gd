class_name PauseMenu
extends CanvasLayer
## Esc pauses the game: volume sliders (persisted), resume, quit to title.

const ACCENT := Color("ff2e88")
const WHITE := Color("f2f2f2")
const DIM := Color(0.949, 0.949, 0.949, 0.45)

var _panel: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keeps working while tree is paused
	layer = 20
	_build_ui()
	_panel.visible = false


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _panel.visible:
		_resume()
	else:
		_open()


func _open() -> void:
	get_tree().paused = true
	_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _resume() -> void:
	get_tree().paused = false
	_panel.visible = false
	var main := get_parent()
	if "game_over" in main and main.game_over:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # score screen keeps a cursor
	else:
		# Back to the captured virtual cursor. If the browser refuses the lock
		# outside a click gesture, the crosshair re-engages it on next click.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _quit_to_title() -> void:
	AudioDirector.save_settings()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/title_screen.tscn")


# ----------------------------------------------------------------- UI build

func _build_ui() -> void:
	_panel = ColorRect.new()
	(_panel as ColorRect).color = Color(0.04, 0.04, 0.05, 0.92)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(280, 0)
	center.add_child(box)

	box.add_child(_label("PAUSED", 30, ACCENT))
	box.add_child(_spacer(6))

	for entry in [["MASTER", "master"], ["MUSIC", "music"], ["SFX", "sfx"]]:
		box.add_child(_label(entry[0], 13, DIM))
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = AudioDirector.get_volume(entry[1])
		slider.custom_minimum_size = Vector2(280, 20)
		var key: String = entry[1]
		slider.value_changed.connect(func(v: float) -> void:
			AudioDirector.set_volume(key, v)
			AudioDirector.save_settings())
		box.add_child(slider)

	box.add_child(_spacer(10))

	var resume := _button("RESUME", "play")
	resume.pressed.connect(_resume)
	box.add_child(resume)

	var quit := _button("QUIT TO TITLE", "back")
	quit.pressed.connect(_quit_to_title)
	box.add_child(quit)

	#box.add_child(_spacer(4))
	#box.add_child(_label("Esc resumes · settings save automatically", 11, DIM))


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _button(text: String, icon_name := "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 40)
	b.add_theme_font_size_override("font_size", 16)
	if icon_name != "":
		b.icon = load("res://assets/icons/%s.svg" % icon_name)
		b.expand_icon = true
		# Left-align icon + text so icons form a column across the buttons.
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("icon_max_width", 18)
		b.add_theme_constant_override("h_separation", 14)
		b.add_theme_color_override("icon_normal_color", WHITE)
		b.add_theme_color_override("icon_hover_color", ACCENT)
		b.add_theme_color_override("icon_pressed_color", ACCENT)
		b.add_theme_color_override("icon_focus_color", ACCENT)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.04, 0.04, 0.05)
	normal.border_color = WHITE
	normal.set_border_width_all(2)
	normal.content_margin_left = 18.0
	normal.content_margin_right = 18.0
	var hover := normal.duplicate()
	hover.border_color = ACCENT
	var pressed := hover.duplicate()
	pressed.bg_color = Color(ACCENT, 0.25)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", WHITE)
	b.add_theme_color_override("font_hover_color", ACCENT)
	return b
