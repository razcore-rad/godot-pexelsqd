extends Control

const LAST := 3
const PB_COLORS := {
	"begin": Color("004c566a"),
	"end": Color("4c566a"),
	"last": Color("d08770")
}

const PCNotification := preload("res://PexelsQD/PanelContainerNotification.tscn")

var _is_first := true
var _session: Session = null
var _tr_image_placeholder: StreamTexture = null
var _tween_funcs := {}

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
onready var tb_help: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonHelp
onready var tb_razcore: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonRazcore
onready var tb_pexels: TextureButton = $VBoxContainerMain/HBoxContainerControls/TextureButtonPexels
onready var pb: ProgressBar = $VBoxContainerMain/ProgressBar
onready var tr_image: TextureRect = $VBoxContainerMain/TextureRectImage
onready var pc_info: PanelContainer = $PanelContainerInfo
onready var pc_help: PanelContainer = $PanelContainerHelp
onready var rtl_help: RichTextLabel = $PanelContainerHelp/RichTextLabelHelp
onready var tween: Tween = $Tween
onready var http_request: HTTPRequest = $HTTPRequest


func _ready() -> void:
	var config_file := _load_config()
	var api_key: String = config_file.get_value(Constants.CONFIG_FILE.section, Constants.CONFIG_FILE.key, "")
	_session = Session.new(api_key, http_request)
	_tr_image_placeholder = tr_image.texture
	_tween_funcs[true] = funcref(tween, "start")
	_tween_funcs[false] = funcref(tween, "stop_all")
	
	if not api_key.empty():
		vbc_main.visible = true
		pc_intro.visible = false
	
	_session.connect("notified", self, "_notify")
	pc_intro.connect("notified", self, "_notify")
	tb_next.connect("pressed", vbc_main, "set_visible", [true])
	tb_back.connect("pressed", vbc_main, "set_visible", [false])
	tb_back.connect("pressed", pc_intro, "set_visible", [true])
	tb_back.connect("pressed", pc_help, "set_visible", [false])
	le_search.connect("text_entered", self, "_on_LineEditSearch_text_entered")
	le_search.connect("text_validated", self, "_on_LineEditSearch_text_validated")
	tb_skip_back.connect("pressed", self, "_seek", [0, false])
	tb_rewind.connect("pressed", self, "_seek", [-Constants.DELTA])
	tb_fast_forward.connect("pressed", self, "_seek", [Constants.DELTA])
	tb_skip_forward.connect("pressed", self, "_seek", [pb.max_value])
	tb_play_pause.connect("toggled", self, "_on_TextureButtonPlayPaused_toggled")
	tb_stop.connect("pressed", self, "_on_TextureButtonStop_pressed")
	tb_info.connect("toggled", pc_info, "set_visible")
	tb_help.connect("toggled", pc_help, "set_visible")
	tb_razcore.connect("pressed", OS, "shell_open", [Constants.URLS.razcore])
	tb_pexels.connect("pressed", OS, "shell_open", [Constants.URLS.pexels])
	pc_info.cr.connect("gui_input", self, "_on_PanelContainerInfoColorRect_gui_input")
	tween.connect("tween_all_completed", self, "_search")
	
	OS.min_window_size = Constants.MIN_WINDOW_SIZE
	pc_intro.setup(config_file)
	rtl_help.bbcode_text = rtl_help.bbcode_text.format([Constants.DELTA])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_quit"):
		get_tree().quit()
	elif event.is_action_pressed("ui_search"):
		var node := get_focus_owner()
		le_search.release_focus() if node == le_search else le_search.grab_focus()
	elif event.is_action_pressed("ui_color_copy"):
		var new_event := InputEventAction.new()
		new_event.action = "left_click"
		new_event.pressed = true
		_on_PanelContainerInfoColorRect_gui_input(new_event)


func _on_LineEditSearch_text_entered(new_text: String) -> void:
	tb_play_pause.pressed = not tb_play_pause.disabled


func _on_LineEditSearch_text_validated(new_text: String) -> void:
	tb_play_pause.disabled = new_text.length() < 3


func _on_TextureButtonPlayPaused_toggled(is_button_pressed: bool) -> void:
	_tween_funcs[is_button_pressed].call_func()
	if _is_first:
		_tween_funcs[true] = funcref(tween, "resume_all")
		_is_first = not _is_first


func _on_TextureButtonStop_pressed() -> void:
	tr_image.texture = _tr_image_placeholder
	pb.value = pb.min_value
	tb_play_pause.pressed = false
	pc_info.refresh()
	tween.remove_all()


func _on_PanelContainerInfoColorRect_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		OS.clipboard = pc_info.html_color
		_notify("{0} copied to clipboard!".format([OS.clipboard]))


func _load_config() -> ConfigFile:
	var config_file := ConfigFile.new()
	if config_file.load(Constants.CONFIG_FILE.path) != OK:
		_notify("ERROR: loading config file.")
	return config_file


func _search() -> void:
	if le_search.text.length() < 3:
		return
	
	_session.search(le_search.text)
	var photo = yield(_session, "photo_fetched")
	
	if tb_play_pause.pressed:
		tween.remove_all()
		pc_info.refresh(photo)
		tr_image.texture = photo.texture
		pb.max_value = sb_time_input.value
		tween.interpolate_property(pb, "value", pb.min_value, pb.max_value, sb_time_input.value)
		tween.interpolate_property(pb, "modulate", PB_COLORS.begin, PB_COLORS.end, sb_time_input.value - LAST, Tween.TRANS_SINE, Tween.EASE_IN)
		tween.interpolate_property(pb, "modulate", PB_COLORS.end, PB_COLORS.last, LAST, Tween.TRANS_LINEAR, Tween.EASE_IN, sb_time_input.value - LAST)
		tween.start()


func _seek(delta: float, is_relative := true) -> void:
	if is_relative:
		delta += tween.tell()
	tween.seek(delta)


func _notify(message: String) -> void:
	var pc_notification := PCNotification.instance()
	pc_notification.get_node("Label").text = message
	add_child(pc_notification)
