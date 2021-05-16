# TODO:
# - check if image can be created - if not give an error notification and stop
# - finish implementing play/pause button
# - implement stop
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
onready var tb_next: TextureButton = $PanelContainerIntro/CenterContainer/VBoxContainer/HBoxContainerControls/TextureButtonNext
onready var vbc_main: VBoxContainer = $VBoxContainerMain
onready var le_search: LineEdit = $VBoxContainerMain/HBoxContainerControls/LineEditSearch
onready var sb_time_input: SpinBox = $VBoxContainerMain/HBoxContainerControls/SpinBoxTimeInput
onready var tb_back: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonBack
onready var tb_skip_back: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonSkipBack
onready var tb_rewind: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonRewind
onready var tb_play_pause: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonPlayPause
onready var tb_stop: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonStop
onready var tb_fast_forward: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonFastForward
onready var tb_skip_forward: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonSkipForward
onready var tb_info: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonInfo
onready var tb_razcore: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonRazcore
onready var tb_pexels: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonPexels
onready var pb: ProgressBar = $VBoxContainerMain/ProgressBar
onready var tr_image: TextureRect = $VBoxContainerMain/TextureRectImage
onready var pc_notification: PanelContainer = $PanelContainerNotification
onready var pc_info: PanelContainer = $PanelContainerInfo
onready var tween: Tween = $Tween
onready var http_request: HTTPRequest = $HTTPRequest
onready var tr_placeholder := tr_image.texture


func _ready() -> void:
	_load_config()
	var api_key: String = _config_file.get_value(Constants.CONFIG_FILE.section, Constants.CONFIG_FILE.key, "")
	_session = Session.new(api_key, http_request)
	
	_session.connect("notified", pc_notification, "trigger")
	pc_intro.connect("notified", pc_notification, "trigger")
	tb_next.connect("pressed", vbc_main, "set_visible", [true])
	tb_back.connect("pressed", vbc_main, "set_visible", [false])
	tb_back.connect("pressed", pc_intro, "set_visible", [true])
	le_search.connect("text_entered", self, "_on_LineEditSearch_text_entered")
	le_search.connect("text_validated", self, "_on_LineEditSearch_text_validated")
	tb_skip_back.connect("pressed", self, "_on_PlaybackButton_pressed", [0, false])
	tb_rewind.connect("pressed", self, "_on_PlaybackButton_pressed", [-Constants.DELTA])
	tb_fast_forward.connect("pressed", self, "_on_PlaybackButton_pressed", [Constants.DELTA])
	tb_skip_forward.connect("pressed", self, "_on_PlaybackButton_pressed", [999])
	tb_play_pause.connect("toggled", self, "_on_TextureButtonPlayPaused_toggled")
	tb_stop.connect("pressed", self, "_on_TextureButtonStop_pressed")
	tb_info.connect("toggled", pc_info, "set_visible")
	tb_razcore.connect("pressed", OS, "shell_open", [Constants.URLS.razcore])
	tb_pexels.connect("pressed", OS, "shell_open", [Constants.URLS.pexels])
	tween.connect("tween_all_completed", self, "_search")
	
	OS.min_window_size = Constants.MIN_WINDOW_SIZE
	pc_intro.setup(_config_file)
	vbc_main.visible = false
	pc_intro.visible = true


func _load_config() -> void:
	if _config_file.load(Constants.CONFIG_FILE.path) != OK:
		var message := "ERROR: loading config file from: {path}"
		pc_notification.trigger(message.format(Constants.CONFIG_FILE))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_search"):
		var node := get_focus_owner()
		le_search.release_focus() if node == le_search else le_search.grab_focus()


func _on_LineEditSearch_text_entered(new_text: String) -> void:
	tb_play_pause.pressed = not tb_play_pause.disabled


func _on_LineEditSearch_text_validated(new_text: String) -> void:
	tb_play_pause.disabled = new_text.length() < 3


func _on_PlaybackButton_pressed(delta: float, is_relative := true) -> void:
	if is_relative:
		delta += tween.tell()
	tween.seek(delta)


func _on_TextureButtonPlayPaused_toggled(is_button_pressed: bool) -> void:
	if is_button_pressed:
		_search()


func _on_TextureButtonStop_pressed() -> void:
	tween.remove_all()
	pc_info.refresh()
	tr_image.texture = tr_placeholder
	pb.value = 0


func _search() -> void:
	if le_search.text.length() < 3:
		return
	
	pb.max_value = sb_time_input.value
	_session.search(le_search.text)
	var photo = yield(_session, "photo_fetched")
	tr_image.texture = photo.texture
	pc_info.refresh(photo)
	tween.interpolate_property(pb, "value", pb.min_value, pb.max_value, sb_time_input.value)
	tween.interpolate_property(pb, "modulate", PB_COLORS.begin, PB_COLORS.end, sb_time_input.value - LAST, Tween.TRANS_SINE, Tween.EASE_IN)
	tween.interpolate_property(pb, "modulate", PB_COLORS.end, PB_COLORS.last, LAST, Tween.TRANS_LINEAR, Tween.EASE_IN, sb_time_input.value - LAST)
	tween.start()
