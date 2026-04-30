extends Resource
class_name BattleStats


# Multiplicative
@export var damage := 1.0:
	set(x):
		damage = x
		if self is PlayerStats:
			print('damage set to ' +str(x))
		s_damage_changed.emit(x)
		s_stat_changed.emit('damage')
@export var defense := 1.0:
	set(x):
		defense = x
		if self is PlayerStats:
			print('defense set to ' + str(x))
		s_defense_changed.emit(x)
		s_stat_changed.emit('defense')
@export var evasiveness := 1.0:
	set(x):
		evasiveness = x
		if self is PlayerStats:
			print('evasiveness set to ' + str(x))
		s_evasiveness_changed.emit(x)
		s_stat_changed.emit('evasiveness')
@export var accuracy := 1.0:
	set(x):
		accuracy = x
		if self is PlayerStats:
			print('accuracy set to ' + str(x))
		s_accuracy_changed.emit(x)
		s_stat_changed.emit('accuracy')
@export var luck := 1.0:
	set(x):
		luck = x
		s_luck_changed.emit(x)
		s_stat_changed.emit('luck')
		print("Luck set to %.2f" % x)

## STAT CLAMPS
static var STAT_CLAMPS: Dictionary[String, Vector2] = {
	'speed' : Vector2(0, 127),
	'damage' : Vector2(0.0, UNCAPPED_STAT_VAL),
	'defense' : Vector2(0.1, UNCAPPED_STAT_VAL),
	'evasiveness' : Vector2(0.0, UNCAPPED_STAT_VAL),
	'luck' : Vector2(1.0, UNCAPPED_STAT_VAL),
}
const UNCAPPED_STAT_VAL := -999.0

# Breaking Grounds: Speed is now an internal battlestat instead
@export var speed := 1:
	set(x):
		speed = x
		if self is PlayerStats:
			print('speed set to ' + str(x))
		s_speed_changed.emit(x)
		s_stat_changed.emit('speed')
# Breaking Grounds: mooooooves
@export var max_turns := 4


# Additive
@export var max_hp := 25:
	set(x):
		max_hp = x
		max_hp_changed.emit(x)
@export var hp := 25:
	set(x):
		if debug_invulnerable:
			hp = max_hp
		else:
			match allow_overheal:
				true: hp = maxi(0, x)
				_: hp = clamp(x, 0, max_hp)
		hp_changed.emit(hp)
@export var turns := 1
var debug_invulnerable := false

var multipliers: Array[StatMultiplier] = []

# Signals for objects listening
signal hp_changed(health: int)
signal max_hp_changed(health: int)

signal s_damage_changed(new_damaage: float)
signal s_accuracy_changed(new_accuracy: float)
signal s_defense_changed(new_defense: float)
signal s_evasiveness_changed(new_evasiveness: float)
signal s_speed_changed(new_speed: float)
signal s_luck_changed(new_luck: float)

signal s_stat_changed(stat: String)

## Modifiers
var allow_overheal := false


func _to_string():
	var return_string := "Stats: \n"
	var active = false 
	for property in get_property_list():
		if not active and property.name != 'damage':
			continue
		elif property.name == 'damage': 
			active = true
		return_string += property.name + ': ' + str(get(property.name)) + '\n'
	return return_string

func get_stat(stat: String):
	if stat in self:
		var base_stat = get(stat)
		var additive_total := 0.0
		var multiplier_total := 1.0
		for multiplier in multipliers:
			if multiplier.stat == stat:
				if multiplier.additive:
					additive_total += multiplier.amount
				else:
					multiplier_total += multiplier.amount
		return clamp_stat(stat, (base_stat + additive_total) * multiplier_total)
	else:
		return 1.0

## Can be added to over time if stats need to be hard capped
func clamp_stat(stat : String, amount):
	if stat in STAT_CLAMPS.keys():
		var stat_min := STAT_CLAMPS[stat].x
		var stat_max := STAT_CLAMPS[stat].y
		if is_equal_approx(stat_min, UNCAPPED_STAT_VAL):
			return minf(amount, stat_max)
		elif is_equal_approx(stat_max, UNCAPPED_STAT_VAL):
			return maxf(amount, stat_min)
		return clamp(amount, stat_min, stat_max)
	return amount

func get_stat_as_percent(stat : String) -> int:
	var stat_as_float: float = get_stat(stat)
	var stat_as_int: int = roundi(stat_as_float * 100.0)
	return stat_as_int

#region Breaking Grounds

# Attributes: New stats that modify internal stats

signal s_punch_changed(new_value: int)
signal s_humor_changed(new_value: int)
signal s_gusto_changed(new_value: int)
signal s_shrug_changed(new_value: int)

# Punch: +5% damage | +4% Parry chance
@export var punch := 0:
	set(x):
		if Util.player_exists():
			attribute_changed('punch', punch, x)
		punch = x
		if self is PlayerStats:
			print('punch set to ' +str(x))
		s_punch_changed.emit(x)
		s_stat_changed.emit('punch')
		
# Humor: +4 Laff | +2 Laff on Cog Destroyed
@export var humor := 0:
	set(x):
		if Util.player_exists():
			attribute_changed('humor', humor, x)
		humor = x
		if self is PlayerStats:
			print('humor set to ' +str(x))
		s_humor_changed.emit(x)
		s_stat_changed.emit('humor')
		
# Gusto: +1 Speed | +10% Gag Regen
@export var gusto := 0:
	set(x):
		if Util.player_exists():
			attribute_changed('gusto', gusto, x)
		gusto = x
		#if self is PlayerStats:
		print('gusto set to ' +str(x))
		s_gusto_changed.emit(x)
		s_stat_changed.emit('gusto')
		
# Shrug: +1 Luck | +4% Dodge Chance
@export var shrug := 0:
	set(x):
		if Util.player_exists():
			attribute_changed('shrug', shrug, x)
		shrug = x
		if self is PlayerStats:
			print('shrug set to ' +str(x))
		s_shrug_changed.emit(x)
		s_stat_changed.emit('shrug')

# New mechanic stats
@export var parry := 0.0 # TODO
@export var heal_on_kill := 0 # TODO
@export var gag_regen_chance := 0.0 # TODO

var attribute_modifiers := {
	'punch': { 'damage': 0.05, 'parry': 0.04 },
	'humor': { 'max_hp': 4, 'heal_on_kill': 2 },
	'gusto': { 'speed': 1, 'gag_regen_chance': 0.10 },
	'shrug': { 'luck': 0.03, 'evasiveness': 0.04 },
}

# TODO: call this correctly

func attribute_changed(attr: String, old_value, new_value) -> void:
	if attr not in attribute_modifiers.keys(): return
	
	var difference = new_value - old_value
	var modifiers = attribute_modifiers[attr]
	for key in modifiers:
		var value = difference * modifiers[key]
		set(key, get(key) + value)
		if key == 'max_hp':
			if value > 0:
				hp += value
			if hp > max_hp:
				hp = max_hp
			
