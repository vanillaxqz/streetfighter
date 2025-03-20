extends ProgressBar

var player: CharacterBody2D

func update():
	if player:
		value = player.current_health * 100 / player.max_health

func _ready() -> void:
	var hud_node = get_parent().get_parent()
	var player_path = NodePath("../../" + str(hud_node.player_path))
	if player_path:
		player = get_node(player_path) as CharacterBody2D
		if player:
			player.HPLoss.connect(update)
			update()
		else:
			print("Node at player_path isn't a CharacterBody2D")
	else:
		print("player_path not set in inspector in HUD")


func _process(delta: float) -> void:
	pass
