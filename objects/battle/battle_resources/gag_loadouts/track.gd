extends Resource
class_name Track

## Gag Track class. Couldn't be called GagTrack bc it's taken :(
enum TrackType {
	OFFENSE,
	SUPPORT,
	SPECIAL
}
@export var track_type := TrackType.OFFENSE

@export var track_name: String
@export var track_color: Color
@export var gags: Array[ToonAttack]

## Specify the modded gag and the level it's assigned (0-6)
@export var mod_gags: Dictionary[ToonAttack, int]

@export var base_regen := 0.0
@export var base_combat_start_gp := 3
@export var base_gp_cap := 10
@export var base_level := 0
@export var base_effectiveness := 1.0

func get_gag_variants(index: int) -> Array[ToonAttack]:
	var variants: Array[ToonAttack] = []
	for action in mod_gags.keys():
		if mod_gags[action] == index:
			variants.append(action)
	return variants

func swap_gag(gag: ToonAttack, level := -1) -> void:
	if level == -1:
		if not gag in mod_gags.keys():
			printerr("Cannot automatically swap Gag not specified in mod gags")
			return
		level = mod_gags[gag]
	
	gags.remove_at(level)
	gags.insert(level, gag)
