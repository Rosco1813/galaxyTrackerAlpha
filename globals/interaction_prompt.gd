extends CanvasLayer

## Interaction prompt that displays "Press [button] to [action]" with controller-specific icons.
## Usage: InteractionPrompt.show_prompt("Enter") / InteractionPrompt.hide_prompt()

@onready var _panel: PanelContainer = $Control/PanelContainer
@onready var _icon: Control = $Control/PanelContainer/MarginContainer/HBoxContainer/ButtonIcon
@onready var _label: Label = $Control/PanelContainer/MarginContainer/HBoxContainer/ActionLabel


func _ready() -> void:
	layer = 100  # Above most UI
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_prompt()


func show_prompt(action_text: String) -> void:
	_label.text = "to " + action_text
	_icon.queue_redraw()
	_panel.visible = true


func hide_prompt() -> void:
	_panel.visible = false
