extends CanvasLayer

var green:Color = Color("71b446")
var orange:Color = Color("e19728")
var salmon:Color = Color("e882df")
var red:Color = Color("e70002d8")
var blue:Color = Color("0235ff")
var p2_tint:Color = Color(0.55, 0.78, 1, 1)  # Blue tint for P2

# Player 1 UI elements (right side in co-op)
@onready var pistol_label:Label = $primary_ammo/VBoxContainer/Label
@onready var pistol_icon:TextureRect = $primary_ammo/VBoxContainer/TextureRect
@onready var shotgun_lable:Label = $shotgun_ammo/VBoxContainer/Label
@onready var shotgun_icon:TextureRect = $shotgun_ammo/VBoxContainer/TextureRect
@onready var grenade_label:Label = $grenade_ammo/VBoxContainer/Label
@onready var grenade_icon: TextureRect = $grenade_ammo/VBoxContainer/TextureRect
@onready var player_one_health:TextureProgressBar = $health_container/TextureProgressBar
@onready var player_one_stamina:TextureProgressBar = $stamina_container/TextureProgressBar
@onready var selected_weapon_label:Label = $selected_weapon/VBoxContainer/Label

# Player 2 UI elements (left side in co-op) - will be null in single player
var p2_pistol_label: Label
var p2_pistol_icon: TextureRect
var p2_shotgun_label: Label
var p2_shotgun_icon: TextureRect
var p2_grenade_label: Label
var p2_grenade_icon: TextureRect
var p2_health: TextureProgressBar
var p2_stamina: TextureProgressBar
var p2_weapon_label: Label

# P2 container for easy show/hide
var p2_container: Control

func _ready() -> void:
	if Globals.coop_enabled:
		_setup_coop_ui()
	update_stats()
	Globals.connect("stats_updated", update_stats)
	print('attempt global connection to stats_updated')


func _setup_coop_ui() -> void:
	# Create P2 UI container on the left side
	p2_container = Control.new()
	p2_container.name = "P2_Container"
	p2_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(p2_container)
	
	# P2 Layout (bottom-left, vertical stack from bottom):
	# Row 1 (bottom): Health bar
	# Row 2: Stamina bar  
	# Row 3: Ammo icons (pistol, shotgun, grenade) + weapon label
	# Row 4 (top): P2 label
	
	# Create P2 health bar (bottom row)
	var p2_health_container = MarginContainer.new()
	p2_health_container.name = "P2_health_container"
	p2_health_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	p2_health_container.offset_left = 10
	p2_health_container.offset_top = -30
	p2_health_container.offset_right = 160
	p2_health_container.offset_bottom = -10
	p2_container.add_child(p2_health_container)
	
	p2_health = TextureProgressBar.new()
	p2_health.max_value = Globals.H
	p2_health.value = Globals.player_two_health
	p2_health.texture_under = player_one_health.texture_under
	p2_health.texture_over = player_one_health.texture_over
	p2_health.texture_progress = player_one_health.texture_progress
	p2_health.tint_under = p2_tint * Color(0.5, 0.5, 0.5, 1.0)
	p2_health.tint_progress = p2_tint
	p2_health_container.add_child(p2_health)
	
	# Create P2 stamina bar (above health)
	var p2_stamina_container = MarginContainer.new()
	p2_stamina_container.name = "P2_stamina_container"
	p2_stamina_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	p2_stamina_container.offset_left = 10
	p2_stamina_container.offset_top = -55
	p2_stamina_container.offset_right = 160
	p2_stamina_container.offset_bottom = -35
	p2_container.add_child(p2_stamina_container)
	
	p2_stamina = TextureProgressBar.new()
	p2_stamina.max_value = Globals.S
	p2_stamina.value = Globals.player_two_stamina
	p2_stamina.texture_under = player_one_stamina.texture_under
	p2_stamina.texture_over = player_one_stamina.texture_over
	p2_stamina.texture_progress = player_one_stamina.texture_progress
	p2_stamina.tint_under = p2_tint * Color(0.5, 0.5, 0.5, 1.0)
	p2_stamina.tint_progress = p2_tint
	p2_stamina_container.add_child(p2_stamina)
	
	# Create P2 ammo displays (above stamina)
	_create_p2_ammo_display()
	
	# Create P2 weapon label (next to ammo)
	p2_weapon_label = Label.new()
	p2_weapon_label.text = "PISTOL"
	p2_weapon_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	p2_weapon_label.offset_left = 140
	p2_weapon_label.offset_top = -80
	p2_weapon_label.modulate = p2_tint
	p2_container.add_child(p2_weapon_label)
	
	# Move P1 UI to right side
	_reposition_p1_ui_for_coop()
	
	# Add P2 label
	var p2_label = Label.new()
	p2_label.text = "P2"
	p2_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	p2_label.offset_left = 10
	p2_label.offset_top = -110
	p2_label.add_theme_color_override("font_color", p2_tint)
	p2_container.add_child(p2_label)
	
	# Add P1 label
	var p1_label = Label.new()
	p1_label.text = "P1"
	p1_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	p1_label.offset_left = -30
	p1_label.offset_top = -110
	p1_label.add_theme_color_override("font_color", orange)
	add_child(p1_label)


