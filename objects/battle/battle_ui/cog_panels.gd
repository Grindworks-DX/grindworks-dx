extends HBoxContainer

const COG_PANEL := preload('res://objects/battle/battle_ui/cog_panel.tscn')

static var scales := {
	7: Vector2(0.88, 0.88),
	3: Vector2(1.0, 1.0),
	0: Vector2(1.08, 1.08),
	-1: Vector2(0.92, 0.92)
}
static var separations := {
	7: -8,
	5: 10,
	3: 24,
	0: 32
}

signal s_cog_panels_assigned

func _ready() -> void:
	BattleService.s_round_started.connect(lerp_to_action.unbind(1))
	BattleService.s_round_ended.connect(lerp_to_gag_selection.unbind(1))
	scale = Vector2(0.001, 0.001)
	await s_cog_panels_assigned
	lerp_to_gag_selection(0.5)

func lerp_to_action(duration := 1.0) -> void:
	LerpProperty.new(self, ^'scale', duration, scales[-1], func(): return scale, false, Tween.EaseType.EASE_OUT, Tween.TransitionType.TRANS_QUAD).as_tween(self).play()

func lerp_to_gag_selection(duration := 1.0) -> void:
	var new_scale := Vector2(1.0, 1.0)
	for key in scales.keys():
		if get_children().size() < key: continue
		new_scale = scales[key]
		break
	var old_separation := theme.get_constant("separation", "BoxContainer")
	var new_separation := old_separation
	for key in separations.keys():
		if get_children().size() < key: continue
		new_separation = separations[key]
		break
	LerpProperty.new(self, ^'scale', duration, new_scale, func(): return scale, false, Tween.EaseType.EASE_OUT, Tween.TransitionType.TRANS_QUAD).as_tween(self).play()
	if new_separation != old_separation:
		LerpFunc.new(theme.set_constant.bind("separation", "BoxContainer"), duration, old_separation, new_separation, Tween.EaseType.EASE_OUT, Tween.TransitionType.TRANS_QUAD).as_tween(self).play()

func assign_cogs(cogs: Array[Cog]):
	var panels = get_children()
	for panel in panels:
		panel.call_deferred("queue_free")

	for cog in cogs:
		var new_panel := COG_PANEL.instantiate()
		
		add_child(new_panel)
		new_panel.set_cog(cog)
	
	s_cog_panels_assigned.emit()

func reset(_gags):
	pass
	# i have no idea what calls this
	#for child in get_children():
	#	child.queue_free()
