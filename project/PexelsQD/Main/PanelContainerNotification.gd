extends PanelContainer


onready var label: Label = $Label
onready var animation_player: AnimationPlayer = $AnimationPlayer


func trigger(message: String) -> void:
	label.text = message
	animation_player.play("fade-out")
