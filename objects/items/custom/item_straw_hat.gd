extends ItemScript

var times_to_heal := 3
@onready var heals_remaining := times_to_heal

func on_collect(_item: Item, _model: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_round_started.connect(on_round_started)
	BattleService.s_toon_dealt_damage.connect(on_toon_dealt_damage)

func on_round_started(_actions: Array[BattleAction]) -> void:
	heals_remaining = times_to_heal

func on_toon_dealt_damage(_action: BattleAction, target: Cog, damage: int) -> void:
	if !damage > 0 or !is_boost_cog(target) or !heals_remaining > 0: return
	
	Util.get_player().stats.do_humor_healing(1.0)
	Util.get_player().boost_queue.queue_text("Farmed!", Color(0.425, 0.276, 0.131, 1.0))
	heals_remaining -= 1

func is_boost_cog(cog: Cog) -> bool:
	var dna := cog.dna
	if dna.is_mod_cog or dna.is_admin or not dna.custom_nametag_suffix == "":
		return true
	return false
