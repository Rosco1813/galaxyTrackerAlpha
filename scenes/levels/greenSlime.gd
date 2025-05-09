extends Sprite2D
@onready var animation = $slimeAnimation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation.play("slime_flow")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
