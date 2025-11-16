extends Control

const MAIN_SCENE_PATH := "res://scenes/levels/first_room_updated.tscn"
const START_BUTTON_INDEX := 0
var _starting := false

func _ready() -> void:
	set_process_unhandled_input(true)
	TransitionLayer.play_music()

func _unhandled_input(event: InputEvent) -> void:
	if _starting:
		return
	if _is_start_event(event):
		_start_game()

func _is_start_event(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return event.physical_keycode == Key.KEY_ENTER or event.physical_keycode == Key.KEY_KP_ENTER
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == START_BUTTON_INDEX
	return false

func _start_game() -> void:
	_starting = true
	TransitionLayer.change_scene(MAIN_SCENE_PATH)
