extends RigidBody2D

@onready var timer = $Timer
@onready var explosionAnimation = $AnimationPlayer

var speed:int = 750
#var direction:Vector2 = Vector2.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.start()
#	print('started timer !!!!')
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
#	position += direction * speed * delta



func _on_timer_timeout() -> void:

	print('timer ended !!!!!!!')
	pass # Replace with function body.

func explode():
	explosionAnimation.play("explosion")
