extends Node
## Autoload: run-wide state — score, multiplier, high score persistence.

signal score_changed
signal multiplier_changed

const SAVE_PATH := "user://highscore.save"
const MAX_MULTIPLIER := 10.0

var score: float = 0.0
var multiplier: float = 1.0
var high_score: int = 0
var best_height: float = 0.0  # metres climbed (positive)
var run_over := false


func _ready() -> void:
	_load_high_score()


func reset_run() -> void:
	score = 0.0
	multiplier = 1.0
	best_height = 0.0
	run_over = false
	score_changed.emit()
	multiplier_changed.emit()


func add_score(points: float) -> void:
	if run_over:
		return
	score += points * multiplier
	score_changed.emit()


func raise_multiplier(amount: float) -> void:
	multiplier = minf(multiplier + amount, MAX_MULTIPLIER)
	multiplier_changed.emit()


func decay_multiplier(amount: float) -> void:
	if multiplier > 1.0:
		multiplier = maxf(1.0, multiplier - amount)
		multiplier_changed.emit()


func reset_multiplier() -> void:
	multiplier = 1.0
	multiplier_changed.emit()


func end_run() -> void:
	run_over = true
	if int(score) > high_score:
		high_score = int(score)
		_save_high_score()


func _load_high_score() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			high_score = f.get_32()


func _save_high_score() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_32(high_score)
