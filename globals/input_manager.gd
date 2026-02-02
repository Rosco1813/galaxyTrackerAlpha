extends Node

# Input schemes
enum InputScheme { SINGLE_PLAYER, COOP_TWO_CONTROLLERS, COOP_CONTROLLER_KEYBOARD, COOP_SPLIT_KEYBOARD }

# Controller types for icon display
enum ControllerType { KEYBOARD, PLAYSTATION, XBOX, GENERIC }

var current_scheme := InputScheme.SINGLE_PLAYER

# Movement vectors per player
var _movement := { 1: Vector2.ZERO, 2: Vector2.ZERO }

# Facing direction vectors per player (right stick)
var _facing := { 1: Vector2.ZERO, 2: Vector2.ZERO }

# Action states per player (for actions that need press tracking)
var _action_pressed := { 1: {}, 2: {} }
var _action_just_pressed := { 1: {}, 2: {} }
var _action_just_released := { 1: {}, 2: {} }

# Split keyboard mappings (P1 = WASD, P2 = Arrows)
const SPLIT_KB_P1_KEYS := {
	"left": KEY_A,
	"right": KEY_D,
	"up": KEY_W,
	"down": KEY_S,
	"ui_left": KEY_A,
	"ui_right": KEY_D,
	"ui_up": KEY_W,
	"ui_down": KEY_S,
	"shoot": KEY_F,
	"aim": KEY_G,
	"select_stuff": KEY_SPACE,
	"ui_accept": KEY_SPACE,
	"switch_weapon": KEY_Q,
	"grenade": KEY_E,
	"reload": KEY_R,
	"roll": KEY_SHIFT,
	"pause": KEY_P,
	"back": KEY_ESCAPE,
}

const SPLIT_KB_P2_KEYS := {
	"left": KEY_LEFT,
	"right": KEY_RIGHT,
	"up": KEY_UP,
	"down": KEY_DOWN,
	"ui_left": KEY_LEFT,
	"ui_right": KEY_RIGHT,
	"ui_up": KEY_UP,
	"ui_down": KEY_DOWN,
	"shoot": KEY_KP_1,
	"aim": KEY_KP_2,
	"select_stuff": KEY_KP_0,
	"ui_accept": KEY_KP_0,
	"switch_weapon": KEY_KP_4,
	"grenade": KEY_KP_5,
	"reload": KEY_KP_3,
	"roll": KEY_KP_ENTER,
	"pause": KEY_P,
	"back": KEY_ESCAPE,
}

# Actions to track (gameplay + menu)
const TRACKED_ACTIONS := [
	"shoot", "aim", "switch_weapon", "grenade", "reload", "select_stuff", "roll",
	"ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "pause", "back"
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	# Clear just_pressed/just_released at end of frame
	for player_id in [1, 2]:
		_action_just_pressed[player_id].clear()
		_action_just_released[player_id].clear()


func _input(event: InputEvent) -> void:
	match current_scheme:
		InputScheme.SINGLE_PLAYER:
			_process_single_player_input(event)
		InputScheme.COOP_TWO_CONTROLLERS:
			_process_coop_two_controllers_input(event)
		InputScheme.COOP_CONTROLLER_KEYBOARD:
			_process_coop_controller_keyboard_input(event)
		InputScheme.COOP_SPLIT_KEYBOARD:
			_process_coop_split_keyboard_input(event)


func _process_single_player_input(_event: InputEvent) -> void:
	# All input goes to player 1
	_movement[1] = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_facing[1] = Input.get_vector("face_left", "face_right", "face_up", "face_down")
	_update_action_states_from_input(1)


func _process_coop_controller_keyboard_input(event: InputEvent) -> void:
	# Player 1: Controller (device 0+)
	# Player 2: Keyboard (device -1 or non-joypad)
	
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		# Controller input -> Player 1
		_movement[1] = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		_facing[1] = _get_controller_facing(0)
		_update_controller_action_states(1, event)
	else:
		# Keyboard input -> Player 2 (no right stick, facing defaults to movement)
		_movement[2] = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		_facing[2] = Vector2.ZERO
		_update_action_states_from_input(2)


func _process_coop_two_controllers_input(event: InputEvent) -> void:
	# Player 1: Controller device 0
	# Player 2: Controller device 1
	
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		var device: int = event.device
		if device == 0:
			# First controller -> Player 1
			_movement[1] = _get_controller_movement(0)
			_facing[1] = _get_controller_facing(0)
			_update_controller_action_states(1, event)
		elif device == 1:
			# Second controller -> Player 2
			_movement[2] = _get_controller_movement(1)
			_facing[2] = _get_controller_facing(1)
			_update_controller_action_states(2, event)


func _get_controller_movement(device: int) -> Vector2:
	# Get movement vector for a specific controller device
	var left_x := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	var left_y := Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
	var movement := Vector2(left_x, left_y)
	
	# Also check d-pad
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT):
		movement.x = -1.0
	elif Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT):
		movement.x = 1.0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP):
		movement.y = -1.0
	elif Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN):
		movement.y = 1.0
	
	# Apply deadzone
	if movement.length() < 0.2:
		return Vector2.ZERO
	return movement.normalized() if movement.length() > 1.0 else movement


