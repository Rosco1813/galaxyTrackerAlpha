extends CharacterBody2D

@onready var animation = $AnimationPlayer
@onready var sprite = $ratSprite
@onready var animationTree = $AnimationTree

var is_enemy:bool = true
var direction = Vector2.RIGHT
var speed = 100
#var speed = 2
var health = 100
var player_in_attack_zone:bool = false
var switchWeapon:bool = false

var ammo = 100

signal rat_shoot(pos, direction)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

#	move_and_slide()
func _physics_process(_delta: float) -> void:
#	pass
	var distance_to_player = global_position.distance_to(Globals.player_position)
	#print('distance to user ', distance_to_player)
	if Globals.player_position == null:
		return
	if player_in_attack_zone == true:
		if distance_to_player > 300:
			direction = (Globals.player_position - global_position).normalized()
		else:
			direction = (Globals.player_position + global_position).normalized()
		var pos:Vector2
		velocity = direction * speed
		rat_move(direction, true)

		if switchWeapon and ammo > 0:
			tail_lazer(direction, true)
			rat_shoot.emit(pos, direction)
		else:
			if ammo > 0:
				guns(direction, true)
				rat_shoot.emit(pos, direction)
		move_and_slide()

func stop_moving(direction):
	rat_move(direction, false)
	tail_lazer(direction, false)
	guns(direction, false)


func idle(direction, condition):
	animationTree.set("parameters/conditions/is_idle", condition)
	animationTree["parameters/idle/blend_position"] = direction

func rat_move(direction, condition):
	animationTree.set("parameters/conditions/is_walking", condition)
	animationTree["parameters/walk/blend_position"] = direction
func tail_lazer(direction, condition):
#	print('tail lazer direction == ', direction)
	animationTree.set("parameters/conditions/shoot_tail", condition)
	animationTree["parameters/shoot_tail/blend_position"] = direction
func guns(direction, condition):
	animationTree.set("parameters/conditions/shoot_gun", condition)
	animationTree["parameters/shoot_gun/blend_position"] = direction
func hit():
	health -=50
	if health == 0:
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:

	if body.name == "Player1":
		Globals.player_one_health -= 40



func _on_attack_area_body_entered(body: Node2D) -> void:
#	$weapon_switch.start()
	if body.name == 'Player1':
		player_in_attack_zone = true
#		rat_move()


func _on_attack_area_body_exited(body: Node2D) -> void:
#	$weapon_switch.stop()
	if body.name == 'Player1':
		player_in_attack_zone = false
		stop_moving(direction)
		idle(direction, true)


func _on_weapon_switch_timeout() -> void:
	pass
#	print('switch weapon')
#	switchWeapon = !switchWeapon

func shoot():
#	print('shoot shoot shoot')
	if ammo > 0:
		ammo -=1
		if ( ammo % 5) == 0:
			switchWeapon = !switchWeapon
	else:
		print('out of ammo')
