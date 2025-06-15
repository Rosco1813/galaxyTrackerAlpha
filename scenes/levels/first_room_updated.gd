extends LevelParent


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_first_room_player_entered_door() -> void:
	var tween = create_tween()
	player_zoom_in(2,2, 1)
	tween.tween_property($Player1, "speed", 0, 0.5)
#	get_tree().change_scene_to_file("res://scenes/levels/second_room.tscn")
	TransitionLayer.change_scene("res://scenes/levels/second_room.tscn")
#	var tween = get_tree().create_tween()
#	tween.tween_property($Player1/Camera2D, "zoom",Vector2(2,2), 1)
#	print('player has entered the door')



func _on_first_room_player_exit_door() -> void:
	player_zoom_in(1.2,1.2, 1)
#	var tween = get_tree().create_tween()
#	tween.tween_property($Player1/Camera2D, "zoom",Vector2(1.2,1.2), 1)
	print('exit the door')


func _on_first_room_sewer_entrance() -> void:
	pass # Replace with function body.


func _on_first_room_sewer_exit() -> void:
	pass # Replace with function body.

func player_zoom_in(x,y, time):
	var tween = get_tree().create_tween()

	tween.set_parallel(true)
#	tween.tween_property($Player1, "speed", 0,0.5)
#	tween.tween_property($Player1, "modulate:a",0,2).from(0.5)
	tween.tween_property($Player1/Camera2D, "zoom",Vector2(x,y), time)
