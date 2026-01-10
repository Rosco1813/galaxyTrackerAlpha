extends Node


signal stats_updated
signal player_died

const DEFAULT_PLAYER_ID := "player_1"
const DEATH_SCREEN_PATH := "res://scenes/UI/death_screen.tscn"

var H = 100
var S = 100
var p_a = 250
var s_a = 6
var g_a = 5

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
		
		# Check for death
		if player_one_health <= 0:
			_show_death_screen()


var _death_screen_shown := false

func _show_death_screen() -> void:
	if _death_screen_shown:
		return
	_death_screen_shown = true
	player_died.emit()
	var death_screen = load(DEATH_SCREEN_PATH).instantiate()
	get_tree().current_scene.add_child(death_screen)


func reset_death_state() -> void:
	_death_screen_shown = false


var player_one_stamina = S:
	set(value):
		if value < 0:
			player_one_stamina = 0
		if value > S:
			player_one_stamina = S
		else:
			player_one_stamina = value
#		print('Global : p1-S : ')
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
