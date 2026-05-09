extends ItemScript

var player: Player
var mult := 2.0

func on_collect(_item: Item, _object: Node3D) -> void:
	player = Util.get_player()
	for track in player.stats.character.gag_loadout.loadout:
		var gag = track.gags[6]
		gag.damage *= mult
		if gag is GagLure:
			gag.lure_effect.knockback_effect *= mult

func on_load(_item: Item) -> void:
	player = Util.get_player()

func on_item_removed() -> void:
	for track in player.stats.character.gag_loadout.loadout:
		var gag = track.gags[6]
		gag.damage /= mult
		if gag is GagLure: gag.lure_effect.knockback_effect /= mult
