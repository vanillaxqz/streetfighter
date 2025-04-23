extends CharacterBody2D

const SPEED = 250.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0

enum State { IDLE, WALK, CROUCH, JUMP, ATTACK, HURT }
var current_state: State = State.IDLE

@onready var animator: AnimatedSprite2D = $animator
@onready var hitbox_anim_player: AnimationPlayer = $AnimationPlayer
@onready var hurtbox: Node2D = $hurtbox  

@export var max_health = 100
@onready var current_health: int = max_health
signal HPLoss

var hurt_applied = false

var is_blocking: bool = false
var ai_timer = 0.0
var ai_action_interval = 0.5 + randf() * 1.0  # act every ~1–2s
var target_body: CharacterBody2D = null

var left_input = "walk_left"
var right_input = "walk_right"
var crouch_input = "crouch"
var jump_input = "jump"
var punch_1_input = "punch_1"
var punch_2_input = "punch_2"
var punch_3_input = "punch_3"
var kick_1_input = "kick_1"
var kick_2_input = "kick_2"
var kick_3_input = "kick_3"

var is_player2: bool = false

@onready var projectile = $projectile

func fire_projectile() -> void:
	projectile.visible = true
	projectile.position = Vector2(30, 0)
	projectile.launch()

func set_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.IDLE:
			hurtbox.position = Vector2(hurtbox.position.x, 0)
			hurtbox.scale = Vector2(hurtbox.scale.x, 1)
		State.CROUCH:
			hurtbox.position = Vector2(hurtbox.position.x, 30)
			hurtbox.scale = Vector2(hurtbox.scale.x, 0.6)
		State.JUMP:
			hurtbox.position = Vector2(hurtbox.position.x, -35)
			hurtbox.scale = Vector2(hurtbox.scale.x, 0.755)

var p1_node = null

func _ready() -> void:
	if get_parent() and get_parent().name == "Player2":
		is_player2 = true
		left_input = "walk_left_p2"
		right_input = "walk_right_p2"
		crouch_input = "crouch_p2"
		jump_input = "jump_p2"
		punch_1_input = "punch_1p2"
		punch_2_input = "punch_2p2"
		punch_3_input = "punch_3p2"
		kick_1_input = "kick_1p2"
		kick_2_input = "kick_2p2"
		kick_3_input = "kick_3p2"
		self.scale.x = -abs(self.scale.x)
	
	animator.animation = "idle"
	animator.play()
	
	animator.animation_finished.connect(_on_animation_finished)
	
	current_health = max_health
	
	if is_player2:
		var p1_node = get_tree().get_root().get_node("Stage/Player1/ryu")
		if p1_node:
			target_body = p1_node
		else:
			print("not found")

func _physics_process(delta: float) -> void:
	if is_player2:
		process_ai(delta)
	else:
		# your existing input-driven match…
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		match current_state:
			State.IDLE:   process_idle(delta)
			State.WALK:   process_walk(delta)
			State.CROUCH: process_crouch(delta)
			State.JUMP:   process_jump(delta)
			State.HURT:   process_hurt(delta)
		move_and_slide()
		_flip_based_on_opponent()
		return  # skip the rest

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()
	_flip_based_on_opponent()

func process_ai(delta: float) -> void:
	if target_body == null:
		return

	ai_timer += delta
	if ai_timer < ai_action_interval:
		if current_state == State.WALK:
			move_toward_target(delta)
		return
	ai_timer = 0.0
	ai_action_interval = 1.0 + randf() * 1.5

	var dist = target_body.global_position.x - global_position.x
	var absd = abs(dist)

	if absd > 500:
		set_state(State.WALK)
		velocity.x = sign(dist) * SPEED
		animator.animation = "walk_forward" if (sign(dist) > 0) else "walk_backward"
		animator.play()
	elif absd < 200:
		var attack_anim = ["stand_punch_1","stand_punch_2","stand_kick_1","stand_kick_2"].pick_random()
		set_state(State.ATTACK)
		velocity.x = 0
		animator.animation = attack_anim
		animator.play()
		hitbox_anim_player.play(attack_anim + "_hitbox")
		await animator.animation_finished
		set_state(State.IDLE)
		animator.animation = "idle"
		animator.play()
	else:
		if randi() % 3 == 0:
			# fire projectile
			set_state(State.ATTACK)
			animator.animation = "hadouken"
			animator.play()
			await animator.animation_finished
			fire_projectile()
			set_state(State.IDLE)
			animator.animation = "idle"
			animator.play()
		else:
			# just walk forward
			set_state(State.WALK)
			velocity.x = sign(dist) * SPEED
			animator.animation = "walk_forward"
			animator.play()

	if not is_player2:
		_flip_based_on_opponent()

