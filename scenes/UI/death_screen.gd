extends CanvasLayer

const MENU_HIGHLIGHT_COLOR := Color(0.95, 0.85, 0.2, 1.0)

@onready var overlay: ColorRect = $Overlay
@onready var menu_container: VBoxContainer = $CenterContainer/MenuContainer
@onready var restart_button: Button = $CenterContainer/MenuContainer/RestartButton
@onready var menu_button: Button = $CenterContainer/MenuContainer/MenuButton

var current_level_path: String = ""
var buttons: Array[Button] = []
var current_button_index := 0

func _ready() -> void:
	# Store current level for restart
	current_level_path = get_tree().current_scene.scene_file_path
	
	# Pause the game
	get_tree().paused = true
	
	# Setup buttons
	buttons = [restart_button, menu_button]
	for button in buttons:
		_prepare_menu_button(button)
	
	# Connect button signals
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Start with overlay transparent, then fade in
	overlay.modulate = Color(1, 1, 1, 0)
	menu_container.modulate = Color(1, 1, 1, 0)
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 1), 1.0)
	tween.tween_property(menu_container, "modulate", Color(1, 1, 1, 1), 0.5)
	
	# Focus first button after fade
	await tween.finished
	buttons[0].grab_focus()


func _process(_delta: float) -> void:
	_handle_menu_navigation()


func _handle_menu_navigation() -> void:
	if Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("down"):
		_focus_next_button(1)
	elif Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("up"):
		_focus_next_button(-1)
	if Input.is_action_just_pressed("select_stuff") or Input.is_action_just_pressed("ui_accept"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.emit_signal("pressed")


func _focus_next_button(direction: int) -> void:
	current_button_index = wrapi(current_button_index + direction, 0, buttons.size())
	buttons[current_button_index].grab_focus()


func _prepare_menu_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_color_override("font_color_focus", MENU_HIGHLIGHT_COLOR)
	
	# Focus style
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	focus_style.border_color = MENU_HIGHLIGHT_COLOR
	focus_style.set_border_width_all(2)
	focus_style.set_corner_radius_all(6)
	focus_style.set_expand_margin_all(4)
	button.add_theme_stylebox_override("focus", focus_style)
	
	# Hover style
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.12, 0.12, 0.12, 0.8)
	hover_style.set_corner_radius_all(6)
	hover_style.set_expand_margin_all(4)
	button.add_theme_stylebox_override("hover", hover_style)


func _on_restart_pressed() -> void:
	# Keep game paused - TransitionLayer will unpause after fade completes
	Globals.reset_all_player_stats()  # Reset health, stamina, ammo for both players
	TransitionLayer.change_scene(current_level_path)
	queue_free()


func _on_menu_pressed() -> void:
	# Keep game paused - TransitionLayer will unpause after fade completes
	Globals.reset_all_player_stats()  # Reset health, stamina, ammo for both players
	TransitionLayer.change_scene("res://scenes/menu/start_menu.tscn")
	queue_free()
