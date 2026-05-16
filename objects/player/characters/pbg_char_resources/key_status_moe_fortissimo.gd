@tool
extends StatusEffect

@export var boosts := {
	'luck': 0.03,
	'speed': 1,
}
@export var refresh_rounds := 2

var turn_multiplier := StatMultiplier.new('turns', -2, true)
var multipliers: Dictionary[String, StatMultiplier] = {}

var conductor_item: ItemMoeConductor = null

var accent_stacks: int:
	get:
		return conductor_item.accent_effect.stacks

func apply():
	var stats = target.get_battle_stats()
	for stat in boosts.keys():
		var multiplier = StatMultiplier.new(stat, 0.0, true)
		stats.multipliers.append(multiplier)
		multipliers.set(stat, multiplier)
	manager.battle_stats[target].multipliers.append(turn_multiplier)
	manager.battle_ui.refresh_turns()
	conductor_item.accent_effect.s_stacks_changed.connect(accent_stacks_updated.unbind(1))
	manager.s_action_finished.connect(on_action_finished)
	accent_stacks_updated()

func expire():
	cleanup()
	manager.expire_status_effect(conductor_item.accent_effect)

func stacks_updated() -> void:
	target.get_battle_stats().s_turns_changed.emit(turn_multiplier.amount, -2 + stacks)
	turn_multiplier.amount = -2 + stacks
	manager.battle_ui.refresh_turns()

func accent_stacks_updated() -> void:
	if multipliers.is_empty(): await s_applied
	for stat in boosts.keys():
		multipliers[stat].amount = boosts[stat] * accent_stacks

func on_action_finished(action: BattleAction) -> void:
	if action.user != target or action is not ToonAttack: return
	if action.track is not Track and action.action_name != "Pass": return
	
	if BattleAction.ActionTag.CHAR_MOE_CUE in action.action_tags:
		rounds += 1
	else:
		rounds -= 1
		if !rounds > 0:
			manager.expire_status_effect(self)

func get_description() -> String:
	return "+%d Speed\n+%s Luck\n%s\nAccented Gags give +30%% Evasiveness and add 1 Round\nPassing or using regular gags removes 1 round" % \
	[
		boosts['speed'] * accent_stacks,
		Util.float_to_perc(boosts['luck'] * accent_stacks),
		("%s%d Move%s" % [
			"+" if turn_multiplier.amount > 0 else "",
			turn_multiplier.amount,
			"s" if absi(turn_multiplier.amount) > 1 else ""
		]) if turn_multiplier.amount != 0 else ""
	]

func cleanup() -> void:
	manager.s_action_finished.disconnect(on_action_finished)
	if conductor_item.accent_effect is StatusEffect:
		conductor_item.accent_effect.s_stacks_changed.disconnect(accent_stacks_updated)
	if target:
		manager.battle_stats[target].multipliers.erase(turn_multiplier)
		for multiplier in multipliers.values():
			var stats = target.get_battle_stats()
			stats.multipliers.erase(multiplier)
			stats.s_stat_changed.emit(multiplier.stat)
