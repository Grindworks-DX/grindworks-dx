extends BattleStats
class_name PlayerStats

## For all stats that are specific to the player

## Money
@export var money := 0:
	set(x):
		if x > money:
			s_gained_money.emit()
		money = x
		if money < 0:
			money = 0
		s_money_changed.emit(x)
		if money >= 100:
			Globals.s_hundred_jellybeans.emit()
signal s_money_changed(value: int)
signal s_gained_money
@export var money_mult := 1.0

@export var items: Array[Item] = []

## Gag Dicts
@export var gags_unlocked: Dictionary[String, int] = {}
@export var gag_balance: Dictionary[String, int] = {}
var debug_gag_points := false
@export var gag_effectiveness: Dictionary[String, float] = {}
@export var gag_regeneration: Dictionary[String, int] = {} # TODO: Deprecate in favor of regen rolls
@export var gag_vouchers: Dictionary[String, int] = {}
@export var bean_vouchers: Dictionary[int, int] = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
@export var gag_battle_start_point_boost: Dictionary[String, int] = {}
@export var global_battle_start_point_boost := 0
@export var toonups: Dictionary[int, int] = {0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 0}
@export var treasures: Dictionary[int, int] = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0}

# Breaking Grounds - Combat starts at fixed gag point values and with varying regen rates
@export var gag_starting_points: Dictionary[String, int] = {}
@export var gag_regen_chance_modifiers: Dictionary[String, float] = {}
@export var gag_point_caps: Dictionary[String, int] = {} # TODO

# Breaking Grounds: Gag cap is per track; gag_cap increases all tracks
@export var gag_cap := 0
@export var gag_discount := -1
@export var character: PlayerCharacter
@export var quests: Array[Quest]
@export var quest_rerolls := 3
@export var pink_slips := 0
@export var agility := 1.0:
	set(x):
		agility = x
		s_agility_changed.emit(x)
		s_stat_changed.emit('agility')
		print("Agility set to %.2f" % x)

# Breaking Grounds - beeeeg crits
@export var crit_mult := 2.0:
	set(x):
		crit_mult = x
		s_stat_changed.emit('crit_mult')
@export var mod_cog_dmg_mult := 1.0
@export var shop_discount := 0
@export var healing_effectiveness := 1.0

# Gag specific boosts
@export var throw_heal_boost := 0.15
@export var squirt_defense_boost := -0.2
@export var drop_aftershock_round_boost := 0
@export var trap_knockback_percent := 0.0
@export var lure_fish_round_boost := 0

@export var anomaly_boost := 0
# Extra value on laff boosts
@export var laff_boost_boost := 0
@export var extra_lives := 0:
	set(x):
		extra_lives = x
		s_extra_lives_changed.emit(x)
signal s_extra_lives_changed(value: int)
signal s_agility_changed(new_agility: float)

@export var toonup_boost := 1.0  # MULTIPLICATIVE
@export var toonup_round_boost := 0

@export var sellbot_boost := 1.0
@export var cashbot_boost := 1.0
@export var lawbot_boost := 1.0
@export var bossbot_boost := 1.0

@export var proxy_chance_boost := 0.0
@export var proxy_health_mod := 1.0

@export var extra_jumps := 0

# How low do cogs HP need to be to die?
@export var cog_hp_death_threshold := 0.0

## Weird Stuff
@export var stranger_chance := 0.0:
	set(x): stranger_chance = maxf(0.0, x)


## Currently held active item
@export var current_active_item: ItemActive:
	set(x):
		if actives_in_reserve.size() < active_reserve_size and current_active_item:
			if current_active_item.node and not current_active_item.node.is_removing:
				actives_in_reserve.append(current_active_item)
		if x in actives_in_reserve: 
			actives_in_reserve.erase(x)
		if x == null and not actives_in_reserve.is_empty():
			x = actives_in_reserve.pop_front()
		current_active_item = x
		s_active_item_changed.emit(x)
signal s_active_item_changed(new_item: ItemActive)
@export var actives_in_reserve: Array[ItemActive] = []
@export var active_reserve_size := 0:
	set(x):
		active_reserve_size = x
		while actives_in_reserve.size() > active_reserve_size:
			drop_active(actives_in_reserve.pop_back())


@export var battle_timers: Array[int] = []

## For pause screen display
var prev_stats: Dictionary[String, float] = {}


