extends Node


signal stats_updated
signal player_died
signal player_downed(player_id: int)
signal player_revived(player_id: int)

const DEFAULT_PLAYER_ID := "player_1"
const DEATH_SCREEN_PATH := "res://scenes/UI/death_screen.tscn"

# Co-op settings
var coop_enabled := false
var friendly_fire_enabled := false

# Player selections for co-op (player number -> profile id)
var selected_players := { 1: "player_1", 2: "player_2" }

# Downed state tracking
var player_is_downed := { 1: false, 2: false }
var player_is_dead := { 1: false, 2: false }

var H = 100
var S = 100
var p_a = 250
var s_a = 6
var g_a = 5

# Per-player ammo pools
var player_ammo := {
	1: { "pistol": 250, "shotgun": 6, "grenade": 5 },
	2: { "pistol": 250, "shotgun": 6, "grenade": 5 }
}

var player_profiles := {
	"player_1": {
		"scene_path": "res://scenes/player1/player_1.tscn",
		"damage_scalar": 1.0,
		"preview_texture": "res://graphics/mainCharacter/Main_Character_Iconpng.png",
		"modulate_color": Color.WHITE,
		"display_name": "Player 1",
		"highlight_color": Color(0.1, 0.7, 1.0, 0.55)
	},
	"player_2": {
		"scene_path": "res://scenes/player2/player_2_placeholder.tscn",
		"damage_scalar": 1.0,
		"preview_texture": "res://graphics/mainCharacter/trinity-matrix.png",
		"modulate_color": Color(0.85, 0.25, 0.25, 1.0),
		"display_name": "Trinity",
		"highlight_color": Color(0.95, 0.25, 0.25, 0.6)
	},
	"player_3": {
		"scene_path": "res://scenes/player3/player_3_placeholder.tscn",
		"damage_scalar": 1.0,
		"preview_texture": "res://graphics/mainCharacter/locke.jpg",
		"modulate_color": Color(1.0, 0.88, 0.25, 1.0),
		"display_name": "Locke",
		"highlight_color": Color(1.0, 0.85, 0.2, 0.6)
	}
}

var selected_player_id := DEFAULT_PLAYER_ID

var player_positions := {
	DEFAULT_PLAYER_ID: Vector2.ZERO
}

var player_position: Vector2
var player_direction:Vector2

var player_one_health = H:
	set(value):
		if value < 0:
			player_one_health = 0
		if value > H:
			player_one_health = H
		else:
			player_one_health = value

		stats_updated.emit()
		
		# Check for downed/death
		if player_one_health <= 0:
			_handle_player_down(1)


var player_two_health = H:
	set(value):
		if value < 0:
			player_two_health = 0
		if value > H:
			player_two_health = H
		else:
			player_two_health = value

		stats_updated.emit()
		
		# Check for downed/death
		if player_two_health <= 0:
			_handle_player_down(2)


var _death_screen_shown := false

func _handle_player_down(player_id: int) -> void:
	if player_is_downed[player_id] or player_is_dead[player_id]:
		return
	
	player_is_downed[player_id] = true
	player_downed.emit(player_id)
	
	# Check if all active players are downed/dead
	_check_all_players_dead()


func _check_all_players_dead() -> void:
	if coop_enabled:
		# Either player dying triggers game over in co-op
		if player_is_downed[1] or player_is_downed[2]:
			player_is_dead[1] = true
			player_is_dead[2] = true
			_show_death_screen()
	else:
		# Single player - downed means death screen
		if player_is_downed[1]:
			player_is_dead[1] = true
			_show_death_screen()


func player_fully_died(player_id: int) -> void:
	# Called when bleed-out timer expires
	player_is_dead[player_id] = true
	_check_all_players_dead()


func revive_player(player_id: int) -> void:
	if not player_is_downed[player_id] or player_is_dead[player_id]:
		return
	
	player_is_downed[player_id] = false
	set_player_health(player_id, H / 2)  # Revive at 50% health
	player_revived.emit(player_id)


func set_player_health(player_id: int, value: int) -> void:
	if player_id == 1:
		player_one_health = value
	else:
		player_two_health = value


func get_player_health(player_id: int) -> int:
	return player_one_health if player_id == 1 else player_two_health


func set_player_stamina(player_id: int, value: int) -> void:
	if player_id == 1:
		player_one_stamina = value
	else:
		player_two_stamina = value


func get_player_stamina(player_id: int) -> int:
	return player_one_stamina if player_id == 1 else player_two_stamina


func get_player_ammo(player_id: int, weapon: String) -> int:
	return player_ammo[player_id].get(weapon, 0)


