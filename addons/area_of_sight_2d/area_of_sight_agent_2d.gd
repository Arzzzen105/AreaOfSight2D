@tool
@icon("res://addons/area_of_sight_2d/icons/area_of_sight_agent_icon.svg")
class_name AreaOfSightAgent2D extends Area2D

## A node tracked by [AreaOfSight2D]. [br]
## [b][i]The shape of the [AreaOfSightAgent2D] can be only a circle![/i][/b][br]
## WARNING: DO NOT CHANGE VARIABLES AND CALL MATHODS THAT STARTS WITH AN UNDERSCOPE!

## Set the node that use the [AreaOfSightAgent2D] here. Usually a player scene.
@export var parent_node : Node2D

@export_group("Circle shape")

## Radius of [CircleShape2D] of [CollisionShape2D]
@export_range(0, 64, 1, "or_greater", "hide_slider") var radius : int = 8 : set = _update_radius

## A number of points that [AreaOfSight2D] will use to consider [AreaOfSightAgent2D] is spotted.
@export_range(4, 64, 4, "or_greater", "hide_slider") var target_points_amount : int = 8 : set = _update_target_points_amount

@export_group("Debug")
## The debug color of the [AreaOfSightAgent2D]
@export var debug_color : Color = Color(1, 0, 1, 0.2):
	set(new_col):
		debug_color = new_col
		_collision_shape.debug_color = debug_color

## Points that [AreaOfSight2D] will use to consider if [AreaOfSightAgent2D] is spotted.
var target_points : PackedVector2Array = []

var _collision_shape : CollisionShape2D = CollisionShape2D.new()
var _shape : CircleShape2D = CircleShape2D.new()

func _ready() -> void:
	_setup_scene()
	_update_radius(radius)

# Updates the value of [member AreaOfSightAgent2D.target_points].
func _set_target_points():
	target_points.clear()
	
	target_points.append(Vector2.ZERO)
	var step_angle = 2 * PI / target_points_amount
	for i in range(target_points_amount):
		target_points.append(Vector2(radius, 0).rotated(i * step_angle))

#region init methods, setgets

func _setup_scene() -> void:
	_collision_shape.shape = _shape
	_collision_shape.debug_color = Color(1, 0, 1, 0.15)
	add_child(_collision_shape)

func _update_radius(new_val : int):
	radius = new_val
	_shape.radius = radius
	_set_target_points()

func _update_target_points_amount(new_val : int):
	target_points_amount = new_val
	_set_target_points()

#endregion
