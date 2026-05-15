extends ToonAttack
class_name GagDrop

const DEBUFF := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_aftershock.tres")

@export var rounds := 1

var skip_button_movie := false

func get_stats() -> String:
	super()
	if rounds > -1:
		stat_string += "\nAftershock: %d" % get_true_damage(0.5)
		stat_string += "\nRounds: %d" % (rounds + 1 + Util.get_player().stats.get_stat("drop_aftershock_round_boost"))

	return stat_string

func apply_debuff(target: Cog, damage_dealt: int) -> void:
	if rounds < 0: return
	var new_effect: StatEffectAftershock = DEBUFF.duplicate(true)
	new_effect.amount = roundi(damage_dealt * 0.5)
	new_effect.target = target
	new_effect.rounds = rounds
	if user.stats.get_stat("drop_aftershock_round_boost") != 0:
		new_effect.rounds += user.stats.get_stat("drop_aftershock_round_boost")
	manager.add_status_effect(new_effect)
