extends LineEdit

signal text_validated(new_text)

const PATTERN := "^[a-z ]*$"

var regex := RegEx.new()
var old_text := ""


func _ready() -> void:
	connect("mouse_entered", self, "grab_focus")
	connect("mouse_exited", self, "release_focus")
	connect("text_changed", self, "_on_text_changed")
	regex.compile(PATTERN)
	old_text = text


func _on_text_changed(new_text: String) -> void:
	var old_caret_position := caret_position
	if regex.search(new_text) == null:
		text = old_text
		caret_position = old_caret_position - 1
	else:
		text = new_text
		caret_position = old_caret_position
		old_text = text
		emit_signal("text_validated", text)
