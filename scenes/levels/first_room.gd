extends StaticBody2D

signal player_entered_door
signal player_exit_door
signal sewer_entrance
signal sewer_exit
var walls:bool = true


func _on_door_trigger_body_entered(_body: Node2D) -> void:

	player_entered_door.emit()

func _on_door_trigger_body_exited(_body: Node2D) -> void:
	player_exit_door.emit()

func _on_sewer_trigger_body_entered(_body: Node2D) -> void:
	sewer_entrance.emit()

func _on_sewer_trigger_body_exited(_body: Node2D) -> void:
	sewer_exit.emit()
