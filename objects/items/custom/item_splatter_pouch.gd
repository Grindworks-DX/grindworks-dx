extends ItemScript

var base_chance := 0.6

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	if not Util.get_player():
		await Util.s_player_assigned
	var player := Util.get_player()
	player.stats.s_humor_healing_triggered.connect(on_humor_healing)

func on_humor_healing() -> void:
	var stats = Util.get_player().stats
	if randf() < (base_chance + stats.luck):
		stats.restock_tick()
