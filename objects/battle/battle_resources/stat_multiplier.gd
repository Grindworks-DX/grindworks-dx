extends Resource
class_name StatMultiplier

@export var stat: String
@export var amount: float
@export var additive := false

func _init(_stat := 'damage', _amount := 1.0, _additive := false) -> void:
	stat = _stat
	amount = _amount
	additive = _additive
