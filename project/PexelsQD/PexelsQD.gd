# TODO:
# - make all buttons work
# - check if image can be created - if not give an error notification and stop
# - add author information
extends Control

const LAST := 3
const PB_COLORS := {
	"begin": Color("004c566a"),
	"end": Color("4c566a"),
	"last": Color("d08770")
}

var _session: Session = null
var _config_file := ConfigFile.new()

onready var pc_intro: PanelContainer = $PanelContainerIntro
onready var tb_next: TextureButton = $PanelContainerIntro/CenterContainer/VBoxContainer/HBoxContainer2/TextureButtonNext
onready var vbc_main: VBoxContainer = $VBoxContainerMain
onready var le_search: LineEdit = $VBoxContainerMain/MarginContainerControls/HBoxContainer/LineEditSearch
onready var sb_time_input: SpinBox = $VBoxContainerMain/MarginContainerControls/HBoxContainer/SpinBoxTimeInput
onready var tb_back: TextureButton = $VBoxContainerMain/MarginContainerControls/HBoxContainer/TextureButtonBack
onready var tb_play_pause: TextureButton = $VBoxContainerMain/MarginContainerControls/HBoxContainer/TextureButtonPlayPause
onready var tr: TextureRect = $VBoxContainerMain/MarginContainerImage/TextureRect
onready var pb: ProgressBar = $VBoxContainerMain/ProgressBar
onready var pc_notification: PanelContainer = $PanelContainerNotification
onready var tb_razcore: TextureButton = $PanelContainerIntro/CenterContainer/VBoxContainer/HBoxContainer1/TextureButtonRazcore
onready var tb_pexels: TextureButton = $PanelContainerIntro/CenterContainer/VBoxContainer/HBoxContainer1/TextureButtonPexels
onready var tween: Tween = $Tween
onready var http_request: HTTPRequest = $HTTPRequest


func _ready() -> void:
	_load_config()
	var api_key: String = _config_file.get_value(Constants.CONFIG_FILE.section, Constants.CONFIG_FILE.key, "")
	_session = Session.new(api_key, http_request)
	
	_session.connect("image_fetched", tr, "set_texture")
	_session.connect("notified", pc_notification, "trigger")
	pc_intro.connect("notified", pc_notification, "trigger")
	tb_next.connect("pressed", vbc_main, "set_visible", [true])
	le_search.connect("text_validated", self, "_on_Find_text_validated")
	tb_back.connect("pressed", vbc_main, "set_visible", [false])
	tb_back.connect("pressed", pc_intro, "set_visible", [true])
	tb_play_pause.connect("toggled", self, "_on_TextureButtonPlayPaused_toggled")
	tween.connect("tween_all_completed", self, "_search")
	tb_razcore.connect("pressed", OS, "shell_open", [Constants.URLS.razcore])
	tb_pexels.connect("pressed", OS, "shell_open", [Constants.URLS.pexels])
	
	OS.min_window_size = Constants.MIN_WINDOW_SIZE
	pc_intro.setup(_config_file)
	vbc_main.visible = false
	pc_intro.visible = true


func _load_config() -> void:
	if _config_file.load(Constants.CONFIG_FILE.path) != OK:
		var message := "ERROR: loading config file from: {path}"
		pc_notification.trigger(message.format(Constants.CONFIG_FILE))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and le_search.text.length() > 2:
		tb_play_pause.pressed = true
	elif event.is_action_pressed("ui_cancel"):
		tb_play_pause.pressed = false
	elif event.is_action_pressed("ui_focus_search"):
		var node := get_focus_owner()
		le_search.release_focus() if node == le_search else le_search.grab_focus()


func _on_Find_text_validated(new_text: String):
	tb_play_pause.disabled = new_text.length() < 3


func _on_TextureButtonPlayPaused_toggled(button_pressed: bool) -> void:
	# Set button to pause etc.
	_search()


func _search() -> void:
	pb.max_value = sb_time_input.value
	_session.search(le_search.text)
	yield(_session, "image_fetched")

	tween.interpolate_property(pb, "value", pb.min_value, pb.max_value, sb_time_input.value)
	tween.interpolate_property(pb, "modulate", PB_COLORS.begin, PB_COLORS.end, sb_time_input.value - LAST, Tween.TRANS_SINE, Tween.EASE_IN)
	tween.interpolate_property(pb, "modulate", PB_COLORS.end, PB_COLORS.last, LAST, Tween.TRANS_LINEAR, Tween.EASE_IN, sb_time_input.value - LAST)
	tween.start()
