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
	var target_pos := Globals.get_closest_player_position(global_position)
	if target_pos == Vector2.ZERO:
		return
	
	var distance_to_player = global_position.distance_to(target_pos)

	if player_in_attack_zone == true:
		if distance_to_player > 300:
			direction = (target_pos - global_position).normalized()
		else:
			direction = (target_pos + global_position).normalized()
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

func stop_moving(directions):
	rat_move(directions, false)
	tail_lazer(directions, false)
	guns(directions, false)


func idle(directions, condition):
	animationTree.set("parameters/conditions/is_idle", condition)
	animationTree["parameters/idle/blend_position"] = directions

func rat_move(directions, condition):
	animationTree.set("parameters/conditions/is_walking", condition)
	animationTree["parameters/walk/blend_position"] = directions
func tail_lazer(directions, condition):

	animationTree.set("parameters/conditions/shoot_tail", condition)
	animationTree["parameters/shoot_tail/blend_position"] = directions
func guns(directions, condition):
	animationTree.set("parameters/conditions/shoot_gun", condition)
	animationTree["parameters/shoot_gun/blend_position"] = directions
func hit():
	health -=50
	if health == 0:
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var pid: int = body.player_id if "player_id" in body else 1
		var current_health := Globals.get_player_health(pid)
		Globals.set_player_health(pid, current_health - 40)



func _on_attack_area_body_entered(body: Node2D) -> void:
#	$weapon_switch.start()
	if body.is_in_group("player"):
		player_in_attack_zone = true
#		rat_move()


func _on_attack_area_body_exited(body: Node2D) -> void:
#	$weapon_switch.stop()
	if body.is_in_group("player"):
		player_in_attack_zone = false
		stop_moving(direction)
		idle(direction, true)


func _on_weapon_switch_timeout() -> void:
	pass

#	switchWeapon = !switchWeapon

func shoot():

	if ammo > 0:
		ammo -=1
		if ( ammo % 5) == 0:
			switchWeapon = !switchWeapon
	else:
		print('out of ammo')
