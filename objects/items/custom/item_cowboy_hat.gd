extends ItemScript

const PUNCH_BOOST := 1

## Houses the Cogs currently in battle, and how many times they've been targeted
var current_cogs: Dictionary[Cog, int] = {}

var battle_already_rewarded := false

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_start)
	BattleService.s_battle_ended.connect(on_battle_end)
	BattleService.s_action_started.connect(on_action_start)

func on_battle_start(manager: BattleManager) -> void:
	battle_already_rewarded = false
	manager.s_participant_died.connect(on_participant_died)
	manager.s_participant_joined.connect(on_participant_joined)
	for cog in manager.cogs:
		current_cogs[cog] = 0

func on_battle_end() -> void:
	current_cogs.clear()

func on_action_start(action: BattleAction) -> void:
	if action is ToonAttack:
		if action is GagLure:
			assess_lure_targets(action.targets)
		elif not action is GagTrap:
			for cog: Cog in action.targets:
				current_cogs[cog] += 1

func on_participant_died(participant: Variant) -> void:
	if participant is Cog:
		if not BattleService.cog_gives_credit(participant): return
		if current_cogs.keys().has(participant):
			if current_cogs[participant] == 1 and !battle_already_rewarded:
				Util.get_player().stats.punch += PUNCH_BOOST
				BattleService.ongoing_battle.battle_stats[Util.get_player()].punch += PUNCH_BOOST
				Util.get_player().boost_queue.queue_text("Deadeye!", Color(0.937, 0.278, 0.278))
				battle_already_rewarded = true

func on_participant_joined(participant: Variant) -> void:
	if participant is Cog:
		current_cogs[participant] = 0

func assess_lure_targets(targets: Array) -> void:
	for cog: Cog in targets:
		if is_instance_valid(cog.trap):
			current_cogs[cog] += 1
