extends CharacterBody2D
@onready var animation = $AnimationPlayer
@onready var sprite = $niceAgentSprite
@onready var animationTree = $AnimationTree

signal nice_agent_shoot(pos, direction)
const FACING_DEAD_ZONE := 0.1
var is_enemy:bool = true
var direction = Vector2.RIGHT
var speed = 100
var hit_type :String = ''
var health = 100
var player_in_attack_zone:bool = false
var switchWeapon:bool = false
var facing := 1
var hit_location:String = ''
var just_hit:bool
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(_delta: float) -> void:
	var distance_to_player = global_position.distance_to(Globals.player_position)
	var to_player = Globals.player_position - global_position
	var away_from_player = Globals.player_position + global_position
	var pos:Vector2
	velocity = direction * speed
	#shoot_shotgun(direction,false)
	update_facing(to_player)
	nice_agent_move(direction, true)
	direction = (Globals.player_position - global_position).normalized()

	if just_hit:
		stop_moving(false)

	if distance_to_player > 240 and distance_to_player < 450:
		velocity = Vector2.ZERO

		if just_hit == false:
			shoot_shotgun(direction, true)
			nice_agent_shoot.emit(pos, direction)
					
	if distance_to_player < 240:
		shoot_shotgun(direction, false)
		direction = (Globals.player_position + global_position).normalized()
		velocity = direction * speed
		update_facing(away_from_player)
		nice_agent_move(direction, true)
		move_and_slide()
	elif distance_to_player < 240 or distance_to_player > 450:
		shoot_shotgun(direction, false)
		move_and_slide()
	


func stop_moving(_direction):
	nice_agent_move(_direction, false)
	shoot_shotgun(_direction, false)


func idle(_direction, condition):
	animationTree.set("parameters/conditions/is_idle", condition)

func update_facing(dir: Vector2) -> void:
	if abs(dir.x) > FACING_DEAD_ZONE:
		facing = -1 if dir.x < 0 else 1
		sprite.flip_h = facing == -1

func nice_agent_move(_direction, condition):
	animationTree.set("parameters/conditions/is_walking", condition)

func shoot_shotgun(_direction, condition):
	animationTree.set("parameters/conditions/is_shooting", condition)
	
func die_1(_direction, condition):
	animationTree.set("parameters/conditions/is_dead_1", condition)
	
func light_damage(_direction, condition):
	animationTree.set("parameters/conditions/is_damaged_light", condition)

func hit():
	just_hit = true
	velocity = Vector2.ZERO
	shoot_shotgun(direction, false)
	health -=10
	hit_type = 'damage_light'
	print('health === ', health)
	if health > 0:
		stop_moving(true)
		light_damage(direction, true)

	
	if health < 0:
		stop_moving(true)
		die_1(direction, true)
		if hit_type == 'damage_crit':
			animationTree.set("parameters/conditions/is_damaged_crit",true )


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player1":
		Globals.player_one_health -= 40

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == 'Player1':
		player_in_attack_zone = true

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.name == 'Player1':
		player_in_attack_zone = false


func _on_weapon_switch_timeout() -> void:
	pass



func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	print('animation name : ', anim_name)
	hit_type = anim_name
	
	animationTree.set('parameters/conditions/is_damaged_light', false)
	just_hit = false
	if anim_name == 'death_crit' or anim_name == 'death_1':
		queue_free()


func _on_animation_tree_animation_started(anim_name: StringName) -> void:
	pass # Replace with function body.
