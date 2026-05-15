extends ToonAttack
class_name GagThrow

const FALLBACK_THROW_SFX := preload('res://audio/sfx/battle/gags/throw/AA_pie_throw_only.ogg')

@export var model: PackedScene
@export var piece_models: Array[PackedScene]:
	get():
		if piece_models.is_empty():
			return [model]
		return piece_models
@export var scale: float = 1.0
@export var splat_color: Color = Color.WHITE
@export var splat_sfx: AudioStream
@export var present_sfx: AudioStream
@export var throw_sfx: AudioStream
@export var miss_sfx: AudioStream
@export var status_effect: StatusEffect
@export var status_effect_base: StatusEffect

@export var sweetspot_damage := 15

func action():
	user = Util.get_player()
	var aoe = targets.size() > 1
	
	user.face_position(targets[0].global_position if !aoe else manager.battle_node.global_position)
	var _throwable = model.instantiate()
	user.toon.right_hand_bone.add_child(_throwable)
	_throwable.scale *= scale
	_throwable.rotation_degrees.y += 180.0
	user.set_animation('pie-throw')
	manager.s_focus_char.emit(user)
	if present_sfx:
		AudioManager.play_sound(present_sfx)

	if action_name == "Birthday Cake":
		_throwable.get_node("AnimationPlayer").play("candles")
	
	if !aoe:
		await [
			func():
				await manager.sleep(2.545)
				manager.s_focus_char.emit(targets[0]),
			func():
				await manager.sleep(1.245)
				set_camera_angle("SIDE_RIGHT")
				await manager.sleep(1.3),
			#func():
				#await manager.sleep(1.545)
				#manager.battle_node.focus_cogs()
				#await manager.sleep(1.0)
		].pick_random().call()
	else:
		await manager.sleep(1.545)
		manager.battle_node.focus_cogs()
		await manager.sleep(1.0)
	
	if not throw_sfx:
		AudioManager.play_sound(FALLBACK_THROW_SFX)
	else:
		AudioManager.play_sound(throw_sfx)
	await manager.sleep(0.07)
	_throwable.queue_free()
	
	var movie = manager.create_tween()
	
	var submovies: Array[Tween] = []
	
	for i in targets.size():
		var throw_tween = manager.create_tween()
		var cog = targets[i]
		var throwable: Node3D
		# cut the cake!
		throwable = model.instantiate()
		throwable.scale *= scale
		if action_name == 'Wedding Cake' and aoe:
			throwable = get_wedding_cake_piece(throwable, i)
		user.toon.right_hand_bone.add_child(throwable)
		throwable.top_level = true
		throwable.look_at(cog.global_position, Vector3.BACK)
		throwable.rotate_y(-90)
		throw_tween.tween_property(throwable, 'global_position', cog.head_node.global_position, randf_range(0.3, 0.4))
		
		# Roll for accuracy
		var hit: bool = manager.roll_for_accuracy(self) or cog.lured
		
		if hit:
			var do_sweetspot := manager.is_target_debuffed(cog)
			user.face_position(manager.battle_node.global_position)
			throw_tween.tween_callback(throwable.queue_free)
			
			var immune := get_immunity(cog)
			
			if not immune:
				var throw_damage: int = manager.get_damage(damage + (sweetspot_damage if do_sweetspot else 0), self, cog)
				throw_tween.tween_callback(manager.affect_target.bind(cog, damage + (sweetspot_damage if do_sweetspot else 0), false, "\nSweetspot!" if do_sweetspot else ""))
				if status_effect:
					throw_tween.tween_callback(apply_status_effect)
				if user.throw_heals:
					throw_tween.tween_callback(user.quick_heal.bind(roundi(throw_damage * user.stats.get_stat("throw_heal_boost"))))
			else:
				throw_tween.tween_callback(manager.battle_text.bind(cog, "IMMUNE"))
			
			var splat = load("res://objects/battle/effects/splat/splat.tscn").instantiate()
			splat.modulate = splat_color
			throw_tween.tween_callback(cog.head_node.add_child.bind(splat))
			if splat_sfx:
				throw_tween.tween_callback(AudioManager.play_sound.bind(splat_sfx))
			
			if not immune:
				if not cog.lured:
					throw_tween.tween_callback(cog.set_animation.bind('pie-small'))
				else:
					throw_tween.tween_callback(manager.knockback_cog.bind(cog))
				throw_tween.tween_callback(do_dizzy_stars.bind(cog))
					
			
		else:
			cog.set_animation('sidestep-left')
			if miss_sfx:
				AudioManager.play_sound(miss_sfx)
			throwable.queue_free()
			manager.battle_text(cog, "MISSED")
		
		throw_tween.tween_interval(2.0)
		submovies.append(throw_tween)
		
	for i in submovies.size():
		var submovie = submovies[i]
		movie.parallel().tween_subtween(submovie)
		if i == submovies.size() - 1:
			await submovie.finished
	
	await movie.finished
	await manager.check_pulses(targets)

func get_stats() -> String:
	super()

	if Util.get_player().throw_heals:
		var player_stats: PlayerStats
		if is_instance_valid(BattleService.ongoing_battle):
			player_stats = BattleService.ongoing_battle.battle_stats[Util.get_player()]
		else:
			player_stats = Util.get_player().stats
		#string += "\nSelf-Heal: %s%%" % roundi(player_stats.get_stat('throw_heal_boost') * 100)
	
	stat_string += "\nSweetspot: %s" % [get_true_damage(1.0, sweetspot_damage + damage)]

	return stat_string

func apply_status_effect() -> void:
	var base_effect = status_effect_base.duplicate()
	if not base_effect is StatusEffect:
		printerr("GagThrow: Status Effect path does not lead to status effect!!!")
		return
	StatusEffect.safe_copy_effect(status_effect, base_effect)
	for target in targets:
		var effect: StatusEffect = base_effect.duplicate()
		effect.target = target
		manager.add_status_effect(effect)

func get_wedding_cake_piece(cake: Node3D, idx := 0) -> Node3D:
	var piece = cake.get_node(NodePath('wedding_cake/cake%s' % (['1', '2', '3', 'top'][idx % 4]))).duplicate()
	manager.battle_node.add_child(piece)
	piece.scale /= (scale * scale)
	cake.queue_free()
	piece.position = Vector3.ZERO
	return piece
	
