extends CharacterBody2D
@onready var animation = $AnimationPlayer
@onready var sprite = $niceAgentSprite
@onready var animationTree = $AnimationTree

var is_enemy:bool = true
var direction = Vector2.RIGHT
var speed = 100
#var speed = 2
var health = 100
var player_in_attack_zone:bool = false
var switchWeapon:bool = false
var facing := 1
const FACING_DEAD_ZONE := 0.1
var ammo = 100

signal nice_agent_shoot(pos, direction)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

#	move_and_slide()
func _physics_process(_delta: float) -> void:
#	pass
	var distance_to_player = global_position.distance_to(Globals.player_position)
	print('distance to user ', distance_to_player)
	if Globals.player_position == null:
		return
	if player_in_attack_zone == true:
		if distance_to_player > 300:
			direction = (Globals.player_position - global_position).normalized()
		else:
			direction = (Globals.player_position + global_position).normalized()
		var pos:Vector2
		velocity = direction * speed
		nice_agent_move(direction, true)

		if switchWeapon and ammo > 0:
			shoot_shotgun(direction, true)
			nice_agent_shoot.emit(pos, direction)
		else:
			if ammo > 0:
				#guns(direction, true)
				nice_agent_shoot.emit(pos, direction)
		move_and_slide()

func stop_moving(direction):
	nice_agent_move(direction, false)
	shoot_shotgun(direction, false)
	#guns(direction, false)


func idle(direction, condition):
	animationTree.set("parameters/conditions/is_idle", condition)
	#animationTree["parameters/idle/blend_position"] = direction

func update_facing(dir: Vector2) -> void:
	if abs(dir.x) > FACING_DEAD_ZONE:
		facing = -1 if dir.x < 0 else 1
		sprite.flip_h = facing == -1

func nice_agent_move(direction, condition):
	update_facing(direction)
	print('condition = ', condition)
	animationTree.set("parameters/conditions/is_walking", condition)
	#animationTree["parameters/walk_right/blend_position"] = direction
func shoot_shotgun(direction, condition):
#	print('tail lazer direction == ', direction)
	animationTree.set("parameters/conditions/is_shooting", condition)
	#animationTree["parameters/shoot_right/blend_position"] = direction
#func guns(direction, condition):
	#animationTree.set("parameters/conditions/shoot_gun", condition)
	#animationTree["parameters/shoot_gun/blend_position"] = direction
func hit():
	health -=50
	animationTree.set('parameters/conditions/is_damaged_light', true)
	
	if health == 0:
		animationTree.set("parameters/conditions/is_damaged_crit",true )
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
