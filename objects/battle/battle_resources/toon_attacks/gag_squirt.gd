extends ToonAttack
class_name GagSquirt

const DEBUFF := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_drenched.tres")
const POISON_COLOR := Color(0, 0.43, 0.151)

@export var drenched_speed := -2

func soak_opponent(who: Node3D, from: Node3D, time: float) -> void:
	var splash: Node3D = load('res://models/props/gags/water_splash/water_splash_untextured.tscn').instantiate()
	user.add_child(splash)
	if Util.get_player().stats.has_item('Witch Hat'):
		splash.set_color(POISON_COLOR)
	splash.global_position = from.global_position
	await splash.spray(who.global_position,time)
	splash.queue_free()

func apply_debuff(target: Cog) -> void:
	var new_effect: StatBoost = DEBUFF.duplicate(true)
	new_effect.target = target
	new_effect.boost = drenched_speed #get_player_stats().get_stat('squirt_defense_boost')
	manager.add_status_effect(new_effect)

func get_player_stats() -> PlayerStats:
	if is_instance_valid(BattleService.ongoing_battle):
		return BattleService.ongoing_battle.battle_stats[Util.get_player()]
	else:
		return Util.get_player().stats

func get_stats() -> String:
	super()
		
	stat_string += "\nOn Hit: %d Speed" % drenched_speed
	
	if Util.get_player().stats.has_item('Witch Hat'):
		stat_string += "\nOn Hit: Poison"
	
	return stat_string
