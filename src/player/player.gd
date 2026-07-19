class_name Player
extends CharacterBody2D
## The climber. Holds up to two Sound Cards; each has a Standard Fire (gun)
## and a Discard Ability (movement skill).

signal hp_changed(hp: int)
signal cards_changed
signal died

const SPEED := 300.0
const ACCEL := 2600.0
const JUMP_VELOCITY := -660.0   # ~4.2 tiles of height
const GRAVITY := 1600.0
const MAX_FALL := 900.0
const STOMP_BOUNCE := -620.0
const COYOTE_TIME := 0.15
const JUMP_BUFFER := 0.12       # press jump slightly before landing and it still counts
const MAX_HP := 4

const PROJECTILE := preload("res://src/projectiles/projectile.tscn")
const EXPLOSION := preload("res://src/projectiles/explosion.tscn")
const MELEE := preload("res://src/player/melee_slash.tscn")

var hp := MAX_HP
## Two slots; each is null or {"id": CardData.Card, "ammo": int}.
## Slot 0 is always the ACTIVE card (left in the HUD); slot 1 is the reserve.
## Swapping exchanges the cards themselves, not a highlight.
var slots: Array = [null, null]
var dead := false
var facing := 1

var _invuln := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _jump_cut_armed := false  # only button-jumps can be height-cut on release
var _fire_cooldown := 0.0
var _burst_left := 0
var _burst_timer := 0.0
var _meteor_time := 0.0
var _grappling := false
var _grapple_point := Vector2.ZERO
var _grapple_time := 0.0

@onready var visual: Node2D = $Visual
@onready var grapple_line: Line2D = $GrappleLine
@onready var contact_box: Area2D = $ContactBox


func _ready() -> void:
	add_to_group("player")
	contact_box.area_entered.connect(_on_contact_area_entered)


func _physics_process(delta: float) -> void:
	if dead:
		return
	_invuln = maxf(0.0, _invuln - delta)
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	visual.modulate.a = 0.4 if (_invuln > 0.0 and int(_invuln * 12.0) % 2 == 0) else 1.0

	if _meteor_time > 0.0:
		_meteor_time -= delta
		move_and_slide()
		if is_on_floor() or is_on_ceiling():
			_meteor_time = 0.0
		return

	if _grappling:
		_grapple_step(delta)
		return
	grapple_line.visible = false

	# Normal platforming. The character faces the crosshair (Katana Zero style).
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, axis * SPEED, ACCEL * delta)
	facing = 1 if aim_dir().x >= 0.0 else -1
	visual.scale.x = facing

	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(0.0, _coyote - delta)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)

	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_coyote = 0.0
		_jump_buffer = 0.0
		_jump_cut_armed = true
	# Variable jump height — but never cut ability-driven jumps (double jump,
	# sound bomb, stomp bounce), only jumps started with the jump button.
	if Input.is_action_just_released("jump") and _jump_cut_armed \
			and velocity.y < JUMP_VELOCITY * 0.4:
		velocity.y = JUMP_VELOCITY * 0.4
		_jump_cut_armed = false

	move_and_slide()

	# Burst rifle follow-up shots (track the crosshair between rounds).
	if _burst_left > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_timer = 0.07
			_burst_left -= 1
			_spawn_shot(aim_dir().rotated(randf_range(-0.06, 0.06)), 950.0, 1)
			AudioDirector.play_fill("fire_tempo")

	if Input.is_action_pressed("fire"):
		_try_fire()
	if Input.is_action_just_pressed("discard"):
		_discard()
	if Input.is_action_just_pressed("swap_card"):
		var tmp = slots[0]
		slots[0] = slots[1]
		slots[1] = tmp
		cards_changed.emit()


# ------------------------------------------------------------------ cards

func has_card(id: int) -> bool:
	for slot in slots:
		if slot != null and slot["id"] == id:
			return true
	return false


func give_card(id: int) -> void:
	var def := CardData.get_def(id)
	for i in 2:
		if slots[i] != null and slots[i]["id"] == id:
			slots[i]["ammo"] = mini(slots[i]["ammo"] + def["ammo"], def["ammo"] * 2)
			cards_changed.emit()
			return
	for i in 2:
		if slots[i] == null:
			slots[i] = {"id": id, "ammo": def["ammo"]}
			cards_changed.emit()
			return
	# Both slots full: the new card replaces the active (left) one.
	slots[0] = {"id": id, "ammo": def["ammo"]}
	cards_changed.emit()


# ------------------------------------------------------------------ firing

## Direction from the player to the crosshair — all weapons and directional
## discard skills aim along this. The crosshair is a virtual cursor (the real
## mouse is captured), so read its node rather than the raw mouse position.
func aim_dir() -> Vector2:
	var crosshair := get_tree().get_first_node_in_group("crosshair")
	var target: Vector2 = crosshair.global_position if crosshair \
			else get_global_mouse_position()
	var to_target := target - global_position
	return to_target.normalized() if to_target.length() > 2.0 else Vector2.UP


