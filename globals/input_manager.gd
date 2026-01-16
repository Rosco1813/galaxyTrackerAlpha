extends Node

# Input schemes
enum InputScheme { SINGLE_PLAYER, COOP_TWO_CONTROLLERS, COOP_CONTROLLER_KEYBOARD, COOP_SPLIT_KEYBOARD }

var current_scheme := InputScheme.SINGLE_PLAYER

# Movement vectors per player
var _movement := { 1: Vector2.ZERO, 2: Vector2.ZERO }

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
	"shoot": KEY_F,
	"aim": KEY_G,
	"select_stuff": KEY_SPACE,
	"switch_weapon": KEY_Q,
	"grenade": KEY_E,
	"reload": KEY_R,
	"roll": KEY_SHIFT,
}

const SPLIT_KB_P2_KEYS := {
	"left": KEY_LEFT,
	"right": KEY_RIGHT,
	"up": KEY_UP,
	"down": KEY_DOWN,
	"shoot": KEY_KP_1,
	"aim": KEY_KP_2,
	"select_stuff": KEY_KP_0,
	"switch_weapon": KEY_KP_4,
	"grenade": KEY_KP_5,
	"reload": KEY_KP_3,
	"roll": KEY_KP_ENTER,
}

# Controller actions to track (only actions that exist in InputMap)
const CONTROLLER_ACTIONS := ["shoot", "aim", "switch_weapon", "grenade", "reload", "select_stuff", "roll"]

# Track which actions are being held (for _just_pressed detection)
var _prev_action_pressed := { 1: {}, 2: {} }


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


func _process_single_player_input(event: InputEvent) -> void:
	# All input goes to player 1
	_movement[1] = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_update_action_states_from_input(1)


func _process_coop_controller_keyboard_input(event: InputEvent) -> void:
	# Player 1: Controller (device 0+)
	# Player 2: Keyboard (device -1 or non-joypad)
	
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		# Controller input -> Player 1
		_movement[1] = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		_update_controller_action_states(1, event)
	else:
		# Keyboard input -> Player 2
		_movement[2] = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		_update_action_states_from_input(2)


func _process_coop_two_controllers_input(event: InputEvent) -> void:
	# Player 1: Controller device 0
	# Player 2: Controller device 1
	
	if event is InputEventJoypadMotion or event is InputEventJoypadButton:
		var device: int = event.device
		if device == 0:
			# First controller -> Player 1
			_movement[1] = _get_controller_movement(0)
			_update_controller_action_states(1, event)
		elif device == 1:
			# Second controller -> Player 2
			_movement[2] = _get_controller_movement(1)
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
			var was_pressed: bool = _action_pressed[player_id].get(action_name, false)
			_action_pressed[player_id][action_name] = pressed
			if pressed and not was_pressed:
				_action_just_pressed[player_id][action_name] = true
			elif not pressed and was_pressed:
				_action_just_released[player_id][action_name] = true


func _update_action_states_from_input(player_id: int) -> void:
	for action in CONTROLLER_ACTIONS:
		var is_pressed := Input.is_action_pressed(action)
		var was_pressed: bool = _action_pressed[player_id].get(action, false)
		_action_pressed[player_id][action] = is_pressed
		if is_pressed and not was_pressed:
			_action_just_pressed[player_id][action] = true
		elif not is_pressed and was_pressed:
			_action_just_released[player_id][action] = true


func _update_controller_action_states(player_id: int, event: InputEvent) -> void:
	for action in CONTROLLER_ACTIONS:
		if event.is_action(action):
			var is_pressed := event.is_pressed()
			var was_pressed: bool = _action_pressed[player_id].get(action, false)
			_action_pressed[player_id][action] = is_pressed
			if is_pressed and not was_pressed:
				_action_just_pressed[player_id][action] = true
			elif not is_pressed and was_pressed:
				_action_just_released[player_id][action] = true


# Public API for players to query their input
func get_movement(player_id: int) -> Vector2:
	if current_scheme == InputScheme.SINGLE_PLAYER:
		return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return _movement.get(player_id, Vector2.ZERO)


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
