extends ItemScript

# Breaking Grounds - -2 HP every time damage is dealt
var damage_to_take := 2

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	if not Util.get_player():
		await Util.s_player_assigned
	var player := Util.get_player()
	
	BattleService.s_toon_dealt_damage.connect(
		func(_current_action, target, _amount):
			if target is Cog:
				player.stats.hp = max(1, player.stats.hp - damage_to_take)
	)
