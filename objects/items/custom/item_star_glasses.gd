extends ItemScript

# Breaking Grounds - +7 Speed on first round of combat
var starting_speed := 7

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_started)

func on_battle_started(manager: BattleManager) -> void:
	await get_tree().process_frame
	manager.battle_stats[Util.get_player()].speed += starting_speed
	manager.s_round_ended.connect(reset_moves.bind(manager), CONNECT_ONE_SHOT)
	manager.battle_ui.refresh_turns()

func reset_moves(manager: BattleManager) -> void:
	manager.battle_stats[Util.get_player()].speed -= starting_speed
	manager.battle_ui.refresh_turns()
