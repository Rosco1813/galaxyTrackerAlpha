extends Node2D
var pistol_shot_scene: PackedScene = preload("res://scenes/weapons/projectiles/pistol_shot.tscn")
var grenade_throw_scene: PackedScene = preload("res://scenes/weapons/projectiles/grenade.tscn")




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass



func _on_first_room_player_entered_door() -> void:
	print('player has entered the door')



func _on_player_1_shoot_weapon(markerPosition, weaponType, direction) -> void:
	print('level heard shot: Position : ',   direction)
	if weaponType == 'pistol':
		var pistolShot = pistol_shot_scene.instantiate() as Area2D
		pistolShot.rotation_degrees = rad_to_deg(direction.angle()) -90
		#update laser position, then move the laser, then add laser to instance of Node2d projectiles
		pistolShot.direction = direction
		pistolShot.position= markerPosition

		$Projectiles.add_child(pistolShot)
	if weaponType == 'grenade':
		var grenadeThrow = grenade_throw_scene.instantiate() as RigidBody2D
		grenadeThrow.position = markerPosition
		grenadeThrow.linear_velocity = direction * 300
		$Projectiles.add_child(grenadeThrow)


func _on_first_room_player_exit_door() -> void:
	print('exit the door')




func _on_first_room_sewer_entrance() -> void:
	print('sewer enter')


func _on_first_room_sewer_exit() -> void:
	print('exit sewer')
