extends CanvasLayer
class_name BattleUI

# Child References
@onready var gag_tracks := %Tracks
@onready var attack_label := %AttackLabel
@onready var right_panel := %RightPanel
@onready var cog_panels := %CogPanels
@onready var main_container := %BattleMenuContainer
@onready var gag_order_menu := %SelectedGags
@onready var pass_button: GagButton = %LockIn
@onready var surge_button: GagButton = %Surge

@onready var target_select := %TargetSelect

@onready var planning_ui := %PlanningUI

# Bottom-right buttons
@onready var fire_button := %Fire

@onready var status_container: HBoxContainer = %StatusContainer

@onready var manager: BattleManager = get_parent()

# Signals
signal s_gag_pressed(gag: BattleAction)
signal s_gag_selected(gag: BattleAction)
signal s_turn_complete(gag_order: Array[ToonAttack])
signal s_gag_canceled(gag: BattleAction)
signal s_gags_updated(gags: Array[ToonAttack])
signal s_update_toonups

# Locals
var turn := 0:
	set(x):
		turn = x
		refresh_turns()
var remaining_turns: int:
	get:
		if manager is BattleManager:
			return roundi(manager.battle_stats[Util.get_player()].get_stat('turns')) > turn
		else:
			return roundi(Util.get_player().get_stat('turns')) > turn

var selected_gags: Array[ToonAttack] = []
var fire_action: ToonAttackFire
var timer : GameTimer

var last_gag_button: GagButton

func _ready():
	refresh_turns()
	reset()
	
	# Create fire action
	fire_action = ToonAttackFire.new()
	fire_action.target_type = BattleAction.ActionTarget.ENEMY
	fire_action.icon = load("res://objects/items/custom/pink_slip/pink_slip_icon.png")
	fire_action.action_name = "FIRE"
	
	var surge = Util.get_silly_surge()
	if surge is SillySurge:
		surge_button.visible = true
		surge.user = Util.get_player() #TEMP
		s_gags_updated.connect(surge.sync_level.unbind(1))
		manager.s_round_ended.connect(surge.sync_level)
		surge.s_surge_level_changed.connect(on_surge_level_changed)
		on_surge_level_changed(0)
		surge.sync_level()
		%SurgeRequirements.text = surge.get_surge_requirement_text()
		%SurgeRequirements.hide()

	pass_action = load("res://objects/battle/battle_resources/pass_action.tres")

	status_container.target = Util.get_player()

	set_button_neighbors()

func gag_selected(gag: BattleAction) -> void:
	if remaining_turns <= 0:
		s_gag_canceled.emit(gag)
		complete_turn()
		return
	
	# Un-preview gag
	gag_hovered(null)

	# Parse gag data
	gag.user = Util.get_player()
	# Infer target
	match gag.target_type:
		BattleAction.ActionTarget.SELF:
			gag.targets = [Util.get_player()]
		BattleAction.ActionTarget.ENEMY, BattleAction.ActionTarget.ENEMY_SPLASH:
			# Skip choice UI if only one Cog
			if get_parent().cogs.size() == 1:
				gag.targets = get_parent().cogs.duplicate(true)
				if gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
					gag.main_target = gag.targets[0]
			else:
				# Swap UIs
				target_select.show()
				target_select.gag = gag
				target_select.reposition_buttons(get_parent().cogs.size())
				main_container.hide()
				target_select.back.grab_focus(true)
				var selection = await target_select.s_arrow_pressed
				if selection == -1:
					# Swap UIs back
					target_select.hide()
					main_container.show()
					s_gag_canceled.emit(gag)
					focus_gag_button()
					return
				else:
					# Set the target
					if gag.target_type == BattleAction.ActionTarget.ENEMY_SPLASH:
						gag.reassess_splash_targets(selection, get_parent())
					else:
						gag.targets = [get_parent().cogs[selection]]
					# Swap UIs back
					target_select.hide()
					main_container.show()
					focus_gag_button()
		_:
			gag.targets = get_parent().cogs.duplicate(true)
	selected_gags.append(gag)
	selected_gags = sort_gags(selected_gags)
	s_gag_selected.emit(gag)
	gag_order_menu.refresh_gags(selected_gags)
	s_gags_updated.emit(selected_gags)
	
	# Lower turns
	turn += 1

