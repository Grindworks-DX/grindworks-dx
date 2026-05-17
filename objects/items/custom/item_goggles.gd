extends ItemScript

# Breaking Grounds - no longer uses timers; instead removes ability to undo gag choices

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_start)

## Connect the gag track elements up to be shuffled
func on_battle_start(manager: BattleManager) -> void:
	await manager.s_ui_initialized
	initialize_ui(manager)

func initialize_ui(manager: BattleManager) -> void:
	var ui := manager.battle_ui
	for element: Control in ui.gag_tracks.get_children():
		element.s_refreshing.connect(on_track_refresh)
		element.refresh()
	ui.target_select.back.hide()
	ui.target_select.back.disabled = true

## Shuffles the gag order of each track
func on_track_refresh(element: Control) -> void:
	var unlocked: int = element.unlocked
	if unlocked > 0:
		element.gags = element.gags.slice(0,unlocked)
		element.gags.shuffle()
