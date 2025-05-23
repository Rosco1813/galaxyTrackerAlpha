extends CharacterBody2D
#todo how to change scale when moving back and forward
#lock onto nearest enemy when shooting
@onready var animation = $AnimationPlayer
@onready var sprite = $playerSprite
@onready var animationTree = $AnimationTree
signal shootWeapon(markerPosition, weaponType, direction)
var speed = 3
var weapons:Array = ['pistol', 'shotgun','empty_handed', 'grenade']
var selectedWeapon: String = weapons[0];
var direction:Vector2 = Vector2.ZERO
var aiming = false
var rolling = false
var shooting = false
var last_position_y = 0.0
var last_shot_position
var player:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print('globals ammo ', Globals.pistol_ammo)
	animationTree.active = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if rolling == false:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

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
			update_level_scale()
			pass
		last_position_y = position.y
	if Input.is_action_just_released("switch_weapon"):
		switchWeapon()
	if Input.is_action_pressed("grenade"):
		set_animation_conditions("is_idle", true)
		speed = 0
	if Input.is_action_just_released("grenade"):
		var previousWeapon = selectedWeapon

		selectedWeapon = 'grenade'

		triggerAmmoAnimation()
		selectedWeapon = previousWeapon
		speed = 3



func switchWeapon():
	var current_index = weapons.find(selectedWeapon)
	if current_index == -1:
		current_index = 0
	current_index = (current_index + 1) % weapons.size()
	selectedWeapon = weapons[current_index]
	print('Current Weapon : ', selectedWeapon)

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

		if selectedWeapon == 'empty_handed' || selectedWeapon == 'pistol':
			aiming = false
			set_animation_conditions('is_moving', true)
		else:
			set_animation_conditions('walk_shotgun', true)
	else:
		set_animation_conditions('is_idle', true)
	if Input.is_action_pressed("aim"):
		aiming = true
		set_animation_conditions('is_aiming', true)
	if shooting == true || aiming == true:

#		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("shoot"):
			shooting = true
			set_animation_conditions('is_shooting', true)
	if Input.is_action_just_released("aim"):
#		$AnimationPlayer.stop()

		set_animation_conditions('is_idle', true)
	if Input.is_action_just_pressed("roll") && aiming == false :
		rolling = true

	if rolling == true && shooting == false:
		speed = 10
		set_animation_conditions("is_rolling", true)

func set_animation_conditions(condition: String, value: bool):
	var all_conditions = ["is_aiming", "is_idle", "is_moving", "is_rolling", "is_shooting", "walk_shotgun"]
	for cond in all_conditions:
		if cond == 'is_moving' && value == true && rolling == false:
			speed = 3
		var param_path = "parameters/conditions/" + cond
		if cond == condition:
			animationTree[param_path] = value
		else:
			animationTree[param_path] = !value

func set_roll(value):
	rolling = value
	animationTree["parameters/conditions/is_rolling"] = value

func set_shooting(value):
	animationTree['parameters/conditions/is_shooting'] = value

func update_blend_position():
	animationTree["parameters/aim_pistol/blend_position"] = direction
	animationTree["parameters/idle/blend_position"] = direction
	animationTree["parameters/roll/blend_position"] = direction
	animationTree["parameters/shoot_pistol/blend_position"] = direction
	animationTree["parameters/walk/blend_position"] = direction
	animationTree["parameters/walk_shotgun/blend_position"] = direction

func endRoll(_value = false):
	speed = 3
	set_roll(false)
func endShooting(value=false):
	shooting = value
	set_shooting(false)

func triggerAmmoAnimation():
		var shooting_markers = $shootingPosition.get_children()
		var selected_marker = shooting_markers[randi() % shooting_markers.size() ]
		shootWeapon.emit(selected_marker.global_position, selectedWeapon, last_shot_position)

