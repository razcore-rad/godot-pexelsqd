extends Button

const STATE := {
	true: "pause",
	false: "start"
}


func _ready() -> void:
	text = STATE[false]
