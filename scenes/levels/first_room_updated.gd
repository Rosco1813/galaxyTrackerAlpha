extends LevelParent

# Transition zone state tracking
var _players_in_door_zone: Array[Node2D] = []
var _players_in_sewer_zone: Array[Node2D] = []
var _current_target_scene := ""
var _current_entrance := ""


func _ready() -> void:
	super._ready()
	# Reposition players based on which entrance they came from
	_position_players_at_entrance()
	
	# Connect door and sewer trigger signals programmatically
	var first_room := get_node_or_null("firstRoom")
	if first_room:
		var door_trigger := first_room.get_node_or_null("doorTrigger")
		var sewer_trigger := first_room.get_node_or_null("sewerTrigger")
		
		if door_trigger:
			door_trigger.body_entered.connect(_on_door_trigger_body_entered)
			door_trigger.body_exited.connect(_on_door_trigger_body_exited)
		if sewer_trigger:
			sewer_trigger.body_entered.connect(_on_sewer_trigger_body_entered)
			sewer_trigger.body_exited.connect(_on_sewer_trigger_body_exited)


func _position_players_at_entrance() -> void:
	# Get spawn position based on which entrance player came from
	var spawn_pos := Vector2.ZERO
	var first_room := get_node_or_null("firstRoom")
	
	match Globals.spawn_entrance:
		"door":
			# Came from second_room through door - spawn near door trigger
			if first_room:
				var door_trigger := first_room.get_node_or_null("doorTrigger/CollisionShape2D")
				if door_trigger:
					spawn_pos = first_room.global_position + door_trigger.position + Vector2(-40, -100)
		"sewer":
			# Came from sewer level - spawn near sewer trigger
			if first_room:
				var sewer_trigger := first_room.get_node_or_null("sewerTrigger/CollisionShape2D")
				if sewer_trigger:
					spawn_pos = first_room.global_position + sewer_trigger.position + Vector2(20, 100)
		_:
			# Default spawn - use original position (don't move)
			return
	
	# Move players to spawn position
	if spawn_pos != Vector2.ZERO:
		if _player:
			_player.global_position = spawn_pos
		if _player_two:
			_player_two.global_position = spawn_pos + Vector2(20, -100)  # Offset P2 slightly


func _process(_delta: float) -> void:
	# Check if any player in a zone pressed the interact button
	if _players_in_door_zone.is_empty() and _players_in_sewer_zone.is_empty():
		return
	
	# Check both players' input in co-op, or use raw Input as fallback
	var should_transition := false
	
	# Check each player in the zone
	for player in _players_in_door_zone + _players_in_sewer_zone:
		var player_id: int = player.player_id if "player_id" in player else 1
		if InputManager.is_action_just_pressed(player_id, "select_stuff"):
			should_transition = true
			break
	
	# Also check raw input as fallback for co-op edge cases
	if not should_transition and Input.is_action_just_pressed("select_stuff"):
		should_transition = true
	
	if should_transition:
		_trigger_transition()


func _trigger_transition() -> void:
	# Hide prompt immediately
	InteractionPrompt.hide_prompt()
	
	# Set spawn entrance for next scene
	Globals.spawn_entrance = _current_entrance
	
	if _player == null:
		TransitionLayer.change_scene(_current_target_scene)
		return
	
	var tween := create_tween()
	player_zoom_in(2, 2, 1)
	tween.tween_property(_player, "speed", 0, 0.5)
	TransitionLayer.change_scene(_current_target_scene)
	_player.hide()


# Door trigger handlers
func _on_door_trigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if body not in _players_in_door_zone:
		_players_in_door_zone.append(body)
	_current_target_scene = "res://scenes/levels/second_room.tscn"
	_current_entrance = "door"
	InteractionPrompt.show_prompt("Enter")


func _on_door_trigger_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_players_in_door_zone.erase(body)
	if _players_in_door_zone.is_empty() and _players_in_sewer_zone.is_empty():
		InteractionPrompt.hide_prompt()
	player_zoom_in(1.2, 1.2, 1)


# Sewer trigger handlers
func _on_sewer_trigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if body not in _players_in_sewer_zone:
		_players_in_sewer_zone.append(body)
	_current_target_scene = "res://scenes/levels/sewer_level.tscn"  # Placeholder
	_current_entrance = "sewer"
	InteractionPrompt.show_prompt("Enter Sewer")


func _on_sewer_trigger_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_players_in_sewer_zone.erase(body)
	if _players_in_door_zone.is_empty() and _players_in_sewer_zone.is_empty():
		InteractionPrompt.hide_prompt()


func player_zoom_in(x: float, y: float, time: float) -> void:
	if _player == null:
		return
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	var camera := _player.get_node_or_null("Camera2D")
	if camera:
		tween.tween_property(camera, "zoom", Vector2(x, y), time)
