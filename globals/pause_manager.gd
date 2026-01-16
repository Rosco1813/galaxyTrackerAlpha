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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_setup_friendly_fire_button()
	_menu_buttons = [resume_button]
	if friendly_fire_button:
		_menu_buttons.append(friendly_fire_button)
	_menu_buttons.append(return_button)
	for button in _menu_buttons:
		_prepare_menu_button(button)
	resume_button.pressed.connect(_on_resume_pressed)
	return_button.pressed.connect(_on_return_to_menu_pressed)
	hide_pause_overlay()


func _setup_friendly_fire_button() -> void:
	# Create friendly fire toggle button
	friendly_fire_button = Button.new()
	friendly_fire_button.name = "FriendlyFireButton"
	_update_friendly_fire_button_text()
	friendly_fire_button.pressed.connect(_on_friendly_fire_pressed)
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
	if Input.is_action_just_pressed("pause"):
		if not _should_allow_pause():
			Input.action_release("pause")
			return
		toggle_pause()
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

func _handle_menu_navigation() -> void:
	if _menu_buttons.is_empty():
		return
	if Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("down"):
		_focus_next_button(1)
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("up"):
		_focus_next_button(-1)
	if Input.is_action_just_pressed("select_stuff") or Input.is_action_just_pressed("ui_accept"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and focused in _menu_buttons:
			focused.emit_signal("pressed")

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
