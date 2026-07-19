extends StaticBody2D
## Breakable environment block — destroyed by shots and explosions.

var hp := 2


func take_damage(amount: int) -> void:
	hp -= amount
	$Visual.modulate = Color(1.0, 0.5, 0.7)
	if hp <= 0:
		GameState.add_score(5.0)
		queue_free()
