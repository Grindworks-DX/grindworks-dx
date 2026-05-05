extends Control

const UPGRADE_SOUND := preload("res://audio/sfx/items/clock03.ogg")

@onready var attribute_graph := %AttributeRadarGraph
@onready var jokes_label := %JokesLabel
@onready var total_jokes_label := %TotalJokesLabel

var upgrade_buttons: Dictionary[String, GeneralButton] = {}

func _ready() -> void:
	await get_tree().process_frame
	var player = Util.get_player()
	# Breaking Grounds - Populate attribute radar graph
	var attributes = ['punch', 'humor', 'gusto', 'shrug']
	for i in attributes.size():
		var button: GeneralButton = attribute_graph.get_node("UpgradeButton%s" % attributes[i].capitalize())
		upgrade_buttons.set(attributes[i], button)
		button.pressed.connect(upgrade_attribute.bind(attributes[i]))
		
	update()

func upgrade_attribute(attribute: String) -> void:
	var stats := Util.get_player().stats
	if stats.jokes > 0:
		stats.set(attribute, stats.get(attribute) + 1)
		stats.jokes -= 1
		AudioManager.play_sound(UPGRADE_SOUND)
	update()

func update() -> void:
	var player := Util.get_player()
	for button in upgrade_buttons.values():
		button.visible = player.stats.jokes > 0
	
	jokes_label.text = str(player.stats.jokes)
	total_jokes_label.text = "/ %d" % player.stats.total_jokes
	
	var attributes = ['punch', 'humor', 'gusto', 'shrug']
	var tween := create_tween().set_parallel()
	for i in attributes.size():
		tween.tween_property(attribute_graph, "items/key_%d/value" %i, player.stats.get(attributes[i]), 1.0)
