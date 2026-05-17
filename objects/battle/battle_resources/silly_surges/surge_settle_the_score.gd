extends SillySurge
class_name SurgeSettle

static var taunt_phrases := [
	'Hit me with your best shot!',
	'You can\'t touch this.',
	'Cat got your tongue?',
	'Why so serious?',
	'I rate you one star out of five!',
	'It takes two to tango, you wanna tango?',
	'Booooooring!!',
	'You stink!'
]

static var taunt_phrases_desperation := [
	'Is that all you got?!',
	'I can do this all day.',
	'You\'ll NEVER green me!',
	'I\'m just getting started!',
	'Just try and stop me!',
	'Are you even trying?',
	'This dance ends when I say it ends!',
	'You REALLY stink!!'
]

func action() -> void:
	var toon: Toon = user.toon
	var desperation = float(user.stats.hp) / float(user.stats.max_hp) < desperation_threshold
	var phrases := taunt_phrases if !desperation else taunt_phrases_desperation 
	
	manager.battle_node.focus_character(user)
	
	await manager.sleep(0.1)
	user.set_animation('toss')
	await manager.sleep(1.0)
	toon.set_emotion(toon.Emotion.LAUGH if !desperation else toon.Emotion.ANGRY)
	toon.speak(phrases.pick_random())
	manager.show_action_name(action_name + "!", summary, true)
	#AudioManager.play_sound(load('res://audio/sfx/battle/gags/toonup/AA_heal_juggle.ogg'))
	await manager.sleep(1.0)
	impact()
	await manager.barrier(user.animator.animation_finished, 5.0)
	toon.set_animation('neutral')
	toon.set_emotion(toon.Emotion.NEUTRAL)

func impact(_target = null) -> void:
	if level not in range(values.size() + 1):
		printerr("Surge: Level out of bounds")
		return
	
	var current_values: Dictionary = values[level - 1]
	
	for status in current_values.get('statuses'):
		if status is StatusEffect: status = status.duplicate(true)
		status.target = user
		manager.add_status_effect(status)
	
	var late_status: StatusEffectLate = load("res://objects/battle/battle_resources/status_effects/resources/status_effect_late_worm.tres")
	late_status.target = user
	manager.add_status_effect(late_status)
	
	user.stats.restock_tick(current_values.get('restock_ticks'))

func get_stats() -> String:
	if !level > 0: return get_general_stats()
	var defense = values[level - 1].get('statuses')[0].boost
	var restock_ticks = values[level - 1].get('restock_ticks')
	var string := "Cogs Attack First\n%sx Defense\nTrigger %d Restock Ticks" % [
			str(defense + 1.0),
			restock_ticks,
		]
	return string

func get_general_stats() -> String:
	var string := "Cogs Attack First\n%s Defense\nTrigger %s Restock Ticks" % [
			(func() -> String:
				var __out := ""
				
				for i in values.size():
					__out += "%sx" % str(values[i].get('statuses')[0].boost + 1.0)
					if i < values.size() - 1:
						__out += " / "
				return __out).call(),
			(func() -> String:
				var __out := ""
				
				for i in values.size():
					__out += str(values[i].get('restock_ticks'))
					if i < values.size() - 1:
						__out += " / "
				return __out).call(),
			]
	return string
