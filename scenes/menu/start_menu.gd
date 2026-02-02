extends Control

const MAIN_SCENE_PATH := "res://scenes/levels/first_room_updated.tscn"
const START_BUTTON_INDEX := 0
const PREVIEW_SIZE := Vector2(128, 128)
const CARD_SCENE := preload("res://scenes/menu/components/character_card.tscn")
const MENU_HIGHLIGHT_COLOR := Color(0.95, 0.85, 0.2, 1.0)
const P1_HIGHLIGHT_COLOR := Color(0.2, 0.6, 1.0, 0.8)  # Blue for P1
const P2_HIGHLIGHT_COLOR := Color(1.0, 0.3, 0.3, 0.8)  # Red for P2

var _starting := false
var _cards: Dictionary = {}
var _card_order: Array[String] = []

# Mode selection
var _mode_selected := false
var _mode_buttons: Array[Button] = []
var _current_mode_index := 0

# Co-op character selection
var _p1_selection_index := 0
var _p2_selection_index := 1
var _p1_confirmed := false
var _p2_confirmed := false

func _ready() -> void:
	set_process_unhandled_input(true)
	TransitionLayer.play_music()
	_setup_mode_selection()
	_setup_character_cards()
	_update_prompt_label()
	_hide_character_cards()


func _setup_mode_selection() -> void:
	var mode_container := get_node_or_null("CenterContainer/VBoxContainer/ModeContainer")
	if mode_container == null:
		# Create mode container if it doesn't exist
		var vbox := get_node("CenterContainer/VBoxContainer")
		mode_container = HBoxContainer.new()
		mode_container.name = "ModeContainer"
		mode_container.alignment = BoxContainer.ALIGNMENT_CENTER
		mode_container.set("theme_override_constants/separation", 40)
		
		var single_btn := Button.new()
		single_btn.name = "SinglePlayerButton"
		single_btn.text = "Single Player"
		single_btn.custom_minimum_size = Vector2(200, 50)
		_prepare_menu_button(single_btn)
		single_btn.pressed.connect(_on_single_player_pressed)
		mode_container.add_child(single_btn)
		
		var coop_btn := Button.new()
		coop_btn.name = "CoopButton"
		coop_btn.text = "Co-op"
		coop_btn.custom_minimum_size = Vector2(200, 50)
		_prepare_menu_button(coop_btn)
		coop_btn.pressed.connect(_on_coop_pressed)
		mode_container.add_child(coop_btn)
		
		# Insert after subtitle
		var subtitle := vbox.get_node("SubtitleLabel")
		var idx := subtitle.get_index() + 1
		vbox.add_child(mode_container)
		vbox.move_child(mode_container, idx)
		
		_mode_buttons = [single_btn, coop_btn]
		single_btn.grab_focus()


func _prepare_menu_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_color_override("font_color_focus", MENU_HIGHLIGHT_COLOR)
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	focus_style.border_color = MENU_HIGHLIGHT_COLOR
	focus_style.set_border_width_all(2)
	focus_style.set_corner_radius_all(6)
	focus_style.set_expand_margin_all(4)
	button.add_theme_stylebox_override("focus", focus_style)


func _on_single_player_pressed() -> void:
	Globals.coop_enabled = false
	InputManager.configure_for_coop(false)
	_mode_selected = true
	
	# Hide mode buttons
	_hide_mode_buttons()
	
	# Single player: Auto-select Trinity (female_player_1) and start game immediately
	Globals.selected_player_id = "female_player_1"
	Globals.selected_players[1] = "female_player_1"
	_start_game()


func _on_coop_pressed() -> void:
	Globals.coop_enabled = true
	InputManager.configure_for_coop(true)
	_mode_selected = true
	_p1_confirmed = false
	_p2_confirmed = false
	_p1_selection_index = 0
	_p2_selection_index = min(1, _card_order.size() - 1)
	
	# Hide mode buttons and release their focus
	_hide_mode_buttons()
	
	_show_character_cards()
	_update_coop_selection_display()
	_update_prompt_label()


func _hide_mode_buttons() -> void:
	var mode_container := get_node_or_null("CenterContainer/VBoxContainer/ModeContainer")
	if mode_container:
		mode_container.visible = false
		# Release focus from mode buttons
		for btn in _mode_buttons:
			if btn:
				btn.release_focus()
				btn.focus_mode = Control.FOCUS_NONE


