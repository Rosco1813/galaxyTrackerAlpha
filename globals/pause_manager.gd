extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var label: Label = $CenterContainer/Label

var is_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	hide_pause_overlay()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	print('pause pause pause pause pause ')
	is_paused = !is_paused
	get_tree().paused = is_paused
	if is_paused:
		show_pause_overlay()
	else:
		hide_pause_overlay()
	Input.action_release("pause")

func show_pause_overlay() -> void:
	overlay.visible = true
	label.visible = true

func hide_pause_overlay() -> void:
	overlay.visible = false
	label.visible = false
