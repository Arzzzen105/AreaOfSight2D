extends CharacterBody2D

@export var follow_node : PathFollow2D

@onready var area_of_sight : AreaOfSight2D = $AreaOfSight2D

func _physics_process(delta):
	global_position = follow_node.global_position
	rotation = lerp_angle(rotation, follow_node.rotation, 10 * delta)

# Make AreaOfSight2D red when sees player.
func _on_area_of_sight_node_entered_area(node):
	if node.is_in_group("player"):
		print(name, " has noticed ", node.name)
		area_of_sight.area_color = Color.RED

# Make AreaOfSight2D green when doesn't see player.
func _on_area_of_sight_node_exited_area(node):
	if node.is_in_group("player"):
		print(name, " has lost ", node.name)
		area_of_sight.area_color = Color.GREEN