func _create_p2_ammo_display() -> void:
	# P2 ammo icons positioned above stamina bar (row at -60 to -100)
	# P2 Pistol ammo
	var p2_pistol = Control.new()
	p2_pistol.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	p2_pistol.offset_left = 10
	p2_pistol.offset_top = -100
	p2_pistol.offset_right = 50
	p2_pistol.offset_bottom = -60
	p2_container.add_child(p2_pistol)
	
	var p2_pistol_vbox = VBoxContainer.new()
	p2_pistol.add_child(p2_pistol_vbox)
	
	p2_pistol_label = Label.new()
	p2_pistol_label.text = str(Globals.get_player_ammo(2, "pistol"))
	p2_pistol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_pistol_label.modulate = p2_tint
	p2_pistol_vbox.add_child(p2_pistol_label)
	
	p2_pistol_icon = TextureRect.new()
	p2_pistol_icon.texture = pistol_icon.texture
	p2_pistol_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p2_pistol_icon.custom_minimum_size = Vector2(20, 20)
	p2_pistol_icon.modulate = p2_tint
	p2_pistol_vbox.add_child(p2_pistol_icon)
	
	# P2 Shotgun ammo
	var p2_shotgun = Control.new()
	p2_shotgun.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	p2_shotgun.offset_left = 50
	p2_shotgun.offset_top = -100
	p2_shotgun.offset_right = 90
	p2_shotgun.offset_bottom = -60
	p2_container.add_child(p2_shotgun)
	
	var p2_shotgun_vbox = VBoxContainer.new()
	p2_shotgun.add_child(p2_shotgun_vbox)
	
	p2_shotgun_label = Label.new()
	p2_shotgun_label.text = str(Globals.get_player_ammo(2, "shotgun"))
	p2_shotgun_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_shotgun_label.modulate = p2_tint
	p2_shotgun_vbox.add_child(p2_shotgun_label)
	
	p2_shotgun_icon = TextureRect.new()
	p2_shotgun_icon.texture = shotgun_icon.texture
	p2_shotgun_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p2_shotgun_icon.custom_minimum_size = Vector2(20, 20)
	p2_shotgun_icon.modulate = p2_tint
	p2_shotgun_vbox.add_child(p2_shotgun_icon)
	
	# P2 Grenade ammo
	var p2_grenade = Control.new()
	p2_grenade.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	p2_grenade.offset_left = 90
	p2_grenade.offset_top = -100
	p2_grenade.offset_right = 130
	p2_grenade.offset_bottom = -60
	p2_container.add_child(p2_grenade)
	
	var p2_grenade_vbox = VBoxContainer.new()
	p2_grenade.add_child(p2_grenade_vbox)
	
	p2_grenade_label = Label.new()
	p2_grenade_label.text = str(Globals.get_player_ammo(2, "grenade"))
	p2_grenade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2_grenade_label.modulate = p2_tint
	p2_grenade_vbox.add_child(p2_grenade_label)
	
	p2_grenade_icon = TextureRect.new()
	p2_grenade_icon.texture = grenade_icon.texture
	p2_grenade_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p2_grenade_icon.custom_minimum_size = Vector2(20, 20)
	p2_grenade_icon.modulate = p2_tint
	p2_grenade_vbox.add_child(p2_grenade_icon)


