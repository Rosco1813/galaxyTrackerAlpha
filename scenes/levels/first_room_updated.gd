extends LevelParent


func _process(_delta: float) -> void:
	pass


func _on_first_room_player_entered_door() -> void:
	if _player == null:
		return
	var tween := create_tween()
	player_zoom_in(2, 2, 1)
	tween.tween_property(_player, "speed", 0, 0.5)
	TransitionLayer.change_scene("res://scenes/levels/second_room.tscn")
	_player.hide()


func _on_first_room_player_exit_door() -> void:
	player_zoom_in(1.2, 1.2, 1)


func _on_first_room_sewer_entrance() -> void:
	pass


func _on_first_room_sewer_exit() -> void:
	pass


func player_zoom_in(x: float, y: float, time: float) -> void:
	if _player == null:
		return
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	var camera := _player.get_node_or_null("Camera2D")
	if camera:
		tween.tween_property(camera, "zoom", Vector2(x, y), time)
