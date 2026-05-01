extends CanvasLayer

## Displays HUD values and the M5 Game Over state.

@onready var resource_label: Label = $MarginContainer/VBoxContainer/ResourceLabel
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HpLabel
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/WeaponLabel
@onready var day_label: Label = $MarginContainer/VBoxContainer/DayLabel
@onready var phase_label: Label = $MarginContainer/VBoxContainer/PhaseLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var build_hint_label: Label = $BuildHintLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var start_label: Label = $StartLabel

func set_resource_count(amount: int) -> void:
	if not is_node_ready():
		await ready
	resource_label.text = "Resources: %d" % amount

func set_player_hp(current_hp: int, max_hp: int) -> void:
	if not is_node_ready():
		await ready
	hp_label.text = "HP: %d / %d" % [current_hp, max_hp]

func set_weapon_level(level: int) -> void:
	if not is_node_ready():
		await ready
	weapon_label.text = "Weapon: Lv.%d" % level

func set_day(day: int) -> void:
	if not is_node_ready():
		await ready
	day_label.text = "Day: %d" % day

func set_phase(phase_name: String) -> void:
	if not is_node_ready():
		await ready
	phase_label.text = "Phase: %s" % phase_name

func set_time_left(time_left: float) -> void:
	if not is_node_ready():
		await ready
	time_label.text = "Time: %02d" % int(ceil(time_left))

func set_game_over(is_game_over: bool) -> void:
	if not is_node_ready():
		await ready
	game_over_label.visible = is_game_over

func set_start_screen(is_visible: bool) -> void:
	if not is_node_ready():
		await ready
	start_label.visible = is_visible

func set_build_hint(text: String) -> void:
	if not is_node_ready():
		await ready
	build_hint_label.text = text
	build_hint_label.visible = not text.is_empty()
