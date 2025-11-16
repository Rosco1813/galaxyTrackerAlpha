extends CanvasLayer

@onready var music: AudioStreamPlayer = $Music

var _music_started := false

func _ready() -> void:
	if music.stream is AudioStreamMP3:
		music.stream.loop = true


func play_music() -> void:
	if _music_started:
		return
	music.play()
	_music_started = true

func change_scene(target:String) ->void:
	$AnimationPlayer.play("fade_to_black")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(target)
#	$AnimationPlayer.play("reveal")
	$AnimationPlayer.play_backwards("fade_to_black")
