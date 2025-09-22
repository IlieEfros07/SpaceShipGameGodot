extends Area2D

var speed: float = 300.0
var direction: Vector2 = Vector2.DOWN
var damage: int = 1

func _ready():
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

	if global_position.y > get_viewport().get_visible_rect().size.y + 50:
		queue_free()
	if global_position.y < -50:
		queue_free()
	if global_position.x < -50 or global_position.x > get_viewport().get_visible_rect().size.x + 50:
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
