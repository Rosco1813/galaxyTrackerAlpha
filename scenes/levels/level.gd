extends Node2D
class_name LevelParent
#var pistol_shot_scene: PackedScene = preload("res://scenes/weapons/projectiles/pistol_shot.tscn")
#var grenade_throw_scene: PackedScene = preload("res://scenes/weapons/projectiles/grenade.tscn")

@export var pistol_shot:PackedScene
@export var grenade: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	print('LEVEL SHELL ===============================')
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_player_1_shoot_weapon(markerPosition, weaponType, direction) -> void:
	if weaponType == 'pistol' or weaponType == 'shotgun':
		var pistolShot = pistol_shot.instantiate() as Area2D
		pistolShot.rotation_degrees = rad_to_deg(direction.angle()) -90
		#update laser position, then move the laser, then add laser to instance of Node2d projectiles
		pistolShot.direction = direction
		pistolShot.position= markerPosition

		$Projectiles.add_child(pistolShot)
		$UI.update_pistol_ammo_text()
	if weaponType == 'grenade':
		var grenadeThrow = grenade.instantiate() as RigidBody2D
		grenadeThrow.position = markerPosition
		grenadeThrow.linear_velocity = direction * 300
		$Projectiles.add_child(grenadeThrow)
		$UI.update_grenade_ammo_text()