func _show_mode_buttons() -> void:
	var mode_container := get_node_or_null("CenterContainer/VBoxContainer/ModeContainer")
	if mode_container:
		mode_container.visible = true
		# Restore focus mode
		for btn in _mode_buttons:
			if btn:
				btn.focus_mode = Control.FOCUS_ALL
		if _mode_buttons.size() > 0 and _mode_buttons[0]:
			_mode_buttons[0].grab_focus()


func _hide_character_cards() -> void:
	var panel := get_node_or_null("CenterContainer/VBoxContainer/CharacterCardPanel")
	if panel:
		panel.visible = false


func _show_character_cards() -> void:
	var panel := get_node_or_null("CenterContainer/VBoxContainer/CharacterCardPanel")
	if panel:
		panel.visible = true


func _go_back_to_mode_selection() -> void:
	_mode_selected = false
	Globals.coop_enabled = false
	_p1_confirmed = false
	_p2_confirmed = false
	
	# Hide character cards and show mode buttons
	_hide_character_cards()
	_show_mode_buttons()
	
	# Reset character card labels to just display names
	for profile_id in _card_order:
		var button := _cards.get(profile_id) as Button
		if button == null:
			continue
		var label := button.get_node_or_null("VBoxContainer/Label") as Label
		if label:
			var profile := Globals.player_profiles.get(profile_id, {}) as Dictionary
			label.text = profile.get("display_name", _format_profile_name(profile_id))
		# Re-enable focus for single player use later
		button.focus_mode = Control.FOCUS_ALL
	
	_update_prompt_label()


func _update_prompt_label() -> void:
	var prompt := get_node_or_null("CenterContainer/VBoxContainer/PromptLabel") as Label
	if prompt == null:
		return
	
	if not _mode_selected:
		prompt.text = "Select Game Mode"
	elif Globals.coop_enabled:
		var scheme := InputManager.get_scheme_description()
		if _p1_confirmed and _p2_confirmed:
			prompt.text = "Press Start to Begin!"
		else:
			var p1_status := "READY" if _p1_confirmed else "selecting..."
			var p2_status := "READY" if _p2_confirmed else "selecting..."
			prompt.text = "%s\nP1: %s | P2: %s" % [scheme, p1_status, p2_status]
	else:
		prompt.text = "Select Character"

func _unhandled_input(event: InputEvent) -> void:
	if _starting:
		return
	
	if not _mode_selected:
		_handle_mode_selection_input(event)
		return
	
	if Globals.coop_enabled:
		_handle_coop_input(event)
	else:
		_handle_single_player_input(event)


