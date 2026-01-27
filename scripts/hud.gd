extends Control

## HUD - Heads-Up Display for score, lives, and game info
## Updates in response to GameManager signals

@onready var score_label = $TopBar/ScoreLabel
@onready var lives_label = $TopBar/LivesLabel
@onready var logo_label = $TopBar/LogoLabel

func _ready():
	print("HUD ready")
	# Initial values will be connected via main.gd signals

func _on_score_changed(new_score: int):
	"""Update score display"""
	score_label.text = "SCORE: " + str(new_score)

func _on_lives_changed(new_lives: int):
	"""Update lives display"""
	lives_label.text = "LIVES: " + str(new_lives)
