extends Node
## Helper node for co-op mode that adjusts camera zoom as players separate.
## Attach this as a child of the level, NOT the camera.

# Default zoom level when players are close together
@export var default_zoom := Vector2(1.1, 1.1)

# Maximum zoom out when players are at max distance
@export var max_zoom_out := Vector2(0.6, 0.6)

# Distance threshold - zoom only starts when players exceed this distance
@export var zoom_start_distance := 150.0

# Distance at which maximum zoom out is reached
@export var max_player_distance := 400.0

# How fast the zoom adjusts (higher = faster)
@export var zoom_speed := 2.0

# Enable/disable debug logging
@export var debug_enabled := true

# How often to print debug info (in seconds)
@export var debug_interval := 0.5

# References set by level.gd
var camera: Camera2D = null
var player_one: Node2D = null
var player_two: Node2D = null

var _debug_timer := 0.0

func _ready() -> void:
	print("[CoopCamera] Helper node ready!")
	print("[CoopCamera] default_zoom: ", default_zoom, " max_zoom_out: ", max_zoom_out)
	print("[CoopCamera] zoom_start_distance: ", zoom_start_distance, " max_player_distance: ", max_player_distance)

func _process(delta: float) -> void:
	if camera == null or player_one == null or player_two == null:
		return
	
	if not is_instance_valid(player_one) or not is_instance_valid(player_two):
		return
	
	# Get positions
	var p1_pos := player_one.global_position
	var p2_pos := player_two.global_position
	
	# Calculate distance between players
	var distance := p1_pos.distance_to(p2_pos)
	
	var target_zoom := default_zoom
	var zoom_factor := 0.0
	
	# Only zoom out if distance exceeds the threshold
	if distance > zoom_start_distance:
		# Calculate how far beyond the threshold we are (0 to 1)
		var zoom_range := max_player_distance - zoom_start_distance
		var distance_beyond := distance - zoom_start_distance
		zoom_factor = clampf(distance_beyond / zoom_range, 0.0, 1.0)
		
		# Lerp between default and max zoom out
		target_zoom = default_zoom.lerp(max_zoom_out, zoom_factor)
	
	# Smoothly interpolate current zoom toward target
	camera.zoom = camera.zoom.lerp(target_zoom, zoom_speed * delta)
	
	# Debug logging
	if debug_enabled:
		_debug_timer += delta
		if _debug_timer >= debug_interval:
			_debug_timer = 0.0
			var status := "CLOSE" if distance <= zoom_start_distance else "ZOOMING"
			print("[CoopCamera] %s | Distance: %.1f | Zoom Factor: %.2f | Zoom: (%.2f, %.2f) -> (%.2f, %.2f)" % [
				status, distance, zoom_factor, camera.zoom.x, camera.zoom.y, target_zoom.x, target_zoom.y
			])
