extends Node3D

var item: Item
var gag_track: String

var value := 0.30
static var lure_value := 0.20
var starting_gp := 3

func setup(new_item: Item) -> void:
	item = new_item
	get_node('GagVoucher').setup(item)
	gag_track = get_node('GagVoucher').gag_track
	if gag_track == 'Lure': value = lure_value
	item.big_description = "+%s: +%s Gag Regen, +%d Starting Points" % [gag_track, Util.float_to_perc(value), starting_gp]

func collect() -> void:
	Util.get_player().stats.gag_regen_chance_modifiers[gag_track] += value
	Util.get_player().stats.gag_starting_points[gag_track] += starting_gp

func modify(ui_asset: Node3D) -> void:
	get_node('GagVoucher').modify(ui_asset.get_node('GagVoucher'))
