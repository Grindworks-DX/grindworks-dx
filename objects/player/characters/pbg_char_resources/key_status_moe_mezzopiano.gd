@tool
extends StatusEffect

var defense_boost := StatMultiplier.new('defense', 0.50, true)
var damage_multiplier := StatMultiplier.new('damage', -0.30, false)
var gag_regen_multiplier := StatMultiplier.new("gag_regen_chance", 0.5, true)
static var speed_gains := [6, 3, 8, 3, 6, 3, 8]

var conductor_item: ItemMoeConductor = null

func apply() -> void:
	target.get_battle_stats().multipliers.append(defense_boost)
	target.get_battle_stats().multipliers.append(damage_multiplier)
	target.stats.multipliers.append(gag_regen_multiplier)
	if !BattleService.s_gag_stat_string_set.is_connected(on_gag_stat_string_set):
		BattleService.s_gag_stat_string_set.connect(on_gag_stat_string_set)
	BattleService.s_action_impact.connect(on_gag_impact)
	if manager.battle_ui.manager is not BattleManager: await manager.s_ui_initialized

func expire() -> void:
	cleanup()

func on_gag_stat_string_set(gag: ToonAttack) -> void:
	if gag.track.track_name != "Sound": return
	gag.stat_string += "\nOn Hit: Cog Gains %d Speed for 2 Rounds" % speed_gains.get(gag.level - 1)

func on_gag_impact(action: BattleAction, _target: Node3D) -> void:
	if action.track.track_name != "Sound" or action.user != target: return
	
	var status := StatBoost.new()
	status.boost = speed_gains.get(action.level - 1)
	status.stat = 'speed'
	status.quality = StatBoost.EffectQuality.POSITIVE
	status.rounds = 1
	status.target = _target
	manager.add_status_effect(status)
	await manager.sleep(1.0)
	manager.battle_text(_target, "ALARMED!")

func cleanup() -> void:
	if is_instance_valid(target):
		target.stats.multipliers.erase(gag_regen_multiplier)
		target.get_battle_stats().multipliers.erase(defense_boost)
		target.get_battle_stats().multipliers.erase(damage_multiplier)
	BattleService.s_gag_stat_string_set.disconnect(on_gag_stat_string_set)
	BattleService.s_action_impact.disconnect(on_gag_impact)
