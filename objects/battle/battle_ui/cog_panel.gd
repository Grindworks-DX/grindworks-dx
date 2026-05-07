extends Control

const BASE_MASK_SIZE := 184.0

# Child references
@onready var light := %HealthLight
@onready var glow := %HealthGlow
@onready var face := %CogFace
@onready var level_label := %Level
@onready var hp_label := %CogHP
@onready var status_container := %StatusEffects
@onready var effect_panel := %EffectPanel
@onready var speed_label := %SpeedLabel
@onready var advantage_label := %AdvantageLabel
@onready var profile := %Profile

@onready var effect_mask := %StatusEffectMask

var current_cog: Cog
var expand_tween : Tween
var status_effects: Array[StatusEffect] = []
var hp_hidden := false:
	set(x):
		hp_hidden = x
		await NodeGlobals.until_ready(self)
		hp_label.set_visible(not hp_hidden)


func set_cog(cog: Cog):
	# Match HP light
	var cog_changed: bool = current_cog != cog
	current_cog = cog

	if cog_changed:
		cog.hp_light.s_color_changed.connect(sync_colors.bind(cog))
	sync_colors(cog.hp_light.get_surface_override_material(0).albedo_color, cog.hp_light.get_child(0).get_surface_override_material(0).albedo_color, cog)
	
	# Show level
	level_label.text = ("Level %d" % cog.level) if !cog.v2 else "Lv%d v2.0" % cog.level

	if not hp_hidden:
		hp_label.show()

	cog.stats.hp_changed.connect(set_hp_label.unbind(1))
	set_hp_label()
	BattleService.ongoing_battle.battle_stats[cog].s_speed_changed.connect(set_speed_label)
	set_speed_label(BattleService.ongoing_battle.battle_stats[cog].speed)
	BattleService.ongoing_battle.s_enemy_moves_assigned.connect(set_advantage_label)
	set_advantage_label()
	
	BattleService.s_round_ended.connect(func(_x):
		if !is_instance_valid(current_cog): queue_free() 
	)

	var head: Node3D = cog.dna.get_head()
	if not cog.dna.head_scale.is_equal_approx(Vector3.ONE * cog.dna.head_scale.x):
		head.scale = cog.dna.head_scale
	face.node = head

	if not BattleService.ongoing_battle:
		await BattleService.s_battle_started
	BattleService.ongoing_battle.s_status_effect_added.connect(func(x: StatusEffect):
		if x.target == cog:
			populate_status_effects(cog)
			x.s_expire.connect(populate_status_effects.bind(cog))
	)
	populate_status_effects(cog)

func set_hp_label():
	hp_label.text = str(current_cog.stats.hp) + '/' + str(current_cog.stats.max_hp)
	if !current_cog.stats.hp > 0:
		modulate = Color(0.451, 0.451, 0.451, 1.0)
		light.hide()
		glow.hide()
		effect_mask.hide()

func set_speed_label(new_speed: int):
	speed_label.text = str(new_speed)

const ADV_LABEL_SETTINGS := [preload("res://ui_assets/battle/labelsettings_adv_label_good.tres"), preload("res://ui_assets/battle/labelsettings_adv_label_bad.tres")]

func set_advantage_label():
	if !is_instance_valid(current_cog): return
	
	var moves := current_cog.stats.turns
	advantage_label.visible = moves != 1 or current_cog.current_moves.is_empty()
	if moves == 1 and !current_cog.current_moves.is_empty(): return
	
	var delayed: bool = moves == 0 or current_cog.current_moves.is_empty()
	advantage_label.label_settings = ADV_LABEL_SETTINGS[int(delayed)]
	
	if delayed:
		advantage_label.text = "Delayed!" if !current_cog.stunned else "Stunned!"
	else:
		advantage_label.text = "%d Extra Move" % (moves - 1)
		if moves > 2: advantage_label.text += "s"
		for i in range(moves):
			advantage_label.text += "!"

func sync_colors(light_color: Color, glow_color: Color, cog: Cog):
	if (not is_instance_valid(cog)) or cog != current_cog:
		return
	light.self_modulate = light_color
	glow.self_modulate = glow_color

func populate_status_effects(target : Cog) -> void:
	for icon in status_container.get_children():
		icon.queue_free()
	status_effects = BattleService.ongoing_battle.get_statuses_for_target(target)
	for effect in status_effects:
		if not effect.visible:
			continue
		var new_icon: StatusEffectIcon = StatusEffectIcon.create()
		new_icon.effect = effect
		status_container.add_child(new_icon)
	await get_tree().process_frame
	effect_mask.size.y = get_retract_size()
	effect_panel.modulate.a = 0.0

func statuses_hovered() -> void:
	if status_effects.size() >= 9:
		expand()

func statuses_unhovered() -> void:
	retract()

func expand() -> void:
	if expand_tween and expand_tween.is_running():
		expand_tween.kill()
	
	expand_tween = create_tween().set_trans(Tween.TRANS_QUAD)
	expand_tween.tween_property(effect_mask, 'size:y', status_container.size.y, 0.15)
	expand_tween.parallel().tween_property(effect_panel, 'modulate:a', 1.0, 0.15)

func retract() -> void:
	if expand_tween and expand_tween.is_running():
		expand_tween.kill()
	
	expand_tween = create_tween().set_trans(Tween.TRANS_QUAD)
	expand_tween.tween_property(effect_mask, 'size:y', get_retract_size(), 0.15)
	expand_tween.parallel().tween_property(effect_panel, 'modulate:a', 0.0, 0.15)

func get_retract_size() -> float:
	return minf(status_container.size.y, BASE_MASK_SIZE)
