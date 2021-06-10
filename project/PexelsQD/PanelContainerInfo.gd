extends PanelContainer

const DEFAULT_COLOR := Color("00ffffff")

var html_color: String = "" setget , get_html_color

onready var l_trt: Label = $CenterContainer/VBoxContainer/LabelTotalResultsText
onready var rtl_photo: RichTextLabel = $CenterContainer/VBoxContainer/RichTextLabelPhoto
onready var rtl_author: RichTextLabel = $CenterContainer/VBoxContainer/RichTextLabelAuthor
onready var cr: ColorRect = $CenterContainer/VBoxContainer/ColorRect


func _ready() -> void:
	rtl_author.connect("meta_clicked", OS, "shell_open")


func refresh(photo: Dictionary = {}) -> void:
	if photo.empty():
		rtl_photo.bbcode_text = ""
		rtl_author.bbcode_text = ""
		l_trt.text = ""
		cr.color = DEFAULT_COLOR
	else:
		rtl_photo.bbcode_text = "[url={url}]Photo Link[/url]".format(photo)
		rtl_author.bbcode_text = "[right][url={photographer_url}]{photographer}[/url][/right]".format(photo)
		l_trt.text = "%d" % photo.total_results
		cr.color = photo.avg_color


func get_html_color() -> String:
	return "#{0}".format([cr.color.to_html(false)])
