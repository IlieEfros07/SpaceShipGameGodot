extends CharacterBody2D

signal enemy_destroyed

# --- Exported variables ---
@export var health: int = 3
@export var movementSpeed: float = 100.0
@export var scoreValue: int = 100
@export var movementType: String = "straight"
@export var can_shoot: bool = true
@export var shoot_cooldown: float = 2.0
@export var bullet_speed: float = 300.0
@export var stop_following_y: float = 600.0 

# --- Internal variables ---
var screenBounds: Rect2
var isWithinBounds: bool = true
var player_ref = null
var time: float = 0.0
var amplitude: float = 50.0
var frequency: float = 1.0
var shoot_timer: float = 0.0
var can_shoot_now: bool = true
var should_follow_player: bool = true

const BULLET_SCENE = preload("res://Scenes/enemyBullet.tscn") 

# --- Ready ---

# --- Ready ---
func _ready():
	add_to_group("enemies")
	screenBounds = get_viewport().get_visible_rect()
	if GameManager and GameManager.player:
		player_ref = GameManager.player

	_setup_hitbox()

# --- Set up hitbox area for bullet detection ---
func _setup_hitbox():
	var hitbox = Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 4  
	hitbox.collision_mask = 2   
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = RectangleShape2D.new()
	collision_shape.shape.size = Vector2(30, 30)
	
	hitbox.add_child(collision_shape)
	add_child(hitbox)
	
	hitbox.area_entered.connect(_on_area_entered)
	hitbox.body_entered.connect(_on_body_entered)

# --- Physics Process ---
func _physics_process(delta):
	_update_velocity(delta)
	velocity = _apply_boundary_constraints(velocity)
	move_and_slide()

	_handle_shooting(delta)

# --- Update velocity based on movement type ---
func _update_velocity(delta):
	match movementType:
		"straight":
			velocity = Vector2.DOWN * movementSpeed
		"zigzag":
			time += delta
			velocity.x = sin(time * frequency) * amplitude
			velocity.y = movementSpeed
		"track_player":
			track_player_movement()
		"circular":
			time += delta
			velocity.x = cos(time * frequency) * amplitude
			velocity.y = movementSpeed

# --- Track player movement with boundary check ---
func track_player_movement():
	# Stop following if below certain Y position
	if global_position.y > stop_following_y:
		should_follow_player = false
	
	if should_follow_player and player_ref and is_instance_valid(player_ref):
		var random_offset = Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
		velocity = (player_ref.global_position - global_position).normalized() * movementSpeed + random_offset * movementSpeed
	else:
		# Fall back to straight downward movement when not following
		velocity = Vector2.DOWN * movementSpeed

# --- Shooting ---
func _handle_shooting(delta):
	if can_shoot and can_shoot_now and player_ref and isWithinBounds:
		shoot_at_player()

	if not can_shoot_now:
		shoot_timer += delta
		if shoot_timer >= shoot_cooldown:
			can_shoot_now = true
			shoot_timer = 0.0

func shoot_at_player():
	if not player_ref or not is_instance_valid(player_ref):
		return

	can_shoot_now = false
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.direction = (player_ref.global_position - global_position).normalized()
	bullet.speed = bullet_speed
	get_parent().add_child(bullet)


# --- Boundary constraints ---
func _apply_boundary_constraints(currentVelocity: Vector2) -> Vector2:
	var newVelocity = currentVelocity
	var margin = 10
	isWithinBounds = screenBounds.has_point(global_position)

	if global_position.x <= screenBounds.position.x + margin:
		newVelocity.x = abs(newVelocity.x)
	elif global_position.x >= screenBounds.end.x - margin:
		newVelocity.x = -abs(newVelocity.x)

	if global_position.y <= screenBounds.position.y + margin:
		newVelocity.y = abs(newVelocity.y)
	elif global_position.y >= screenBounds.end.y - margin:
		newVelocity.y = -abs(newVelocity.y)

	return newVelocity

# --- Damage handling ---
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

# --- Collision handlers --- (ADD THESE)
func _on_area_entered(area):
	print("Enemy hit by area: ", area.name)  # Debug
	if area.is_in_group("player_bullets"):
		print("BULLET HIT ENEMY!")  # Debug
		take_damage(area.damage)
		var knockback_direction = (global_position - area.global_position).normalized()
		position += knockback_direction * 10

func _on_body_entered(body):
	print("Enemy hit by body: ", body.name)  # Debug
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		die()
