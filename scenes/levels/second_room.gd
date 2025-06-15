extends LevelParent


var health_item_scene:PackedScene = preload("res://scenes/container/item.tscn")
#var first_room: PackedScene = preload("res://scenes/levels/first_room_updated.tscn")
#@export var first_room:PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for container in get_tree().get_nodes_in_group("container"):
		container.connect("reveal_content", _on_container_opened)

func _on_container_opened(pos):
	var health_item = health_item_scene.instantiate() as StaticBody2D
	health_item.position = pos
	print('health item created ===== ', health_item)
#	$"../Items".add_child(health_item)
#	$firstRoomItems.add_child(health_item)
	$Items.call_deferred("add_child", health_item)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_door_trigger_body_entered(_body: Node2D) -> void:
	var tween = create_tween()
	tween.tween_property($Player1, "speed", 0, 0.5)
#	get_tree().change_scene_to_packed(first_room)
	TransitionLayer.change_scene("res://scenes/levels/first_room_updated.tscn")
