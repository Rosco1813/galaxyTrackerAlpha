extends Control

const MAIN_SCENE_PATH := "res://scenes/levels/first_room_updated.tscn"
const START_BUTTON_INDEX := 0
const PREVIEW_SIZE := Vector2(128, 128)
const CARD_SCENE := preload("res://scenes/menu/components/character_card.tscn")
var _starting := false
var _cards: Dictionary = {}
var _card_order: Array[String] = []

func _ready() -> void:
	set_process_unhandled_input(true)
	TransitionLayer.play_music()
	_setup_character_cards()
	_select_player(Globals.selected_player_id)

func _unhandled_input(event: InputEvent) -> void:
	if _starting:
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("left"):
		_move_selection(-1)
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("right"):
		_move_selection(1)
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("up"):
		_move_selection(-1)
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("down"):
		_move_selection(1)
		return
	if event.is_action_pressed("select_stuff"):
		_activate_current_card()
		return
	#if _is_start_event(event):
		#_start_game()

#func _is_start_event(event: InputEvent) -> bool:
	#if event.is_action_pressed("ui_accept"):
		#return true
	#if event is InputEventKey and event.pressed and not event.echo:
		#return event.physical_keycode == Key.KEY_ENTER or event.physical_keycode == Key.KEY_KP_ENTER
	#if event is InputEventJoypadButton and event.pressed:
		#return event.button_index == START_BUTTON_INDEX
	#return false

func _start_game() -> void:
	_starting = true
	# Reset player stats when starting a new game
	Globals.reset_death_state()
	Globals.player_one_health = Globals.H
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
	_select_player(profile_id)

func _select_player(profile_id: String) -> void:
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
	var current_card := _cards.get(Globals.selected_player_id) as Button
	if current_card:
		current_card.emit_signal("pressed")
	#if _is_start_event(event):
		_start_game()
