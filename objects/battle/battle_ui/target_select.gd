extends TextureRect

const ARROW_NORM := preload("res://ui_assets/battle/target_select/PckMn_Arrow_Up.png")
const ARROW_RED := preload("res://ui_assets/battle/target_select/PckMn_Arrow_Up_RED.png")

# Child references
@onready var arrow := $Buttons/Arrows/ArrowButton
@onready var back := $Buttons/Back

# Signals
signal s_arrow_pressed(index: int)

# Locals
var gag: ToonAttack

func reposition_buttons(cogs: int):
	for i in cogs:
		var newbutton: GeneralButton
		if i == 0:
			newbutton = arrow
		else:
			newbutton = arrow.duplicate()
			$Buttons/Arrows.add_child(newbutton)
		newbutton.pressed.connect(arrow_pressed.bind(i))
		newbutton.mouse_entered.connect(on_arrow_hovered.bind(i))
		newbutton.mouse_exited.connect(on_arrow_unhovered.bind(i))
		newbutton.focus_entered.connect(on_arrow_hovered.bind(i))
		newbutton.focus_exited.connect(on_arrow_unhovered.bind(i))
		newbutton.disabled = false
		
		var cog: Cog = BattleService.ongoing_battle.cogs[i]
		if gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
			%TargetCenterLabel.text = "Which Cogs?"
		else:
			%TargetCenterLabel.text = "Which Cog?"
		if gag is LureFish and cog.lured:
			newbutton.disabled = true
		elif gag is GagTrap:
			if (Util.get_player().trap_needs_lure and cog.lured) or cog.trap:
				newbutton.disabled = true
			else:
				newbutton.disabled = false
	
	$GagPanel/GagImage.set_texture(gag.icon)
	$GagPanel.self_modulate = Globals.get_gag_color(gag)

func reset_buttons():
	for i in range($Buttons/Arrows.get_child_count()-1,0,-1):
		$Buttons/Arrows.get_child(i).queue_free()
	arrow.disconnect('pressed',arrow_pressed)
	arrow.mouse_entered.disconnect(on_arrow_hovered)
	arrow.mouse_exited.disconnect(on_arrow_unhovered)
	arrow.focus_entered.disconnect(on_arrow_hovered)
	arrow.focus_exited.disconnect(on_arrow_unhovered)

func arrow_pressed(index : int):
	s_arrow_pressed.emit(index)
	reset_buttons()

func on_arrow_hovered(index : int) -> void:
	var cog_panels := BattleService.ongoing_battle.battle_ui.cog_panels
	var panels = cog_panels.get_children()
	panels[index].profile.self_modulate = Color(0.645, 0.813, 0.972, 1.0)
	
	if gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
		for i in get_neighboring_indices(index, cog_panels.get_child_count()):
			panels[i].profile.self_modulate = Color(0.855, 0.665, 0.88, 1.0)
		for button in get_neighbor_buttons(index):
			button.texture_normal = ARROW_RED

## Returns splash neighbors
func get_neighbor_buttons(index : int) -> Array[GeneralButton]:
	var neighbors : Array[GeneralButton] = []
	var button_container : HBoxContainer = $Buttons/Arrows
	
	for i in get_neighboring_indices(index, button_container.get_child_count()):
		neighbors.append(button_container.get_child(i))
	
	return neighbors

func get_neighboring_indices(index: int, amount: int) -> Array[int]:
	var neighbors : Array[int] = []
	
	if index == 0:
		var i := 1
		while i < amount and i < 3:
			neighbors.append(i)
			i += 1
	elif index == amount - 1:
		var i := amount - 2
		while i >= 0 and i > amount - 4:
			neighbors.append(i)
			i -= 1
	else:
		neighbors.append(index - 1)
		neighbors.append(index + 1)
	
	return neighbors

func on_arrow_unhovered(index : int) -> void:
	var cog_panels := BattleService.ongoing_battle.battle_ui.cog_panels
	cog_panels.get_children()[index].profile.self_modulate = Color('e0e0e0a6')
	
	if gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
		for i in get_neighboring_indices(index, cog_panels.get_child_count()):
			cog_panels.get_children()[i].profile.self_modulate = Color('e0e0e0a6')
	
	for button : GeneralButton in $Buttons/Arrows.get_children():
		button.texture_normal = ARROW_NORM
