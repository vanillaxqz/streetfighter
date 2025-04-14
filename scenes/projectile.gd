extends Area2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var speed: float = 300.0
var travel_distance: float = 300.0

func _ready() -> void:
	visible = false

func launch() -> void:
	visible = true
	anim_sprite.animation = "default"
	anim_sprite.play()
	
	var tween = get_tree().create_tween()
	var start_position = position
	var target_position = start_position + Vector2(travel_distance, 0)
	var travel_time = travel_distance / speed
	tween.tween_property(self, "position", target_position, travel_time)
	tween.tween_callback(Callable(self, "reset_projectile"))

func reset_projectile() -> void:
	visible = false
	position = Vector2.ZERO
