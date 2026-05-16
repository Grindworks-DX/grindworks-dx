extends ItemScript
class_name ItemMoeConductor

enum MoeStances {
	MEZZOPIANO,
	FORTISSIMO
}
static var speed_advantage_threshold := 3

var stance := MoeStances.MEZZOPIANO
var stance_effect: StatusEffect:
	set(x):
		stance_effect = x
		if x is StatusEffect:
			x.set('conductor_item', self)
			x.target = Util.get_player()
			BattleService.ongoing_battle.add_status_effect(x)

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_started)
	BattleService.s_battle_ended.connect(on_battle_ended)
	BattleService.s_cog_dealt_damage.connect(on_cog_dealt_damage)

func on_battle_started(_manager: BattleManager) -> void:
	enter_stance(MoeStances.MEZZOPIANO)
	
func on_battle_ended() -> void:
	stance_effect = null

func on_cue_gag_used(stacks: int) -> void:
	if stance == MoeStances.MEZZOPIANO:
		enter_stance(MoeStances.FORTISSIMO)
		Util.get_player().boost_queue.queue_text("Fortissimo!", Color(0.671, 0.18, 0.192, 1.0))
		stance_effect.stacks = 0
	stance_effect.stacks += stacks

func enter_stance(_stance: MoeStances) -> void:
	if stance_effect is StatusEffect: BattleService.ongoing_battle.expire_status_effect(stance_effect)
	match _stance:
		MoeStances.MEZZOPIANO:
			stance_effect = load("uid://cmfrphxalx3c2").duplicate(true)
		MoeStances.FORTISSIMO:
			stance_effect = load("res://objects/player/characters/pbg_char_resources/key_status_moe_fortissimo.tres").duplicate(true)
			stance_effect.s_expire.connect(enter_stance.bind(MoeStances.MEZZOPIANO))
	stance = _stance

func on_cog_dealt_damage(action: BattleAction, _target: Node3D, amount: int) -> void:
	var manager := BattleService.ongoing_battle
	var target := Util.get_player()
	if _target != target or !amount > 0 or manager is not BattleManager: return
	var difference = action.user.get_battle_stats().get_stat('speed') - target.get_battle_stats().get_stat('speed')
	
	if difference >= speed_advantage_threshold:
		Util.get_player().boost_queue.queue_text("Cue Gained!", Color(0.255, 0.545, 0.343, 1.0))
		var status: StatusEffect = load("res://objects/player/characters/pbg_char_resources/key_status_moe_accent.tres").duplicate(true)
		status.stacks = floori(difference / speed_advantage_threshold)
		status.target = target
		status.s_cue_gag_used.connect(on_cue_gag_used)
		manager.add_status_effect(status)
