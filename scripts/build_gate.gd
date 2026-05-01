extends "res://scripts/buildable.gd"

## Player-built gate. Player pass-through is reserved in config for a later collision pass.

func _ready() -> void:
	add_to_group("player_buildings")