## Sets the player's base gag loadout
func set_loadout(loadout: GagLoadout) -> void:
	var gag_dicts := [gags_unlocked, gag_balance, gag_effectiveness, gag_regeneration, gag_vouchers, gag_battle_start_point_boost, gag_starting_points, gag_regen_chance_modifiers, gag_point_caps]
	for dict in gag_dicts:
		dict.clear()
		for track in loadout.loadout:
			var value 
			match gag_dicts.find(dict):
				0: value = track.base_level
				5: value = 0
				1, 8: value = track.base_gp_cap
				2: value = track.base_effectiveness
				3: value = 1
				6: value = track.base_combat_start_gp
				7: value = track.base_regen
				_: value = 1
			dict[track.track_name] = value

func first_time_setup() -> void:
	if character:
		character = character.duplicate(true)
		set_loadout(character.gag_loadout)
		if character.base_stats:
			for stat in [
				'damage',
				'defense',
				'evasiveness',
				'accuracy',
				'luck',
				'speed',
				'turns',
				'max_turns',
			]:
				set(stat, character.base_stats.get(stat))
		for attribute in [
			'punch',
			'humor',
			'gusto',
			'shrug'
		]:
			var value = character.starting_attributes[attribute]
			attribute_changed(attribute, 0, value)
			set(attribute, value)
	
	initialize()

func initialize_quests() -> void:
	# Breaking Grounds - NO QUESTS HEHEHE
	return
	# Quest setup
	#if quests.is_empty():
		#for i in 4:
			#var new_quest := QuestCog.new()
			#new_quest.goal_dept = i as CogDNA.CogDept
			#new_quest.setup()
			#quests.append(new_quest)

func clear_quests(clear_check := true) -> void:
	for quest: Quest in quests.duplicate(true):
		if not quest.is_complete() or not clear_check:
			quests.erase(quest)
			ItemService.items_in_play.erase(quest.item_reward)

func initialize() -> void:
	hp_changed.connect(attempt_revive)
	attributes_initialized = true
	start_stat_monitors()
	monitor_stranger_chance()

func start_stat_monitors() -> void:
	var stat_monitors := ['damage', 'defense', 'evasiveness', 'speed', 'luck', 'crit_mult', 'silly_meter']
	for stat in stat_monitors + attributes:
		prev_stats[stat] = get_stat(stat)

func max_out() -> void:
	if character:
		max_hp = 100
		hp = 100
	for track in gags_unlocked:
		gags_unlocked[track] = 7
		gag_balance[track] = 25
	for key in toonups.keys():
		toonups[key] = 0
	for key in gag_vouchers.keys():
		gag_vouchers[key] = 0
	#turns = max_turns

func get_highest_gag_level() -> int:
	return gags_unlocked.values().max()

func on_round_end(_battle: BattleManager) -> void:
	restock_tick()

func on_battle_started(_battle: BattleManager) -> void:
	for track in gag_balance.keys():
		if not gags_unlocked[track] > 0: continue
		gag_balance[track] = gag_starting_points[track]
		restock(track, roll_gag_regen(track) + gag_battle_start_point_boost.get(track, 0) + global_battle_start_point_boost)
	_battle.battle_stats[Util.get_player()].silly_meter = starting_silly_meter

func restock_tick(amount := 1) -> void:
	print('Restock tick!')
	for track in gag_balance.keys():
		if not gags_unlocked[track] > 0: continue
		restock(track, roll_gag_regen(track, amount))

func restock(track: String, add: int) -> void:
	if debug_gag_points:
		gag_balance[track] = gag_cap
	else:
		gag_balance[track] = min(gag_point_caps[track] + gag_cap, gag_balance[track] + add)

func attempt_revive(_hp: int = 0) -> void:
	if _hp > 0 or extra_lives <= 0:
		return
	
	extra_lives -= 1
	var revive_amount := maxi(1, Util.get_player().stats.max_hp / 2)
	if not Util.get_player().revives_are_hp or extra_lives == 0:
		Util.get_player().quick_heal(revive_amount)
	else:
		hp += revive_amount
		Util.do_3d_text(Util.get_player(), "-1")
	if Util.get_player().state == Player.PlayerState.WALK:
		Util.get_player().do_invincibility_frames()
	
	# Create the unite effect
	if not Util.get_player().revives_are_hp or extra_lives == 0:
		#var unite: GPUParticles3D = load('res://objects/battle/effects/unite/unite.tscn').instantiate()
		#Util.get_player().add_child(unite)
		#Util.get_player().toon.speak("Toons of the world, Toon-Up!")
		Util.get_player().boost_queue.queue_text("Revived!", Color(0.372, 0.568, 1.0, 1.0))
		AudioManager.play_sound(load("res://audio/sfx/misc/Holy_Mackerel.ogg"))

	print('Revived!')