func refresh_turns() -> void:
	attack_label.set_text("Moves Remaining: " + str(roundi(manager.battle_stats[Util.get_player()].get_stat('turns')) - turn))
	gag_order_menu.update_panels()
	
	if remaining_turns == 0:
		for track in gag_tracks.get_children():
			track.set_disabled(true)
		fire_button.disable()
		pass_button.label.text = "GO!"
		pass_button.self_modulate = Color("18ba77")
	else:
		for track in gag_tracks.get_children():
			track.set_disabled(false)
		check_pink_slips()
		pass_button.label.text = "PASS MOVE"
		pass_button.self_modulate = Color("c19d6fff")

func check_fires() -> bool:
	return Util.get_player().stats.pink_slips > 0

func gag_hovered(gag: BattleAction):
	right_panel.preview_gag(gag)

func gag_unhovered() -> void:
	right_panel.clear_display()
	%SurgeRequirements.hide()

func complete_turn():
	var gag_order := sort_gags(selected_gags)
	
	s_turn_complete.emit(gag_order)
	selected_gags.clear()
	
	await BattleService.ongoing_battle.s_actions_ended
	
	# Reset turns
	turn = 0
	gag_order_menu.refresh_gags(selected_gags)

func sort_gags(gags: Array[ToonAttack]) -> Array[ToonAttack]:
	if Util.get_player().custom_gag_order:
		return gags
	
	var gag_order : Array[ToonAttack] = []
	var loadout: Array[Track] = Util.get_player().character.gag_loadout.loadout
	for track in loadout:
		for gag in track.gags:
			for selection in selected_gags:
				if selection.action_name == gag.action_name:
					gag_order.append(selection)
	for i in range(selected_gags.size() -1, -1, -1):
		if not selected_gags[i] in gag_order:
			gag_order.insert(0, selected_gags[i])
	
	return gag_order

func reset():
	show()
	planning_ui.show()
	cog_panels.assign_cogs(get_parent().cogs)
	for track in gag_tracks.get_children():
		track.refresh()
	status_container.refresh()

	if %TargetSelect.visible:
		# Force reset target select, and also potentially
		# refund any points player might have spent on this
		# without it going through
		# This is relevant because goggles (and maybe other items eventually)
		# can force the battle UI to be over early
		%TargetSelect.s_arrow_pressed.emit(-1)
		%TargetSelect.reset_buttons()
	focus_gag_button()
	try_start_timer()

func try_start_timer() -> void:
	var player := Util.get_player()
	if player.stats.get_battle_time() > 0:
		timer = Util.run_timer(player.stats.get_battle_time(), Control.PRESET_TOP_RIGHT)
		
		timer.timer.timeout.connect(on_timer_timeout)
		AudioManager.play_sound(load("res://audio/sfx/objects/moles/MG_sfx_travel_game_bell_for_trolley.ogg"))
		s_turn_complete.connect(
			func(_actions):
				if is_instance_valid(timer):
					timer.queue_free()
		)

func on_timer_timeout() -> void:
	if visible:
		complete_turn()

func cancel_gag(index: int):
	var gag: BattleAction = selected_gags[index]
	if !Util.get_player().can_cancel_gags or gag.ActionTag.NO_CANCEL in gag.action_tags: return
	selected_gags.remove_at(index)
	s_gag_canceled.emit(gag)
	s_gags_updated.emit(selected_gags)
	turn -= 1
	if Util.get_player().gags_cost_beans:
		refresh_tracks()
	AudioManager.play_sound(load("res://audio/sfx/ui/GUI_balloon_popup.ogg"))

func get_track_element(track: Track) -> TextureRect:
	for track_elem in gag_tracks.get_children():
		if track_elem.track == track:
			return track_elem 
	return null

func fire_pressed() -> void:
	Util.get_player().stats.pink_slips -= 1
	check_pink_slips()
	gag_selected(fire_action.duplicate(true))

func check_pink_slips() -> void:
	if Util.get_player().stats.pink_slips <= 0:
		fire_button.disable()
	else:
		fire_button.enable()

func gag_canceled(gag: BattleAction) -> void:
	if gag is ToonAttackFire:
		Util.get_player().stats.pink_slips += 1
		check_pink_slips()

