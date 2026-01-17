extends LevelParent

var health_item_scene: PackedScene = preload("res://scenes/container/item.tscn")

# Transition zone state tracking
var _players_in_door_zone: Array[Node2D] = []
var _current_target_scene := ""
var _current_entrance := ""


func _ready() -> void:
	super._ready()
	# Reposition players based on which entrance they came from
	_position_players_at_entrance()
	
	for container in get_tree().get_nodes_in_group("container"):
		container.connect("reveal_content", _on_container_opened)
	
	# Connect door trigger signal programmatically
	var door_trigger := get_node_or_null("doorTrigger")
	if door_trigger:
		door_trigger.body_entered.connect(_on_door_trigger_body_entered)
		door_trigger.body_exited.connect(_on_door_trigger_body_exited)


func _position_players_at_entrance() -> void:
	var spawn_pos := Vector2.ZERO
	
	match Globals.spawn_entrance:
		"door":
			# Came from first_room through door - spawn near door trigger
			var door_trigger := get_node_or_null("doorTrigger/CollisionShape2D")
			if door_trigger:
				spawn_pos = door_trigger.global_position + Vector2(40, -100)
		_:
			# Default spawn - use original position
			return
	
	# Move players to spawn position
	if spawn_pos != Vector2.ZERO:
		if _player:
			_player.global_position = spawn_pos
		if _player_two:
			_player_two.global_position = spawn_pos + Vector2(50, 0)


func _on_container_opened(pos):
	var health_item = health_item_scene.instantiate() as StaticBody2D
	health_item.position = pos
	print('health item created ===== ', health_item)
	$Items.call_deferred("add_child", health_item)


func _process(_delta: float) -> void:
	if _players_in_door_zone.is_empty():
		return
	
	# Check both players' input in co-op, or use raw Input as fallback
	var should_transition := false
	
	# Check each player in the zone
	for player in _players_in_door_zone:
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
	InteractionPrompt.hide_prompt()
	
	# Set spawn entrance for next scene
	Globals.spawn_entrance = _current_entrance
	
	if _player:
		var tween := create_tween()
		tween.tween_property(_player, "speed", 0, 0.5)
	
	TransitionLayer.change_scene(_current_target_scene)


func _on_door_trigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if body not in _players_in_door_zone:
		_players_in_door_zone.append(body)
	_current_target_scene = "res://scenes/levels/first_room_updated.tscn"
	_current_entrance = "door"
	InteractionPrompt.show_prompt("Enter")


func _on_door_trigger_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_players_in_door_zone.erase(body)
	if _players_in_door_zone.is_empty():
		InteractionPrompt.hide_prompt()