func get_track_effectiveness(track: String) -> float:
	var effectiveness := 1.0
	if track in gag_effectiveness.keys():
		effectiveness = gag_effectiveness[track]
	return maxf(effectiveness, 0.3)

func get_cog_dept_boost(dept: CogDNA.CogDept) -> float:
	match dept:
		CogDNA.CogDept.SELL: return sellbot_boost
		CogDNA.CogDept.CASH: return cashbot_boost
		CogDNA.CogDept.LAW: return lawbot_boost
		CogDNA.CogDept.BOSS: return bossbot_boost
		_: return 1.0

func add_money(amount: int) -> void:
	money += ceili(amount * money_mult)
	SaveFileService.progress_file.jellybeans_collected += amount

func charge_active_item(amount := 1) -> void:
	if current_active_item:
		current_active_item.current_charge += amount
	for item in actives_in_reserve:
		item.current_charge += amount

func has_item(item_name : String) -> bool:
	for item in items:
		if item.item_name == item_name:
			return true
	return false

func get_battle_time() -> int:
	if battle_timers.is_empty():
		return -1
	else:
		return battle_timers.min()

func drop_active(active: ItemActive) -> void:
	var world_item: WorldItem = load('res://objects/items/world_item/world_item.tscn').instantiate()
	world_item.item = active
	var zone: Node = SceneLoader.current_scene
	if is_instance_valid(Util.floor_manager):
		zone = Util.floor_manager.get_current_room()
	zone.add_child(world_item)
	world_item.global_position = Util.get_player().toon.to_global(Vector3(3, 0.25, 0))

## Returns a chance value influenced by luck
func get_luck_weighted_chance(start_chance: float, end_chance: float, max_luck: float) -> float:
	var _luck: float = clampf(luck, 1.0, max_luck)
	return lerpf(start_chance, end_chance, inverse_lerp(1.0, max_luck, _luck))

#region STRANGER TRACKING
## General Rules:
# Starts at 0%
# Anomalies on the floor when the floor *starts* are counted towards stranger chance
# Stranger chance is maintained from floor to floor
# Rolling Stranger resets the chance to 0%

static var stranger_chance_per_anomaly := 0.1

func monitor_stranger_chance() -> void:
	Util.s_floor_started.connect(stranger_check_anomalies)

func stranger_check_anomalies(gfloor: GameFloor) -> void:
	stranger_chance += gfloor.floor_variant.anomalies.size() * stranger_chance_per_anomaly

func run_stranger_roll() -> bool:
	if not SaveFileService.progress_file.proxies_unlocked: return false
	if Util.get_player() and Util.get_player().stranger_guaranteed: return true
	var stranger_roll := RNG.channel(RNG.ChannelStrangerRoll).randf()
	var result := stranger_roll < stranger_chance
	print("Stranger roll was: %f and needed lower than %f" % [stranger_roll, stranger_chance])
	if result:
		stranger_chance = 0.0
	return result

#endregion

#region Breaking Grounds

# Attributes: New stats that modify internal stats

static var attributes: Array[String] = ['punch', 'humor', 'gusto', 'shrug']

signal s_punch_changed(new_value: int)
signal s_humor_changed(new_value: int)
signal s_gusto_changed(new_value: int)
signal s_shrug_changed(new_value: int)

# Punch: +5% damage | +4% Parry chance
@export var punch := 0:
	set(x):
		if Util.player_exists() and attributes_initialized:
			attribute_changed('punch', punch, x)
		punch = x
		if self is PlayerStats:
			print('punch set to ' +str(x))
		s_punch_changed.emit(x)
		s_stat_changed.emit('punch')
		
# Humor: +4 Laff | +2 Laff on Cog Destroyed
@export var humor := 0:
	set(x):
		if Util.player_exists() and attributes_initialized:
			attribute_changed('humor', humor, x)
		humor = x
		if self is PlayerStats:
			print('humor set to ' +str(x))
		s_humor_changed.emit(x)
		s_stat_changed.emit('humor')
		
