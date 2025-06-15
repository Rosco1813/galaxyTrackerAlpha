extends ItemContainer

var box_health = 20
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func hit():
	box_health -=10
	if box_health == 0:
#		var pos = $spawnPositions.get_child(randi()%$spawnPositions.get_child_count()).global_position
		var pos = $".".global_position
		print('pos ===== ', pos)
		reveal_content.emit(pos)
#		var containers = get_tree().get_nodes_in_group("container")
#		print('== Containers ==', containers)
		queue_free()
#		$Sprite2D.hide()
#	print('box')
