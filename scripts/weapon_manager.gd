extends Node

## Loads weapon config, exposes current damage, and handles resource-paid upgrades.

signal weapon_changed(level: int)

const ConfigLoader := preload("res://scripts/config_loader.gd")

@export var game_manager_path: NodePath
@export var ui_path: NodePath

var weapon_config := {}
var current_level := 1

@onready var game_manager: Node = get_node(game_manager_path)
@onready var ui: CanvasLayer = get_node(ui_path)

func _ready() -> void:
	weapon_config = ConfigLoader.get_config("res://data/weapon_config.json")
	if not ui.is_node_ready():
		await ui.ready
	weapon_changed.connect(ui.set_weapon_level)
	weapon_changed.emit(current_level)

func get_damage() -> int:
	return int(_get_current_config().get("damage", 10))

func get_attack_interval() -> float:
	return float(_get_current_config().get("attack_interval", 0.4))

func try_upgrade() -> bool:
	var next_level := current_level + 1
	if not weapon_config.has(str(next_level)):
		return false

	var next_config: Dictionary = weapon_config[str(next_level)]
	var cost: int = int(next_config.get("upgrade_cost", 0))
	if not game_manager.try_spend_resource(cost):
		return false

	current_level = next_level
	weapon_changed.emit(current_level)
	return true

func _get_current_config() -> Dictionary:
	return weapon_config.get(str(current_level), {})
