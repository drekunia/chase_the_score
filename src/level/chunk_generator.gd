class_name ChunkGenerator
extends RefCounted
## Chunk-Based Dependency Grid — stacks pre-designed chunks upward, applies
## the Look-Ahead Rule (key enemy spawns before every lock) and runs the
## Dynamic Fallback Drop softlock fail-safe.

const TILE := 32
const WIDTH := 15
const GEN_AHEAD := 1400.0       # generate when player is this close to the top
const SOFTLOCK_SECONDS := 4.0

const PLATFORM := preload("res://src/level/platform_tile.tscn")
const ONE_WAY := preload("res://src/level/one_way_platform.tscn")
const BREAKABLE := preload("res://src/level/breakable_block.tscn")
const HOPPER := preload("res://src/enemies/hopper.tscn")
const GLITCH_SHELL := preload("res://src/enemies/glitch_shell.tscn")
const BASS_BLOCK := preload("res://src/enemies/bass_block.tscn")
const HOOK_WEAVER := preload("res://src/enemies/hook_weaver.tscn")
const METRONOME := preload("res://src/enemies/metronome.tscn")
const BUTTERFLY := preload("res://src/pickups/butterfly.tscn")

## Card -> enemy scene that guarantees the drop of that card.
const KEY_ENEMY := {
	CardData.Card.PITCH: HOPPER,
	CardData.Card.TEMPO: GLITCH_SHELL,
	CardData.Card.FORTE: BASS_BLOCK,
	CardData.Card.CHORD: HOOK_WEAVER,
}

var parent: Node2D
var player: Player
var next_top_y := 0.0           # y of the top edge of generated content
var _last_name := ""
var _chunks: Array = []         # records per spawned chunk
var chunks_spawned := 0


func _init(p_parent: Node2D, p_player: Player) -> void:
	parent = p_parent
	player = p_player


func generate_start() -> void:
	_spawn_chunk(ChunkLibrary.START)


func ensure_generated(player_y: float) -> void:
	while player_y < next_top_y + GEN_AHEAD:
		_spawn_chunk(_pick_chunk())


func _pick_chunk() -> Dictionary:
	var pool: Array = []
	for def in ChunkLibrary.CHUNKS:
		if def["name"] == _last_name:
			continue
		# Ramp-up: only REQ-free chunks for the first stretch of the tower.
		if def["req"] != ChunkLibrary.NO_REQ and chunks_spawned < 2:
			continue
		var weight: int = def["weight"]
		# Dual-Card Inventory Safeguard: if the player already holds the
		# required card (either slot acts as a buffer), the engine feels free
		# to pick that chunk more often.
		if def["req"] != ChunkLibrary.NO_REQ and player.has_card(def["req"]):
			weight += 2
		for i in weight:
			pool.append(def)
	return pool.pick_random()


