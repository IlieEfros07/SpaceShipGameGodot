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
	{"enemies": 5, "spawnRate": 1.0, "enemyHealth": 6},
	{"enemies": 8, "spawnRate": 0.8, "enemyHealth": 6},
	{"enemies": 12, "spawnRate": 0.6, "enemyHealth": 9},
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

func spawn_enemy(enemy_scene, health):
	var enemy = enemy_scene.instantiate()
	enemy.scale = Vector2(enemySize, enemySize)
	enemies_in_on_screen(1)
	var current_scene = get_tree().current_scene
	current_scene.add_child(enemy)
	
	var viewportSize = get_viewport().get_visible_rect().size
	enemy.global_position = Vector2(
		randf_range(50, viewportSize.x - 50),
		-50
	)
	enemy.health = health
	enemy.movementType = "track_player"
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)


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
