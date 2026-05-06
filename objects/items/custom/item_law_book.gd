extends ItemScriptActive


func use() -> void:
	AudioManager.play_sound(load('res://audio/sfx/ui/GUI_stickerbook_open.ogg'))
	for cog in BattleService.ongoing_battle.cogs:
		cog.delayed = true
	BattleService.ongoing_battle.populate_enemy_moves(true, true)
	Util.get_player().boost_queue.queue_text("Lay down the law!", Color(0.659, 0.801, 0.89))
