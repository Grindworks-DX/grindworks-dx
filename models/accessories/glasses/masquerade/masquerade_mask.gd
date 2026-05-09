extends Node3D

# Breaking Grounds - Double one attribute, -2 to the others

## Funny script that's necessary for this item to work
## Also before you ask, no it cannot use an item script

const ROLL_STATS: Array[String] = ['punch', 'humor', 'gusto', 'shrug']

func setup(item: Item) -> void:
	if item.stats_add.is_empty():
		roll_for_stats(item)
	# Fake evergreen corrector
	ItemService.seen_item(load("res://objects/items/resources/accessories/glasses/masquerade_mask.tres"))

func roll_for_stats(item: Item) -> void:
	var stats_order := ROLL_STATS.duplicate(true)
	RNG.channel(RNG.ChannelMasqueradeStats).shuffle(stats_order)
	for i in 3:
		item.stats_add.set(stats_order[i], -1)
	item.stats_multiply.set(stats_order[3], 2)
