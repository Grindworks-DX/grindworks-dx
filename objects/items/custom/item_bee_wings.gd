extends ItemScript

# Breaking Grounds - bee wings my beloved; adapted for integer speed
# +4% Crit Mult per Speed; +1% Luck per Speed
var crit_multiplier: StatMultiplier
var luck_multiplier: StatMultiplier

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	if not Util.get_player():
		await Util.s_player_assigned
	var player := Util.get_player()
	player.stats.s_speed_changed.connect(on_speed_changed)
	create_multipliers()
	on_speed_changed(player.stats.speed)
	# TODO: add mid-battle multipliers to other applicable items
	BattleService.s_battle_started.connect(on_battle_started)

func on_item_removed() -> void:
	Util.get_player().stats.multipliers.erase(luck_multiplier)
	Util.get_player().stats.multipliers.erase(crit_multiplier)

## Sync multipliers to current speed amount
func on_speed_changed(speed: int) -> void:
	crit_multiplier.amount = maxf(0.0, speed * 0.03)
	luck_multiplier.amount = maxf(0.0, speed * 0.01)

func create_multipliers() -> void:
	crit_multiplier = StatMultiplier.new()
	crit_multiplier.stat = 'crit_mult'
	crit_multiplier.amount = 0.0
	crit_multiplier.additive = true
	Util.get_player().stats.multipliers.append(crit_multiplier)
	
	luck_multiplier = StatMultiplier.new()
	luck_multiplier.stat = 'luck'
	luck_multiplier.amount = 0.0
	luck_multiplier.additive = true
	Util.get_player().stats.multipliers.append(luck_multiplier)

func on_battle_started(manager: BattleManager) -> void:
	var b_crit_multiplier = crit_multiplier.duplicate()
	var b_luck_multiplier = luck_multiplier.duplicate()
	
	var battle_stats = manager.battle_stats[Util.get_player()]
	battle_stats.multipliers.erase(crit_multiplier)
	battle_stats.multipliers.erase(luck_multiplier)
	
	var on_bspeed_changed := func(x: int):
		b_crit_multiplier.amount = maxf(0.0, x * 0.03)
		b_luck_multiplier.amount = maxf(0.0, x * 0.01)
	
	battle_stats.multipliers.append(b_crit_multiplier)
	battle_stats.multipliers.append(b_luck_multiplier)
	
	battle_stats.s_speed_changed.connect(on_bspeed_changed)
	on_bspeed_changed.call(battle_stats.speed)
