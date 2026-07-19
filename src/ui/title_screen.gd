extends Control
## Title screen — shown on launch. START (or any key) to play; SETTINGS for
## volume. Built from plain Control nodes; restyle or replace when ready.

const ACCENT := Color("ff2e88")
const WHITE := Color("f2f2f2")
const DIM := Color(0.949, 0.949, 0.949, 0.45)

var _title: Label
var _menu: Control
var _settings: Control
var _controls: Control
var _beat_pulse := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioDirector.set_proximity(0.0)  # full mix on the menu

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_build_menu()
	_build_settings()
	_build_controls()
	_settings.visible = false
	_controls.visible = false

	AudioDirector.beat.connect(func(_c: int) -> void: _beat_pulse = 1.0)


func _build_menu() -> void:
	_menu = CenterContainer.new()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_menu)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.add_child(box)

	_title = _label("CHASE THE SCORE", 40, ACCENT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)

	box.add_child(_spacer(8))
	box.add_child(_label("BEST  %d" % GameState.high_score, 18, WHITE, true))
	box.add_child(_spacer(8))

	var start := _button("START", 20, Vector2(220, 46), "play")
	start.pressed.connect(_start_game)
	box.add_child(start)

	var controls_btn := _button("CONTROLS", 16, Vector2(220, 40), "keyboard")
	controls_btn.pressed.connect(_show_panel.bind(true))
	box.add_child(controls_btn)

	var settings_btn := _button("SETTINGS", 16, Vector2(220, 40), "gear")
	settings_btn.pressed.connect(_show_panel.bind(false))
	box.add_child(settings_btn)

	# Browsers manage their own tabs — no exit button on web builds.
	if not OS.has_feature("web"):
		var exit_btn := _button("EXIT", 16, Vector2(220, 40), "close")
		exit_btn.pressed.connect(func() -> void: get_tree().quit())
		box.add_child(exit_btn)


func _build_settings() -> void:
	_settings = CenterContainer.new()
	_settings.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_settings)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(280, 0)
	_settings.add_child(box)

	box.add_child(_label("SETTINGS", 30, ACCENT))
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
	var back := _button("BACK", 16, Vector2(280, 40), "back")
	back.pressed.connect(_close_panels)
	box.add_child(back)


func _build_controls() -> void:
	_controls = CenterContainer.new()
	_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_controls)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_controls.add_child(box)

	box.add_child(_label("CONTROLS", 30, ACCENT))
	box.add_child(_spacer(4))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.custom_minimum_size = Vector2(340, 0)
	grid.add_theme_constant_override("h_separation", 36)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)

	for row in [
		["Move", "A / D"],
		["Jump", "Space"],
		["Aim", "Mouse"],
		["Attack/Fire", "Left click"],
		["Use card", "Right click"],
		["Swap card", "Shift"],
		["Pause", "Esc"],
		["Restart", "R"],
	]:
		var action := _label(row[0], 15, WHITE)
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(action)
		var key := _label(row[1], 15, ACCENT)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(key)

	box.add_child(_spacer(4))
	box.add_child(_label("get closer to the music to raise score multiplier", 12, DIM, true))
	box.add_child(_spacer(6))

	var back := _button("BACK", 16, Vector2(280, 40), "back")
	back.pressed.connect(_close_panels)
	box.add_child(back)


func _process(delta: float) -> void:
	_beat_pulse = maxf(0.0, _beat_pulse - delta * 3.0)
	_title.pivot_offset = _title.size / 2.0
	_title.scale = Vector2.ONE * (1.0 + 0.03 * _beat_pulse)


func _unhandled_input(event: InputEvent) -> void:
	# Esc closes an open panel; the game starts only via the START button.
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_ESCAPE \
			and (_settings.visible or _controls.visible):
		_close_panels()


func _show_panel(controls: bool) -> void:
	_menu.visible = false
	_controls.visible = controls
	_settings.visible = not controls


func _close_panels() -> void:
	_settings.visible = false
	_controls.visible = false
	_menu.visible = true


func _start_game() -> void:
	get_tree().change_scene_to_file("res://src/main/main.tscn")


# ------------------------------------------------------------------ helpers

func _label(text: String, font_size: int, color: Color, centered := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if centered:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _button(text: String, font_size: int, min_size: Vector2, icon_name := "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	if icon_name != "":
		b.icon = load("res://assets/icons/%s.svg" % icon_name)
		b.expand_icon = true
		# Left-align icon + text with a fixed margin so the icons line up in a
		# column across the stacked menu buttons.
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("icon_max_width", font_size + 2)
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
