extends CharacterBody2D

@onready var animation = $AnimationPlayer
@onready var sprite = $ratSprite
@onready var animationTree = $AnimationTree

var is_enemy:bool = true
var direction = Vector2.RIGHT
var speed = 200

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	velocity = direction * speed
	move_and_slide()

func hit():
	queue_free()
	print('Damage')
