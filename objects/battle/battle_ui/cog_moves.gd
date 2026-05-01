extends HBoxContainer

## References to the selected gag panels
var panels: Array[TextureRect] = []

## The base move panel
const COG_MOVE := preload("uid://wgwxlmdh0cm")
@onready var battle_ui : BattleUI = get_parent()
@onready var manager: BattleManager = NodeGlobals.get_ancestor_of_type(self, BattleManager)


## Find the proper amount of gag panels to have on startup
func _ready():
	manager.s_enemy_moves_assigned.connect(update_panels)
	# Add the first gag panel to the array
	#panels.append(move_panel)
	#configure_panel(move_panel)
	update_panels()

func configure_panel(panel) -> void:
	pass
	#panel.get_node('GagIcon').mouse_entered.connect(hover_slot.bind(panels.find(panel)))
	#panel.get_node('GagIcon').mouse_exited.connect(stop_hover)
	#panel.get_node('GagIcon').focus_entered.connect(hover_slot.bind(panels.find(panel)))
	#panel.get_node('GagIcon').focus_exited.connect(stop_hover)
	#panel.get_node('GeneralButton').disabled = true
	#panel.get_node('GeneralButton').hide()
	#panel.get_node('GeneralButton').pressed.connect(cancel_gag.bind(panels.find(panel)))
		
func update_panels() -> void:
	var panels_to_make: int = manager.enemy_moves.size() - panels.size()
	if panels_to_make > 0:
		# Append the panels
		for i in panels_to_make:
			var panel = COG_MOVE.instantiate()
			reset_panel(panel)
			add_child(panel)
			panels.append(panel)
		
		# X Button configuration
		for i in range(panels.size() - panels_to_make, panels.size()):
			configure_panel(panels[i])
			
	# definitely not complete negative support
	if panels_to_make < 0:
		for i in abs(panels_to_make):
			panels.pop_back().queue_free()
	
	refresh_moves()
	

func append_move(move: BattleAction) -> void:
	# Add the icon to the gag panels
	for panel in panels:
		var icon: TextureRect = panel.get_node('GagIcon')
		if not icon.texture:
			#icon.texture = 
			break

## Reset all panels
func reset_panel(panel) -> void:
		panel.get_node('GagIcon').texture = null
		panel.get_node('GeneralButton').disabled = true
		panel.get_node('GeneralButton').hide()
		panel.get_node('DamageLabel').text = ""
		
@onready var incoming_label := manager.battle_ui.get_node('%IncomingLabel')
var damage_total := 0

func refresh_moves():
	damage_total = 0
	
	for i in panels.size():
		var move: BattleAction = manager.enemy_moves[i]
		var damage: int = 0
		
		if move is CogAttack:
			damage = manager.get_damage(move.damage, move, Util.get_player())
			damage_total += damage
		
		var cog: Cog = move.user
		var panel = panels[i]
		
		if i < manager.enemy_moves.size():
			var head: Node3D = cog.dna.get_head()
			if not cog.dna.head_scale.is_equal_approx(Vector3.ONE * cog.dna.head_scale.x):
				head.scale = cog.dna.head_scale
			panel.get_node('CogFace').node = head
			panel.get_node('GeneralButton').disabled = true
			
			var damage_label: Label = panel.get_node('DamageLabel')
			if damage > 0:
				damage_label.label_settings.font_color = Color(1.0, 0.0, 0.0, 1.0)
				damage_label.text = "-" + str(damage)
			else:
				damage_label.label_settings.font_color = Color("ff4d00")
				damage_label.text = "!"
			
			var accuracy_bar: ProgressBar = panel.get_node('AccuracyBar')
			accuracy_bar.value = manager.calculate_accuracy(move)
			
			panel.get_node('TargetingLabel').text = get_source_string(cog)
	
	incoming_label.text = "Incoming Damage: %d" % damage_total

#func hover_slot(idx: int) -> void:
	#if (not current_gags) or current_gags.size() - 1 < idx:
		#return
#
	#var gag: ToonAttack = current_gags[idx]
	#var atk_string: String = ""
	#var has_main_target: bool = gag.main_target != null
	#for cog in manager.cogs:
		#if cog in gag.targets:
			#atk_string += "X" if ((not has_main_target) or (has_main_target and cog == gag.main_target)) else "x"
		#else:
			#atk_string += "-"
		#if manager.cogs.find(cog) < manager.cogs.size() - 1:
			#atk_string += " "
	#HoverManager.hover(atk_string, 20, 0.0125)
#
#func stop_hover() -> void:
	#HoverManager.stop_hover()

func get_source_string(_cog: Cog) -> String:
	var atk_string := ""
	for cog in manager.cogs:
		if cog == _cog:
			atk_string += "V"
		else:
			atk_string += "-"
		if manager.cogs.find(cog) < manager.cogs.size() - 1:
			atk_string += ""
	return atk_string
