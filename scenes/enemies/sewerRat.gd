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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:
#	var dir_to_player = (Globals.player_position - global_position).normalized()
#	velocity = dir_to_player * speed
##	velocity = direction * speed
##	velocity = Globals.player_position * speed
##	look_at(Globals.player_position)
#	print('==================================')
#	print('player position ', Globals.player_position)
#	print('Rat animation == ', animationTree)
#	direction = Globals.player_direction
#	print('= rat direction =- ', direction)
#	print('== rat velocity == ', velocity)
##	velocity = Globals.player_direction * speed
#	velocity = Globals.player_position * speed
#	print('==================================')
	move_and_slide()
func _physics_process(_delta: float) -> void:
	pass
	if Globals.player_position == null:
		return
	if player_in_attack_zone == true:
		direction = (Globals.player_position - global_position).normalized()
		velocity = direction * speed
		rat_move(direction)
		move_and_slide()
#
#	animationTree.set("parameters/conditions/is_walking", true)
#	animationTree["parameters/walk/blend_position"] = direction

func rat_move(direction):
#	if Globals.player_position == null:
#		return
#	direction = (Globals.player_position - global_position).normalized()
#	velocity = direction * speed
#	move_and_slide()

	animationTree.set("parameters/conditions/is_walking", true)
	animationTree["parameters/walk/blend_position"] = direction

func hit():
	health -=50
	if health == 0:
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player1":
		Globals.player_one_health -= 40



func _on_attack_area_body_entered(body: Node2D) -> void:

	print('rat attack zone : : ', body.name)
	if body.name == 'Player1':
		player_in_attack_zone = true
#		rat_move()


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.name == 'Player1':
		player_in_attack_zone = false
