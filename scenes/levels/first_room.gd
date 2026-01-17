extends StaticBody2D

var health_item_scene:PackedScene = preload("res://scenes/container/item.tscn")
var walls:bool = true


func _ready() -> void:
	print('level ready player one')
	for container in get_tree().get_nodes_in_group("container"):
		container.connect("reveal_content", _on_container_opened)


func _on_container_opened(pos):
	var health_item = health_item_scene.instantiate() as StaticBody2D
	health_item.position = pos
	print('health item created ===== ', health_item)
	$firstRoomItems.call_deferred("add_child", health_item)
