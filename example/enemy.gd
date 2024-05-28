extends CharacterBody2D

@onready var area_of_sight : AreaOfSight = $AreaOfSight

# Make AreaOfSight red when sees player.
func _on_area_of_sight_node_entered_area(node):
	if node.is_in_group("player"):
		area_of_sight.area_color = Color.RED

# Make AreaOfSight green when doesn't see player.
func _on_area_of_sight_node_exited_area(node):
	if node.is_in_group("player"):
		area_of_sight.area_color = Color.GREEN
