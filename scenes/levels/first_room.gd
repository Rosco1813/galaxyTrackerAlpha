extends StaticBody2D

signal player_entered_door
signal player_exit_door
signal sewer_entrance
signal sewer_exit

var health_item_scene:PackedScene = preload("res://scenes/container/item.tscn")
var walls:bool = true

func  _ready() -> void:
	print('level ready player one')
	for container in get_tree().get_nodes_in_group("container"):
		container.connect("reveal_content", _on_container_opened)
#		print('level : container : ', container.name)


func _on_container_opened(pos):
	var health_item = health_item_scene.instantiate() as StaticBody2D
	health_item.position = pos
	print('health item created ===== ', health_item)
#	$"../Items".add_child(health_item)
#	$firstRoomItems.add_child(health_item)
	$firstRoomItems.call_deferred("add_child", health_item)

func _on_door_trigger_body_entered(_body: Node2D) -> void:

	player_entered_door.emit()

func _on_door_trigger_body_exited(_body: Node2D) -> void:
	player_exit_door.emit()

func _on_sewer_trigger_body_entered(_body: Node2D) -> void:
	sewer_entrance.emit()

func _on_sewer_trigger_body_exited(_body: Node2D) -> void:
	sewer_exit.emit()
