extends ToonAttack
class_name GagLure

const LURED_EFFECT := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_lured.tres")

@export var lure_effect: StatusLured
var trap_gags: Array[GagTrap] = []
# Required for crit storage to work properly
var current_activating_trap: GagTrap = null

func get_stats() -> String:
	if not lure_effect:
		return "NO LURE EFFECT SET UP"

	var knockback_damage: int = lure_effect.get_true_knockback()
	stat_string = "Knockback Damage: " + str(knockback_damage) + "\n"\
	+ "Affects: "
	match target_type:
		ActionTarget.SELF:
			stat_string += "Self"
		ActionTarget.ENEMIES:
			stat_string += "All Cogs"
		ActionTarget.ENEMY:
			stat_string += "One Cog"
		ActionTarget.ENEMY_SPLASH:
			stat_string += "Three Cogs"
	stat_string += "\n" + lure_effect.get_effect_string()
	stat_string += "\nRounds: " + str(get_lure_rounds())
	return stat_string


## Get a properly ID'd version of the lure effect specified
func get_lure_effect() -> StatusLured:
	var new_effect := LURED_EFFECT.duplicate(true)
	
	# Copy the attributes from the reference value
	if lure_effect:
		new_effect.quality = StatusEffect.EffectQuality.NEGATIVE
		new_effect.icon = icon
		new_effect.lure_type = lure_effect.lure_type
		new_effect.knockback_effect = lure_effect.knockback_effect
		new_effect.damage_debuff = lure_effect.damage_debuff
		new_effect.accuracy_debuff = lure_effect.accuracy_debuff
	
	return new_effect

func apply_lure(who: Cog) -> void:
	var effect := get_lure_effect()
	effect.target = who
	effect.rounds = get_lure_rounds()
	#if not who == main_target:
		#effect.damage_debuff.amount -= effect.damage_debuff.amount / 2.0
	manager.add_status_effect(effect)

func get_lure_rounds() -> int:
	var base_rounds := lure_effect.rounds
	if self is LureFish: base_rounds += Util.get_player().stats.lure_fish_round_boost
	return base_rounds

func effect_battle_text(target: Actor) -> void:
	match lure_effect.lure_type:
		StatusLured.LureType.STUN:
			manager.battle_text(target, "Stunned!", BattleText.colors.orange[0], BattleText.colors.orange[1])
		StatusLured.LureType.DAMAGE_DOWN:
			manager.battle_text(target, "Damage Down!", BattleText.colors.orange[0], BattleText.colors.orange[1])
			Task.delay(1.0).connect(manager.battle_text.bind(target, "Accuracy Down!", BattleText.colors.orange[0], BattleText.colors.orange[1]))
