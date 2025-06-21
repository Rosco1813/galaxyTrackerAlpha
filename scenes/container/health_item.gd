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
	if body.name == 'Player1':
		print('enter health area ')
		if Globals.player_one_health < 100:
			Globals.player_one_health += 20
		if Globals.player_one_stamina < 100:
			Globals.player_one_stamina +=15
		queue_free()
#	print('Health pack pick up ', body.name)
