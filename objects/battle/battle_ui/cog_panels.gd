extends HBoxContainer

const COG_PANEL := preload('res://objects/battle/battle_ui/cog_panel.tscn')

func _ready() -> void:
	var scales = [Vector2(0.9, 0.9), Vector2(1.08, 1.08)]
	BattleService.s_round_started.connect(func(_x):
		LerpProperty.new(self, ^'scale', 1.0, scales[0], scales[1], false, Tween.EaseType.EASE_OUT, Tween.TransitionType.TRANS_QUAD).as_tween(self).play()
	)
	BattleService.s_round_ended.connect(func(_x):
		LerpProperty.new(self, ^'scale', 1.0, scales[1], scales[0], false, Tween.EaseType.EASE_OUT, Tween.TransitionType.TRANS_QUAD).as_tween(self).play()
	)

func assign_cogs(cogs: Array[Cog]):
	var panels = get_children()
	for panel in panels:
		panel.call_deferred("queue_free")

	for cog in cogs:
		var new_panel := COG_PANEL.instantiate()
		
		add_child(new_panel)
		new_panel.set_cog(cog)

func reset(_gags):
	pass
	# i have no idea what calls this
	#for child in get_children():
	#	child.queue_free()