func move_toward_target(delta):
	var dir = sign(target_body.global_position.x - global_position.x)
	velocity.x = dir * SPEED
	
func process_idle(delta: float) -> void:
	var direction = Input.get_axis(left_input, right_input)

	if Input.is_action_pressed(crouch_input):
		set_state(State.CROUCH)
		animator.animation = "crouch"
		animator.play()
		return
	elif Input.is_action_just_pressed(jump_input) and is_on_floor():
		set_state(State.JUMP)
		velocity.y = JUMP_VELOCITY
		animator.animation = "jump"
		animator.play()
		return
	elif abs(direction) > 0:
		set_state(State.WALK)
		velocity.x = direction * SPEED
		if is_player2:
			if direction > 0:
				animator.animation = "walk_backward"
			else:
				animator.animation = "walk_forward"
		else:
			if direction > 0:
				animator.animation = "walk_forward"
			else:
				animator.animation = "walk_backward"
		animator.play()
		return

	var attack_anim = get_attack_animation("stand")
	if attack_anim != "":
		velocity.x = 0
		set_state(State.ATTACK)
		animator.animation = attack_anim
		animator.play()
		if attack_anim == "stand_punch_1":
			hitbox_anim_player.play("stand_punch_1_hitbox")
		if attack_anim == "stand_punch_2":
			hitbox_anim_player.play("stand_punch_2_hitbox")
		if attack_anim == "stand_punch_3":
			hitbox_anim_player.play("stand_punch_3_hitbox")	
		if attack_anim == "stand_kick_1":
			hitbox_anim_player.play("stand_kick_1_hitbox")
		if attack_anim == "stand_kick_2":
			hitbox_anim_player.play("stand_kick_2_hitbox")
		await animator.animation_finished
		if attack_anim == "hadouken":
			fire_projectile()
		set_state(State.IDLE)
		animator.animation = "idle"
		animator.play()
		return

	set_state(State.IDLE)
	animator.animation = "idle"
	animator.play()
	velocity.x = move_toward(velocity.x, 0, SPEED)

func process_walk(delta: float) -> void:
	var direction = Input.get_axis(left_input, right_input)
	
	if abs(direction) > 0:
		velocity.x = direction * SPEED
		if is_player2:
			if direction > 0:
				if animator.animation != "walk_backward":
					animator.animation = "walk_backward"
					animator.play()
			else:
				if animator.animation != "walk_forward":
					animator.animation = "walk_forward"
					animator.play()
		else:
			if direction > 0:
				if animator.animation != "walk_forward":
					animator.animation = "walk_forward"
					animator.play()
			else:
				if animator.animation != "walk_backward":
					animator.animation = "walk_backward"
					animator.play()
	else:
		set_state(State.IDLE)
		animator.animation = "idle"
		animator.play()
		velocity.x = move_toward(velocity.x, 0, SPEED)
		return

	if Input.is_action_just_pressed(jump_input) and is_on_floor():
		set_state(State.JUMP)
		velocity.y = JUMP_VELOCITY
		animator.animation = "jump"
		animator.play()
		return

	if Input.is_action_pressed(crouch_input):
		set_state(State.CROUCH)
		animator.animation = "crouch"
		animator.play()
		return

	var attack_anim = get_attack_animation("stand")
	if attack_anim != "":
		velocity.x = 0
		set_state(State.ATTACK)
		animator.animation = attack_anim
		animator.play()
		if attack_anim == "stand_punch_1":
			hitbox_anim_player.play("stand_punch_1_hitbox")
		if attack_anim == "stand_punch_2":
			hitbox_anim_player.play("stand_punch_2_hitbox")
		if attack_anim == "stand_punch_3":
			hitbox_anim_player.play("stand_punch_3_hitbox")	
		if attack_anim == "stand_kick_1":
			hitbox_anim_player.play("stand_kick_1_hitbox")
		if attack_anim == "stand_kick_2":
			hitbox_anim_player.play("stand_kick_2_hitbox")
		await animator.animation_finished
		set_state(State.IDLE)
		animator.animation = "idle"
		animator.play()
		return

