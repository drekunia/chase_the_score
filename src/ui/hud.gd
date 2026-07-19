class_name HUD
extends CanvasLayer
## 1-bit HUD: score, multiplier, HP dots, card slots, Proximity Meter.
## Built from plain Control nodes in code — replace with themed scenes later.

const ACCENT := Color("ff2e88")
const WHITE := Color("f2f2f2")
const DIM := Color(0.949, 0.949, 0.949, 0.35)

const ICON_MELEE := preload("res://assets/icons/melee.svg")
const ICON_NOTE := preload("res://assets/icons/note.svg")
const ICON_INFINITY := preload("res://assets/icons/infinity.svg")
const ICON_ARROW_UP := preload("res://assets/icons/arrow_up.svg")

var player: Player
var music_source: MusicSource

var _score_label: Label
var _mult_label: Label
var _hp_dots: Array[ColorRect] = []
var _slot_panels: Array[PanelContainer] = []
var _slot_glyphs: Array[TextureRect] = []
var _slot_names: Array[Label] = []
var _slot_ammo: Array[Label] = []
var _slot_ammo_icons: Array[TextureRect] = []
var _prox_track: ColorRect
var _prox_fill: ColorRect
var _game_over: Control
var _final_score: Label
var _high_score: Label


func setup(p_player: Player, p_source: MusicSource) -> void:
	player = p_player
	music_source = p_source
	player.hp_changed.connect(func(_hp: int) -> void: _refresh_hp())
	player.cards_changed.connect(_refresh_cards)
	_refresh_hp()
	_refresh_cards()


func _ready() -> void:
	# --- top left: score + multiplier -------------------------------------
	var top := VBoxContainer.new()
	top.position = Vector2(14, 10)
	add_child(top)

	_score_label = _make_label("0", 30, WHITE)
	top.add_child(_score_label)
	_mult_label = _make_label("x1.0", 16, ACCENT)
	top.add_child(_mult_label)

	# --- HP dots ----------------------------------------------------------
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 6)
	top.add_child(hp_row)
	for i in Player.MAX_HP:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.color = ACCENT
		hp_row.add_child(dot)
		_hp_dots.append(dot)

	# --- right edge: Proximity Meter --------------------------------------
	_prox_track = ColorRect.new()
	_prox_track.color = Color(0.949, 0.949, 0.949, 0.15)
	_prox_track.anchor_left = 1.0
	_prox_track.anchor_right = 1.0
	_prox_track.anchor_top = 0.0
	_prox_track.anchor_bottom = 1.0
	_prox_track.offset_left = -18.0
	_prox_track.offset_right = -8.0
	_prox_track.offset_top = 60.0
	_prox_track.offset_bottom = -60.0
	add_child(_prox_track)

	_prox_fill = ColorRect.new()
	_prox_fill.color = ACCENT
	_prox_track.add_child(_prox_fill)

	var prox_box := HBoxContainer.new()
	prox_box.anchor_left = 1.0
	prox_box.anchor_right = 1.0
	prox_box.offset_left = -86.0
	prox_box.offset_right = -6.0
	prox_box.offset_top = 36.0
	prox_box.offset_bottom = 56.0
	prox_box.alignment = BoxContainer.ALIGNMENT_END
	prox_box.add_theme_constant_override("separation", 4)
	add_child(prox_box)
	prox_box.add_child(_make_label("SCORE", 11, WHITE))
	prox_box.add_child(_make_icon(ICON_ARROW_UP, 12, WHITE))

	# --- bottom: card slots ----------------------------------------------
	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 10)
	slots_row.anchor_top = 1.0
	slots_row.anchor_bottom = 1.0
	slots_row.offset_left = 14.0
	slots_row.offset_top = -74.0
	slots_row.offset_bottom = -12.0
	add_child(slots_row)

	for i in 2:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(140, 56)  # uniform card size
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.04, 0.04, 0.05, 0.85)
		style.border_color = DIM
		style.set_border_width_all(2)
		style.content_margin_left = 8.0
		style.content_margin_right = 8.0
		style.content_margin_top = 4.0
		style.content_margin_bottom = 4.0
		panel.add_theme_stylebox_override("panel", style)
		slots_row.add_child(panel)
		_slot_panels.append(panel)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		panel.add_child(row)

		var glyph := _make_icon(ICON_MELEE, 28, WHITE)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(glyph)
		_slot_glyphs.append(glyph)

		var col := VBoxContainer.new()
		row.add_child(col)
		var name_l := _make_label("EMPTY", 12, DIM)
		col.add_child(name_l)
		_slot_names.append(name_l)
		var ammo_row := HBoxContainer.new()
		ammo_row.add_theme_constant_override("separation", 4)
		col.add_child(ammo_row)
		var ammo_icon := _make_icon(ICON_NOTE, 13, ACCENT)
		ammo_row.add_child(ammo_icon)
		_slot_ammo_icons.append(ammo_icon)
		var ammo_l := _make_label("", 12, ACCENT)
		ammo_row.add_child(ammo_l)
		_slot_ammo.append(ammo_l)

	# --- game over overlay ------------------------------------------------
	_game_over = ColorRect.new()
	(_game_over as ColorRect).color = Color(0.04, 0.04, 0.05, 0.88)
	_game_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over.visible = false
	add_child(_game_over)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	box.add_child(_make_label("GAME OVER", 22, ACCENT))
	_final_score = _make_label("SCORE 0", 34, WHITE)
	box.add_child(_final_score)
	_high_score = _make_label("BEST 0", 16, DIM)
	box.add_child(_high_score)
	box.add_child(_make_label("press R to restart", 14, WHITE))


func _make_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _make_icon(texture: Texture2D, size: int, color: Color) -> TextureRect:
	var t := TextureRect.new()
	t.texture = texture
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.self_modulate = color
	return t


func _process(_delta: float) -> void:
	_score_label.text = str(int(GameState.score))
	_mult_label.text = "x%.1f" % GameState.multiplier
	if player and music_source:
		var closeness := music_source.get_closeness(player.global_position.y)
		var h := _prox_track.size.y * closeness
		_prox_fill.position = Vector2(0, _prox_track.size.y - h)
		_prox_fill.size = Vector2(_prox_track.size.x, h)


func _refresh_hp() -> void:
	for i in _hp_dots.size():
		_hp_dots[i].color = ACCENT if i < player.hp else Color(0.949, 0.949, 0.949, 0.12)


func _refresh_cards() -> void:
	for i in 2:
		var slot = player.slots[i]
		var style: StyleBoxFlat = _slot_panels[i].get_theme_stylebox("panel")
		style.border_color = ACCENT if i == 0 else DIM  # left slot = active
		if slot == null:
			_slot_glyphs[i].texture = ICON_MELEE
			_slot_glyphs[i].self_modulate = DIM
			_slot_names[i].text = "MELEE"
			_slot_ammo_icons[i].texture = ICON_INFINITY
			_slot_ammo[i].text = ""
		else:
			var def := CardData.get_def(slot["id"])
			_slot_glyphs[i].texture = load(def["icon"])
			_slot_glyphs[i].self_modulate = WHITE
			_slot_names[i].text = def["name"]
			_slot_ammo_icons[i].texture = ICON_NOTE
			_slot_ammo[i].text = "%d" % slot["ammo"]


func show_game_over() -> void:
	_final_score.text = "SCORE %d" % int(GameState.score)
	_high_score.text = "BEST %d" % GameState.high_score
	_game_over.visible = true
