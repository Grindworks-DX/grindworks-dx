@tool
extends StatusEffect
class_name StatusLured

enum LureType {
	STUN,
	DAMAGE_DOWN
}

@export var lure_type := LureType.STUN
@export var knockback_effect := 10
@export var damage_debuff := StatMultiplier.new('damage', -0.3, false)
@export var accuracy_debuff := -0.3

func apply() -> void:
	stacks = get_true_knockback()
	var cog: Cog = target
	cog.lured = true
	cog.get_node('Body').position.z = Globals.SUIT_LURE_DISTANCE
	if lure_type == LureType.STUN:
		manager.skip_turn(cog)
		cog.stunned = true
	else:
		var stats: BattleStats = manager.battle_stats[cog]
		stats.multipliers.append(damage_debuff)
		stats.accuracy += accuracy_debuff

func get_description() -> String:
	var return_string := "Knockback Damage: %d" % get_true_knockback()
	if lure_type == LureType.DAMAGE_DOWN:
		var dmg_nerf: String = str(roundi(damage_debuff.amount * 100.0))
		var acc_nerf: String = str(roundi((accuracy_debuff) * 100.0))
		return_string += "\n%s%% Damage\n%s%% Accuracy" % [dmg_nerf, acc_nerf]
	return return_string

func expire() -> void:
	target.lured = false
	var walk_tween := create_walk_tween()
	await walk_tween.finished
	walk_tween.kill()
	if lure_type == LureType.DAMAGE_DOWN:
		manager.battle_stats[target].multipliers.erase(damage_debuff)
		manager.battle_stats[target].accuracy -= accuracy_debuff
	else:
		target.stunned = false 
		# Breaking Grounds: No longer acts after unluring - instead gains Lure Resistance
		var new_effect := apply_lure_immunity()
		new_effect.rounds -= 1
		manager.unskip_turn(target)
		await manager.run_actions()

func get_true_knockback() -> int:
	var stats: BattleStats
	if BattleService.ongoing_battle is BattleManager: stats = BattleService.ongoing_battle.battle_stats[Util.get_player()]
	else: stats = Util.get_player().stats
	return roundi(knockback_effect * stats.get_stat('damage') * stats.get_track_effectiveness('Lure'))

func create_walk_tween() -> Tween:
	var cog: Cog = target
	var battle_node := manager.battle_node
	
	var walk_tween := manager.create_tween()
	walk_tween.tween_callback(cog.set_animation.bind('walk'))
	walk_tween.tween_callback(battle_node.focus_character.bind(cog))
	walk_tween.tween_callback(cog.animator.set_speed_scale.bind(-1.0))
	walk_tween.tween_property(cog.get_node('Body'), 'position:z', 0.0, 0.5)
	walk_tween.tween_callback(cog.set_animation.bind('neutral'))
	walk_tween.tween_callback(cog.animator.set_speed_scale.bind(1.0))
	return walk_tween

func get_effect_string() -> String:
	match lure_type:
		LureType.STUN: return 'While Lured: Stun'
		_: return 'While Lured: %s DMG' % Util.float_to_perc(damage_debuff.amount)

func get_status_name() -> String:
	return "Lured"

func apply_lure_immunity() -> StatusEffect:
	# Breaking Grounds: Stun lures apply temporary Lure Immunity when expired
	var lure_immunity: StatusEffectGagImmunity = load("res://objects/battle/battle_resources/status_effects/resources/status_effect_gag_immunity.tres").duplicate(true)
	if lure_immunity.id not in manager.get_status_ids_for_target(target):
		lure_immunity.set_track(load("res://objects/battle/battle_resources/gag_loadouts/gag_tracks/lure.tres"))
		lure_immunity.rounds = 1
		lure_immunity.target = target
		manager.add_status_effect(lure_immunity)
		Task.delay(1.0).connect(manager.battle_text.bind(target, "Lure Immunity!", BattleText.colors.orange[0], BattleText.colors.orange[1]))
	return lure_immunity