func _spawn_chunk(def: Dictionary) -> void:
	var rows: Array = def["rows"]
	var n := rows.size()
	var base_y := next_top_y            # bottom edge of this chunk
	var top_y := base_y - n * TILE
	var root := Node2D.new()
	root.name = "Chunk_%d_%s" % [chunks_spawned, def["name"]]
	parent.add_child(root)

	var safe_min_x := INF
	var safe_max_x := -INF
	var safe_y := base_y

	for r in n:
		var row: String = rows[r]
		var y := top_y + r * TILE + TILE * 0.5
		for c in WIDTH:
			var ch := row[c]
			var x := c * TILE + TILE * 0.5
			var pos := Vector2(x, y)
			match ch:
				"#":
					_place(PLATFORM, root, pos)
				"S":
					# Safe platforms are standing platforms (one-way strips).
					_place(ONE_WAY, root, pos)
					safe_min_x = minf(safe_min_x, x - TILE)
					safe_max_x = maxf(safe_max_x, x + TILE)
					safe_y = y
				"=":
					_place(ONE_WAY, root, pos)
				"B":
					_place(BREAKABLE, root, pos)
				"H":
					_place(HOPPER, root, pos)
				"G":
					_place(GLITCH_SHELL, root, pos)
				"T":
					_place(BASS_BLOCK, root, pos)
				"W":
					_place(HOOK_WEAVER, root, pos)
				"M":
					_place(METRONOME, root, pos)
				"?":
					# Random light enemy — keeps the roster varied between runs.
					# (No Bass Block here: those must cling beneath ledges.)
					var roll := randf()
					if roll < 0.35:
						_place(HOPPER, root, pos)
					elif roll < 0.65:
						_place(GLITCH_SHELL, root, pos)
					elif roll < 0.85:
						_place(HOOK_WEAVER, root, pos)
					else:
						_place(METRONOME, root, pos)
				"!":
					# Look-Ahead Rule: the key is always provided before the lock.
					if def["req"] != ChunkLibrary.NO_REQ:
						_place(KEY_ENEMY[def["req"]], root, pos)

	_build_walls(root, top_y, n * TILE)

	var record := {
		"node": root,
		"top_y": top_y,
		"base_y": base_y,
		"req": def["req"],
		"safe_zone": Rect2(),
		"softlock_timer": 0.0,
		"fallback_spawned": false,
	}
	if def["req"] != ChunkLibrary.NO_REQ and safe_min_x < safe_max_x:
		record["safe_zone"] = Rect2(
			safe_min_x, safe_y - TILE * 3.0,
			safe_max_x - safe_min_x, TILE * 3.5)
	_chunks.append(record)

	next_top_y = top_y
	_last_name = def["name"]
	chunks_spawned += 1


func _place(scene: PackedScene, root: Node2D, pos: Vector2) -> void:
	var node: Node2D = scene.instantiate()
	node.position = pos
	root.add_child(node)


func _build_walls(root: Node2D, top_y: float, height: float) -> void:
	# REPLACE ART: side walls are plain StaticBody2D + ColorRect strips.
	for side in 2:
		var wall := StaticBody2D.new()
		wall.collision_layer = 1
		wall.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE, height)
		shape.shape = rect
		wall.add_child(shape)
		var visual := ColorRect.new()
		visual.size = Vector2(TILE, height)
		visual.position = Vector2(-TILE * 0.5, -height * 0.5)
		visual.color = Color(0.949, 0.949, 0.949)
		wall.add_child(visual)
		var wall_x := -TILE * 0.5 if side == 0 else WIDTH * TILE + TILE * 0.5
		wall.position = Vector2(wall_x, top_y + height * 0.5)
		root.add_child(wall)


## Dynamic Fallback Drop: if the player sits in a REQ chunk's safe zone for
## SOFTLOCK_SECONDS without the required card, a pixel butterfly delivers it
## (collecting it resets the multiplier — handled by the butterfly).
func update_softlock(delta: float) -> void:
	for rec in _chunks:
		if rec["fallback_spawned"] or rec["req"] == ChunkLibrary.NO_REQ:
			continue
		var zone: Rect2 = rec["safe_zone"]
		if zone.size.x <= 0.0:
			continue
		if player.has_card(rec["req"]) or not zone.has_point(player.global_position):
			rec["softlock_timer"] = 0.0
			continue
		rec["softlock_timer"] += delta
		if rec["softlock_timer"] >= SOFTLOCK_SECONDS:
			rec["fallback_spawned"] = true
			var butterfly := BUTTERFLY.instantiate()
			butterfly.card_id = rec["req"]
			butterfly.global_position = Vector2(
				zone.get_center().x, zone.position.y - 320.0)
			parent.add_child(butterfly)


## Free chunks that have fallen entirely below the kill line.
func cleanup(kill_y: float) -> void:
	for i in range(_chunks.size() - 1, -1, -1):
		var rec: Dictionary = _chunks[i]
		if rec["top_y"] > kill_y + 200.0:
			if is_instance_valid(rec["node"]):
				rec["node"].queue_free()
			_chunks.remove_at(i)
