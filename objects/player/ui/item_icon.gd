extends TextureRect
class_name ItemIcon

@onready var counter_label := %CounterLabel

@onready var item: Item:
	set(x):
		item = x
		
		if x is Item:
			texture = item.icon
			if item.icon_material:
				material = item.icon_material
			if !is_node_ready(): await ready
			x.s_item_icon_connected.emit(self)
