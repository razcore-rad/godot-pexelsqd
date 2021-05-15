extends LineEdit


func _ready() -> void:
	connect("mouse_entered", self, "grab_focus")
	connect("mouse_exited", self, "release_focus")
	connect("focus_entered", self, "set_secret", [false])
	connect("focus_exited", self, "set_secret", [true])
