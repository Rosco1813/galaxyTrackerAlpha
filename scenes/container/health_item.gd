extends ItemContainer

@onready var health_texture = $Sprite2D
var available_options = ['small', 'medium', 'large']
var type = available_options[randi()%len(available_options)]
var rotation_speed : int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#	pass
#	print('== available health item options : : ', type)
	match type:
		"small":
			health_texture.texture = preload("res://graphics/pickUps/Small_Health_Front.png")
		"medium":
			health_texture.texture = preload("res://graphics/pickUps/Small_Health_Right.png")
		"large":
			health_texture.texture = preload("res://graphics/pickUps/Full_Health_Front.png")
#	print('=== HEALTH Texture === ', health_texture)
	var tween = create_tween()
#	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1,1), 0.3 ).from(Vector2(0,0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
#	skew += rotation_speed * delta
#	rotation = skew
	pass





func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var pid: int = body.player_id if "player_id" in body else 1
		var current_health := Globals.get_player_health(pid)
		var current_stamina := Globals.get_player_stamina(pid)
		if current_health < 100:
			Globals.set_player_health(pid, mini(current_health + 20, 100))
		if current_stamina < 100:
			Globals.set_player_stamina(pid, mini(current_stamina + 15, 100))
		queue_free()
