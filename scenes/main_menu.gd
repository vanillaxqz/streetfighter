extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_playervsplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stages/ryu_stage.tscn")

func _on_playervsai_pressed() -> void:
	print("Player vs AI pressed")

func _on_exit_pressed() -> void:
	get_tree().quit()
