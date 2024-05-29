extends Node2D

func _on_slider_value_changed(value):
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.area_of_sight.radius = value


func _on_angle_slider_value_changed(value):
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.area_of_sight.angle_deg = value
		enemy.area_of_sight.rays_amount = value

