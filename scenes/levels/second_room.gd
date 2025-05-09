extends LevelParent

#var first_room: PackedScene = preload("res://scenes/levels/first_room_updated.tscn")
@export var first_room:PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_door_trigger_body_entered(_body: Node2D) -> void:
	var tween = create_tween()
	tween.tween_property($Player1, "speed", 0, 0.5)
	get_tree().change_scene_to_packed(first_room)
