extends PanelContainer

signal notified(message)

var _config_file: ConfigFile = null

onready var tb_razcore: TextureButton = $CenterContainer/VBoxContainer/HBoxContainerLogos/TextureButtonRazcore
onready var tb_pexels: TextureButton = $CenterContainer/VBoxContainer/HBoxContainerLogos/TextureButtonPexels
onready var le_api_key: LineEdit = $CenterContainer/VBoxContainer/HBoxContainerControls/LineEditApiKey
onready var tb_next: TextureButton = $CenterContainer/VBoxContainer/HBoxContainerControls/TextureButtonNext


func setup(config_file: ConfigFile) -> void:
	_config_file = config_file
	le_api_key.text = _config_file.get_value(Constants.CONFIG_FILE.section, Constants.CONFIG_FILE.key, "")


func _ready() -> void:
	tb_razcore.connect("pressed", OS, "shell_open", [Constants.URLS.razcore])
	tb_pexels.connect("pressed", OS, "shell_open", [Constants.URLS.pexels])
	le_api_key.connect("text_entered", tb_next, "set_pressed", [true])
	tb_next.connect("pressed", self, "set_visible", [false])
	tb_next.connect("pressed", self, "_on_TextureButtonNext_pressed")


func _on_TextureButtonNext_pressed() -> void:
	var api_key: String = _config_file.get_value(
		Constants.CONFIG_FILE.section, Constants.CONFIG_FILE.key, ""
	)
	if api_key != le_api_key.text:
		_config_file.set_value(Constants.CONFIG_FILE.section, Constants.CONFIG_FILE.key, le_api_key.text)
		_config_file.save(Constants.CONFIG_FILE.path)
		emit_signal("notified", "API-KEY saved!")
