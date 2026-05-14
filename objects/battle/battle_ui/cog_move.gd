extends TextureRect

var action: BattleAction:
	set(x):
		action = x
		if action is BattleAction: setup()
var damage := 0:
	set(x):
		damage = x
		if damage is int:
			if damage > 0:
				damage_label.label_settings.font_color = Color(1.0, 0.0, 0.0, 1.0)
				damage_label.text = "-" + str(damage)
			else:
				damage_label.label_settings.font_color = Color("ff4d00")
				damage_label.text = "!"
		s_cog_move_updated.emit()

signal s_cog_move_updated

@onready var damage_label := %DamageLabel
@onready var accuracy_bar := %AccuracyBar

func setup() -> void:
	var manager := BattleService.ongoing_battle
	accuracy_bar.value = 0.0
	
	var cog: Cog = action.user
	
	var head: Node3D = cog.dna.get_head()
	if not cog.dna.head_scale.is_equal_approx(Vector3.ONE * cog.dna.head_scale.x):
		head.scale = cog.dna.head_scale
	%CogFace.node = head
	get_node('GeneralButton').disabled = true
	
	update()
	# good god why
	manager.battle_stats[action.user].s_stat_changed.connect(update)
	action.user.stats.hp_changed.connect(update.unbind(1))
	action.user.stats.s_stunned.connect(update)
	manager.battle_stats[Util.get_player()].s_stat_changed.connect(update)
	manager.s_status_effect_added.connect(update.unbind(1))

func update(stat := "") -> void:
	var manager := BattleService.ongoing_battle
	if stat != "" and stat not in ['hp', 'damage', 'defense', 'accuracy', 'evasiveness']: return
	
	if !action.user.stats.hp > 0 or action.user.stunned:
		modulate = Color(0.337, 0.337, 0.337, 0.867)
		return
	else: modulate = Color(1.0, 1.0, 1.0, 1.0)
		
	var accuracy_lerp := LerpProperty.new(accuracy_bar, ^"value", 1.5, manager.calculate_accuracy(action), accuracy_bar.value)
	var damage_lerp := LerpProperty.new(self, ^"damage", 1.5, manager.get_damage(action.damage, action, Util.get_player()), damage)
	for _lerp: LerpProperty in [accuracy_lerp, damage_lerp]:
		_lerp.interp(Tween.EaseType.EASE_OUT, Tween.TransitionType.TRANS_QUAD)
		_lerp.as_tween(self)
	%TargetingLabel.text = get_source_string(action.user)
	
	s_cog_move_updated.emit()

func get_source_string(_cog: Cog) -> String:
	var manager := BattleService.ongoing_battle
	var atk_string := ""
	for cog in manager.cogs:
		if cog == _cog:
			atk_string += "V"
		else:
			atk_string += "-"
		if manager.cogs.find(cog) < manager.cogs.size() - 1:
			atk_string += ""
	return atk_string
