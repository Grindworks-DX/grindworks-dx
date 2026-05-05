@tool
extends Control
class_name StatsDisplay

const SFX_STAT_CHANGE := preload("res://audio/sfx/ui/sfx_pop.ogg")

@onready var StatInfo: Array = [
	[%Damage, "damage"],
	[%Defense, "defense"],
	[%Evasiveness, "evasiveness"],
	[%Luck, "luck"],
	[%Speed, "speed"],
]

@export var is_mini := false:
	set(x):
		is_mini = x
		apply_stat_labels()

func _ready() -> void:
	Util.s_player_assigned.connect(update.unbind(1))
	
	if !Util.player_exists():
		await Util.s_player_assigned
	else: update()
	
	Util.get_player().stats.s_stat_changed.connect(update.unbind(1))
	
	Globals.s_game_started.connect(update, CONNECT_ONE_SHOT)

func update() -> void:
	if !Util.get_player().stats.is_connected("s_stat_changed", update):
		Util.get_player().stats.s_stat_changed.connect(update.unbind(1))
	apply_stat_labels()
	apply_stat_changes()

func apply_stat_labels() -> void:
	for stat_array: Array in StatInfo:
		stat_array[0].text = "" if is_mini else "%s: " % stat_array[1].capitalize()
		if stat_array[1] in ['damage', 'defense', 'evasiveness', 'luck']:
			stat_array[0].text += '%d%%' % Util.get_player().stats.get_stat_as_percent(stat_array[1]) if Util.player_exists() else 100
		else:
			stat_array[0].text += str(ceili(Util.get_player().stats.get_stat(stat_array[1])))

func apply_stat_changes() -> void:
	var stat_up_color := Color("4de64d")
	var stat_down_color := Color("e64d4d")
	var stat_change_labels : Array[Label] = [
		%DamageChange, %DefenseChange, %EvasivenessChange, %LuckChange, %SpeedChange
	]
	for label : Label in stat_change_labels:
		var stat_change := get_stat_change(label.name.to_lower().trim_suffix('change'))
		if is_equal_approx(stat_change, 0.0):
			label.set_text("")
			continue
		var stat_change_txt := "%d%%" % roundi(stat_change * 100.0)
		if stat_change >= 0.0:
			label.set_text("+%s" % stat_change_txt.trim_suffix('0'))
			label.label_settings.font_color = stat_up_color
		else: 
			label.set_text("%s" % stat_change_txt.trim_suffix('0'))
			label.label_settings.font_color = stat_down_color
		do_stat_change_flash(label, 0.1 * stat_change_labels.find(label))
	Util.get_player().stats.start_stat_monitors()

func get_stat_change(stat : String) -> float:
	var stats := Util.get_player().stats
	if not stat in stats.prev_stats:
		return stats.get_stat(stat)
	return stats.get_stat(stat) - stats.prev_stats[stat]

func do_stat_change_flash(label : Label, delay := 0.0) -> void:
	label.pivot_offset = Vector2(label.size.x / 2.0, label.size.y / 2.0)
	label.scale = Vector2.ONE * 0.01
	var tween := create_tween().set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(delay)
	tween.tween_callback(
		func():
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
	var stats := Util.get_player().stats
	for stat in stats.prev_stats:
		if not is_equal_approx(stats.get_stat(stat), stats.prev_stats[stat]):
			return true
	return false
