extends ItemContainer

@onready var ammo_texture = $Sprite2D
var ammo_types = ['pistol', 'shotgun']
var type = ammo_types[randi()%len(ammo_types)]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	match type:
		"pistol":
			ammo_texture.texture= preload("res://graphics/pickUps/Revolver_Ammo.png")
		"shotgun":
			ammo_texture.texture = preload("res://graphics/pickUps/Shotgun_Ammo.png")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var pid: int = body.player_id if "player_id" in body else 1
		if type == "pistol":
			Globals.add_player_ammo(pid, "pistol", 6)
		if type == 'shotgun':
			Globals.add_player_ammo(pid, "shotgun", 2)
		queue_free()
