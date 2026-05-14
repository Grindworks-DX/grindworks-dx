@tool
extends Node3D


enum TextureType { REGULAR, HOT }

const HOT_MAT := preload("res://models/props/facility_objects/mint/shelf/materials/moneybag_hot_mat.tres")
const REGULAR_MAT := preload("res://models/props/facility_objects/mint/shelf/materials/moneybag_regular_mat.tres")

const SHELF_PANEL_REGULAR_MAT := preload("res://models/props/facility_objects/mint/shelf/materials/shelf_panel_regular_mat.tres")
const SHELF_PANEL_HOT_MAT := preload("res://models/props/facility_objects/mint/shelf/materials/shelf_panel_hot_mat.tres")
const SHELF_BACK_REGULAR_MAT := preload("res://models/props/facility_objects/mint/shelf/materials/shelf_back_regular_mat.tres")
const SHELF_BACK_HOT_MAT := preload("res://models/props/facility_objects/mint/shelf/materials/shelf_back_hot_mat.tres")

@export var texture_type := TextureType.REGULAR:
	set(x):
		texture_type = x
		await NodeGlobals.until_ready(self)
		update_texture()


func update_texture() -> void:
	var shelf_mesh: MeshInstance3D = NodeGlobals.get_child_of_type(%shelf_2, MeshInstance3D)
	match texture_type:
		TextureType.REGULAR:
			shelf_mesh.set_surface_override_material(1, SHELF_BACK_REGULAR_MAT)
			shelf_mesh.set_surface_override_material(2, SHELF_PANEL_REGULAR_MAT)
			for mesh in NodeGlobals.get_children_of_type(%MoneyBags, MeshInstance3D, true):
				mesh.set_surface_override_material(0, REGULAR_MAT)
		TextureType.HOT:
			shelf_mesh.set_surface_override_material(1, SHELF_BACK_HOT_MAT)
			shelf_mesh.set_surface_override_material(2, SHELF_PANEL_HOT_MAT)
			for mesh in NodeGlobals.get_children_of_type(%MoneyBags, MeshInstance3D, true):
				mesh.set_surface_override_material(0, HOT_MAT)
