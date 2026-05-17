extends ItemScript

# Breaking Grounds - +5% Defense; +3% Defense per Shrug point
var base_defense := 0.05
var defense_per_shrug := 0.03

var mult: StatMultiplier

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	if not Util.get_player():
		await Util.s_player_assigned
	var player := Util.get_player()
	player.stats.s_shrug_changed.connect(on_shrug_changed)
	create_multiplier()
	on_shrug_changed(player.stats.shrug)

func create_multiplier() -> void:
	mult = StatMultiplier.new()
	mult.stat = 'defense'
	mult.amount = 0.0
	mult.additive = true
	Util.get_player().stats.multipliers.append(mult)

func on_shrug_changed(new_value: int) -> void:
	mult.amount = new_value * defense_per_shrug
