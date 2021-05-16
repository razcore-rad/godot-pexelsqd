extends LineEdit


func _ready() -> void:
	connect("mouse_entered", self, "grab_focus")
	connect("mouse_exited", self, "release_focus")
