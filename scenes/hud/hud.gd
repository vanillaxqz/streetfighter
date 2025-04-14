extends Node2D
@export var player_path: NodePath
@export var player_path_p2: NodePath

func _ready() -> void:
	$Timer.wait_time = 1.0
	$Timer.start()
	update_timer_display()
	print(player_path, '\n', player_path_p2)

func _process(delta: float) -> void:
	pass

var digit_textures = [
	preload("res://assets/hud/0.png"),
	preload("res://assets/hud/1.png"),
	preload("res://assets/hud/2.png"),
	preload("res://assets/hud/3.png"),
	preload("res://assets/hud/4.png"),
	preload("res://assets/hud/5.png"),
	preload("res://assets/hud/6.png"),
	preload("res://assets/hud/7.png"),
	preload("res://assets/hud/8.png"),
	preload("res://assets/hud/9.png")
]

var round_time = 60

func update_timer_display():
	var tens_digit = int(round_time / 10)
	var ones_digit = round_time % 10

	$TimerDisplay/Tens.texture = digit_textures[tens_digit]
	$TimerDisplay/Ones.texture = digit_textures[ones_digit]


func _on_timer_timeout() -> void:
	if round_time > 0:
		var p1_hp = $Player1HP/ProgressBar.value
		var p2_hp = $Player2HP/ProgressBar.value
		
		if p1_hp == 0:
			$ResultLabel.text = "Player 2 won"
			await get_tree().create_timer(3.0).timeout
			get_tree().quit()
		if p2_hp == 0:
			$ResultLabel.text = "Player 1 won"
			await get_tree().create_timer(3.0).timeout
			get_tree().reload_current_scene()
		
		round_time -= 1
		update_timer_display()
	else:
		var p1_hp = $Player1HP/ProgressBar.value
		var p2_hp = $Player2HP/ProgressBar.value

		if p1_hp == p2_hp:
			print("Draw")
			$ResultLabel.text = "Draw"
		elif p1_hp > p2_hp:
			print("Player 1 won")
			$ResultLabel.text = "Player 1 won"
		else:
			print("Player 2 won")
			$ResultLabel.text = "Player 2 won"
		await get_tree().create_timer(3.0).timeout
		get_tree().reload_current_scene()
