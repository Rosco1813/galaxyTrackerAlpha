extends RigidBody2D

@onready var timer = $Timer
@onready var explosionAnimation = $AnimationPlayer

var speed:int = 750
#var direction:Vector2 = Vector2.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("player_projectile")
	timer.start()
#	print('started timer !!!!')
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
#	position += direction * speed * delta



func _on_timer_timeout() -> void:

#	print('timer ended !!!!!!!')
	pass # Replace with function body.

func explode():
	
	explosionAnimation.play("explosion")

#func hit():
	#print('GRENDADE HIT =======')


func _on_body_entered(body: Node) -> void:
	#print("Collision Body : : : ", body)
	#if "head_hit" in body:
		#body.head_hit()
	if "hit" in body:
		body.hit()
		if "is_enemy" in body:
			pass
			#print('is an enemy', body)
	if "player" in body:
		pass
	elif  "walls" in body:
		pass
	else:
		queue_free()
	pass # Replace with function body.