func _reposition_p1_ui_for_coop() -> void:
	# P1 Layout (bottom-right, mirroring P2 exactly):
	# Row 1 (bottom): Health bar at -30 to -10
	# Row 2: Stamina bar at -55 to -35
	# Row 3: Ammo icons at -100 to -60, weapon label at -80
	# Row 4 (top): P1 label at -110
	
	# Move health bar to right side (bottom row) - mirror P2's left=10, right=160
	var health_container = $health_container
	health_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	health_container.anchor_left = 1.0
	health_container.anchor_top = 1.0
	health_container.anchor_right = 1.0
	health_container.anchor_bottom = 1.0
	health_container.offset_left = -160
	health_container.offset_right = -10
	health_container.offset_top = -30
	health_container.offset_bottom = -10
	health_container.add_theme_constant_override("margin_bottom", 0)
	
	# Apply orange tint to P1 health bar
	player_one_health.tint_progress = orange
	player_one_health.tint_under = orange * Color(0.5, 0.5, 0.5, 1.0)
	
	# Move stamina bar to right side (above health) - mirror P2's left=10, right=160
	var stamina_container = $stamina_container
	stamina_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	stamina_container.anchor_left = 1.0
	stamina_container.anchor_top = 1.0
	stamina_container.anchor_right = 1.0
	stamina_container.anchor_bottom = 1.0
	stamina_container.offset_left = -160
	stamina_container.offset_right = -10
	stamina_container.offset_top = -55
	stamina_container.offset_bottom = -35
	stamina_container.add_theme_constant_override("margin_top", 0)
	stamina_container.add_theme_constant_override("margin_right", 0)
	
	# Apply orange tint to P1 stamina bar
	player_one_stamina.tint_progress = orange
	player_one_stamina.tint_under = orange * Color(0.5, 0.5, 0.5, 1.0)
	
	# Move ammo displays above stamina (row at -60 to -100)
	# Mirror P2's layout: pistol at 10-50, shotgun at 50-90, grenade at 90-130
	# So P1: pistol at -130 to -90, shotgun at -90 to -50, grenade at -50 to -10
	$primary_ammo.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	$primary_ammo.anchor_left = 1.0
	$primary_ammo.anchor_top = 1.0
	$primary_ammo.anchor_right = 1.0
	$primary_ammo.anchor_bottom = 1.0
	$primary_ammo.offset_left = -130
	$primary_ammo.offset_right = -90
	$primary_ammo.offset_top = -100
	$primary_ammo.offset_bottom = -60
	
	$shotgun_ammo.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	$shotgun_ammo.anchor_left = 1.0
	$shotgun_ammo.anchor_top = 1.0
	$shotgun_ammo.anchor_right = 1.0
	$shotgun_ammo.anchor_bottom = 1.0
	$shotgun_ammo.offset_left = -90
	$shotgun_ammo.offset_right = -50
	$shotgun_ammo.offset_top = -100
	$shotgun_ammo.offset_bottom = -60
	
	$grenade_ammo.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	$grenade_ammo.anchor_left = 1.0
	$grenade_ammo.anchor_top = 1.0
	$grenade_ammo.anchor_right = 1.0
	$grenade_ammo.anchor_bottom = 1.0
	$grenade_ammo.offset_left = -50
	$grenade_ammo.offset_right = -10
	$grenade_ammo.offset_top = -100
	$grenade_ammo.offset_bottom = -60
	
	# Resize P1 icons to match P2 (20x20) and apply orange tint
	pistol_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pistol_icon.custom_minimum_size = Vector2(20, 20)
	pistol_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pistol_icon.modulate = orange
	pistol_label.modulate = orange
	
	shotgun_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shotgun_icon.custom_minimum_size = Vector2(20, 20)
	shotgun_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shotgun_icon.modulate = orange
	shotgun_lable.modulate = orange
	
	grenade_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grenade_icon.custom_minimum_size = Vector2(20, 20)
	grenade_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	grenade_icon.modulate = orange
	grenade_label.modulate = orange
	
	# Move weapon label to the right of ammo icons - mirror P2's left=140
	$selected_weapon.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	$selected_weapon.anchor_left = 1.0
	$selected_weapon.anchor_top = 1.0
	$selected_weapon.anchor_right = 1.0
	$selected_weapon.anchor_bottom = 1.0
	$selected_weapon.offset_left = -220
	$selected_weapon.offset_right = -135
	$selected_weapon.offset_top = -90
	$selected_weapon.offset_bottom = -60
	selected_weapon_label.modulate = orange


