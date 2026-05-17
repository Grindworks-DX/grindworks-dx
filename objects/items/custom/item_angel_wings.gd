extends ItemScript

const STAT_BOOST := "res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres"
const BOOST_AMT := 0.3
static var points_needed := 9

var count := 0:
	set(x):
		count = x
		if count is int: count_changed()

var threshold := 10

var is_active := true
var buffed_gags: Array[ToonAttack] = []

func on_collect(_item: Item, _model: Node3D) -> void:
	super(_item, _model)
	setup()

func on_load(_item: Item) -> void:
	super(_item)
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(
		func(x: BattleManager):
			x.battle_ui.s_gags_updated.connect(on_gags_updated.unbind(1))
			x.battle_ui.s_gag_selected.connect(on_gags_updated.unbind(1))
			x.s_round_started.connect(on_round_started)
			x.s_round_ended.connect(on_gags_updated)
	)

func on_gags_updated():
	var player := Util.get_player()
	
	count = player.stats.gag_balance.values().filter(func(x): return x == points_needed).size()

func on_round_started(_actions) -> void:
	if count > 0:
		Util.get_player().boost_queue.queue_text("Divine Power!", Color(0.816, 0.845, 0.943, 1.0))
		var status_effect: StatBoost = load(STAT_BOOST).duplicate(true)
		status_effect.stat = 'damage'
		status_effect.quality = StatBoost.EffectQuality.POSITIVE
		status_effect.boost = BOOST_AMT * count
		status_effect.target = Util.get_player()
		status_effect.rounds = 0
		BattleService.ongoing_battle.add_status_effect(status_effect)
	

func count_changed() -> void:
	if count_label is Label:
		count_label.text = str(count)
