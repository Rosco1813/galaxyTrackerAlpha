extends CharacterBody2D

@onready var animation = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var animationTree = $AnimationTree
var shot_sfx_pool_node: Node = null
var shot_sfx_players: Array[AudioStreamPlayer] = []
var shot_sfx_index := 0

signal shootWeapon(markerPosition, weaponType, direction)

@export var player_id := 1  # 1 for player 1, 2 for player 2

var speed = 8
var weapons: Array = ['pistol', 'shotgun', 'empty_handed', 'grenade']
var selectedWeapon: String = weapons[0]
var direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.ZERO  # For twin-stick aiming
var aiming = false
var rolling = false
var shooting = false
var last_position_y = 0.0
var last_shot_position
var player: bool = true

var overlapping_bodies: Array[Node2D] = []

# Stamina regeneration
var stamina_regen_cooldown := 4.0  # Seconds to wait before regenerating
var stamina_regen_rate := 15.0  # Stamina points per second
var time_since_stamina_used := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("player")
	Globals.set_player_weapon(player_id, selectedWeapon)
	animationTree.active = true
	# Optional nodes - check if they exist
	shot_sfx_pool_node = get_node_or_null("ShotSFXPool")
	if shot_sfx_pool_node:
		for child in shot_sfx_pool_node.get_children():
			if child is AudioStreamPlayer:
				shot_sfx_players.append(child)

func _get_state_machine() -> AnimationNodeStateMachinePlayback:
	return animationTree["parameters/playback"]

func _is_shoot_animation_finished() -> bool:
	# Check if the current animation has reached its end
	var state_machine = _get_state_machine()
	var current_state = state_machine.get_current_node()
	if not ("shoot" in current_state or "Shoot" in current_state):
		return false
	# Get the current animation length and position
	var current_length = state_machine.get_current_length()
	var current_position = state_machine.get_current_play_position()
	# Consider it finished if we're at 95% or more of the animation
	return current_length > 0 and current_position >= current_length * 0.95

func _restart_shoot_animation() -> void:
	# Force restart the current shooting animation by traveling to it again
	var state_machine = _get_state_machine()
	var current_state = state_machine.get_current_node()
	if "shoot" in current_state or "Shoot" in current_state:
		state_machine.start(current_state, true)  # true = reset

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	update_z_index()
	Globals.player_position = global_position
	
	# Stamina regeneration
	_update_stamina_regen(delta)
	
	# Get movement input (unless rolling)
	if rolling == false:
		direction = InputManager.get_movement(player_id)
		Globals.player_direction = direction
	
	# Get facing direction from right stick (twin-stick controls)
	var right_stick := InputManager.get_facing(player_id)
	if right_stick.length() > 0.2:
		# Right stick is being used - face that direction
		facing_direction = right_stick.normalized()
	elif direction != Vector2.ZERO:
		# No right stick input - default to movement direction
		facing_direction = direction.normalized()
	# else: keep facing previous direction when standing still
	
	# Flip sprite and shooting position based on facing direction
	if facing_direction.x < 0:
		sprite.flip_h = true
		var shoot_pos = get_node_or_null("shootingPosition")
		if shoot_pos:
			shoot_pos.scale.x = -1
	elif facing_direction.x > 0:
		sprite.flip_h = false
		var shoot_pos = get_node_or_null("shootingPosition")
		if shoot_pos:
			shoot_pos.scale.x = 1
	
	# Aiming when right stick is used OR when moving (auto-aim)
	aiming = facing_direction != Vector2.ZERO
	
	# Set speed based on state
	if rolling == true:
		speed = 10  # Roll fast
	elif direction != Vector2.ZERO:
		speed = 3  # Walk speed
	else:
		speed = 0  # Standing still (idle)
	
	velocity = direction * speed
	
	# Always allow movement - only idle states have zero speed anyway
	move_and_collide(velocity)
	
	update_animation()
	
	if position.y != last_position_y:
		pass
	last_position_y = position.y
	
	if InputManager.is_action_just_released(player_id, "switch_weapon"):
		switchWeapon()
	if InputManager.is_action_pressed(player_id, "grenade"):
		set_animation_conditions("is_idle", true)
		speed = 0
	if InputManager.is_action_just_released(player_id, "grenade") and Globals.get_player_ammo(player_id, "grenade") > 0:
		var previousWeapon = selectedWeapon
		selectedWeapon = 'grenade'
		Globals.use_player_ammo(player_id, "grenade")
		triggerAmmoAnimation()
		selectedWeapon = previousWeapon
		speed = 3

