extends ItemScript

const AFFECTED_STATS := ['punch', 'humor', 'gusto', 'shrug']

func on_collect(_item: Item, _object: Node3D) -> void:
	var total_stats: int = 0
	for stat_name: String in AFFECTED_STATS:
		total_stats += Util.get_player().stats.get(stat_name)
	for stat_name: String in AFFECTED_STATS:
		Util.get_player().stats.set(stat_name, ceili(total_stats / float(AFFECTED_STATS.size())))
	print('Balancing Scale: Setting %s to %s' % [AFFECTED_STATS, ceili(total_stats / float(AFFECTED_STATS.size()))])
