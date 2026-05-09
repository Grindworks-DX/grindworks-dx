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
	if randf() < (base_chance + BattleService.ongoing_battle.battle_stats[Util.get_player()].luck):
		Util.get_player().boost_queue.queue_text("Splatter restock!", Color(0.593, 0.143, 0.562, 1.0))
		Util.gett_player().stats.restock_tick()