func switchWeapon():
	var current_index = weapons.find(selectedWeapon)
	if current_index == -1:
		current_index = 0
	current_index = (current_index + 1) % weapons.size()
	selectedWeapon = weapons[current_index]
	Globals.set_player_weapon(player_id, selectedWeapon)
	# TODO: Add shotgun equip animation when shotgun animations are ready
	#if selectedWeapon == 'shotgun':
	#	set_animation_conditions('equip_shotgun', true)

func update_animation():
	# Update blend position when facing direction exists
	if facing_direction != Vector2.ZERO:
		last_shot_position = facing_direction
		update_blend_position()
	
	# FIRST: Process inputs to update state variables
	# Handle shoot input (shooting while button held)
	if InputManager.is_action_pressed(player_id, "shoot"):
		if selectedWeapon == 'pistol' and Globals.get_player_ammo(player_id, "pistol") > 0:
			shooting = true
		elif selectedWeapon == 'shotgun' and Globals.get_player_ammo(player_id, "shotgun") > 0:
			shooting = true
			Globals.use_player_ammo(player_id, "shotgun")
		else:
			shooting = false  # No ammo
	else:
		# Shoot button released - stop shooting
		shooting = false
	
	# Handle roll input (can roll anytime you have stamina)
	if InputManager.is_action_just_pressed(player_id, "roll") and Globals.get_player_stamina(player_id) > 0:
		rolling = true
		# Deduct stamina when starting roll
		_use_stamina(10)
		# Make sure roll blend position is set (use last direction if standing still)
		if direction == Vector2.ZERO and last_shot_position != null:
			animationTree["parameters/roll/blend_position"] = last_shot_position
		else:
			animationTree["parameters/roll/blend_position"] = direction
	
	# Check if we need to restart a shooting animation (held shoot, animation ended)
	if shooting and _is_shoot_animation_finished():
		_restart_shoot_animation()
	
	# THEN: Determine animation state based on updated state variables (priority order)
	if rolling == true && shooting == false:
		set_animation_conditions("is_rolling", true)
	elif shooting == true:
		if direction != Vector2.ZERO:
			set_animation_conditions('is_walking_shooting', true)
		else:
			set_animation_conditions('is_idle_shooting', true)
	elif direction != Vector2.ZERO:
		# Moving = automatically in walk_aim
		set_animation_conditions('is_walking_aiming', true)
	elif facing_direction != Vector2.ZERO and direction == Vector2.ZERO:
		# Standing still but aiming with right stick = idle_aim
		set_animation_conditions('is_idle_aiming', true)
	else:
		# Standing still = idle
		set_animation_conditions('is_idle', true)

func set_animation_conditions(condition: String, value: bool):
	# Current female player conditions
	var all_conditions = ["is_idle", "is_idle_aiming", "is_idle_shooting", "is_rolling", "is_walking_aiming", "is_walking_shooting"]
	
	for cond in all_conditions:
		var param_path = "parameters/conditions/" + cond
		if cond == condition:
			animationTree[param_path] = value
		else:
			animationTree[param_path] = !value

func _use_stamina(amount: int) -> void:
	# Use stamina and reset regen timer
	var current_stamina := Globals.get_player_stamina(player_id)
	Globals.set_player_stamina(player_id, current_stamina - amount)
	time_since_stamina_used = 0.0

func _update_stamina_regen(delta: float) -> void:
	var current_stamina := Globals.get_player_stamina(player_id)
	var max_stamina: int = Globals.S  # Max stamina from Globals
	
	if current_stamina < max_stamina:
		time_since_stamina_used += delta
		
		if time_since_stamina_used >= stamina_regen_cooldown:
			# Regenerate stamina
			var regen_amount := int(stamina_regen_rate * delta)
			if regen_amount < 1:
				regen_amount = 1  # Ensure at least 1 point per applicable frame
			var new_stamina := mini(current_stamina + regen_amount, max_stamina)
			Globals.set_player_stamina(player_id, new_stamina)

