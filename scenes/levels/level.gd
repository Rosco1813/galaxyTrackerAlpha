extends Node2D
class_name LevelParent
#var pistol_shot_scene: PackedScene = preload("res://scenes/weapons/projectiles/pistol_shot.tscn")
#var grenade_throw_scene: PackedScene = preload("res://scenes/weapons/projectiles/grenade.tscn")

@export var pistol_shot:PackedScene
@export var grenade: PackedScene

var _player: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
#	print('LEVEL SHELL ===============================')
	_spawn_selected_player()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func get_active_player() -> Node2D:
	return _player


func _spawn_selected_player() -> void:
	var existing_player := get_node_or_null("Player1") as Node2D
	if existing_player == null:
		return
	var parent := existing_player.get_parent()
	var child_index := existing_player.get_index()
	var spawn_position := existing_player.global_position
	var spawn_rotation := existing_player.rotation
	var spawn_scale := existing_player.scale
	var camera_settings := {}
	var existing_camera := existing_player.get_node_or_null("Camera2D") as Camera2D
	if existing_camera:
		camera_settings["zoom"] = existing_camera.zoom
		camera_settings["offset"] = existing_camera.offset
		camera_settings["position"] = existing_camera.position
		camera_settings["smoothing_enabled"] = existing_camera.position_smoothing_enabled
		camera_settings["smoothing_speed"] = existing_camera.position_smoothing_speed
	var profile := Globals.get_active_player_profile()
	var scene_path := profile.get("scene_path", "") as String
	var new_player := existing_player
	if scene_path != "":
		var packed := load(scene_path)
		if packed is PackedScene:
			new_player = (packed as PackedScene).instantiate() as Node2D
			if new_player:
				new_player.name = "Player1"
	var new_camera := existing_camera
	if new_player != existing_player and new_player:
		existing_player.name = "Player1_Original"
		parent.add_child(new_player)
		parent.move_child(new_player, child_index)
		new_camera = new_player.get_node_or_null("Camera2D") as Camera2D
		if new_camera == null and existing_camera:
			existing_player.remove_child(existing_camera)
			new_player.add_child(existing_camera)
			existing_camera.owner = new_player.owner
			new_camera = existing_camera
		if existing_player.is_inside_tree():
			existing_player.queue_free()
	if new_player:
		new_player.global_position = spawn_position
		new_player.rotation = spawn_rotation
		new_player.scale = spawn_scale
		if new_camera == null:
			new_camera = new_player.get_node_or_null("Camera2D") as Camera2D
		if new_camera:
			if camera_settings.has("zoom"):
				new_camera.zoom = camera_settings["zoom"]
			if camera_settings.has("offset"):
				new_camera.offset = camera_settings["offset"]
			if camera_settings.has("position"):
				new_camera.position = camera_settings["position"]
			if camera_settings.has("smoothing_enabled"):
				new_camera.position_smoothing_enabled = camera_settings["smoothing_enabled"]
			if camera_settings.has("smoothing_speed"):
				new_camera.position_smoothing_speed = camera_settings["smoothing_speed"]
			new_camera.make_current()
	_player = new_player
	_connect_player_signals()


func _connect_player_signals() -> void:
	if _player == null:
		return
	var shoot_callable := Callable(self, "_on_player_1_shoot_weapon")
	if _player.has_signal("shootWeapon"):
		if _player.shootWeapon.is_connected(shoot_callable):
			_player.shootWeapon.disconnect(shoot_callable)
		_player.shootWeapon.connect(shoot_callable)


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
