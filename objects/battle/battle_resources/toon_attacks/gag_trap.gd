extends ToonAttack
class_name GagTrap

const TRAP_EFFECT := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_trapped.tres")
const GULLIBLE_EFFECT := preload("res://objects/battle/battle_resources/status_effects/resources/status_effect_gullible.tres")

@export var gullible_defense := -0.2

# Signals when trap movie is over
signal s_trap
signal s_activate

var baked_crit_chance := 0.0
var activating_lure: GagLure = null

# Runs when a Cog is lured into the trap
func activate():
	pass

## Get a properly ID'd version of the trap effect specified
func get_trap_effect() -> StatusTrapped:
	var new_effect := TRAP_EFFECT.duplicate(true)
	new_effect.quality = StatusEffect.EffectQuality.NEGATIVE
	new_effect.gag = self
	new_effect.rounds = -1
	new_effect.stacks = get_true_damage()
	s_activate.connect(manager.expire_status_effect.bind(new_effect))
	
	return new_effect

func apply_trap_effect(who: Cog) -> void:
	var effect := get_trap_effect()
	effect.target = who
	manager.add_status_effect(effect)

func apply_debuff(who: Cog) -> void:
	var effect := GULLIBLE_EFFECT.duplicate(true)
	effect.boost = gullible_defense
	effect.target = who
	manager.add_status_effect(effect)

func apply_extra_knockback(cog: Cog) -> void:
	if not activating_lure:
		# Honestly, let's just fake it.
		var lure_effect: StatusLured = manager.find_cog_lure(targets[0])
		if not lure_effect:
			return
		activating_lure = GagLure.new()
		activating_lure.lure_effect = lure_effect
	
	if (not Util.get_player()) or is_equal_approx(Util.get_player().stats.trap_knockback_percent, 0.0):
		return

	var boost_percent: float = Util.get_player().stats.trap_knockback_percent
	manager.do_standalone_knockback_damage(cog, roundi(activating_lure.get_lure_effect().get_true_knockback() * boost_percent))

func get_stats() -> String:
	var string := "Damage: " + str(get_true_damage()) + "\n"\
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
		
	string += "\nOn Hit: %d%% Defense" % ceili(gullible_defense * 100)
	
	if Util.get_player().stats.has_item('Witch Hat'):
		string += "\nOn Hit: Poison"
	
	return string