func set_player_ammo(player_id: int, weapon: String, value: int) -> void:
	var max_ammo: int = p_a if weapon == "pistol" else (s_a if weapon == "shotgun" else g_a)
	player_ammo[player_id][weapon] = clampi(value, 0, max_ammo)
	stats_updated.emit()


func use_player_ammo(player_id: int, weapon: String) -> bool:
	# Returns true if ammo was used, false if out of ammo
	var current := get_player_ammo(player_id, weapon)
	if current <= 0:
		return false
	set_player_ammo(player_id, weapon, current - 1)
	return true


func add_player_ammo(player_id: int, weapon: String, amount: int) -> void:
	var current := get_player_ammo(player_id, weapon)
	set_player_ammo(player_id, weapon, current + amount)


func _show_death_screen() -> void:
	if _death_screen_shown:
		return
	_death_screen_shown = true
	player_died.emit()
	var death_screen = load(DEATH_SCREEN_PATH).instantiate()
	get_tree().current_scene.add_child(death_screen)


func reset_death_state() -> void:
	_death_screen_shown = false
	player_is_downed = { 1: false, 2: false }
	player_is_dead = { 1: false, 2: false }


func reset_all_player_stats() -> void:
	reset_death_state()
	player_one_health = H
	player_two_health = H
	player_one_stamina = S
	player_two_stamina = S
	player_ammo = {
		1: { "pistol": p_a, "shotgun": s_a, "grenade": g_a },
		2: { "pistol": p_a, "shotgun": s_a, "grenade": g_a }
	}
	player_weapons = { 1: "pistol", 2: "pistol" }
	# Also reset legacy ammo vars for compatibility
	pistol_ammo = p_a
	shot_gun_ammo = s_a
	grenade_ammo = g_a


var player_one_stamina = S:
	set(value):
		if value < 0:
			player_one_stamina = 0
		if value > S:
			player_one_stamina = S
		else:
			player_one_stamina = value
		stats_updated.emit()

var player_two_stamina = S:
	set(value):
		if value < 0:
			player_two_stamina = 0
		if value > S:
			player_two_stamina = S
		else:
			player_two_stamina = value
		stats_updated.emit()

var pistol_ammo = p_a:
	set(value):
		if value < 0:
			pistol_ammo = 0
		if value > p_a:
			pistol_ammo = p_a
		else:
			pistol_ammo = value
#		print('global pistol : ammo global emit')
		stats_updated.emit()

var shot_gun_ammo = s_a:
	set(value):
		if value < 0:
			shot_gun_ammo = 0
		if value > s_a:
			shot_gun_ammo = s_a
		else:
			shot_gun_ammo = value
#		print('global shotgun : ammo global emit')
		stats_updated.emit()

var grenade_ammo = g_a:
	set(value):
		if value < 0:
			grenade_ammo = 0
		if value > g_a:
			grenade_ammo = g_a
		else:
			grenade_ammo = value
#		print('grenade : ammo global emit')
		stats_updated.emit()

var selectedWeapon:String:
	set(value):
		selectedWeapon = value
#		print('select weapon :  global emit')
		stats_updated.emit()

# Per-player weapon selection
var player_weapons := { 1: "pistol", 2: "pistol" }

func set_player_weapon(player_id: int, weapon: String) -> void:
	player_weapons[player_id] = weapon
	# Also update legacy variable for P1 compatibility
	if player_id == 1:
		selectedWeapon = weapon
	stats_updated.emit()

func get_player_weapon(player_id: int) -> String:
	return player_weapons.get(player_id, "pistol")


## Returns the closest player node to the given position, or null if no players found.
func get_closest_player(from_position: Vector2) -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	var closest: Node2D = null
	var closest_dist := INF
	for p in players:
		if not is_instance_valid(p):
			continue
		var dist := from_position.distance_to(p.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = p
	return closest


## Returns the position of the closest player, or Vector2.ZERO if no players found.
func get_closest_player_position(from_position: Vector2) -> Vector2:
	var closest := get_closest_player(from_position)
	if closest:
		return closest.global_position
	return Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
#	print('globals file')
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func set_selected_player(player_id: String) -> void:
	if not player_profiles.has(player_id):
		return
	selected_player_id = player_id
	if player_positions.has(player_id):
		player_position = player_positions[player_id]


func get_active_player_profile() -> Dictionary:
	return player_profiles.get(selected_player_id, player_profiles[DEFAULT_PLAYER_ID])


func get_active_player_damage_scalar() -> float:
	var profile = get_active_player_profile()
	return profile.get("damage_scalar", 1.0)


func update_player_position(player_id: String, position: Vector2) -> void:
	player_positions[player_id] = position
	if player_id == selected_player_id:
		player_position = position