func _handle_mode_selection_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("left"):
		_focus_mode_button(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("right"):
		_focus_mode_button(1)
	elif event.is_action_pressed("select_stuff") or event.is_action_pressed("ui_accept"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and focused in _mode_buttons:
			focused.emit_signal("pressed")


func _focus_mode_button(direction: int) -> void:
	_current_mode_index = wrapi(_current_mode_index + direction, 0, _mode_buttons.size())
	_mode_buttons[_current_mode_index].grab_focus()


func _handle_single_player_input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		_go_back_to_mode_selection()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("left"):
		_move_selection(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("right"):
		_move_selection(1)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("up"):
		_move_selection(-1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("down"):
		_move_selection(1)
	elif event.is_action_pressed("select_stuff"):
		_activate_current_card()


func _handle_coop_input(event: InputEvent) -> void:
	# Back button - any player can go back if neither has confirmed
	if event.is_action_pressed("back") and not _p1_confirmed and not _p2_confirmed:
		_go_back_to_mode_selection()
		return
	
	var is_p1_input := _is_player_1_input(event)
	var is_p2_input := _is_player_2_input(event)
	
	# Handle P1 input
	if is_p1_input and not _p1_confirmed:
		if _is_p1_left(event):
			_move_p1_selection(-1)
		elif _is_p1_right(event):
			_move_p1_selection(1)
		elif _is_p1_confirm(event):
			_confirm_p1_selection()
	
	# Handle P2 input
	if is_p2_input and not _p2_confirmed:
		if _is_p2_left(event):
			_move_p2_selection(-1)
		elif _is_p2_right(event):
			_move_p2_selection(1)
		elif _is_p2_confirm(event):
			_confirm_p2_selection()
	
	# Start game when both confirmed
	if _p1_confirmed and _p2_confirmed:
		if event.is_action_pressed("select_stuff") or event.is_action_pressed("ui_accept"):
			_start_game()


func _is_player_1_input(event: InputEvent) -> bool:
	match InputManager.current_scheme:
		InputManager.InputScheme.COOP_TWO_CONTROLLERS:
			# P1 = controller device 0
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				return event.device == 0
			return false
		InputManager.InputScheme.COOP_CONTROLLER_KEYBOARD:
			# P1 = any controller
			return event is InputEventJoypadButton or event is InputEventJoypadMotion
		InputManager.InputScheme.COOP_SPLIT_KEYBOARD:
			# P1 = WASD keys
			if event is InputEventKey:
				var k := event as InputEventKey
				return k.physical_keycode in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_F, KEY_SPACE]
	return false


func _is_player_2_input(event: InputEvent) -> bool:
	match InputManager.current_scheme:
		InputManager.InputScheme.COOP_TWO_CONTROLLERS:
			# P2 = controller device 1
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				return event.device == 1
			return false
		InputManager.InputScheme.COOP_CONTROLLER_KEYBOARD:
			# P2 = keyboard
			return not (event is InputEventJoypadButton or event is InputEventJoypadMotion)
		InputManager.InputScheme.COOP_SPLIT_KEYBOARD:
			# P2 = arrow/numpad keys
			if event is InputEventKey:
				var k := event as InputEventKey
				return k.physical_keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_KP_0, KEY_KP_1]
	return false


func _is_p1_left(event: InputEvent) -> bool:
	match InputManager.current_scheme:
		InputManager.InputScheme.COOP_TWO_CONTROLLERS:
			if event is InputEventJoypadButton and event.device == 0 and event.pressed:
				return event.button_index == JOY_BUTTON_DPAD_LEFT
			return false
		InputManager.InputScheme.COOP_CONTROLLER_KEYBOARD:
			if (event is InputEventJoypadButton or event is InputEventJoypadMotion):
				return event.is_action_pressed("ui_left") or event.is_action_pressed("left")
			return false
		InputManager.InputScheme.COOP_SPLIT_KEYBOARD:
			if event is InputEventKey and event.pressed:
				return (event as InputEventKey).physical_keycode == KEY_A
	return false


func _is_p1_right(event: InputEvent) -> bool:
	match InputManager.current_scheme:
		InputManager.InputScheme.COOP_TWO_CONTROLLERS:
			if event is InputEventJoypadButton and event.device == 0 and event.pressed:
				return event.button_index == JOY_BUTTON_DPAD_RIGHT
			return false
		InputManager.InputScheme.COOP_CONTROLLER_KEYBOARD:
			if (event is InputEventJoypadButton or event is InputEventJoypadMotion):
				return event.is_action_pressed("ui_right") or event.is_action_pressed("right")
			return false
		InputManager.InputScheme.COOP_SPLIT_KEYBOARD:
			if event is InputEventKey and event.pressed:
				return (event as InputEventKey).physical_keycode == KEY_D
	return false


func _is_p1_confirm(event: InputEvent) -> bool:
	match InputManager.current_scheme:
		InputManager.InputScheme.COOP_TWO_CONTROLLERS:
			if event is InputEventJoypadButton and event.device == 0 and event.pressed:
				return event.button_index == JOY_BUTTON_A
			return false
		InputManager.InputScheme.COOP_CONTROLLER_KEYBOARD:
			if (event is InputEventJoypadButton or event is InputEventJoypadMotion):
				return event.is_action_pressed("select_stuff") or event.is_action_pressed("ui_accept")
			return false
		InputManager.InputScheme.COOP_SPLIT_KEYBOARD:
			if event is InputEventKey and event.pressed:
				return (event as InputEventKey).physical_keycode in [KEY_F, KEY_SPACE, KEY_ENTER]
	return false


func _is_p2_left(event: InputEvent) -> bool:
	match InputManager.current_scheme:
		InputManager.InputScheme.COOP_TWO_CONTROLLERS:
			if event is InputEventJoypadButton and event.device == 1 and event.pressed:
				return event.button_index == JOY_BUTTON_DPAD_LEFT
			return false
		InputManager.InputScheme.COOP_CONTROLLER_KEYBOARD:
			if event is InputEventKey and event.pressed:
				return (event as InputEventKey).physical_keycode in [KEY_A, KEY_LEFT]
			return false
		InputManager.InputScheme.COOP_SPLIT_KEYBOARD:
			if event is InputEventKey and event.pressed:
				return (event as InputEventKey).physical_keycode == KEY_LEFT
	return false


func _is_p2_right(event: InputEvent) -> bool:
	match InputManager.current_scheme:
		InputManager.InputScheme.COOP_TWO_CONTROLLERS:
			if event is InputEventJoypadButton and event.device == 1 and event.pressed:
				return event.button_index == JOY_BUTTON_DPAD_RIGHT
			return false
		InputManager.InputScheme.COOP_CONTROLLER_KEYBOARD:
			if event is InputEventKey and event.pressed:
				return (event as InputEventKey).physical_keycode in [KEY_D, KEY_RIGHT]
			return false
		InputManager.InputScheme.COOP_SPLIT_KEYBOARD:
			if event is InputEventKey and event.pressed:
				return (event as InputEventKey).physical_keycode == KEY_RIGHT
	return false


func _is_p2_confirm(event: InputEvent) -> bool:
	match InputManager.current_scheme:
		InputManager.InputScheme.COOP_TWO_CONTROLLERS:
			if event is InputEventJoypadButton and event.device == 1 and event.pressed:
				return event.button_index == JOY_BUTTON_A
			return false
		InputManager.InputScheme.COOP_CONTROLLER_KEYBOARD:
			if event is InputEventKey and event.pressed:
				return (event as InputEventKey).physical_keycode in [KEY_F, KEY_SPACE, KEY_ENTER]
			return false
		InputManager.InputScheme.COOP_SPLIT_KEYBOARD:
			if event is InputEventKey and event.pressed:
				return (event as InputEventKey).physical_keycode in [KEY_KP_0, KEY_KP_ENTER]
	return false


func _move_p1_selection(direction: int) -> void:
	_p1_selection_index = wrapi(_p1_selection_index + direction, 0, _card_order.size())
	_update_coop_selection_display()


func _move_p2_selection(direction: int) -> void:
	_p2_selection_index = wrapi(_p2_selection_index + direction, 0, _card_order.size())
	_update_coop_selection_display()


func _confirm_p1_selection() -> void:
	_p1_confirmed = true
	Globals.selected_players[1] = _card_order[_p1_selection_index]
	_update_coop_selection_display()
	_update_prompt_label()


func _confirm_p2_selection() -> void:
	_p2_confirmed = true
	Globals.selected_players[2] = _card_order[_p2_selection_index]
	_update_coop_selection_display()
	_update_prompt_label()


func _update_coop_selection_display() -> void:
	for i in _card_order.size():
		var profile_id := _card_order[i]
		var button := _cards[profile_id] as Button
		if button == null:
			continue
		
		# Disable focus on character cards in co-op mode to prevent focus outline
		button.focus_mode = Control.FOCUS_NONE
		button.release_focus()
		
		var highlight := button.get_node_or_null("VBoxContainer/PreviewWrapper/Preview/Highlight") as ColorRect
		var label := button.get_node_or_null("VBoxContainer/Label") as Label
		
		var is_p1 := (i == _p1_selection_index)
		var is_p2 := (i == _p2_selection_index)
		
		# Hide the highlight in co-op mode - use P1/P2 labels instead
		if highlight:
			highlight.color = Color(0, 0, 0, 0)
		
		if label:
			var label_text: String = Globals.player_profiles[profile_id].get("display_name", profile_id)
			var indicators: Array[String] = []
			if is_p1:
				indicators.append("P1" + (" ✓" if _p1_confirmed else ""))
			if is_p2:
				indicators.append("P2" + (" ✓" if _p2_confirmed else ""))
			
			if indicators.size() > 0:
				label.text = "%s\n[%s]" % [label_text, " | ".join(indicators)]
			else:
				label.text = label_text

func _start_game() -> void:
	_starting = true
	# Reset all player stats when starting a new game
	Globals.reset_all_player_stats()
	# Set selected player for single player mode
	if not Globals.coop_enabled:
		Globals.selected_player_id = Globals.selected_players.get(1, "player_1")
	TransitionLayer.change_scene(MAIN_SCENE_PATH)

func _setup_character_cards() -> void:
	_cards.clear()
	_card_order.clear()
	var container := get_node("CenterContainer/VBoxContainer/CharacterCardPanel/CardContainer") as Container
	if container:
		for child in container.get_children():
			child.queue_free()
	var profile_ids := Globals.player_profiles.keys()
	profile_ids.sort()
	for profile_id in profile_ids:
		var profile := Globals.player_profiles.get(profile_id, {}) as Dictionary
		if container == null:
			continue
		var button := CARD_SCENE.instantiate() as Button
		if button == null:
			continue
		button.name = _get_card_name(profile_id)
		container.add_child(button)
		_cards[profile_id] = button
		_card_order.append(profile_id)
		var callback := Callable(self, "_on_character_card_pressed").bind(profile_id)
		if not button.pressed.is_connected(callback):
			button.pressed.connect(callback)
		_update_card_content(profile_id, profile)
	if not _cards.has(Globals.selected_player_id) and not _card_order.is_empty():
		_select_player(_card_order[0])

func _on_character_card_pressed(profile_id: String) -> void:
	if not Globals.coop_enabled:
		_select_player(profile_id)

func _select_player(profile_id: String) -> void:
	# Only used in single player mode
	if Globals.coop_enabled:
		return
	Globals.set_selected_player(profile_id)
	for id in _cards.keys():
		var button := _cards[id] as Button
		if button == null:
			continue
		var highlight := button.get_node_or_null("VBoxContainer/PreviewWrapper/Preview/Highlight") as ColorRect
		if highlight:
			if id == Globals.selected_player_id:
				highlight.color = _get_profile_highlight(id)
			else:
				highlight.color = Color(1, 1, 1, 0)
		var label := button.get_node_or_null("VBoxContainer/Label") as Label
		if label:
			if id == Globals.selected_player_id:
				label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
			else:
				label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _update_card_preview(profile_id: String) -> void:
	var profile := Globals.player_profiles.get(profile_id, {}) as Dictionary
	var button := _cards.get(profile_id) as Button
	if button == null:
		return
	var preview_rect := button.get_node_or_null("VBoxContainer/PreviewWrapper/Preview") as TextureRect
	if preview_rect == null:
		return
	preview_rect.custom_minimum_size = PREVIEW_SIZE
	preview_rect.size = PREVIEW_SIZE
	preview_rect.ignore_texture_size = true
	preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture_path := profile.get("preview_texture", "") as String
	if texture_path != "":
		preview_rect.texture = _load_preview_texture(texture_path)
	preview_rect.modulate = profile.get("modulate_color", Color.WHITE)

func _update_card_content(profile_id: String, profile: Dictionary) -> void:
	_update_card_preview(profile_id)
	var button := _cards.get(profile_id) as Button
	if button == null:
		return
	var label := button.get_node_or_null("VBoxContainer/Label") as Label
	if label:
		var display_name := profile.get("display_name", _format_profile_name(profile_id)) as String
		label.text = display_name
	var highlight := button.get_node_or_null("VBoxContainer/PreviewWrapper/Preview/Highlight") as ColorRect
	if highlight:
		highlight.color = Color(1, 1, 1, 0)

func _get_card_name(profile_id: String) -> String:
	return _format_profile_name(profile_id).replace(" ", "") + "Card"

func _format_profile_name(profile_id: String) -> String:
	var name_parts := profile_id.split("_")
	for i in name_parts.size():
		name_parts[i] = name_parts[i].capitalize()
	return " ".join(name_parts)

func _get_profile_highlight(profile_id: String) -> Color:
	var profile := Globals.player_profiles.get(profile_id, {}) as Dictionary
	return profile.get("highlight_color", Color(0.1, 0.7, 1.0, 0.55))

func _load_preview_texture(texture_path: String) -> Texture2D:
	var loaded_resource := load(texture_path)
	if loaded_resource is Texture2D:
		var base_texture := loaded_resource as Texture2D
		var base_image := base_texture.get_image()
		if base_image:
			var thumbnail := base_image.duplicate()
			thumbnail.resize(int(PREVIEW_SIZE.x), int(PREVIEW_SIZE.y), Image.INTERPOLATE_LANCZOS)
			return ImageTexture.create_from_image(thumbnail)
		return base_texture
	return null

func _move_selection(direction: int) -> void:
	if _card_order.is_empty():
		return
	var current_index := _card_order.find(Globals.selected_player_id)
	if current_index == -1:
		current_index = 0
	var next_index := posmod(current_index + direction, _card_order.size())
	_select_player(_card_order[next_index])

func _activate_current_card() -> void:
	# In single player mode, selecting a card starts the game
	Globals.selected_players[1] = Globals.selected_player_id
	_start_game()
