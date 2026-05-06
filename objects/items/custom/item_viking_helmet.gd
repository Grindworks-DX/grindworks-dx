extends ItemScript

# Breaking Grounds - When you deal 80 or more damage in one instance, trigger 50% Humor Healing
var damage_threshold := 80
var humor_healing_effectiveness := 0.5

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	if not Util.get_player():
		await Util.s_player_assigned
	var player := Util.get_player()
	
	BattleService.s_toon_dealt_damage.connect(
		func(current_action, target, amount):
			if target is Cog and amount >= damage_threshold and player.stats.humor_healing > 0:
				player.stats.do_humor_healing(humor_healing_effectiveness)
				current_action.store_boost_text("Glorious!", Color(1, 0.431, 0))
	)
	
