extends TextureButton

const ICONS = {
	"play": preload("res://assets/icons/playback/play.svg"),
	"play-disabled": preload("res://assets/icons/playback/play-disabled.svg"),
	"play-hover": preload("res://assets/icons/playback/play-hover.svg"),
	"pause": preload("res://assets/icons/playback/pause.svg"),
	"pause-disabled": preload("res://assets/icons/playback/pause-disabled.svg"),
	"pause-hover": preload("res://assets/icons/playback/pause-hover.svg")
}


func _ready() -> void:
	connect("toggled", self, "_on_toggled")


func _on_toggled(is_button_pressed: bool) -> void:
	var which := "pause" if is_button_pressed else "play"
	texture_normal = ICONS[which]
	texture_disabled = ICONS["{0}-disabled".format([which])]
	texture_hover = ICONS["{0}-hover".format([which])]
