extends ItemScript
class_name ItemMoeConductor

enum MoeStances {
	MEZZOPIANO,
	FORTISSIMO
}
static var speed_advantage_threshold := 5
static var max_accent_per_hit := 1
static var ff_accent_evasiveness_bonus := 0.3

var stance := MoeStances.MEZZOPIANO
var stance_effect: StatusEffect:
	set(x):
		stance_effect = x
		if x is StatusEffect:
			x.set('conductor_item', self)
			x.target = Util.get_player()
			manager.add_status_effect(x)
var accent_effect: StatusEffect:
	set(x):
		accent_effect = x
		if accent_effect is StatusEffect:
			accent_effect.s_expire.connect(set.bind("accent_effect", null))

var manager: BattleManager

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_started)
	BattleService.s_battle_ended.connect(on_battle_ended)
	BattleService.s_round_started.connect(on_round_started)
	BattleService.s_cog_dealt_damage.connect(on_unit_dealt_damage)
	BattleService.s_toon_dealt_damage.connect(on_unit_dealt_damage)

func on_battle_started(_manager: BattleManager) -> void:
	manager = _manager
	Util.get_player().get_battle_stats().s_turns_changed.connect(on_player_turns_changed)
	enter_stance(MoeStances.MEZZOPIANO)
	
func on_battle_ended() -> void:
	Util.get_player().get_battle_stats().s_turns_changed.disconnect(on_player_turns_changed)
	accent_effect = null
	stance_effect = null
	manager = null

func on_player_turns_changed(old: int, new: int) -> void:
	if new > old: Util.get_player().stats.do_humor_healing()

func on_round_started(turn_array: Array[BattleAction]) -> void:
	match stance:
		MoeStances.FORTISSIMO:
			var full_accent := true
			var evasiveness_gain := 0.0
			for action in turn_array:
				if action.user == Util.get_player():
					if BattleAction.ActionTag.CHAR_MOE_CUE in action.action_tags:
						evasiveness_gain += ff_accent_evasiveness_bonus
					else:
						full_accent = false
			if evasiveness_gain > 0.0:
				var boost := StatBoost.new('evasiveness', evasiveness_gain, false)
				boost.target = Util.get_player()
				manager.add_status_effect(boost)
			if full_accent:
				Util.get_player().boost_queue.queue_text("Full Scale!", Color(0.671, 0.18, 0.192, 1.0))
				stance_effect.stacks += 1

func on_cue_gag_used() -> void:
	match stance:
		MoeStances.MEZZOPIANO:
			enter_stance(MoeStances.FORTISSIMO)

func enter_stance(_stance: MoeStances) -> void:
	if stance_effect is StatusEffect: manager.expire_status_effect(stance_effect)
	match _stance:
		MoeStances.MEZZOPIANO:
			Util.get_player().boost_queue.queue_text("Mezzopiano!", Color(0.236, 0.384, 0.615, 1.0))
			stance_effect = load("uid://cmfrphxalx3c2").duplicate(true)
			if accent_effect is StatusEffect: accent_effect.expire()
		MoeStances.FORTISSIMO:
			Util.get_player().boost_queue.queue_text("Fortissimo!", Color(0.671, 0.18, 0.192, 1.0))
			stance_effect = load("res://objects/player/characters/pbg_char_resources/key_status_moe_fortissimo.tres").duplicate(true)
			stance_effect.s_expire.connect(enter_stance.bind(MoeStances.MEZZOPIANO))
			stance_effect.stacks = 0
	stance = _stance

func on_unit_dealt_damage(action: BattleAction, target: Node3D, amount: int) -> void:
	if !amount > 0 or manager is not BattleManager or (target != Util.get_player() and action.user != Util.get_player()): return
	var difference = absi(action.user.get_battle_stats().get_stat('speed') - target.get_battle_stats().get_stat('speed'))
	
	if difference >= speed_advantage_threshold:
		gain_accent(mini(floori(difference / speed_advantage_threshold), max_accent_per_hit))

func gain_accent(amount := 1) -> void:
	Util.get_player().boost_queue.queue_text("Accent Gained!", Color(0.255, 0.545, 0.343, 1.0))
	if accent_effect is StatusEffect:
		accent_effect.stacks += amount
	else:
		var status: StatusEffect = load("res://objects/player/characters/pbg_char_resources/key_status_moe_accent.tres").duplicate(true)
		status.stacks = amount
		status.target = Util.get_player()
		status.s_cue_gag_used.connect(on_cue_gag_used)
		status.s_expire.connect(set.bind("accent_effect", null))
		manager.add_status_effect(status)
		accent_effect = status
