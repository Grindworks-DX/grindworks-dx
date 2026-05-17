extends Sprite3D

# Breaking Grounds - Now gives gag regen and starting points

var value := 0.15
static var lure_value := 0.10
var starting_gp := 2

## Don't mind the fact that it don't look right in the preview
## It looks correct in game for some reason?!?!

# Child references
@onready var ticket := $SubViewport/Ticket
@onready var gag := $SubViewport/Ticket/Gag

# Locals
var resource: Item
var gag_track: String

func setup(item: Item):
	resource = item
	
	if Util.get_player().gags_cost_beans:
		item.reroll()
	
	if not resource.arbitrary_data.has('gag_track'):
		# Find the gag tracks that the player has access to
		var tracks := []
		var player := Util.get_player()
		
		if not player:
			player = await Util.s_player_assigned
		
		for track in player.stats.gags_unlocked.keys():
			if player.stats.gags_unlocked[track] > 0:
				tracks.append(track)
		
		if tracks.is_empty():
			gag_track = player.stats.gags_unlocked.keys()[RNG.channel(RNG.ChannelGagVouchers).randi() % player.stats.gags_unlocked.keys().size()]
		else:
			gag_track = tracks[RNG.channel(RNG.ChannelGagVouchers).randi() % tracks.size()]
		
		if gag_track == "Lure": value = lure_value
		
		resource.arbitrary_data['gag_track'] = gag_track
		resource.big_description = "+%s: +%s Gag Regen, +%d Starting Points" % [gag_track, Util.float_to_perc(value), starting_gp]
	else:
		gag_track = resource.arbitrary_data['gag_track']

	gag.texture = get_icon()

func collect() -> void:
	Util.get_player().stats.gag_regen_chance_modifiers[gag_track] += value
	Util.get_player().stats.gag_starting_points[gag_track] += starting_gp

func modify(model: Sprite3D):
	model.gag.texture = gag.texture
	model.ticket.modulate = ticket.modulate

func get_icon() -> Texture2D:
	var player := Util.get_player()
	var loadout: Array[Track] = player.stats.character.gag_loadout.loadout

	var track: Track
	for entry in loadout:
		if entry.track_name == gag_track:
			track = entry
			break
	return track.gags[0].icon