func fire_hovered() -> void:
	if fire_action:
		gag_hovered(fire_action)

func open_items() -> void:
	%ItemPanel.show()
	main_container.hide()

func refresh_tracks() -> void:
	for track: TrackElement in gag_tracks.get_children():
		track.refresh()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed('end_turn') and visible:
		complete_turn()

func set_button_neighbors() -> void:
	var tracks = gag_tracks.get_children()
	var first_focused := false
	# Iterate through each TrackElement and set a two-way connection between the current one and the next available one
	for i in range(tracks.size()):
		var current_te: TrackElement = tracks[i]
		if !current_te.unlocked > -1:
			continue

		var next_te: TrackElement
		for j in range(1, tracks.size()):
			if tracks[(i + j) % tracks.size()].unlocked > 1:
				next_te = tracks[(i + j) % tracks.size()]
		
		var buttons = current_te.gag_buttons
		for k in range(buttons.size()):
			var button: GagButton = buttons[k]
			button.track_color = current_te.track.track_color
			# # Left + Right
			# button.focus_neighbor_left = buttons[k - 1].get_path()
			# button.focus_neighbor_right = buttons[(k + 1) % buttons.size()].get_path()
			# # Down + Up
			# if next_te is TrackElement:
			# 	var next_buttons = next_te.gag_buttons
			# 	var b_neighbor = next_buttons[k]
			# 	if b_neighbor.disabled:
			# 		for next_k in range(k + 1):
			# 			if next_buttons[next_k + 1].disabled:
			# 				b_neighbor = next_buttons[next_k]
			# 				break
			# 	button.focus_neighbor_top = b_neighbor.get_path()
			# 	b_neighbor.focus_neighbor_bottom = button.get_path()
			# # TEMP: set first button focus
			if !first_focused:
				last_gag_button = button
				focus_gag_button()
				first_focused = true

func focus_gag_button(_gb: GagButton = null) -> void:
	var gb = last_gag_button
	if _gb is GagButton: gb = _gb
	if gb is not GagButton: return
	gb.grab_focus.bind(true).call_deferred()

func _input(event: InputEvent):
	if event.is_pressed():
		if InputMap.event_is_action(event, "undo_move") and turn > 0:
			cancel_gag(turn - 1)

var pass_action: ToonAttack

func on_pass_pressed() -> void:
	# Check if there are free moves - if so, pass; otherwise, end turn
	var has_move: bool = roundi(manager.battle_stats[Util.get_player()].get_stat('turns')) > turn
	if has_move:
		Util.get_player().stats.restock_tick()
		var action := pass_action.duplicate(true)
		action.user = Util.get_player()
		gag_selected(action)
	else: complete_turn()

func on_pass_hovered() -> void:
	var has_move: bool = roundi(manager.battle_stats[Util.get_player()].get_stat('turns')) > turn
	if has_move:
		gag_hovered(pass_action)

func on_surge_pressed() -> void:
	# Do surge instantly
	var surge := Util.get_silly_surge()
	surge.user = Util.get_player()
	surge.manager = manager
	await Util.do_instant_battle_action(surge)
	manager.battle_stats[Util.get_player()].silly_meter -= surge.thresholds[surge.level - 1]
	surge.sync_level()
	# it is intentional to allow the player to perform their surge multiple times if they can rebuild it; this also makes low cost surges recharge-dependent instead of infinite
	disable_surge()

func on_surge_hovered() -> void:
	gag_hovered(Util.get_silly_surge())
	%SurgeRequirements.show()

func on_surge_level_changed(level := 0) -> void:
	surge_button.label.text = "SILLY SURGE"
	if level > 0:
		surge_button.disabled = false
		surge_button.self_modulate = Color(0.878, 0.858, 0.381, 1.0)
	else:
		disable_surge()
	
	for i in range(level):
		surge_button.label.text += "!"
	
	%SillyMeterBar.value = manager.battle_stats[Util.get_player()].silly_meter
	%SillyMeterBar.max_value = Util.get_silly_surge().thresholds[Util.get_silly_surge().thresholds.size() - 1]

func disable_surge() -> void:
	surge_button.disabled = true
	surge_button.self_modulate = Color(0.112, 0.144, 0.153, 1.0)
