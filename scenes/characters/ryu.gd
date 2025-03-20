extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0

enum State { IDLE, WALK, CROUCH, JUMP, ATTACK, HURT }
var current_state: State = State.IDLE

@onready var animator: AnimatedSprite2D = $animator
@onready var hitbox_anim_player: AnimationPlayer = $AnimationPlayer  # Adjust the path if needed

@export var max_health = 100
@onready var current_health: int = max_health
signal HPLoss

var hurt_applied = false

func _ready() -> void:
	animator.animation_finished.connect(_on_animation_finished)
	if get_parent() and get_parent().name == "Player2":
		animator.flip_h = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	match current_state:
		State.IDLE:
			process_idle(delta)
		State.WALK:
			process_walk(delta)
		State.CROUCH:
			process_crouch(delta)
		State.JUMP:
			process_jump(delta)
		State.ATTACK:
			pass
		State.HURT:
			process_hurt(delta)

	move_and_slide()

func process_idle(delta: float) -> void:
	var direction = Input.get_axis("walk_left", "walk_right")

	if Input.is_action_pressed("crouch"):
		current_state = State.CROUCH
		animator.animation = "crouch"
		animator.play()
		return
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		current_state = State.JUMP
		velocity.y = JUMP_VELOCITY
		animator.animation = "jump"
		animator.play()
		return
	elif abs(direction) > 0:
		current_state = State.WALK
		velocity.x = direction * SPEED
		if direction > 0:
			animator.animation = "walk_forward"
		else:
			animator.animation = "walk_backward"
		animator.play()
		return

	var attack_anim = get_attack_animation("stand")
	if attack_anim != "":
		current_state = State.ATTACK
		animator.animation = attack_anim
		animator.play()
		if attack_anim == "stand_punch_1":
			hitbox_anim_player.play("stand_punch_1_hitbox")
		await animator.animation_finished
		current_state = State.IDLE
		animator.animation = "idle"
		animator.play()
		return

	animator.animation = "idle"
	animator.play()
	velocity.x = move_toward(velocity.x, 0, SPEED)

func process_walk(delta: float) -> void:
	var direction = Input.get_axis("walk_left", "walk_right")

	if abs(direction) > 0:
		velocity.x = direction * SPEED
		if direction > 0:
			if animator.animation != "walk_forward":
				animator.animation = "walk_forward"
				animator.play()
		else:
			if animator.animation != "walk_backward":
				animator.animation = "walk_backward"
				animator.play()
	else:
		current_state = State.IDLE
		animator.animation = "idle"
		animator.play()
		velocity.x = move_toward(velocity.x, 0, SPEED)
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		current_state = State.JUMP
		velocity.y = JUMP_VELOCITY
		animator.animation = "jump"
		animator.play()
		return

	if Input.is_action_pressed("crouch"):
		current_state = State.CROUCH
		animator.animation = "crouch"
		animator.play()
		return

	var attack_anim = get_attack_animation("stand")
	if attack_anim != "":
		current_state = State.ATTACK
		animator.animation = attack_anim
		animator.play()
		if attack_anim == "stand_punch_1":
			hitbox_anim_player.play("stand_punch_1_hitbox")
		await animator.animation_finished
		current_state = State.IDLE
		animator.animation = "idle"
		animator.play()
		return

func process_crouch(delta: float) -> void:
	if not Input.is_action_pressed("crouch"):
		current_state = State.IDLE
		animator.animation = "idle"
		animator.play()
		return

	var attack_anim = get_attack_animation("crouch")
	if attack_anim != "":
		current_state = State.ATTACK
		animator.animation = attack_anim
		animator.play()
		await animator.animation_finished
		if Input.is_action_pressed("crouch"):
			current_state = State.CROUCH
			animator.animation = "crouch"
			animator.play()
		else:
			current_state = State.IDLE
			animator.animation = "idle"
			animator.play()
		return

	if animator.animation != "crouch":
		animator.animation = "crouch"
		animator.play()

	velocity.x = move_toward(velocity.x, 0, SPEED)

func process_jump(delta: float) -> void:
	var attack_anim = get_attack_animation("jump")
	if attack_anim != "":
		current_state = State.ATTACK
		animator.animation = attack_anim
		animator.play()
		await animator.animation_finished
		if is_on_floor():
			current_state = State.IDLE
			animator.animation = "idle"
			animator.play()
		else:
			current_state = State.JUMP
			var direction = Input.get_axis("walk_left", "walk_right")
			if abs(direction) > 0:
				velocity.x = direction * SPEED
				if direction > 0:
					animator.animation = "jump_forward"
				else:
					animator.animation = "jump"
				animator.play()
			else:
				animator.animation = "jump"
				animator.play()
		return

	if is_on_floor():
		current_state = State.IDLE
		animator.animation = "idle"
		animator.play()
		return

	var direction = Input.get_axis("walk_left", "walk_right")
	if abs(direction) > 0:
		velocity.x = direction * SPEED
		if direction > 0:
			if animator.animation != "jump_forward":
				animator.animation = "jump_forward"
				animator.play()
		else:
			if animator.animation != "jump":
				animator.animation = "jump"
				animator.play()
	else:
		if animator.animation != "jump":
			animator.animation = "jump"
			animator.play()

func process_hurt(delta: float) -> void:
	if not hurt_applied:
		print("Taking damage: current_health before =", current_health)
		current_health -= 20
		print("Taking damage: current_health after =", current_health)
		emit_signal("HPLoss")
		hurt_applied = true
		
		if current_health <= 0:
			animator.animation = "jump_hit"
			animator.play()
			await get_tree().create_timer(0.1).timeout
			var frame_count = animator.sprite_frames.get_frame_count("jump_hit")
			animator.stop()
			await get_tree().create_timer(3.0).timeout
			get_tree().reload_current_scene()
			return
		
		else:
			animator.animation = "stand_hit_high"
			animator.play()
			await animator.animation_finished
			hurt_applied = false
			current_state = State.IDLE
			animator.animation = "idle"
			animator.play()
			return

func hurt() -> void:
	if current_state != State.HURT:
		current_state = State.HURT
		process_hurt(0)

func _on_Hurtbox_area_entered(area: Area2D) -> void:
	print("Hurtbox entered by:", area.name)
	if area.get_parent() == self:
		return
	
	if area.is_in_group("attack_hitboxes"):
		hurt()

func _on_animation_finished() -> void:
	if animator.animation == "crouch" and current_state == State.CROUCH:
		if Input.is_action_pressed("crouch"):
			var frame_count = animator.sprite_frames.get_frame_count("crouch")
			animator.frame = frame_count - 1
			animator.stop()

func get_attack_animation(context: String) -> String:
	if Input.is_action_just_pressed("punch_1"):
		return context + "_punch_1"
	elif Input.is_action_just_pressed("punch_2"):
		return context + "_punch_2"
	elif Input.is_action_just_pressed("punch_3"):
		return context + "_punch_3"
	elif Input.is_action_just_pressed("kick_1"):
		return context + "_kick_1"
	elif Input.is_action_just_pressed("kick_2"):
		return context + "_kick_2"
	elif Input.is_action_just_pressed("kick_3"):
		return context + "_kick_3"
	return ""
