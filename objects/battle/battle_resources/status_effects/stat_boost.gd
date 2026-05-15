@tool
extends StatusEffect
class_name StatBoost

var ICONS := {
	'damage': load("res://ui_assets/battle/statuses/damage.png"),
	'defense': load("res://ui_assets/battle/statuses/defense.png"),
	'evasiveness': load("res://ui_assets/battle/statuses/evasiveness.png"),
	'luck': load("res://ui_assets/battle/statuses/luck_crit.png"),
	'speed': load("res://ui_assets/battle/statuses/speed.png"),
	'delay_resist': load("res://ui_assets/player_ui/pause/time_crunch.png")
}

@export var stat: String = 'defense'
@export var boost: Variant

var multiplier: StatMultiplier

func apply():
	var battle_stats: BattleStats = manager.battle_stats[target]
	if stat in battle_stats:
		if multiplicative:
			multiplier = StatMultiplier.new(stat, boost, false)
			battle_stats.multipliers.append(multiplier)
			stacks_as_percent = false
			stacks_label_prefix = "x"
			stacks = boost + 1.0
		else:
			battle_stats.set(stat,battle_stats.get(stat) + boost)
			if boost is float:
				stacks_as_percent = true
				stacks = roundi(boost * 100.0)
			else:
				stacks = boost

func expire():
	var battle_stats = manager.battle_stats[target]
	if stat in battle_stats:
		if multiplicative: battle_stats.multipliers.erase(multiplier)
		else: battle_stats.set(stat, battle_stats.get(stat) - boost)

func get_description() -> String:
	var __out: String
	if multiplicative:
		__out = "x %s " % str(boost + 1.0)
	else:
		__out = "%s" % "+" if boost > 0.0 else "-"
		__out += "%s%s " % [roundi(abs(boost) * (100 if boost is float else 1)), "%" if boost is float else ""]
	__out += stat.capitalize()
	return __out

func get_icon() -> Texture2D:
	return ICONS[stat]

func get_status_name() -> String:
	return stat.capitalize() + (" Up" if boost > 0.0 else " Down")

func combine(effect: StatusEffect) -> bool:
	if not effect is StatBoost:
		return false
	
	if force_no_combine or effect.force_no_combine:
		return false

	if effect is StatBoost:
		if effect.stat == stat and effect.rounds == rounds and get_quality() == effect.get_quality():
			expire()
			boost = get_combined_boost(boost, effect.boost)
			apply()
			return true
	
	return false

func get_quality() -> EffectQuality:
	if boost >= 0.0:
		return EffectQuality.POSITIVE
	return EffectQuality.NEGATIVE

func randomize_effect() -> void:
	stat = ICONS.keys().pick_random()
	rounds = randi_range(1, 3)
	boost = randf_range(-0.25, 0.25)
	if boost > 0.0:
		quality = StatusEffect.EffectQuality.POSITIVE
	else:
		quality = StatusEffect.EffectQuality.NEGATIVE

func get_combined_boost(boost1, boost2):
	return boost1 + boost2
