extends Area2D

## Player projectile: flies in the aimed direction, damages the first enemy it hits.

@export var speed: float = 520.0
@export var lifetime: float = 0.75

var direction := Vector2.RIGHT
var damage := 10

@onready var hit_effect: Polygon2D = $HitEffect
@onready var bullet_visual: Polygon2D = $BulletVisual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func setup(start_position: Vector2, shoot_direction: Vector2, attack_damage: int) -> void:
	global_position = start_position
	direction = shoot_direction.normalized()
	damage = attack_damage
	rotation = direction.angle()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	hit_effect.visible = false

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		return
	if (body.collision_layer & 2) == 0:
		return

	body.take_damage(damage)
	_show_hit_effect()

func _show_hit_effect() -> void:
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	bullet_visual.visible = false
	hit_effect.visible = true
	await get_tree().create_timer(0.08).timeout
	queue_free()
