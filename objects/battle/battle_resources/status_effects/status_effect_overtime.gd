@tool
extends StatusEffect
@export var moves := 1

func apply() -> void:
	if target is Cog:
		target.stats.turns += moves
	else:
		manager.battle_stats[target].turns += moves
		manager.battle_ui.refresh_turns()

func expire() -> void:
	if target is Cog: target.stats.turns -= moves
	else:
		manager.battle_stats[target].turns -= moves
		manager.battle_ui.refresh_turns()

#func combine(effect : StatusEffect) -> bool:
	#if effect.rounds > rounds:
		#rounds = effect.rounds
	#return true
