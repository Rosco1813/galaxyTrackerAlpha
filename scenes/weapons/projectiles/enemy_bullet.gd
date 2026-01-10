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
	# Player damage now handled by hurtboxes
	if not body.is_in_group("player"):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_head_hurtbox") or area.is_in_group("player_body_hurtbox"):
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()
