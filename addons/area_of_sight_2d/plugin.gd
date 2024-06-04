@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("AreaOfSight2D", "Node2D", preload("area_of_sight_2d.gd"), preload("icons/area_of_sight_icon.svg"))
	add_custom_type("AreaOfSightAgent2D", "Area2D", preload("area_of_sight_agent_2d.gd"), preload("icons/area_of_sight_agent_icon.svg"))


func _exit_tree():
	remove_custom_type("AreaOfSight2D")
	remove_custom_type("AreaOfSightAgent2D")
	pass
