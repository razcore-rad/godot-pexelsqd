extends PanelContainer


onready var rtl_author: RichTextLabel = $CenterContainer/VBoxContainer/RichTextLabelAuthor
onready var cr: ColorRect = $CenterContainer/VBoxContainer/ColorRect


func _ready() -> void:
	cr.connect("gui_input", self, "_on_ColorRect_gui_input")
	rtl_author.connect("meta_clicked", OS, "shell_open")


func _on_ColorRect_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		OS.clipboard = "#{0}".format([cr.color.to_html(false)])


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
