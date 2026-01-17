extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var menu_container: VBoxContainer = $CenterContainer/PauseMenu
@onready var pause_label: Label = $CenterContainer/PauseMenu/Label
@onready var resume_button: Button = $CenterContainer/PauseMenu/ResumeButton
@onready var friendly_fire_button: Button = null
@onready var return_button: Button = $CenterContainer/PauseMenu/ReturnToMenuButton

var is_paused := false
var _menu_buttons: Array[Button] = []
const MENU_HIGHLIGHT_COLOR := Color(0.95, 0.85, 0.2, 1.0)
var _menu_player_id: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	resume_button.pressed.connect(_on_resume_pressed)
	return_button.pressed.connect(_on_return_to_menu_pressed)
	_prepare_menu_button(resume_button)
	_prepare_menu_button(return_button)
	hide_pause_overlay()


func _setup_friendly_fire_button() -> void:
	# Only show friendly fire toggle in co-op mode
	if not Globals.coop_enabled:
		# Remove button if it exists and co-op is disabled
		if friendly_fire_button and is_instance_valid(friendly_fire_button):
			friendly_fire_button.queue_free()
			friendly_fire_button = null
		return
	
	# Already exists
	if friendly_fire_button and is_instance_valid(friendly_fire_button):
		_update_friendly_fire_button_text()
		return
	
	# Create friendly fire toggle button
	friendly_fire_button = Button.new()
	friendly_fire_button.name = "FriendlyFireButton"
	friendly_fire_button.focus_mode = Control.FOCUS_ALL
	_update_friendly_fire_button_text()
	friendly_fire_button.pressed.connect(_on_friendly_fire_pressed)
	_prepare_menu_button(friendly_fire_button)
	# Insert between resume and return buttons
	menu_container.add_child(friendly_fire_button)
	menu_container.move_child(friendly_fire_button, resume_button.get_index() + 1)


func _update_friendly_fire_button_text() -> void:
	if friendly_fire_button:
		var status := "ON" if Globals.friendly_fire_enabled else "OFF"
		friendly_fire_button.text = "Friendly Fire: %s" % status


func _on_friendly_fire_pressed() -> void:
	Globals.friendly_fire_enabled = not Globals.friendly_fire_enabled
	_update_friendly_fire_button_text()

func _process(_delta: float) -> void:
	# Check for pause toggle using raw Input (more reliable timing)
	if Input.is_action_just_pressed("pause"):
		if not _should_allow_pause():
			return
		# Determine which player pressed pause for menu control
		_menu_player_id = _get_pause_pressing_player()
		if _menu_player_id == -1:
			_menu_player_id = 1  # Default to player 1
		toggle_pause()
		return
	if is_paused:
		_handle_menu_navigation()

func toggle_pause() -> void:
	if is_paused:
		_resume_game()
	else:
		_pause_game()

func _pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	show_pause_overlay()

func _resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	hide_pause_overlay()
	Input.action_release("pause")

func show_pause_overlay() -> void:
	# Setup friendly fire button based on current co-op status
	_setup_friendly_fire_button()
	# Rebuild menu buttons array
	_menu_buttons = [resume_button]
	if friendly_fire_button and is_instance_valid(friendly_fire_button):
		_menu_buttons.append(friendly_fire_button)
	_menu_buttons.append(return_button)
	
	overlay.visible = true
	menu_container.visible = true
	if resume_button:
		resume_button.grab_focus()

func hide_pause_overlay() -> void:
	overlay.visible = false
	menu_container.visible = false
	if get_viewport().gui_get_focus_owner() in _menu_buttons:
		get_viewport().gui_get_focus_owner().release_focus()

func _on_return_to_menu_pressed() -> void:
	if not is_paused:
		return
	_resume_game()
	TransitionLayer.change_scene("res://scenes/menu/start_menu.tscn")

func _on_resume_pressed() -> void:
	if is_paused:
		_resume_game()

func _prepare_menu_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_color_override("font_color_focus", MENU_HIGHLIGHT_COLOR)
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	focus_style.border_color = MENU_HIGHLIGHT_COLOR
	focus_style.set_border_width_all(2)
	focus_style.set_corner_radius_all(6)
	focus_style.set_expand_margin_all(4)
	button.add_theme_stylebox_override("focus", focus_style)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.12, 0.12, 0.12, 0.8)
	hover_style.set_corner_radius_all(6)
	hover_style.set_expand_margin_all(4)
	button.add_theme_stylebox_override("hover", hover_style)

