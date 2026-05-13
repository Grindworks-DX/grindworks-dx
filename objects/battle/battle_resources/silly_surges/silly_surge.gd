extends BattleAction
class_name SillySurge

# Silly Surges are "super" actions used during Gag Selection
# They are available when the Silly Meter is filled and consume all filled segments to get stronger accordingly
# Surges do not use a move and do not specify a target through TargetSelect

@export var thresholds: Array[int] = [20, 40, 60]
@export var values: Array[Dictionary]
@export_multiline var summary := ""

signal s_surge_level_set(level: int)

var level := 0:
	set(x):
		level = x
		if level is int: s_surge_level_set.emit(level)

func get_action_name() -> String:
	if !level > 0: return action_name
	return "%s Lv. %d" % [action_name, level]

func sync_level() -> void:
	var meter: int = BattleService.ongoing_battle.battle_stats[Util.get_player()].silly_meter
	level = 0
	for threshold in thresholds:
		if meter >= threshold: level += 1
		else: break

func get_general_stats() -> String:
	return ""

func get_surge_requirement_text() -> String:
	var string := "Silly Meter Needed: "
	for i in thresholds.size():
		string += str(thresholds[i])
		if i < thresholds.size() - 1: string += "/"
	
	return string
