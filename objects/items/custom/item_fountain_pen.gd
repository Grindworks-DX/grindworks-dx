extends ItemScript

const STAT_BOOST := "res://objects/battle/battle_resources/status_effects/resources/status_effect_stat_boost.tres"
const BOOST_AMT := 0.5

var count := 0:
	set(x):
		count = x
		if count is int: count_changed()
var count_label: Label

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
			x.battle_ui.s_gag_selected.connect(on_gag_selected)
			x.battle_ui.s_gag_canceled.connect(on_gag_canceled)
	)

func on_gag_selected(gag: BattleAction):
	var player := Util.get_player()
	
	if gag.track is Track:
		if gag.track.track_name not in player.stats.gags_unlocked.keys(): return
		
	
	count = count + 1 if count + 1 < threshold else 0
	
func on_gag_canceled(gag: BattleAction):
	var player := Util.get_player()
	
	if gag.track is Track:
		if gag.track.track_name not in player.stats.gags_unlocked.keys(): return
		
	
	count = count - 1 if count - 1 > 0 else threshold - 1

func on_item_icon_assigned(item_icon: ItemIcon) -> void:
	count_label = item_icon.counter_label
	count_label.show()

func count_changed() -> void:
	if count_label is Label:
		count_label.text = str(count)
