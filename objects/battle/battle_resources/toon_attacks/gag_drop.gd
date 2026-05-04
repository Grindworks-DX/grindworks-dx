extends ToonAttack
class_name GagDrop

const DEBUFF := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_aftershock.tres")

@export var rounds := 1

var skip_button_movie := false

func get_stats() -> String:
	var string := "Damage: " + get_true_damage() + "\n"\
	+ "Affects: "
	match target_type:
		ActionTarget.SELF:
			string += "Self"
		ActionTarget.ENEMIES:
			string += "All Cogs"
		ActionTarget.ENEMY:
			string += "One Cog"
		ActionTarget.ENEMY_SPLASH:
			string += "Three Cogs"

	string += "\nAftershock: %s" % get_true_damage(0.5)
	string += "\nRounds: %d" % (rounds + 1 + Util.get_player().stats.get_stat("drop_aftershock_round_boost"))

	return string

func apply_debuff(target: Cog, damage_dealt: int) -> void:
	var new_effect: StatEffectAftershock = DEBUFF.duplicate(true)
	new_effect.amount = roundi(damage_dealt * 0.5)
	new_effect.target = target
	new_effect.rounds = rounds
	if user.stats.get_stat("drop_aftershock_round_boost") != 0:
		new_effect.rounds += user.stats.get_stat("drop_aftershock_round_boost")
	manager.add_status_effect(new_effect)