func update_selected_weapon():
	# Update P1 weapon
	var p1_weapon := Globals.get_player_weapon(1)
	selected_weapon_label.text = p1_weapon.to_upper()
	if p1_weapon == 'shotgun':
		update_shotgun_ui()
	
	# Update P2 weapon if in co-op
	if Globals.coop_enabled and p2_weapon_label:
		var p2_weapon := Globals.get_player_weapon(2)
		p2_weapon_label.text = p2_weapon.to_upper()


func update_pistol_ammo_text():
	# Update P1 pistol ammo
	var p1_ammo := Globals.get_player_ammo(1, "pistol")
	pistol_label.text = str(p1_ammo)
	if p1_ammo == 0:
		pistol_label.modulate = red
		pistol_icon.modulate = red
	else:
		pistol_label.modulate = salmon
		pistol_icon.modulate = orange
	
	# Update P2 pistol ammo if in co-op
	if Globals.coop_enabled and p2_pistol_label:
		var p2_ammo := Globals.get_player_ammo(2, "pistol")
		p2_pistol_label.text = str(p2_ammo)
		if p2_ammo == 0:
			p2_pistol_label.modulate = red
			p2_pistol_icon.modulate = red
		else:
			p2_pistol_label.modulate = p2_tint
			p2_pistol_icon.modulate = p2_tint


func update_shotgun_ui():
	# Update P1 shotgun ammo
	var p1_ammo := Globals.get_player_ammo(1, "shotgun")
	shotgun_lable.text = str(p1_ammo)
	if p1_ammo == 0:
		shotgun_lable.modulate = red
		shotgun_icon.modulate = red
	else:
		shotgun_lable.modulate = blue
		shotgun_icon.modulate = blue
	
	# Update P2 shotgun ammo if in co-op
	if Globals.coop_enabled and p2_shotgun_label:
		var p2_ammo := Globals.get_player_ammo(2, "shotgun")
		p2_shotgun_label.text = str(p2_ammo)
		if p2_ammo == 0:
			p2_shotgun_label.modulate = red
			p2_shotgun_icon.modulate = red
		else:
			p2_shotgun_label.modulate = p2_tint
			p2_shotgun_icon.modulate = p2_tint


func update_grenade_ammo_text():
	# Update P1 grenade ammo
	var p1_ammo := Globals.get_player_ammo(1, "grenade")
	grenade_label.text = str(p1_ammo)
	if p1_ammo == 0:
		grenade_label.modulate = red
		grenade_icon.modulate = red
	else:
		grenade_label.modulate = salmon
		grenade_icon.modulate = green
	
	# Update P2 grenade ammo if in co-op
	if Globals.coop_enabled and p2_grenade_label:
		var p2_ammo := Globals.get_player_ammo(2, "grenade")
		p2_grenade_label.text = str(p2_ammo)
		if p2_ammo == 0:
			p2_grenade_label.modulate = red
			p2_grenade_icon.modulate = red
		else:
			p2_grenade_label.modulate = p2_tint
			p2_grenade_icon.modulate = p2_tint


func update_player_one_health():
	player_one_health.value = Globals.player_one_health


func update_player_one_stamina():
	player_one_stamina.value = Globals.player_one_stamina


func update_player_two_health():
	if p2_health:
		p2_health.value = Globals.player_two_health


func update_player_two_stamina():
	if p2_stamina:
		p2_stamina.value = Globals.player_two_stamina


func update_stats():
	update_pistol_ammo_text()
	update_grenade_ammo_text()
	update_player_one_health()
	update_player_one_stamina()
	update_selected_weapon()
	update_shotgun_ui()
	
	# Update P2 stats if in co-op
	if Globals.coop_enabled:
		update_player_two_health()
		update_player_two_stamina()
