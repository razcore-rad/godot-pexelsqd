extends PanelContainer


var html_color: String = "" setget , get_html_color

onready var rtl_author: RichTextLabel = $CenterContainer/VBoxContainer/RichTextLabelAuthor
onready var cr: ColorRect = $CenterContainer/VBoxContainer/ColorRect


func _ready() -> void:
	rtl_author.connect("meta_clicked", OS, "shell_open")


func refresh(photo: Dictionary = {}) -> void:
	if photo.empty():
		rtl_author.bbcode_text = ""
		cr.color = Color.white
		cr.visible = false
	else:
		var text := "[right][url={photographer_url}]{photographer}[/url][/right]"
		rtl_author.bbcode_text = text.format(photo)
		cr.color = photo.avg_color
		cr.visible = true


func get_html_color() -> String:
	return "#{0}".format([cr.color.to_html(false)])
