extends ProgressBar

var player2: CharacterBody2D

func update():
	if player2:
		value = player2.current_health * 100 / player2.max_health


func _ready() -> void:
	var hud_node = get_parent().get_parent()
	var player_pathp2 = NodePath("../../" + str(hud_node.player_path_p2))
	if player_pathp2:
		player2 = get_node(player_pathp2) as CharacterBody2D
		if player2:
			player2.HPLoss.connect(update)
			update()
		else:
			print("Node at player_pathp2 isn't a CharacterBody2D")
	else:
		print("player_pathp2 not set in inspector in HUD")

func _process(delta: float) -> void:
	pass
