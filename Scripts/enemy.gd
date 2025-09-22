extends Area2D

signal enemy_destroyed
@export var health: int = 3
@export var movementSpeed: float = 100.0
@export var scoreValue: int = 100
@export var movementType: String = "straight"
@export var can_shoot: bool = true
@export var shoot_cooldown: float = 2.0
@export var bullet_speed: float = 300.0


const BULLET_SCENE = preload("res://Scenes/enemyBullet.tscn") 
var shoot_timer: float = 0.0
var can_shoot_now: bool = true
var player_ref = null

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
		player_ref = GameManager.player
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Existing movement code...
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
	
	# Handle shooting
	if can_shoot and can_shoot_now and player_ref:
		shoot_at_player()
	
	# Update shoot cooldown
	if not can_shoot_now:
		shoot_timer += delta
		if shoot_timer >= shoot_cooldown:
			can_shoot_now = true
			shoot_timer = 0.0
	
	# Remove if off screen
	if global_position.y > screenSize.y + 50:
		queue_free()

func shoot_at_player():
	if not player_ref or not is_instance_valid(player_ref):
		return
	
	can_shoot_now = false
	var bullet = BULLET_SCENE.instantiate()
	
	# Position bullet at enemy
	bullet.global_position = global_position
	
	# Calculate direction to player
	var direction_to_player = (player_ref.global_position - global_position).normalized()
	bullet.direction = direction_to_player
	bullet.speed = bullet_speed
	
	# Add to scene
	get_parent().add_child(bullet)

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