func process_crouch(delta: float) -> void:
	if not Input.is_action_pressed(crouch_input):
		set_state(State.IDLE)
		animator.animation = "idle"
		animator.play()
		return

	var attack_anim = get_attack_animation("crouch")
	if attack_anim != "":
		velocity.x = 0
		set_state(State.ATTACK)
		animator.animation = attack_anim
		animator.play()
		if attack_anim == "crouch_kick_1":
			hitbox_anim_player.play("crouch_kick_1_hitbox")
		if attack_anim == "crouch_kick_2":
			hitbox_anim_player.play("crouch_kick_2_hitbox")
		if attack_anim == "crouch_punch_1":
			hitbox_anim_player.play("crouch_punch_1_hitbox")
		if attack_anim == "crouch_punch_2":
			hitbox_anim_player.play("crouch_punch_2_hitbox")
		if attack_anim == "crouch_punch_3":
			hitbox_anim_player.play("crouch_punch_3_hitbox")
		await animator.animation_finished
		if Input.is_action_pressed(crouch_input):
			set_state(State.CROUCH)
			animator.animation = "crouch"
			animator.play()
		else:
			set_state(State.IDLE)
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
		velocity.x = 0
		set_state(State.ATTACK)
		animator.animation = attack_anim
		animator.play()
		if attack_anim == "jump_punch_1":
			hitbox_anim_player.play("jump_punch_1_hitbox")
		if attack_anim == "jump_punch_2":
			hitbox_anim_player.play("jump_punch_2_hitbox")
		if attack_anim == "jump_kick_1":
			hitbox_anim_player.play("jump_kick_1_hitbox")
		if attack_anim == "jump_kick_2":
			hitbox_anim_player.play("jump_kick_2_hitbox")
		await animator.animation_finished
		if is_on_floor():
			set_state(State.IDLE)
			animator.animation = "idle"
			animator.play()
		else:
			set_state(State.JUMP)
			var direction = Input.get_axis(left_input, right_input)
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
		set_state(State.IDLE)
		animator.animation = "idle"
		animator.play()
		return

	var direction = Input.get_axis(left_input, right_input)
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
		var block_pressed = false
		if is_player2:
			block_pressed = Input.is_action_pressed("walk_right_p2")
		else:
			block_pressed = Input.is_action_pressed("walk_left")
		
		if block_pressed:
			print("Block input detected. Playing stand_block animation and ignoring damage.")
			animator.animation = "stand_block"
			animator.play()
			await animator.animation_finished
			set_state(State.IDLE)
			animator.animation = "idle"
			animator.play()
			return
		
		print("Taking damage: current_health before =", current_health)
		current_health -= 10
		print("Taking damage: current_health after =", current_health)
		emit_signal("HPLoss")
		hurt_applied = true
		
		if current_health <= 0:
			animator.animation = "jump_hit"
			animator.play()
			await get_tree().create_timer(0.1).timeout
			var frame_count = animator.sprite_frames.get_frame_count("jump_hit")
			animator.stop()
			if get_parent() and get_parent().name == "Player2":
				print("player1 won")
			else:
				print("player2 won")
			await get_tree().create_timer(3.0).timeout
			get_tree().reload_current_scene()
			return
		else:
			animator.animation = "stand_hit_high"
			animator.play()
			await animator.animation_finished
			hurt_applied = false
			set_state(State.IDLE)
			animator.animation = "idle"
			animator.play()
			return

func hurt() -> void:
	if current_state != State.HURT:
		set_state(State.HURT)
		process_hurt(0)

func _on_Hurtbox_area_entered(area: Area2D) -> void:
	if is_blocking:
		return
	print("Hurtbox entered by:", area.name)
	if area.get_parent() == self:
		return
	if area.is_in_group("attack_hitboxes"):
		hurt()

func _on_animation_finished() -> void:
	if animator.animation == "crouch" and current_state == State.CROUCH:
		if Input.is_action_pressed(crouch_input):
			var frame_count = animator.sprite_frames.get_frame_count("crouch")
			animator.frame = frame_count - 1
			animator.stop()
			
func get_attack_animation(context: String) -> String:
	if context == "stand" and Input.is_action_just_pressed(punch_1_input) and Input.is_action_just_pressed(punch_2_input):
		return "hadouken"
	if Input.is_action_just_pressed(punch_1_input):
		return context + "_punch_1"
	elif Input.is_action_just_pressed(punch_2_input):
		return context + "_punch_2"
	elif Input.is_action_just_pressed(punch_3_input):
		return context + "_punch_3"
	elif Input.is_action_just_pressed(kick_1_input):
		return context + "_kick_1"
	elif Input.is_action_just_pressed(kick_2_input):
		return context + "_kick_2"
	return ""

func _flip_based_on_opponent() -> void:
	var parent_node = get_parent()
	if parent_node == null:
		return

	var other_player_body: CharacterBody2D = null
	if parent_node.name == "Player1":
		if parent_node.get_parent().has_node("Player2/CharacterBody2D"):
			other_player_body = parent_node.get_parent().get_node("Player2/CharacterBody2D")
	elif parent_node.name == "Player2":
		return

	if other_player_body:
		animator.flip_h = (global_position.x > other_player_body.global_position.x)
