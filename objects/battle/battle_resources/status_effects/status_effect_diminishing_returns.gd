@tool
extends StatusEffect
class_name StatusEffectDiminishingReturns


@export var diminish_factor := 0.8

var just_applied := true

func renew() -> void:
	if just_applied:
		just_applied = false
		return
	stacks = floori(stacks * diminish_factor)
	if stacks <= 0:
		manager.expire_status_effect(self)

func cleanup() -> void:
	Util.get_player().stats.add_money(stacks)
	stacks = 0

func get_description() -> String:
	if stacks == 1:
		return "Defeat this Cog to get 1 jellybean back"
	return "Defeat this Cog to get %d jellybeans back" % stacks

func combine(effect : StatusEffect) -> bool:
	if 'stacks' in effect:
		stacks += effect.stacks
		return true
	return false
