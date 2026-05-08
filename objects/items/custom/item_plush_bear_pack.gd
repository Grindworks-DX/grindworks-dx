extends ItemScript

# TODO: defense rework

const STAT_BOOST := "res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres"
const BOOST_AMT := 0.65

var is_active := true

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_round_started.connect(on_round_start)
	BattleService.s_battle_started.connect(func(_x): is_active = true)

func on_round_start(actions: Array[BattleAction]) -> void:
	for action in actions:
		if action is ToonAttack and not action.special_action_exclude:
			return
	if is_active:
		apply_boost()
		is_active = false

func apply_boost() -> void:
	var boost: StatBoost = load(STAT_BOOST).duplicate(true)
	boost.boost = BOOST_AMT
	boost.rounds = 0
	boost.stat = 'defense'
	boost.quality = StatusEffect.EffectQuality.POSITIVE
	boost.target = Util.get_player()
	boost.multiplicative = true
	BattleService.ongoing_battle.add_status_effect(boost)
	Util.get_player().boost_queue.run_text("Biiig hug!", Color(0.235, 0.278, 0.431, 1.0))
