extends CharacterBody2D

@onready var animation = $AnimationPlayer
@onready var sprite = $playerSprite
@onready var animationTree = $AnimationTree
@onready var shot_sfx_pool_node: Node = $ShotSFXPool
var shot_sfx_players: Array[AudioStreamPlayer] = []
var shot_sfx_index := 0

signal shootWeapon(markerPosition, weaponType, direction)

@export var player_id := 1  # 1 for player 1, 2 for player 2

var speed = 6
var weapons:Array = ['pistol', 'shotgun','empty_handed', 'grenade']
var selectedWeapon: String = weapons[0];
var direction:Vector2 = Vector2.ZERO
var aiming = false
var rolling = false
var shooting = false
var last_position_y = 0.0
var last_shot_position
var player:bool = true


var overlapping_bodies: Array[Node2D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#	print('globals ammo ', Globals.pistol_ammo)
	add_to_group("player")
	Globals.set_player_weapon(player_id, selectedWeapon)
	animationTree.active = true
	for child in shot_sfx_pool_node.get_children():
		if child is AudioStreamPlayer:
			shot_sfx_players.append(child)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:
func _physics_process(_delta: float) -> void:
	update_z_index()
	Globals.player_position = global_position
	if rolling == false:
		direction = InputManager.get_movement(player_id)
		Globals.player_direction = direction
#		print('=== DIRECTION player ==',  direction)
	if shooting == true || aiming == true:
		speed = 0
	velocity = direction * speed
	if aiming == false && shooting == false || rolling == true:
#		move_and_slide()
		move_and_collide(velocity)
	update_animation()
	if aiming == false && shooting == false:
		if position.y != last_position_y:
#			update_character_scale()
#			update_level_scale()
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
	if selectedWeapon == 'shotgun':
		set_animation_conditions('equip_shotgun', true)

func update_character_scale():
	if position.y > last_position_y && sprite.scale.y < 0.38 :
		sprite.scale += Vector2(.001, .001)
	elif position.y < last_position_y && sprite.scale.y > 0.28:
		sprite.scale += Vector2(-.001, -.001)

func update_level_scale():
	var parent = get_parent()
	if parent:

		if position.y > last_position_y && parent.scale.y  > 0.85:
#			print('1 : position y : ', position.y, ' : last position : ', last_position_y, " :  Parent scale : ", parent.scale.y)
			parent.scale += Vector2(-.001, -.001)
		elif position.y < last_position_y && parent.scale.y < 1.1:
#			print('2 : position y : ', position.y, ' : last position : ', last_position_y, " :  Parent scale : ", parent.scale.y)
			parent.scale += Vector2(.001, .001)
	last_position_y = position.y

func update_animation():
	if direction != Vector2.ZERO:
		last_shot_position = direction
		update_blend_position()

		if selectedWeapon != 'shotgun':
			aiming = false
			set_animation_conditions('is_moving', true)
		else:
			aiming = false
			set_animation_conditions('walk_shotgun', true)
	else:
		set_animation_conditions('is_idle', true)
	if InputManager.is_action_pressed(player_id, "aim"):
		aiming = true
		if selectedWeapon =='pistol':
			set_animation_conditions('is_aiming', true)
		elif  selectedWeapon =='shotgun':
			set_animation_conditions('aim_shotgun', true)
	if shooting == true || aiming == true:

		if InputManager.is_action_just_pressed(player_id, "shoot")  :
#			if selectedWeapon == 'pistol':
#			elif  selectedWeapon == 'shotgun':

#			shooting = true
			if selectedWeapon =='pistol' and Globals.get_player_ammo(player_id, "pistol") > 0 :
				shooting = true
				set_animation_conditions('is_shooting', true)
				#play_shot_sound()
				#Globals.pistol_ammo -= 1
			elif  selectedWeapon =='shotgun' and Globals.get_player_ammo(player_id, "shotgun") > 0:
				shooting = true
				set_animation_conditions('shoot_shotgun', true)
				Globals.use_player_ammo(player_id, "shotgun")
	if InputManager.is_action_just_released(player_id, "aim"):
#		$AnimationPlayer.stop()

		set_animation_conditions('is_idle', true)
	if InputManager.is_action_just_pressed(player_id, "roll") && aiming == false and Globals.get_player_stamina(player_id) > 0:
		rolling = true

	if rolling == true && shooting == false:
		speed = 10
		set_animation_conditions("is_rolling", true)

func set_animation_conditions(condition: String, value: bool):
	var all_conditions = ["is_aiming", "is_idle", "is_moving", "is_rolling", "is_shooting", "walk_shotgun", "aim_shotgun", "equip_shotgun",  "reload_shotgun", "shoot_shotgun"]
	for cond in all_conditions:
		var param_path = "parameters/conditions/" + cond
		if cond == 'is_moving' && value == true && rolling == false or cond == "walk_shotgun" && value == true && rolling == false:
			speed = 3
		if cond == condition:
			animationTree[param_path] = value
		else:
			animationTree[param_path] = !value

func set_roll(value):
	rolling = value
	var current_stamina := Globals.get_player_stamina(player_id)
	Globals.set_player_stamina(player_id, current_stamina - 10)
	animationTree["parameters/conditions/is_rolling"] = value

func set_shooting(value):
	if selectedWeapon =='pistol':
		animationTree['parameters/conditions/is_shooting'] = value
	elif selectedWeapon == 'shotgun':
		animationTree['parameters/conditions/shoot_shotgun'] = value

func update_blend_position():
	animationTree["parameters/idle/blend_position"] = direction
	animationTree["parameters/walk/blend_position"] = direction
	animationTree["parameters/roll/blend_position"] = direction
	animationTree["parameters/aim_pistol/blend_position"] = direction
	animationTree["parameters/shoot_pistol/blend_position"] = direction
	animationTree["parameters/walk_shotgun/blend_position"] = direction
	animationTree["parameters/aim_shotgun/blend_position"] = direction
	animationTree["parameters/equip_shotgun/blend_position"] = direction
	animationTree["parameters/reload_shotgun/blend_position"] = direction
	animationTree["parameters/shoot_shotgun/blend_position"] = direction

func endRoll(_value = false):
	speed = 3
	set_roll(false)

func endShooting(value=false):
	shooting = value
	set_shooting(false)

func triggerAmmoAnimation():
		Globals.use_player_ammo(player_id, "pistol")
		var shooting_markers = $shootingPosition.get_children()
		var selected_marker = shooting_markers[randi() % shooting_markers.size() ]
		shootWeapon.emit(selected_marker.global_position, selectedWeapon, last_shot_position)

func play_shot_sound() -> void:
	if shot_sfx_players.is_empty():
		return
	var sfx_player: AudioStreamPlayer = shot_sfx_players[shot_sfx_index]
	sfx_player.stop()
	sfx_player.play()
	shot_sfx_index = (shot_sfx_index + 1) % shot_sfx_players.size()

func hit():
#	print('Player one hit')
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
#	print('player : entered player area : ', body.name)
	if  body.name != 'firstRoom' and body.name != 'Player1' and body.name != 'StaticBody2D' and body.name != 'steamVent':
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
#		z_index = min(1, highest_body_y.z_index - 1)
		z_index = 0
#		highest_body_y.z_index = max(3, highest_body_y.z_index + 1)
		highest_body_y.z_index = 1
	else:
		z_index = 1
		highest_body_y.z_index = 0
#		z_index = max(3, highest_body_y.z_index + 1)
#		highest_body_y.z_index =min(1, highest_body_y.z_index - 1)
#	print('==========================')
#	print(" player z  == ", z_index)
#	print('highest body  === ', highest_body_y.z_index, )
#	print('body name === ', highest_body_y.name)
#	print('==========================')

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
