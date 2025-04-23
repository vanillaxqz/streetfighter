extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var paused = not get_tree().paused
		get_tree().paused = paused
		visible = paused

func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
