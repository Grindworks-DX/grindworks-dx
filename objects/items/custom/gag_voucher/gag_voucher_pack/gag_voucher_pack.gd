extends Node3D

var item: Item
var gag_track: String

var value := 0.35
static var lure_value := 0.25

func setup(new_item: Item) -> void:
	item = new_item
	get_node('GagVoucher').setup(item)
	gag_track = get_node('GagVoucher').gag_track
	if gag_track == 'Lure': value = lure_value
	item.item_description = "%s %s Gag Regen!" % [Util.float_to_perc(value), gag_track]
	item.big_description = item.item_description

func collect() -> void:
	Util.get_player().stats.gag_regen_chance_modifiers[gag_track] += value

func modify(ui_asset: Node3D) -> void:
	get_node('GagVoucher').modify(ui_asset.get_node('GagVoucher'))
