extends Area2D


var speed:int = 1000
var direction:Vector2 = Vector2.UP

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	position += direction * speed * delta
# Called every frame. 'delta' is the elapsed time since the previous frame.



func _on_body_entered(body: Node2D) -> void:
#	print("Collision Body : : : ")
	if "hit" in body:
		body.hit()
		if "is_enemy" in body:
			print('is an enemy')
	if "player" in body:
		pass
	elif  "walls" in body:
		pass
	else:
		queue_free()
	pass # Replace with function body.


func _on_timer_timeout() -> void:
	queue_free()