func set_roll(value):
	rolling = value
	_use_stamina(10)
	animationTree["parameters/conditions/is_rolling"] = value

func set_shooting(value):
	# Set shooting condition based on current state
	if direction != Vector2.ZERO:
		animationTree['parameters/conditions/is_walking_shooting'] = value
	else:
		animationTree['parameters/conditions/is_idle_shooting'] = value

func update_blend_position():
	# Use facing_direction for all aim/shoot animations (twin-stick support)
	animationTree["parameters/idle/blend_position"] = facing_direction
	animationTree["parameters/idle_aim/blend_position"] = facing_direction
	animationTree["parameters/idle_shoot/blend_position"] = facing_direction
	animationTree["parameters/roll/blend_position"] = direction  # Roll uses movement direction
	animationTree["parameters/walk_aim/blend_position"] = facing_direction
	animationTree["parameters/walk_shoot/blend_position"] = facing_direction

func endRoll(_value = false):
	speed = 3
	set_roll(false)

func endShooting(value = false):
	shooting = value
	set_shooting(false)

func triggerAmmoAnimation():
	Globals.use_player_ammo(player_id, "pistol")
	var shooting_position_node = get_node_or_null("shootingPosition")
	if shooting_position_node:
		var shooting_markers = shooting_position_node.get_children()
		if shooting_markers.size() > 0:
			var selected_marker = shooting_markers[randi() % shooting_markers.size()]
			shootWeapon.emit(selected_marker.global_position, selectedWeapon, last_shot_position)
	else:
		# Fallback: emit from player position if no markers exist
		shootWeapon.emit(global_position, selectedWeapon, last_shot_position)

func play_shot_sound() -> void:
	if shot_sfx_players.is_empty():
		return
	var sfx_player: AudioStreamPlayer = shot_sfx_players[shot_sfx_index]
	sfx_player.stop()
	sfx_player.play()
	shot_sfx_index = (shot_sfx_index + 1) % shot_sfx_players.size()

func hit():
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name != 'firstRoom' and body.name != 'Player1' and body.name != 'StaticBody2D' and body.name != 'steamVent':
		if body is Node2D:
			overlapping_bodies.append(body)
			update_z_index()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Node2D and body in overlapping_bodies:
		overlapping_bodies.erase(body)
		update_z_index()

func update_z_index():
	if overlapping_bodies.is_empty():
		z_index = 0
		return
	var highest_body_y = null
	for body in overlapping_bodies:
		if highest_body_y == null or body.global_position.y > highest_body_y.global_position.y:
			highest_body_y = body
	if highest_body_y and global_position.y < highest_body_y.global_position.y:
		z_index = 0
		highest_body_y.z_index = 1
	else:
		z_index = 1
		highest_body_y.z_index = 0

func _on_body_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_projectile"):
		var current_health := Globals.get_player_health(player_id)
		Globals.set_player_health(player_id, current_health - area.damage)
		area.queue_free()
	# Friendly fire check
	elif area.is_in_group("player_projectile") and Globals.friendly_fire_enabled:
		if "owner_player_id" in area and area.owner_player_id != player_id:
			var current_health := Globals.get_player_health(player_id)
			var dmg = area.damage if "damage" in area else 10
			Globals.set_player_health(player_id, current_health - dmg)
			area.queue_free()

func _on_head_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_projectile"):
		var current_health := Globals.get_player_health(player_id)
		Globals.set_player_health(player_id, current_health - area.damage * 2)
		area.queue_free()
	# Friendly fire check (headshot = 2x damage)
	elif area.is_in_group("player_projectile") and Globals.friendly_fire_enabled:
		if "owner_player_id" in area and area.owner_player_id != player_id:
			var current_health := Globals.get_player_health(player_id)
			var dmg = area.damage if "damage" in area else 10
			Globals.set_player_health(player_id, current_health - dmg * 2)
			area.queue_free()
