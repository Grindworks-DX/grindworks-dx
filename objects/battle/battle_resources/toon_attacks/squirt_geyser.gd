extends GagSquirt
class_name SquirtGeyser

const PROP := preload('res://models/props/gags/geyser-revamp/geyser_gag.tscn')
const SFX := preload('res://audio/sfx/battle/gags/squirt/AA_squirt_Geyser.ogg')


func action() -> void:
	var player: Player = user
	
	var water_color := Color.WHITE
	if Util.get_player().stats.has_item('Witch Hat'):
		water_color = Color(0, 0.43, 0.151)
	
	# Movie Start
	var movie := manager.create_tween()
	
	# Press button
	movie.tween_callback(battle_node.focus_character.bind(player))
	movie.tween_callback(press_button)
	movie.tween_interval(2.4)
	movie.tween_callback(AudioManager.play_sound.bind(SFX))
	movie.tween_interval(1.0)
	movie.tween_callback(battle_node.focus_cogs)
	
	var submovies: Array[Tween] = []
	
	for cog: Cog in targets:
		var geyser := PROP.instantiate()
		geyser.get_node('Geyser').water_color = water_color
		
		var submovie := manager.create_tween()
		submovie.tween_interval(randf_range(0.01, 0.8))
		
		# Spawn geyser
		submovie.tween_callback(battle_node.add_child.bind(geyser))
		submovie.tween_callback(geyser.set_global_position.bind(cog.body_root.global_position))
		
		submovie.tween_callback(geyser.get_node('AnimationPlayer').play.bind('squirt'))
		
		var hit: bool = manager.roll_for_accuracy(self) or cog.lured 
		if hit:
			if not get_immunity(cog):
				submovie.tween_callback(s_hit.emit)
				# Play geyser anim, parent cog to cog root
				submovie.tween_callback(cog_flyup.bind(cog))
				submovie.tween_callback(manager.affect_target.bind(cog, damage))
				submovie.tween_interval(0.01)
				submovie.tween_callback(cog.reset_physics_interpolation)
				submovie.tween_callback(cog.body_root.reparent.bind(geyser.get_node('CogRoot')))
				submovie.tween_interval(0.5)
				# Knockback damage here
				if cog.lured:
					var kb_dmg := manager.get_knockback_damage(cog)
					submovie.tween_callback(manager.battle_text.bind(cog, '-' + str(kb_dmg), BattleText.colors.orange[0], BattleText.colors.orange[1]))
					submovie.tween_callback(func(): cog.stats.hp -= kb_dmg)
				submovie.tween_callback(apply_debuff.bind(cog))
				submovie.tween_interval(1.75)
				submovie.tween_callback(manager.battle_text.bind(cog, "Drenched!", BattleText.colors.orange[0], BattleText.colors.orange[1]))
				submovie.tween_callback(cog_slip.bind(cog))
				submovie.tween_callback(cog.body_root.reparent.bind(cog))
				submovie.tween_callback(func(): cog.body_root.position.y = 0.0)
				submovie.tween_interval(2.0)
				if cog.lured:
					submovie.tween_callback(manager.force_unlure.bind(cog))
					submovie.tween_callback(cog.set_animation.bind('walk'))
					submovie.tween_property(cog.body_root, 'position:z', 0.0, 0.5)
					submovie.tween_callback(cog.set_animation.bind('neutral'))
			else:
				submovie.tween_callback(manager.battle_text.bind(cog, "IMMUNE"))
				submovie.tween_interval(4.0)
		else:
			submovie.tween_callback(cog.set_animation.bind('sidestep-left'))
			submovie.tween_callback(manager.battle_text.bind(cog, "MISSED"))
			submovie.tween_interval(5.0)
		
		submovie.tween_callback(geyser.queue_free)
		#submovie.pause()
		submovies.append(submovie)
	
	for i in submovies.size():
		var submovie = submovies[i]
		movie.parallel().tween_subtween(submovie)
		if i == submovies.size() - 1:
			await submovie.finished
	
	await movie.finished
	await manager.check_pulses(targets)

func cog_flyup(cog : Cog) -> void:
	cog.set_animation('slip-backward')
	cog.animator.speed_scale = 0.5
	#Task.delay(1.0).connect(cog.pause_animator)
	Task.delay(2.0).connect(cog.animator.set.bind("speed_scale", 1.0))

func cog_slip(cog : Cog) -> void:
	cog.set_animation('slip-backward')
	match cog.dna.suit:
		CogDNA.SuitType.SUIT_A:
			cog.animator_seek(2.43)
		CogDNA.SuitType.SUIT_B:
			cog.animator_seek(1.94)
		CogDNA.SuitType.SUIT_C:
			cog.animator_seek(2.58)

func get_knockback_damage() -> int:
	return 0
