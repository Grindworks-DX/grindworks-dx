extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	update_text()
	Util.s_floor_number_changed.connect(update_text)
	Util.s_floor_started.connect(func(_x=null): show())
	Util.s_floor_ended.connect(func(_x=null): hide())
	BattleService.s_battle_started.connect(func(_x=null): hide())
	BattleService.s_battle_ended.connect(func(_x=null): if Util.floor_number != -1: show())

func update_text() -> void:
	text = 'Floor %d' % (Util.floor_number + 1)
