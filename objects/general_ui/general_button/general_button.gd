@tool
extends TextureButton
class_name GeneralButton

@export var label: Label
@export var focus_texture: TextureRect
#@export var focus_panel: Panel

#var stylebox: StyleBoxTexture = load("res://general_resources/ui_focus_style_box_texture.tres")

@export var press_sfx: AudioStream
@export var hover_sfx: AudioStream
@export var hover_db_offset := 6.0
@export var press_db_offset := 0.0
@export_multiline var text := "":
	set(x):
		label.text = x
	get:
		return label.text
var font_size: float:
	set(x):
		if x > 0.0: label.label_settings.font_size = x
	get:
		return label.label_settings.font_size

func _ready() -> void:
	pass
	#focus_panel.add_theme_stylebox_override("texture", stylebox)

func on_button_down() -> void:
	if press_sfx:
		AudioManager.play_sound(press_sfx, press_db_offset)

func hover(cursor := false) -> void:
	#stylebox.texture = texture_normal
	#focus_panel.size = 
	# "Button Press" for non-mouse, "Button Release" for mouse
	#z_index += 10
	action_mode = int(!has_focus(true))
	if !cursor:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	focus_texture.visible = has_focus(true)
	AudioManager.play_sound(hover_sfx, hover_db_offset)

func unhover() -> void:
	#z_index -= 10
	focus_texture.visible = false
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and has_focus(true):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().warp_mouse(focus_texture.global_position + event.relative)
		focus_texture.visible = false
		grab_focus(true)
