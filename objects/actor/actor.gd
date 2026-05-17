extends CharacterBody3D
class_name Actor

signal s_battle_ready

var current_moves: Array[BattleAction] = []

func get_battle_stats() -> BattleStats:
	if BattleService.ongoing_battle is BattleManager:
		return BattleService.ongoing_battle.battle_stats[self]
	return self.stats
