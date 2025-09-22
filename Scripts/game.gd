extends Node2D

func _ready():
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.game_won.connect(_on_game_won)
	GameManager.enemies_in_wave_updated.connect(_on_enemies_updated)

func _on_score_updated(score_value):
	var score_label = get_node_or_null("Labels/ScoreLabel")
	if score_label:
		score_label.text = "Score: " + str(score_value)
	else:
		print("ScoreLabel not found!")

func _on_game_won():
	var win_label = get_node_or_null("Labels/WinLabel")
	if win_label:
		win_label.visible = true
	else:
		print("WinLabel not found!")
func _on_enemies_updated(count):
	var count_label = get_node_or_null("Labels/EnemiesWave")
	if count_label:
		count_label.text= "Enemies: " + str(count)
	else:
		print("Enemies label not found!")
		
