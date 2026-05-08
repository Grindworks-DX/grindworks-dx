extends ItemScriptActive

const chomp = "res://audio/sfx/items/big_chomp.ogg"

var heal_amount := 0.2

const BANNED_SCENES: Array[String] = [
	'StrangerShop',
	'ElevatorScene',
]

func initialize(_item: Item, _object: Node3D) -> void:
	charge_to_use = 1

func validate_use() -> bool:
	if SceneLoader.current_scene.name in BANNED_SCENES:
		return false
	return Util.get_player().stats.hp < Util.get_player().stats.max_hp and item.charge_count > 0

func use() -> void:
	var player := Util.get_player()
	
	player.quick_heal(roundi(player.stats.max_hp * heal_amount))
	AudioManager.play_sound(load(chomp))
