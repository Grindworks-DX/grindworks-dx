extends ItemScript

# Breaking Grounds - Add a battle timer after the first Cog is destroyed

# This item runs a x second battle timer on every round

## Battle Timer created by Util
var timer: GameTimer

var timer_seconds_base := 20
var timer_seconds_per_speed := 2

var current_time := 20

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_start)

func activate_timer() -> void:
	var player := Util.get_player()
	current_time = get_time(BattleService.ongoing_battle.battle_stats[player].speed)
	player.stats.battle_timers.append(current_time)
	
	BattleService.ongoing_battle.battle_stats[player].s_speed_changed.connect(func(x):
		player.stats.battle_timers.erase(current_time)
		current_time = get_time(x)
		player.stats.battle_timers.append(current_time)
	)

func get_time(speed: int) -> int:
	return timer_seconds_base + (timer_seconds_per_speed * speed)

func on_battle_start(manager: BattleManager) -> void:
	BattleService.s_cog_died.connect(activate_timer.unbind(1), CONNECT_ONE_SHOT)
	await manager.s_ui_initialized
	initialize_ui(manager)
	BattleService.s_battle_ended.connect(on_battle_ended)

func on_battle_ended() -> void:
	if BattleService.is_connected('s_cog_died', activate_timer): BattleService.s_cog_died.disconnect(activate_timer)
	var player := Util.get_player()
	if current_time in player.stats.battle_timers: player.stats.battle_timers.erase(current_time)

func initialize_ui(manager: BattleManager) -> void:
	var ui := manager.battle_ui
	ui.s_turn_complete.connect(on_turn_complete)

func on_turn_complete(_gags: Array[ToonAttack]) -> void:
	if is_instance_valid(timer) and not timer.is_queued_for_deletion():
		timer.queue_free()
