extends CharacterBody2D

const SPEED = 300.0
const FIRE_RATE = 0.2
var fireTimer = 0.0
var canFire = true
const BULLET_URL = preload("res://Scenes/bullet.tscn")

func _ready() -> void:
	add_to_group("player")

	if GameManager:
		GameManager.player = self

func _exit_tree() -> void:

	if GameManager:
		GameManager.player = null

func _physics_process(delta: float) -> void:
	var directionX := Input.get_axis("move_left", "move_right")
	
	if directionX:
		velocity.x = directionX * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		
	if Input.is_action_pressed("shoot") and canFire:
		_shoot()
	
	if not canFire:
		fireTimer += delta
		if fireTimer >= FIRE_RATE:
			canFire = true
			fireTimer = 0.0

	move_and_slide()

func _shoot():
	canFire = false
	var bullet = BULLET_URL.instantiate()
	bullet.global_position = global_position
	bullet.direction = Vector2.UP
	
	get_parent().add_child(bullet)

func take_damage(damage_amount: int):
	# Handle player damage here
	# You might want to emit a signal or call GameManager
	print("Player took damage: ", damage_amount)
	# Example: GameManager.player_took_damage(damage_amount)
