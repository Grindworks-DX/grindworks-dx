extends ItemCharSetup

func first_time_setup(player: Player) -> void:
	var stats := player.stats
	stats.gag_effectiveness['Sound'] = 1.1
	stats.gag_regen_chance_modifiers['Sound'] += 0.3
