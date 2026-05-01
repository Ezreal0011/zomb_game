extends Node

## Runs the M4 day/night timer and notifies UI/game state when phases switch.

signal phase_changed(phase_name: String)
signal time_changed(time_left: float)
signal wave_requested(phase_name: String)

const ConfigLoader := preload("res://scripts/config_loader.gd")

@export var game_manager_path: NodePath
@export var ui_path: NodePath
@export var wave_manager_path: NodePath

var day_duration: float = 90.0
var night_duration: float = 60.0
var current_phase := "Day"
var time_left: float = 90.0

@onready var game_manager: Node = get_node(game_manager_path)
@onready var ui: CanvasLayer = get_node(ui_path)
@onready var wave_manager: Node = get_node(wave_manager_path)

func _ready() -> void:
	_load_config()
	time_left = day_duration
	if not ui.is_node_ready():
		await ui.ready
	if not wave_manager.is_node_ready():
		await wave_manager.ready
	phase_changed.connect(ui.set_phase)
	time_changed.connect(ui.set_time_left)
	wave_requested.connect(wave_manager.spawn_for_phase)
	phase_changed.emit(current_phase)
	time_changed.emit(time_left)
	wave_requested.emit(current_phase)

func _process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0:
		_advance_phase()
	time_changed.emit(max(time_left, 0.0))

func _load_config() -> void:
	var config := ConfigLoader.get_config("res://data/game_config.json")
	day_duration = float(config.get("day_duration", day_duration))
	night_duration = float(config.get("night_duration", night_duration))

func _advance_phase() -> void:
	if current_phase == "Day":
		current_phase = "Night"
		time_left += night_duration
	else:
		current_phase = "Day"
		time_left += day_duration
		game_manager.advance_day()

	phase_changed.emit(current_phase)
	wave_requested.emit(current_phase)
