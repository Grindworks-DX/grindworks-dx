extends Node

func _ready() -> void:
	call_deferred(&"connect_viewport")
	
func connect_viewport() -> void:
	var viewport: Viewport = get_viewport()
	viewport.gui_focus_changed.connect(
		func(x: Control):
			print(x)
	)
