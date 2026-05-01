extends Area2D

## Gives one resource automatically when the player walks over it.

@export var resource_amount: int = 1

var picked_up := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _pick_up() -> void:
	if picked_up:
		return
	picked_up = true

	var managers := get_tree().get_nodes_in_group("game_manager")
	if managers.is_empty():
		picked_up = false
		return

	managers[0].add_resource(resource_amount)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		_pick_up()