# Gusto: +1 Speed | +10% Gag Regen
@export var gusto := 0:
	set(x):
		if Util.player_exists() and attributes_initialized:
			attribute_changed('gusto', gusto, x)
		gusto = x
		#if self is PlayerStats:
		print('gusto set to ' +str(x))
		s_gusto_changed.emit(x)
		s_stat_changed.emit('gusto')
		
# Shrug: +1 Luck | +4% Dodge Chance
@export var shrug := 0:
	set(x):
		if Util.player_exists() and attributes_initialized:
			attribute_changed('shrug', shrug, x)
		shrug = x
		if self is PlayerStats:
			print('shrug set to ' +str(x))
		s_shrug_changed.emit(x)
		s_stat_changed.emit('shrug')

@export var attributes_initialized := false

# New mechanic stats
@export var parry := 0.0 # TODO
@export var humor_healing := 0.0
@export var gag_regen_chance := 0.0

@export var humor_healing_multiplier := 1.0 

static var attribute_modifiers := {
	'punch': { 'damage': 0.05, 'parry': 0.04 },
	'humor': { 'max_hp': 3, 'humor_healing': 1.0 },
	'gusto': { 'speed': 1, 'gag_regen_chance': 0.05, 'starting_silly_meter': 1 },
	'shrug': { 'luck': 0.04, 'evasiveness': 0.05 },
}

func attribute_changed(attr: String, old_value, new_value) -> void:
	if attr not in attribute_modifiers.keys(): return
	
	var difference = new_value - old_value
	var modifiers = attribute_modifiers[attr]
	for key in modifiers:
		var value = difference * modifiers[key]
		print("%s modifying %s by %s" % [attr, key, str(value)])
		if key == 'max_hp':
			set(key, get(key) + value + laff_boost_boost)
			if value > 0:
				hp += value
			if hp > max_hp:
				hp = max_hp
		else:
			set(key, get(key) + value)

@export var jokes := 0
@export var total_jokes := 0

@export var regen_crit_chance := 0.0

func roll_gag_regen(track_name: String, amount := 1) -> int:
	var __out := 0
	var regen_rate := gag_regen_chance + gag_regen_chance_modifiers[track_name]
	for i in range(amount):
		var tick = floori(regen_rate)
		# TODO: implement rng
		var bonus = (randf() < (regen_rate - floori(regen_rate)))
		if bonus: tick += int(bonus)
		# Crit regen: Luck% chance per track to double its regeneration
		if randf() < (luck - 1.0) + regen_crit_chance:
			print("Regen crit! %s" % track_name)
			tick *= 2
		__out += tick
	print("Gag regen: %s gained %d points" % [track_name, __out])
	return __out

signal s_humor_healing_triggered

func do_humor_healing(_effectiveness := 1.0) -> void:
	# this is a hack mb
	var effectiveness := _effectiveness
	if character.character_id == PlayerCharacter.Character.MYSTERY:
		effectiveness *= 2.0
	
	allow_overheal = true
	if BattleService.ongoing_battle is BattleManager:
		BattleService.ongoing_battle.s_round_ended.connect(func(): allow_overheal = false, CONNECT_ONE_SHOT)
		BattleService.ongoing_battle.s_battle_ended.connect(func(): allow_overheal = false, CONNECT_ONE_SHOT)
	Util.get_player().quick_heal(maxi(1, ceili(humor_healing * effectiveness * get_stat('humor_healing_multiplier'))))
	s_humor_healing_triggered.emit()
	if humor_healing * effectiveness > 0:
		Task.delay(0.2).connect(AudioManager.play_sound.bind(load("res://audio/sfx/items/laff_boost_pickup.ogg"), -5.0))

signal s_toonup_used(gag: ToonAttack)

# Silly Meter: Builds in combat by spending gag points

@export var silly_meter := 0:
	set(x):
		silly_meter = x
		s_stat_changed.emit('silly_meter')
@export var starting_silly_meter := 0

func on_action_finished(action: BattleAction) -> void:
	if action is not ToonAttack or action.user != Util.get_player(): return
	action.manager.battle_stats[Util.get_player()].silly_meter += maxi(0, action.price)
