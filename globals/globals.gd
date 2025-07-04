extends Node


signal stats_updated

var H = 100
var S = 100
var p_a = 25
var s_a = 6
var g_a = 5

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

