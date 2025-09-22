extends Area2D

signal enemy_destroyed
@export var health: int = 6
@export var movementSpeed: float = 100.0
@export var scoreValue: int = 100
@export var movementType: String = "straight"  

var velocity: Vector2 = Vector2.ZERO
var screenSize: Vector2
var playerRef = null

var time: float = 0.0
var amplitude: float = 50.0
var frequency: float = 1.0

func _ready():
	add_to_group("enemies")
	screenSize = get_viewport().get_visible_rect().size

	if GameManager and GameManager.player:
		playerRef = GameManager.player
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	match movementType:
		"straight":
			velocity = Vector2.DOWN * movementSpeed
		"zigzag":
			time += delta
			velocity.x = sin(time * frequency) * amplitude
			velocity.y = movementSpeed  
		"track_player":
			track_player_movement(delta)
		"circular":
			time += delta
			velocity.x = cos(time * frequency) * amplitude
			velocity.y = movementSpeed
	
	position += velocity * delta
	
	if global_position.y > screenSize.y + 50:
		queue_free()

func track_player_movement(delta):
	if playerRef and is_instance_valid(playerRef):
		var directionToPlayer = (playerRef.global_position - global_position).normalized()
		var randomOffSet = Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
		velocity = (directionToPlayer + randomOffSet) * movementSpeed
	else:
		velocity = Vector2.DOWN * movementSpeed

func take_damage(damageAmount: int):
	health -= damageAmount
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if health <= 0:
		die()


func die():

	enemy_destroyed.emit()
	
	if GameManager:
		GameManager.add_score(scoreValue)
	
	queue_free()

func _on_area_entered(area):
	if area.is_in_group("player_bullets"):
		take_damage(area.damage)
		var knockbackDirection = (global_position - area.global_position).normalized()
		position += knockbackDirection * 10

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		die()
