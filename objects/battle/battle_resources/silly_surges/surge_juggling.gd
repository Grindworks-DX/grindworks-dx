extends SillySurge
class_name SurgeJuggling

func action():
	var toon = user.toon
	
	manager.battle_node.focus_character(user)
	
	var cubes: Node3D = load('res://models/props/gags/cubes/cubes.tscn').instantiate()
	toon.hip_bone.add_child(cubes)
	cubes.rotate_y(deg_to_rad(180.0))
	
	cubes.get_node('AnimationPlayer').play('juggle')
	await manager.sleep(0.1)
	user.set_animation('juggle')
	await manager.sleep(1.0)
	manager.show_action_name(action_name + "!", summary, true)
	AudioManager.play_sound(load('res://audio/sfx/battle/gags/toonup/AA_heal_juggle.ogg'))
	await manager.sleep(3.0)
	impact()
	user.toon.speak(MovieUtil.big_laughs[randi() % MovieUtil.big_laughs.size()])
	await manager.barrier(user.animator.animation_finished, 5.0)
	toon.set_animation('neutral')

func impact(_target: Actor = null) -> void:
	if level not in range(values.size() + 1):
		printerr("Surge: Level out of bounds")
		return
	
	var current_values: Dictionary = values[level - 1]
	
	var status = current_values['status']
	if status is StatusEffect:
		status = status.duplicate(true)
		status.target = user
		manager.add_status_effect(status)
	
	var healing_percent = current_values['healing_percent']
	if healing_percent is float:
		manager.affect_target(user, -1 * ceili(user.stats.max_hp * healing_percent))
	
	BattleService.s_action_impact.emit(self)

func get_stats() -> String:
	if !level > 0: return get_general_stats()
	var moves = values[level - 1].get('status').moves
	var healing_percent = values[level - 1].get('healing_percent')
	var string := "Affects: All Toons\nHeals %s Laff (%d)\nGives %s this round" % [
			Util.float_to_perc(healing_percent),
			ceili(user.stats.max_hp * healing_percent),
			"%d Move%s" % [moves, "s" if moves > 1 else ""]
		]
	return string

func get_general_stats() -> String:
	var string := "Affects: All Toons\nHeals %s Max Laff\nGives %s this round" % [
			(func() -> String:
				var __out := ""
				
				for i in values.size():
					__out += Util.float_to_perc(values[i].get('healing_percent'))
					if i < values.size() - 1:
						__out += " / "
				return __out).call(),
			(func() -> String:
				var __out := ""
				
				for i in values.size():
					__out += str(values[i].get('status').moves)
					if i < values.size() - 1:
						__out += " / "
					if i == values.size() - 1:
						__out += " Moves"
				return __out).call(),
			]
	return string