func _try_fire() -> void:
	if _fire_cooldown > 0.0 or _burst_left > 0:
		return
	var aim := aim_dir()
	var card = slots[0]
	if card == null or card["ammo"] <= 0:
		_melee_slash(aim)  # default melee when no usable card is in hand
		return
	match card["id"]:
		CardData.Card.PITCH:  # Handgun — single precise note
			card["ammo"] -= 1
			_fire_cooldown = 0.16
			_spawn_shot(aim, 1000.0, 1)
			AudioDirector.play_fill("fire_pitch")
		CardData.Card.TEMPO:  # Burst rifle — 3-round burst
			var rounds: int = mini(3, card["ammo"])
			card["ammo"] -= rounds
			_fire_cooldown = 0.42
			_burst_left = rounds - 1
			_burst_timer = 0.07
			_spawn_shot(aim.rotated(randf_range(-0.06, 0.06)), 950.0, 1)
			AudioDirector.play_fill("fire_tempo")
		CardData.Card.FORTE:  # Shotgun — wide short-range blast
			card["ammo"] -= 1
			_fire_cooldown = 0.55
			for i in 5:
				var pellet := _spawn_shot(aim.rotated(deg_to_rad((i - 2) * 12.0)), 750.0, 2)
				pellet.lifetime = 0.24
			# Recoil opposite the aim — shooting downward boosts you up.
			velocity += -aim * 180.0
			velocity.y = clampf(velocity.y, JUMP_VELOCITY, MAX_FALL)
			AudioDirector.play_fill("fire_forte")
		CardData.Card.CHORD:  # Rocket launcher — slow heavy speaker, AoE
			card["ammo"] -= 1
			_fire_cooldown = 0.8
			var rocket := _spawn_shot(aim, 380.0, 4)
			rocket.aoe = 90.0
			rocket.scale = Vector2(1.8, 1.8)
			AudioDirector.play_fill("fire_chord")
	# Neon White rule: the last round spends the card — it vanishes with it,
	# and the reserve card slides into the active slot.
	if card["ammo"] <= 0:
		slots[0] = slots[1]
		slots[1] = null
	cards_changed.emit()


func _melee_slash(aim: Vector2) -> void:
	_fire_cooldown = 0.26
	var slash := MELEE.instantiate()
	slash.position = aim * 10.0
	slash.rotation = aim.angle()
	add_child(slash)
	AudioDirector.play_fill("slash")


func _spawn_shot(dir: Vector2, speed: float, damage: int) -> Projectile:
	var shot: Projectile = PROJECTILE.instantiate().setup(dir, speed, damage)
	shot.global_position = global_position + dir * 20.0
	get_tree().current_scene.add_child(shot)
	return shot


# ------------------------------------------------------------------ discard

func _discard() -> void:
	var card = slots[0]
	if card == null:
		return
	var id: int = card["id"]
	match id:
		CardData.Card.PITCH:  # Double Jump — full-strength, can't be height-cut
			velocity.y = JUMP_VELOCITY
			_jump_cut_armed = false
		CardData.Card.TEMPO:  # Sound Bomb — explode below, rocket-jump up
			var ex := EXPLOSION.instantiate()
			ex.global_position = global_position + Vector2(0, 44)
			ex.radius = 110.0
			ex.friendly = true
			get_tree().current_scene.add_child(ex)
			velocity.y = -1000.0
			_invuln = maxf(_invuln, 0.3)
			_jump_cut_armed = false
		CardData.Card.FORTE:  # Meteor Launch — sonic fireball toward the crosshair
			velocity = aim_dir() * 1030.0
			_meteor_time = 0.45
			_invuln = maxf(_invuln, 0.7)
		CardData.Card.CHORD:  # Grapple Hook — tether toward the crosshair
			if not _start_grapple():
				return  # nothing to latch onto — keep the card
	# Discarded card is gone; the reserve slides into the active slot.
	slots[0] = slots[1]
	slots[1] = null
	cards_changed.emit()
	AudioDirector.play_fill(CardData.get_def(id)["fill"])


func _start_grapple() -> bool:
	var aim := aim_dir()
	var space := get_world_2d().direct_space_state
	var hit := {}
	# Aim at the crosshair, with a little forgiveness either side.
	for tolerance in [0.0, -0.18, 0.18]:
		hit = space.intersect_ray(PhysicsRayQueryParameters2D.create(
			global_position, global_position + aim.rotated(tolerance) * 900.0, 1))
		if not hit.is_empty():
			break
	if hit.is_empty():
		return false
	_grapple_point = hit["position"]
	_grappling = true
	_grapple_time = 0.0
	return true


func _grapple_step(delta: float) -> void:
	_grapple_time += delta
	var to_point := _grapple_point - global_position
	grapple_line.visible = true
	grapple_line.points = PackedVector2Array([Vector2.ZERO, to_point])
	if to_point.length() < 28.0 or _grapple_time > 0.7:
		_grappling = false
		velocity = Vector2(velocity.x * 0.3, JUMP_VELOCITY * 0.6)  # release pop
		return
	velocity = to_point.normalized() * 1300.0
	move_and_slide()
	if get_slide_collision_count() > 0:
		_grappling = false


# ------------------------------------------------------------------ damage

func bounce() -> void:
	## Downwell-style head-stomp bounce.
	velocity.y = STOMP_BOUNCE
	_coyote = 0.0
	_jump_cut_armed = false
	GameState.raise_multiplier(0.25)


func heal(amount: int) -> void:
	hp = mini(hp + amount, MAX_HP)
	hp_changed.emit(hp)


func take_hit(amount: int, from_pos: Vector2) -> void:
	if dead or _invuln > 0.0 or _meteor_time > 0.0:
		return
	hp -= amount
	_invuln = 1.2
	velocity = (global_position - from_pos).normalized() * 260.0 + Vector2(0, -180)
	hp_changed.emit(hp)
	AudioDirector.play_fill("hit")
	if hp <= 0:
		kill()


func kill() -> void:
	## Instant death (kill line) or HP reaching zero.
	if dead:
		return
	dead = true
	visible = false
	set_physics_process(false)
	AudioDirector.play_fill("death")
	died.emit()


func _on_contact_area_entered(area: Area2D) -> void:
	# During Meteor Launch the player is a blazing fireball — destroy enemies.
	if _meteor_time > 0.0:
		var enemy := area.get_parent()
		if enemy and enemy.has_method("take_damage"):
			enemy.take_damage(5, global_position)
