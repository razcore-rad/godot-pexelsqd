extends PanelContainer

signal notified(message)

var _config_file: ConfigFile = null

onready var le_api_key := $CenterContainer/VBoxContainer/HBoxContainer2/LineEditApiKey
onready var b_next := $CenterContainer/VBoxContainer/HBoxContainer2/ButtonNext


func setup(config_file: ConfigFile) -> void:
	_config_file = config_file
	le_api_key.text = _config_file.get_value(Constants.CONFIG_FILE.section, Constants.CONFIG_FILE.key, "")


func _ready() -> void:
	le_api_key.connect("text_entered", b_next, "set_pressed", [true])
	b_next.connect("pressed", self, "set_visible", [false])
	b_next.connect("pressed", self, "_on_ButtonNext_pressed")


func _on_ButtonNext_pressed() -> void:
	var api_key: String = _config_file.get_value(
		Constants.CONFIG_FILE.section, Constants.CONFIG_FILE.key, ""
	)
	if api_key != le_api_key.text:
		_config_file.set_value(Constants.CONFIG_FILE.section, Constants.CONFIG_FILE.key, le_api_key.text)
		_config_file.save(Constants.CONFIG_FILE.path)
		emit_signal("notified", "API-KEY saved!")
