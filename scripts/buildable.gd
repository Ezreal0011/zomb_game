extends StaticBody2D

## Base class for player-built structures with health and destruction.

@export var building_id: String = ""
@export var max_hp: int = 100
@export var can_player_pass: bool = false
@export var can_enemy_pass: bool = false
@export var destructible: bool = true

var hp: int = max_hp

func setup(config: Dictionary) -> void:
	building_id = str(config.get("id", building_id))
	max_hp = int(config.get("hp", max_hp))
	can_player_pass = bool(config.get("can_player_pass", can_player_pass))
	can_enemy_pass = bool(config.get("can_enemy_pass", can_enemy_pass))
	destructible = bool(config.get("destructible", destructible))
	hp = max_hp

func take_damage(amount: int) -> void:
	if not destructible:
		return

	hp = max(hp - amount, 0)
	if hp == 0:
		destroy()

func destroy() -> void:
	queue_free()
