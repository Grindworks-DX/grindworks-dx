@tool
extends StatusEffect

var cue_order: Array[ToonAttack] = []
@export var cue_cost := 2
@export var cue_color := Color(0.243, 0.741, 0.514, 1.0)
@export var damage_boost := 0.50

# Ref to battle ui's gag tracks
var track_elements: Array[TrackElement]:
	get: 
		var arr: Array[TrackElement] = []
		arr.assign(manager.battle_ui.gag_tracks.get_children())
		return arr

var gag_loadout: GagLoadout:
	get:
		return Util.get_player().character.gag_loadout

func apply() -> void:
	for track: Track in gag_loadout.loadout:
		for i in Util.get_player().stats.gags_unlocked[track.track_name]:
			var gag = track.gags[i]
			cue_order.append(gag)
	RNG.channel(RNG.ChannelMoeCueGags).shuffle(cue_order)
	BattleService.s_action_finished.connect(on_action_finished)
	
	for element in track_elements:
		element.s_refreshed.connect(track_refreshed)
	super()

func expire() -> void:
	cleanup()

func combine(effect: StatusEffect) -> bool:
	stacks += effect.stacks
	return true

func track_refreshed(track) -> void:
	for button in track.gag_buttons:
		if button.gag in cue_order.slice(0, stacks):
			add_cue_gag(button.gag)
			button.default_color = cue_color
		else:
			button.default_color = Color("00a1ff")

func add_cue_gag(gag: ToonAttack) -> void:
	if gag in cue_order.slice(0, stacks) and BattleAction.ActionTag.CHAR_MOE_CUE not in gag.action_tags:
		gag.add_tag(BattleAction.ActionTag.CHAR_MOE_CUE)
		gag.price_modifier += cue_cost
		gag.damage_modifier += damage_boost

func remove_cue_gags() -> void:
	for gag: ToonAttack in cue_order:
		if gag.has_tag(BattleAction.ActionTag.CHAR_MOE_CUE):
			gag.action_tags.erase(BattleAction.ActionTag.CHAR_MOE_CUE)
			gag.price_modifier -= cue_cost
			gag.damage_modifier -= damage_boost
	for track in track_elements:
		for button in track.gag_buttons:
			button.default_color = Color("00a1ff")
		if track.s_refreshed.is_connected(track_refreshed): track.s_refreshed.disconnect(track_refreshed)

signal s_cue_gag_used

func on_action_finished(action: BattleAction) -> void:
	if action.has_tag(BattleAction.ActionTag.CHAR_MOE_CUE):
		s_cue_gag_used.emit()

func get_description() -> String:
	return "%d Gags are Accented with +%s Damage and +%d Cost (marked in green)\nUsing one will switch to Fortissimo stance" % \
	[stacks, Util.float_to_perc(damage_boost), cue_cost]

func cleanup() -> void:
	BattleService.s_action_finished.disconnect(on_action_finished)
	remove_cue_gags()
