extends ItemScript

var cogs_to_try: Array[Cog] = []
var cogs_already_affected: Array[Cog] = []

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_start)
	BattleService.s_battle_ended.connect(func():
		cogs_to_try.clear()
		cogs_already_affected.clear()
	)

func on_battle_start(manager: BattleManager) -> void:
	manager.s_round_started.connect(on_round_start.bind(manager))
	manager.s_cog_delayed.connect(on_cog_delayed)

func on_cog_delayed(cog: Cog) -> void:
	if cog not in cogs_already_affected: cogs_to_try.append(cog)

func on_round_start(_actions: Array[BattleAction], manager: BattleManager) -> void:
	if cogs_to_try.is_empty(): return
	
	var cogs_acted: Array[Cog] = []
	for action in manager.round_actions:
		if action.user is Cog and action.user not in cogs_acted:
			cogs_acted.append(action.user)
	
	# Skip Cogs' first turn
	for cog in cogs_to_try:
		if !is_instance_valid(cog): continue
		if !randf() < 0.5 or cog.delayed: continue
		for i in range(manager.round_actions.size() - 1, -1, -1):
			var action := manager.round_actions[i]
			if action.user == cog:
				manager.round_actions.remove_at(i)
				Util.get_player().boost_queue.queue_text("Cog Turn Skipped!", Color(0.659, 0.801, 0.89))
		cogs_already_affected.append(cog)
	
	for cog in cogs_acted:
		if cog in cogs_to_try and cogs_already_affected: cogs_to_try.erase(cog)

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()
