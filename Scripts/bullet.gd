extends Area2D

const SPEED = 600.0
var health = 10
var damage = 1
var maxDistance = 1000.0
var distanceTraveld = 0.0
var direction = Vector2.UP
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player_bullets")
	
	# FIX: Set proper collision layers/masks
	collision_layer = 2  # Bullets are on layer 2
	collision_mask = 4   # Bullets can detect layer 4 (enemies)
	
	# Fix signal connection issue
	if area_entered.is_connected(_on_area_entered):
		area_entered.disconnect(_on_area_entered)
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var movement = direction * SPEED * delta
	position += movement
	distanceTraveld += movement.length()
	if distanceTraveld >= maxDistance:
		queue_free()

func _on_area_entered(area):
	print("Bullet hit area: ", area.name, " Groups: ", area.get_groups())  # Debug
	if area.is_in_group("enemies"):
		print("BULLET HIT ENEMY AREA! Damage: ", damage)  # Debug
		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()

func _on_body_entered(body):
	print("Bullet hit body: ", body.name, " Groups: ", body.get_groups())  # Debug
	if body.is_in_group("enemies"):
		print("BULLET HIT ENEMY BODY! Damage: ", damage)  # Debug
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
