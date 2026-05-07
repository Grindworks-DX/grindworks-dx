extends ItemScript

var humor_effectiveness := 0.5

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	var player := Util.get_player()
	player.stats.s_toonup_used.connect(on_toonup_used)

func on_toonup_used(_gag: ToonAttack) -> void:
	var player := Util.get_player()
	player.stats.do_humor_healing(humor_effectiveness)
