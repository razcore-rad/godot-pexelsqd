extends SpinBox

const PATTERN := "^(\\d{1,3}) s$"

var regex := RegEx.new()
var old_text := ""

onready var le := get_line_edit()


func _ready() -> void:
	connect("mouse_entered", le, "grab_focus")
	connect("mouse_exited", le, "release_focus")
	le.connect("text_changed", self, "_on_LineEdit_text_changed")
	regex.compile(PATTERN)
	old_text = le.text


func _on_LineEdit_text_changed(new_text: String) -> void:
	var old_caret_position := le.caret_position
	var regex_match := regex.search(new_text)
	
	if regex_match == null:
		le.text = old_text
		le.caret_position = old_caret_position - 1
	else:
		old_text = new_text
		le.caret_position = old_caret_position
		value = regex_match.get_string(1).to_int()
