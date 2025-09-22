extends Area2D

const SPEED = 600.0
var health = 10
var damage=1
var maxDistance = 1000.0
var distanceTraveld= 0.0
var direction = Vector2.UP
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("player_bullets")
	#area_entered.connect(_on_area_entered)
	#body_entered.connect(_on_body_entered)
	#animated_sprite_2d.scale = Vector2(0.025,0.025)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var movement = direction * SPEED * delta
	position += movement
	distanceTraveld += movement.length()
	if distanceTraveld >= maxDistance:
		queue_free()
	
