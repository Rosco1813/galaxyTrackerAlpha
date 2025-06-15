extends CharacterBody2D

@onready var animation = $AnimationPlayer
@onready var sprite = $ratSprite
@onready var animationTree = $AnimationTree

var is_enemy:bool = true
var direction = Vector2.RIGHT
var speed = 200
var health = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	velocity = direction * speed
	move_and_slide()

func hit():
	health -=50
	if health == 0:
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player1":
		Globals.player_one_health -= 40

