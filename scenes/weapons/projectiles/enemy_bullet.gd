extends Area2D

var speed: int = 600
var direction: Vector2 = Vector2.UP
var damage: int = 15

func _ready() -> void:
	add_to_group("enemy_projectile")

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if "hit" in body:
		body.hit()
	if body.is_in_group("player"):
		Globals.player_one_health -= damage
	queue_free()

func _on_timer_timeout() -> void:
	queue_free()
