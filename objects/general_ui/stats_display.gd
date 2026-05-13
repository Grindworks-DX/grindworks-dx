@tool
extends Control
class_name StatsDisplay

const SFX_STAT_CHANGE := preload("res://audio/sfx/ui/sfx_pop.ogg")

@export var stat_info: Dictionary[Label, String]

@export var is_mini := false:
	set(x):
		is_mini = x
		apply_stat_labels()

@export var use_battle_stats := false
var stats: PlayerStats

func _ready() -> void:
	Util.s_player_assigned.connect(update.unbind(1))
	for key in stat_info:
		key.get_node("%sChange" % stat_info[key].capitalize()).text = ""
	
	if !Util.player_exists():
		await Util.s_player_assigned
	
	assign_stats()
	
	if !stats.is_connected("s_stat_changed", update):
		stats.s_stat_changed.connect(update)
	
	update()
	
	Globals.s_game_started.connect(update, CONNECT_ONE_SHOT)
	if !use_battle_stats:
		BattleService.s_battle_started.connect(
			func(x: BattleManager):
				hide()
				x.s_battle_ended.connect(show)
		)

func assign_stats() -> void:
	if !use_battle_stats: stats = Util.get_player().stats
	else: stats = BattleService.ongoing_battle.battle_stats[Util.get_player()]

func update(stat := "") -> void:
	if stat not in stat_info.values() and stat != "": return
	if stats is not PlayerStats: assign_stats()
	if !stats.is_connected("s_stat_changed", update):
		stats.s_stat_changed.connect(update)
	apply_stat_labels()
	apply_stat_changes()

func apply_stat_labels() -> void:
	for label in stat_info.keys():
		var stat = stat_info[label]
		label.text = "%s: " % stat.capitalize() if (!is_mini or stat in PlayerStats.attributes + ['crit_mult', 'silly_meter']) else ""
		if stat in ['damage', 'defense', 'evasiveness', 'luck', 'crit_mult']:
			label.text += '%d%%' % stats.get_stat_as_percent(stat) if Util.player_exists() else 100
		else:
			label.text += str(ceili(stats.get_stat(stat)))

func apply_stat_changes() -> void:
	var stat_up_color := Color("4de64d")
	var stat_down_color := Color("e64d4d")
	for key in stat_info:
		var stat = stat_info[key]
		var label: Label = key.get_node("%sChange" % stat.capitalize())
		var stat_change = get_stat_change(stat)
		if is_equal_approx(stat_change, 0.0):
			#label.set_text("")
			continue
		var stat_change_txt: String
		if stat in PlayerStats.attributes + ['speed', 'silly_meter']:
			stat_change = roundi(stat_change)
			stat_change_txt = str(stat_change)
		elif stat_change is float:
			stat_change_txt = Util.float_to_perc(stat_change)
		
		if stat_change >= 0.0:
			stat_change_txt = "+%s" % stat_change_txt.trim_suffix('0')
			label.label_settings.font_color = stat_up_color
		else: 
			stat_change_txt = "%s" % stat_change_txt.trim_suffix('0')
			label.label_settings.font_color = stat_down_color
		do_stat_change_flash(label, 0.1 * stat_info.keys().find(key), stat_change_txt)
	stats.start_stat_monitors()

func get_stat_change(stat : String):
	if not stat in stats.prev_stats:
		return stats.get_stat(stat)
	return stats.get_stat(stat) - stats.prev_stats[stat]

func do_stat_change_flash(label : Label, delay := 0.0, text := "") -> void:
	label.text = text
	if text == "":
		return
	
	label.pivot_offset = Vector2(label.size.x / 2.0, label.size.y / 2.0)
	label.scale = Vector2.ONE * 0.01
	var tween := create_tween().set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(delay)
	tween.tween_callback(
		func():
			if use_battle_stats: return
			var player := AudioManager.play_sound(SFX_STAT_CHANGE)
			player.pitch_scale = 1.0 + delay / 2.0
	)
	tween.tween_property(label.label_settings, 'font_color', Color.WHITE, 0.2)
	tween.parallel().tween_property(label, 'scale', Vector2.ONE * 1.1, 0.2)
	tween.tween_interval(0.01)
	tween.tween_property(label.label_settings, 'font_color', label.label_settings.font_color, 0.2)
	tween.parallel().tween_property(label, 'scale', Vector2.ONE, 0.2)
	if is_mini:
		tween.tween_interval(3.0)
		tween.tween_property(label, 'scale', Vector2.ONE * 0.01, 0.2)
	tween.finished.connect(tween.kill)

func did_stats_change() -> bool:
	var stats := stats
	for stat in stats.prev_stats:
		if not is_equal_approx(stats.get_stat(stat), stats.prev_stats[stat]):
			return true
	return false
