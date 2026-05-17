extends TextureRect
class_name ItemIcon

@onready var counter_label := %CounterLabel

var use_count_label := false

@onready var item: Item:
	set(x):
		item = x
		
		if x is Item:
			texture = item.icon
			if item.icon_material:
				material = item.icon_material
			if !is_node_ready(): await ready
			#if item.item_script is Script:
				#await item.s_item_script_applied
			x.s_item_icon_connected.emit(self)