var _prev_dpad_state: Dictionary = {}  # Track per-device d-pad state {device: {up: bool, down: bool}}

func _handle_menu_navigation() -> void:
	if _menu_buttons.is_empty():
		return
	
	var nav_down := false
	var nav_up := false
	
	# Keyboard navigation (W/S, Up/Down arrows)
	if Input.is_key_pressed(KEY_DOWN) and not _prev_dpad_state.get("kb_down", false):
		nav_down = true
	if Input.is_key_pressed(KEY_UP) and not _prev_dpad_state.get("kb_up", false):
		nav_up = true
	if Input.is_key_pressed(KEY_S) and not _prev_dpad_state.get("kb_s", false):
		nav_down = true
	if Input.is_key_pressed(KEY_W) and not _prev_dpad_state.get("kb_w", false):
		nav_up = true
	_prev_dpad_state["kb_down"] = Input.is_key_pressed(KEY_DOWN)
	_prev_dpad_state["kb_up"] = Input.is_key_pressed(KEY_UP)
	_prev_dpad_state["kb_s"] = Input.is_key_pressed(KEY_S)
	_prev_dpad_state["kb_w"] = Input.is_key_pressed(KEY_W)
	
	# Controller navigation: d-pad and stick, per device
	for device in Input.get_connected_joypads():
		if not _prev_dpad_state.has(device):
			_prev_dpad_state[device] = {"up": false, "down": false, "stick_y": 0.0, "confirm": false}
		var prev: Dictionary = _prev_dpad_state[device]
		var dpad_down_now := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)
		var dpad_up_now := Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP)
		if dpad_down_now and not prev["down"]:
			nav_down = true
		if dpad_up_now and not prev["up"]:
			nav_up = true
		_prev_dpad_state[device]["down"] = dpad_down_now
		_prev_dpad_state[device]["up"] = dpad_up_now
		var axis_y := Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		var prev_stick: float = prev["stick_y"]
		if axis_y > 0.5 and prev_stick <= 0.5:
			nav_down = true
		elif axis_y < -0.5 and prev_stick >= -0.5:
			nav_up = true
		_prev_dpad_state[device]["stick_y"] = axis_y
	
	if nav_down:
		_focus_next_button(1)
	elif nav_up:
		_focus_next_button(-1)
	
	# Confirm/back
	var confirm := false
	if Input.is_action_just_pressed("ui_accept"):
		confirm = true
	if Input.is_key_pressed(KEY_SPACE) and not _prev_dpad_state.get("kb_space", false):
		confirm = true
	_prev_dpad_state["kb_space"] = Input.is_key_pressed(KEY_SPACE)
	for device in Input.get_connected_joypads():
		if not _prev_dpad_state.has(device):
			_prev_dpad_state[device] = {"up": false, "down": false, "stick_y": 0.0, "confirm": false}
		if Input.is_joy_button_pressed(device, JOY_BUTTON_A):
			if not _prev_dpad_state[device].get("confirm", false):
				confirm = true
			_prev_dpad_state[device]["confirm"] = true
		else:
			_prev_dpad_state[device]["confirm"] = false
	if confirm:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and focused in _menu_buttons:
			focused.emit_signal("pressed")
	if Input.is_action_just_pressed("back"):
		_resume_game()


func _get_pause_pressing_player() -> int:
	var players := [1, 2] if Globals.coop_enabled else [1]
	for player_id in players:
		if InputManager.is_menu_pause_just_pressed(player_id) or InputManager.is_menu_back_just_pressed(player_id):
			return player_id
	return -1

func _focus_next_button(direction: int) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	var index := _menu_buttons.find(focused)
	if index == -1:
		index = 0
	else:
		index = clamp(index + direction, 0, _menu_buttons.size() - 1)
	_menu_buttons[index].grab_focus()

func _should_allow_pause() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	var scene_path := current_scene.scene_file_path
	if scene_path == "res://scenes/menu/start_menu.tscn":
		return false
	return true
