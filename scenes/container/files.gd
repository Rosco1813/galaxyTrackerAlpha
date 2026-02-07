extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var pid: int = body.player_id if "player_id" in body else 1
		#var current_stamina := Globals.get_player_stamina(pid)
		#Globals.set_player_stamina(pid, mini(current_stamina + 50, 100))
		queue_free()
