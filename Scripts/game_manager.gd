extends Node
signal enemies_in_wave_updated(count)
signal score_updated(score_value)
signal game_won()

var enemySize: float = 0.6
var enemyCollSize: float = 0.6
var scoreVal: int = 0
var currentWave: int = 0
var enemiesInWave: int = 0 
var enemiesAlive: int = 0 
var player = null
var enemiesOnScreen: int = 0
var enemiesSpawnedThisWave: int = 0

var waveData = [
	{"enemies": 5, "spawnRate": 1.0, "enemyHealth": 1},
	{"enemies": 8, "spawnRate": 0.8, "enemyHealth": 2},
	{"enemies": 12, "spawnRate": 0.6, "enemyHealth": 2},
]

func _ready():
	await get_tree().process_frame
	start_next_wave()

func add_score(score):
	scoreVal += score
	score_updated.emit(scoreVal)

func set_enemy_size(size: float):
	enemySize = size
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.scale = Vector2(enemySize, enemySize)

func enemies_in_on_screen(enemies: int):
	enemiesOnScreen += enemies
	enemies_in_wave_updated.emit(enemiesOnScreen)
	
func win_game():
	game_won.emit()

func start_next_wave():
	currentWave += 1
	if currentWave > waveData.size():
		win_game()
		return
	
	var wave = waveData[currentWave - 1]
	enemiesInWave = wave.enemies
	enemiesAlive = enemiesInWave
	enemiesSpawnedThisWave = 0  
	
	spawn_wave_enemies(wave)

func spawn_wave_enemies(wave):
	var enemyScene = preload("res://Scenes/enemy.tscn")
	var spawnTimer = Timer.new()
	add_child(spawnTimer)
	spawnTimer.wait_time = wave.spawnRate
	spawnTimer.one_shot = false
	
	spawnTimer.timeout.connect(_on_spawn_timer_timeout.bind(wave, enemyScene, spawnTimer))
	spawnTimer.start()

func spawn_enemy(enemyScene, health):
	var enemy = enemyScene.instantiate()
	enemy.scale = Vector2(enemySize, enemySize)
	enemies_in_on_screen(1)
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d()
	
	if camera:
		# Get the actual visible world area based on camera position
		var camera_pos = camera.global_position
		var zoom = camera.zoom
		var viewport_size = viewport.get_visible_rect().size
		
		# Calculate actual world coordinates that are visible
		var visible_world_size = viewport_size / zoom
		var world_rect = Rect2(
			camera_pos - visible_world_size / 2,
			visible_world_size
		)
		
		print("Camera position: ", camera_pos)
		print("Visible world rect: ", world_rect)
		
		# Create spawn area within the visible world bounds
		var spawn_margin = 80
		var spawn_area = Rect2(
			world_rect.position.x + spawn_margin,
			world_rect.position.y + spawn_margin,
			world_rect.size.x - spawn_margin * 2,
			world_rect.size.y * 0.4  # Top 40% of visible area
		)
		
		enemy.global_position = Vector2(
			randf_range(spawn_area.position.x, spawn_area.end.x),
			randf_range(spawn_area.position.y, spawn_area.end.y)
		)
		
		# Set screen bounds for enemy movement constraints
		enemy.screenBounds = Rect2(
			world_rect.position.x + 20,
			world_rect.position.y + 20,
			world_rect.size.x - 40,
			world_rect.size.y - 40
		)
	else:
		# Fallback: try to get player position as reference
		var reference_pos = Vector2.ZERO
		if player:
			reference_pos = player.global_position
		
		var viewport_size = viewport.get_visible_rect().size
		var spawn_margin = 80
		
		# Create spawn area around reference position
		var spawn_area = Rect2(
			reference_pos.x - viewport_size.x / 2 + spawn_margin,
			reference_pos.y - viewport_size.y / 2 + spawn_margin,
			viewport_size.x - spawn_margin * 2,
			viewport_size.y * 0.4
		)
		
		enemy.global_position = Vector2(
			randf_range(spawn_area.position.x, spawn_area.end.x),
			randf_range(spawn_area.position.y, spawn_area.end.y)
		)
		
		enemy.screenBounds = Rect2(
			reference_pos.x - viewport_size.x / 2 + 20,
			reference_pos.y - viewport_size.y / 2 + 20,
			viewport_size.x - 40,
			viewport_size.y - 40
		)
	
	print("Enemy spawned at: ", enemy.global_position)
	print("Enemy screen bounds: ", enemy.screenBounds)
	
	enemy.health = health
	enemy.movementType = "track_player"

	enemy.enemy_destroyed.connect(_on_enemy_destroyed)
	
	get_tree().current_scene.add_child(enemy)

func _on_spawn_timer_timeout(wave, enemyScene, spawnTimer):
	if enemiesSpawnedThisWave < wave.enemies:
		spawn_enemy(enemyScene, wave.enemyHealth)
		enemiesSpawnedThisWave += 1
	else:
		spawnTimer.stop()
		spawnTimer.queue_free()

func _on_enemy_destroyed():
	enemies_in_on_screen(-1)
	enemiesAlive -= 1
	if enemiesAlive <= 0:
		await get_tree().create_timer(2.0).timeout
		start_next_wave()
