extends Node2D
class_name LevelParent
#var pistol_shot_scene: PackedScene = preload("res://scenes/weapons/projectiles/pistol_shot.tscn")
#var grenade_throw_scene: PackedScene = preload("res://scenes/weapons/projectiles/grenade.tscn")

@export var pistol_shot:PackedScene
@export var grenade: PackedScene

var _player: Node2D
var _player_two: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
#	print('LEVEL SHELL ===============================')
	_spawn_selected_player()
	if Globals.coop_enabled:
		_spawn_player_two()

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


func _spawn_player_two() -> void:
	if _player == null:
		return
	
	# Get player 2's selected character from Globals
	var profile_id := Globals.selected_players.get(2, "player_2") as String
	var profile := Globals.player_profiles.get(profile_id, {}) as Dictionary
	var scene_path := profile.get("scene_path", "") as String
	
	if scene_path == "":
		push_warning("No scene path for player 2 profile: " + profile_id)
		return
	
	var packed := load(scene_path)
	if not packed is PackedScene:
		push_warning("Failed to load player 2 scene: " + scene_path)
		return
	
	_player_two = (packed as PackedScene).instantiate() as Node2D
	if _player_two == null:
		return
	
	_player_two.name = "Player2"
	
	# Spawn player 2 offset from player 1
	_player_two.global_position = _player.global_position + Vector2(60, 0)
	_player_two.rotation = _player.rotation
	_player_two.scale = _player.scale
	
	# Set player_id for input routing
	if "player_id" in _player_two:
		_player_two.player_id = 2
	
	# Make sure player 2 is in the player group
	if not _player_two.is_in_group("player"):
		_player_two.add_to_group("player")
	
	# Disable player 2's camera (we'll use player 1's camera with coop zoom)
	var p2_camera := _player_two.get_node_or_null("Camera2D") as Camera2D
	if p2_camera:
		p2_camera.enabled = false
	
	# Setup co-op camera zoom helper
	var p1_camera := _player.get_node_or_null("Camera2D") as Camera2D
	if p1_camera:
		var coop_script := load("res://scenes/levels/coop_camera.gd")
		if coop_script:
			var coop_helper := Node.new()
			coop_helper.name = "CoopCameraHelper"
			coop_helper.set_script(coop_script)
			add_child(coop_helper)
			
			# Set references after adding to tree
			coop_helper.camera = p1_camera
			coop_helper.player_one = _player
			coop_helper.player_two = _player_two
			
			print("[Level] Co-op camera helper created")
		else:
			push_error("[Level] Failed to load coop_camera.gd script")
	else:
		push_warning("[Level] No Camera2D found on Player 1")
	
	add_child(_player_two)
	_connect_player_two_signals()


func _connect_player_two_signals() -> void:
	if _player_two == null:
		return
	var shoot_callable := Callable(self, "_on_player_2_shoot_weapon")
	if _player_two.has_signal("shootWeapon"):
		if _player_two.shootWeapon.is_connected(shoot_callable):
			_player_two.shootWeapon.disconnect(shoot_callable)
		_player_two.shootWeapon.connect(shoot_callable)


func _on_player_2_shoot_weapon(markerPosition, weaponType, direction) -> void:
	if weaponType == 'pistol' or weaponType == 'shotgun':
		var pistolShot = pistol_shot.instantiate() as Area2D
		pistolShot.rotation_degrees = rad_to_deg(direction.angle()) - 90
		pistolShot.direction = direction
		pistolShot.position = markerPosition
		pistolShot.owner_player_id = 2  # Mark as player 2's projectile
		$Projectiles.add_child(pistolShot)
		# TODO: Update P2 ammo UI when implemented
	if weaponType == 'grenade':
		var grenadeThrow = grenade.instantiate() as RigidBody2D
		grenadeThrow.position = markerPosition
		grenadeThrow.linear_velocity = direction * 300
		grenadeThrow.owner_player_id = 2  # Mark as player 2's projectile
		$Projectiles.add_child(grenadeThrow)


func _on_player_1_shoot_weapon(markerPosition, weaponType, direction) -> void:
	if weaponType == 'pistol' or weaponType == 'shotgun':
		var pistolShot = pistol_shot.instantiate() as Area2D
		pistolShot.rotation_degrees = rad_to_deg(direction.angle()) -90
		#update laser position, then move the laser, then add laser to instance of Node2d projectiles
		pistolShot.direction = direction
		pistolShot.position= markerPosition
		pistolShot.owner_player_id = 1  # Mark as player 1's projectile

		$Projectiles.add_child(pistolShot)
		$UI.update_pistol_ammo_text()
	if weaponType == 'grenade':
		var grenadeThrow = grenade.instantiate() as RigidBody2D
		grenadeThrow.position = markerPosition
		grenadeThrow.linear_velocity = direction * 300
		grenadeThrow.owner_player_id = 1  # Mark as player 1's projectile
		$Projectiles.add_child(grenadeThrow)
		$UI.update_grenade_ammo_text()
