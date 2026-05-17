extends Node
class_name ItemScript

var count_label: Label

## Script class that will be attached to the player as nodes


## Called when an item is first collected by the player
func on_collect(_item: Item, _object: Node3D) -> void:
	_item.s_item_icon_connected.connect(on_item_icon_assigned)

## Called when an item is re-instanced on game-load
func on_load(_item: Item) -> void:
	_item.s_item_icon_connected.connect(on_item_icon_assigned)

## Called if the item is removed from the Player
func on_item_removed() -> void:
	pass

## Adds an item script to the player
static func add_item_script(player: Player, item_script: Script) -> Node:
	var new_node := Node.new()
	new_node.set_script(item_script)
	player.get_node('Items').add_child(new_node)
	return new_node

func on_item_icon_assigned(item_icon: ItemIcon) -> void:
	if item_icon.use_count_label:
		count_label = item_icon.counter_label
		count_label.show()