func _get_controller_facing(device: int) -> Vector2:
	# Get facing direction from right stick for a specific controller device
	var right_x := Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)
	var right_y := Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
	var facing := Vector2(right_x, right_y)
	
	# Apply deadzone
	if facing.length() < 0.2:
		return Vector2.ZERO
	return facing.normalized() if facing.length() > 1.0 else facing


func _process_coop_split_keyboard_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var keycode := key_event.physical_keycode
		
		# Check Player 1 keys (WASD)
		_update_split_kb_movement(1, SPLIT_KB_P1_KEYS, keycode, key_event.pressed)
		_update_split_kb_actions(1, SPLIT_KB_P1_KEYS, keycode, key_event.pressed)
		
		# Check Player 2 keys (Arrows + Numpad)
		_update_split_kb_movement(2, SPLIT_KB_P2_KEYS, keycode, key_event.pressed)
		_update_split_kb_actions(2, SPLIT_KB_P2_KEYS, keycode, key_event.pressed)


func _update_split_kb_movement(player_id: int, key_map: Dictionary, keycode: int, pressed: bool) -> void:
	var movement: Vector2 = _movement[player_id]
	
	if keycode == key_map["left"]:
		movement.x = -1.0 if pressed else (1.0 if Input.is_key_pressed(key_map["right"]) else 0.0)
	elif keycode == key_map["right"]:
		movement.x = 1.0 if pressed else (-1.0 if Input.is_key_pressed(key_map["left"]) else 0.0)
	elif keycode == key_map["up"]:
		movement.y = -1.0 if pressed else (1.0 if Input.is_key_pressed(key_map["down"]) else 0.0)
	elif keycode == key_map["down"]:
		movement.y = 1.0 if pressed else (-1.0 if Input.is_key_pressed(key_map["up"]) else 0.0)
	
	_movement[player_id] = movement.normalized() if movement.length() > 1.0 else movement


func _update_split_kb_actions(player_id: int, key_map: Dictionary, keycode: int, pressed: bool) -> void:
	for action_name in key_map.keys():
		if action_name in ["left", "right", "up", "down"]:
			continue
		if keycode == key_map[action_name]:
			_record_action_state(player_id, action_name, pressed)


func _update_action_states_from_input(player_id: int) -> void:
	for action in TRACKED_ACTIONS:
		var is_pressed := Input.is_action_pressed(action)
		_record_action_state(player_id, action, is_pressed)


func _update_controller_action_states(player_id: int, event: InputEvent) -> void:
	for action in TRACKED_ACTIONS:
		if event.is_action(action):
			_record_action_state(player_id, action, event.is_pressed())


func _record_action_state(player_id: int, action_name: String, is_pressed: bool) -> void:
	var was_pressed: bool = _action_pressed[player_id].get(action_name, false)
	_action_pressed[player_id][action_name] = is_pressed
	if is_pressed and not was_pressed:
		_action_just_pressed[player_id][action_name] = true
	elif not is_pressed and was_pressed:
		_action_just_released[player_id][action_name] = true


# Public API for players to query their input
func get_movement(player_id: int) -> Vector2:
	if current_scheme == InputScheme.SINGLE_PLAYER:
		return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return _movement.get(player_id, Vector2.ZERO)


func get_facing(player_id: int) -> Vector2:
	# Get facing direction from right stick (or face_ actions)
	if current_scheme == InputScheme.SINGLE_PLAYER:
		# Try face_ actions first, then fall back to controller right stick
		var facing := Input.get_vector("face_left", "face_right", "face_up", "face_down")
		if facing.length() < 0.2:
			# Try reading right stick directly for single player controller
			facing = _get_controller_facing(0)
		return facing
	return _facing.get(player_id, Vector2.ZERO)


func is_action_pressed(player_id: int, action: String) -> bool:
	if current_scheme == InputScheme.SINGLE_PLAYER and player_id == 1:
		return Input.is_action_pressed(action)
	return _action_pressed[player_id].get(action, false)


func is_action_just_pressed(player_id: int, action: String) -> bool:
	if current_scheme == InputScheme.SINGLE_PLAYER and player_id == 1:
		return Input.is_action_just_pressed(action)
	return _action_just_pressed[player_id].get(action, false)


func is_action_just_released(player_id: int, action: String) -> bool:
	if current_scheme == InputScheme.SINGLE_PLAYER and player_id == 1:
		return Input.is_action_just_released(action)
	return _action_just_released[player_id].get(action, false)


# Menu helpers
func get_menu_nav(player_id: int) -> Vector2:
	var nav := Vector2.ZERO
	if is_action_just_pressed(player_id, "ui_left"):
		nav.x = -1
	elif is_action_just_pressed(player_id, "ui_right"):
		nav.x = 1
	if is_action_just_pressed(player_id, "ui_up"):
		nav.y = -1
	elif is_action_just_pressed(player_id, "ui_down"):
		nav.y = 1
	return nav


func is_menu_confirm_just_pressed(player_id: int) -> bool:
	return is_action_just_pressed(player_id, "select_stuff") or is_action_just_pressed(player_id, "ui_accept")


func is_menu_pause_just_pressed(player_id: int) -> bool:
	return is_action_just_pressed(player_id, "pause")


func is_menu_back_just_pressed(player_id: int) -> bool:
	return is_action_just_pressed(player_id, "back")


# Auto-detect if a controller is connected
func has_controller() -> bool:
	return Input.get_connected_joypads().size() > 0


func has_two_controllers() -> bool:
	return Input.get_connected_joypads().size() >= 2


# Set scheme based on co-op mode and controller availability
func configure_for_coop(enabled: bool) -> void:
	if not enabled:
		current_scheme = InputScheme.SINGLE_PLAYER
	elif has_two_controllers():
		current_scheme = InputScheme.COOP_TWO_CONTROLLERS
	elif has_controller():
		current_scheme = InputScheme.COOP_CONTROLLER_KEYBOARD
	else:
		current_scheme = InputScheme.COOP_SPLIT_KEYBOARD


func get_scheme_description() -> String:
	match current_scheme:
		InputScheme.SINGLE_PLAYER:
			return "Single Player"
		InputScheme.COOP_TWO_CONTROLLERS:
			return "P1: Controller 1 | P2: Controller 2"
		InputScheme.COOP_CONTROLLER_KEYBOARD:
			return "P1: Controller | P2: Keyboard"
		InputScheme.COOP_SPLIT_KEYBOARD:
			return "P1: WASD | P2: Arrow Keys + Numpad"
	return ""


## Returns the controller type for the given device (for displaying appropriate button icons)
func get_controller_type(device_id: int = 0) -> ControllerType:
	var joypads := Input.get_connected_joypads()
	if joypads.is_empty():
		return ControllerType.KEYBOARD
	
	# Use first connected joypad if device_id not found
	var actual_device := device_id if device_id in joypads else joypads[0]
	var joy_name := Input.get_joy_name(actual_device).to_lower()
	
	if "playstation" in joy_name or "dualshock" in joy_name or "dualsense" in joy_name or "ps4" in joy_name or "ps5" in joy_name:
		return ControllerType.PLAYSTATION
	elif "xbox" in joy_name or "xinput" in joy_name:
		return ControllerType.XBOX
	elif joy_name != "":
		return ControllerType.GENERIC
	
	return ControllerType.KEYBOARD
