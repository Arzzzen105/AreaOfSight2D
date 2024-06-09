@tool
@icon("res://addons/area_of_sight_2d/icons/area_of_sight_icon.svg")
class_name AreaOfSight2D extends Node2D

## A node for a procedurally generated area of sight (usually cone of sight). [br]
## [AreaOfSight2D] [b]does NOT[/b] track [Area2D]s and other [CollisionObject2D]s! [b]Use [AreaOfSightAgent2D] instead.[/b][br]
## WARNING: DO NOT CHANGE VARIABLES AND CALL MATHODS THAT STARTS WITH AN UNDERSCOPE!

## Emitted when the [AreaOfSightAgent2D] of [param node] enters the [AreaOfSight2D].
signal node_entered_area(node : Node2D)
## Emitted when the [AreaOfSightAgent2D] of [param node] exits the [AreaOfSight2D].
signal node_exited_area(node : Node2D)

@export_group("Vision")

## Max distance that [AreaOfSight2D] can reach.
@export_range(0, 256, 8, "or_greater") var radius : int = 80 : set = _update_radius

## [AreaOfSight2D]'s angle of view.
@export_range(0, 360, 5, "or_greater") var angle_deg : int = 90: 
	set(new_val):
		angle_deg = new_val
		_update_angle_params()

## Amount of rays that [AreaOfSight2D] uses to render the polygon.
## The smaller the value, the faster the render will happen and the worse the accuracy of detection will be.
@export_range(2, 360, 1, "or_greater") var rays_amount : int = 90: 
	set(new_val):
		rays_amount = new_val
		_update_angle_step()

@export_subgroup("Debug")

## When enabled, [member AreaOfSight2D._detecting_shape] will be shown.
@export var show_reach_area_in_editor : bool = false : set = _update_visibility_in_editor

## The debug color of [member AreaOfSight2D._detecting_shape].
@export var debug_color : Color = Color(1, 0, 1, 0.1) : set = _update_debug_color

@export_group("Collision")

## The layers that rays of the area polygon will track. Usually a wall and obstacles.
@export_flags_2d_physics var obstacle_mask = 0

## The layers of [AreaOfSightAgent2D]s that the AreaOfSight2D will track. Usually a player.
@export_flags_2d_physics var tracking_agents_mask = 0 : set = _update_tracking_mask

## Add the parent's [AreaOfSightAgent2D] here to avoid selftracking. Ignore if parent doesn't have own [AreaOfSightAgent2D].
@export var parent_agent : AreaOfSightAgent2D

@export_group("Colors")

## Color of the area polygon.
@export var area_color : Color : set = _update_area_color

## Texture of area polygon. Usually used as [GradientTexture1D].
@export var area_texture : Texture2D : set = _update_area_texture

## The edge of the area polygon will be drawn if enabled.
@export var show_edge : bool = false:
	set(new_value):
		show_edge = new_value
		notify_property_list_changed()

# The color of the edge. Ignore if show_edge is disabled.
var edge_color : Color : set = _update_edge_color

# Width of the edge of the area. Ignore if show_edge is disabled.
var edge_width : float = 1 : set = _update_edge_width

# Private Polygon2D that draws the area.
var _area_polygon : Polygon2D = Polygon2D.new()

# Private Line2D that draws the edge of the area. Will not be shown if member AreaOfSight2D.show_edge is disabled.
var _edge : Line2D = Line2D.new()

# Private Area2D used to storage all the AreaOfSightAgent2Ds 
# that are in the distanse of member AreaOfSight2D.radius to the AreaOfSight2D. 
# signal Area2D.area_entered and signal Area2D.area_entered are connected to 
# method AreaOfSight2D._add_to_reach_area_list and method AreaOfSight2D._remove_from_reach_area_list.
var _detecting_area : Area2D = Area2D.new()

# Private CollisionShape2D to setup the member AreaOfSight2D._detecting_area.
var _detecting_shape : CollisionShape2D = CollisionShape2D.new()

# Private CircleShape2D to setup the member AreaOfSight2D._detecting_shape.
var _detecting_cirlce_shape : CircleShape2D = CircleShape2D.new()

# Variables for working with angles in radians. Updated when angle_deg is changed
var _angle_rad : float
var _semiangle : float
var _angle_step : float

# A PackedVector2Array of points that are used to draw the AreaOfSight2D. Updated in [method AreaOfSight2D._set_points].
var _polygon_points : PackedVector2Array = []

# An Array of AreaOfSightAgent2Ds that area in member AreaOfSight2D._detecting_area.
var _agents_in_reach_area : Array[AreaOfSightAgent2D] = []

# An Array of Node2Ds that are seen by the AreaOfSight2D. Updated in method AreaOfSight2D._check_collisions.
var _nodes_in_area_of_sight : Array[Node2D] = []

# Initialization of the scene
func _ready() -> void:
	
	await get_tree().physics_frame
	
	_setup_scene()
	_set_points()
	_redraw()
	_check_collisions()

@warning_ignore("unused_parameter")
func _process(delta : float) -> void:
	_redraw()

@warning_ignore("unused_parameter")
func _physics_process(delta : float) -> void:
	_set_points()
	_check_collisions()

# Method that adds edge_color to the editor inspector
# when param show_edge is enabled.
func _get_property_list():
	var result : Array[Dictionary] = []
	var usage = PROPERTY_USAGE_NO_EDITOR
	if show_edge:
		usage = PROPERTY_USAGE_DEFAULT
		
	result.append({
			"name" : "edge_color",
			"type" : TYPE_COLOR,
			"usage" : usage
		})
		
	result.append({
			"name" : "edge_width",
			"type" : TYPE_FLOAT,
			"usage" : usage,
			"hint" : PROPERTY_HINT_RANGE,
			"hint_string" : "0, 5, 0.2"
		})
	
	return result

#region draw methods

# Redraws the area using method AreaOfSight2D._redraw_polygon and method AreaOfSight2D._redraw_edge.
func _redraw() -> void:
	_redraw_polygon()
	if show_edge:
		_redraw_edge()
	else:
		_edge.points = []

# Redraws the area.
func _redraw_polygon() -> void:
	_area_polygon.polygon = _polygon_points

# Redraws the edge of the area. Ignored when member AreaOfSight2D.show_edge is disabled.
func _redraw_edge() -> void:
	_edge.points = _polygon_points

#endregion

#region collision methods

# Set member AreaOfSight2D._polygon_points using method AreaOfSight2D._ray_to.
func _set_points() -> void:
	var result : PackedVector2Array = []
	var it = -1
	if angle_deg <  360:
		result.append(Vector2.ZERO)
		it = 1
		
	for i in range(rays_amount + it):
		var point : Vector2 = _ray_to(
			to_global(Vector2(radius, 0).rotated(rotation - _semiangle + i * _angle_step))
		)
		result.append(to_local(point))
		
	if it == 0:
		result.append(result[0])
	_polygon_points = result


# Returns the coordinates of a ray collision position from member Node2D.global_position
# of AreaOfSight2D to Vector2 param to. If there's no collision, then returns param to.
# The raycasting takes place with the usage of method DirectSpaceState.intersect_ray
func _ray_to(to : Vector2) -> Vector2:
	
	if Engine.is_editor_hint():
		return to
		
	var space = get_world_2d().direct_space_state
	
	var result = space.intersect_ray(PhysicsRayQueryParameters2D.create(
		global_position, to, obstacle_mask, [self]
	))
	
	if result:
		return result.position
	else:
		return to


# Iterates over all AreaOfSight2D in the reach area and applies method AreaOfSight2D.sees_agent
# to them to update the member AreaOfSight2D._nodes_in_area_of_sight. 
# If some agent has just entered the AOS, then emits signal AreaOfSight2D.node_entered_area.
# If some agent has just exited the AOS, then emits signal AreaOfSight2D.node_exited_area.
func _check_collisions() -> void:
	for agent in _agents_in_reach_area:
		
		var has_common_bits = (agent.collision_layer & tracking_agents_mask) > 0
		
		if not has_common_bits:
			_agents_in_reach_area.erase(agent)
			
			if agent.parent_node in _nodes_in_area_of_sight:
				_nodes_in_area_of_sight.erase(agent.parent_node)
				node_exited_area.emit(agent.parent_node)
			
			continue
		
		var see_agent = sees_agent(agent)
		var node = agent.parent_node
		
		if not node:
			continue
		
		if (see_agent) and (not node in _nodes_in_area_of_sight):
			_nodes_in_area_of_sight.append(node)
			node_entered_area.emit(node)
		elif (not see_agent) and (node in _nodes_in_area_of_sight):
			_nodes_in_area_of_sight.erase(node)
			node_exited_area.emit(node)


# Adds an param agent to member AreaOfSight2D._agents_in_reach_area.
func _add_to_reach_area_list(agent : Area2D) -> void:
	if agent is AreaOfSightAgent2D and agent != parent_agent:
		if not agent in _agents_in_reach_area:
			_agents_in_reach_area.append(agent)


# Removes an param agent from member AreaOfSight2D._agents_in_reach_area.
func _remove_from_reach_area_list(agent : Area2D) -> void:
	if agent is AreaOfSightAgent2D and agent != parent_agent:
		if agent in _agents_in_reach_area:
			_agents_in_reach_area.erase(agent)


## Returns [code]true[/code] if the [param agent] is seen by the [AreaOfSight2D] at the moment.
## Uses [member AreaOfSightAgent2D.target_points] to calculate.
func sees_agent(agent : AreaOfSightAgent2D) -> bool:
	
	var agent_pos : Vector2 = to_local(agent.global_position)
	for point in agent.target_points:
		var point_to_check : Vector2 = agent_pos + point
		if Geometry2D.is_point_in_polygon(point_to_check, _polygon_points):
			return true
	
	return false


## Returns the [Array] of [Node]s whose [AreaOfSightAgent2D]s are in the [AreaOfSight2D] at the moment.
func get_spotted_nodes() -> Array[Node2D]:
	return _nodes_in_area_of_sight

#endregion

#region init methods, setgets


func _setup_scene() -> void:
	
	_edge.closed = true
	_detecting_area.collision_layer = 0
	_detecting_shape.shape = _detecting_cirlce_shape
	_detecting_area.area_entered.connect(_add_to_reach_area_list)
	_detecting_area.area_exited.connect(_remove_from_reach_area_list)
	
	add_child(_area_polygon)
	add_child(_edge)
	add_child(_detecting_area)
	_detecting_area.add_child(_detecting_shape)
	
	_update_scene_props()


func _update_scene_props() -> void:
	_update_angle_params()
	_update_area_color(area_color)
	_update_area_texture(area_texture)
	_update_edge_color(edge_color)
	_update_edge_width(edge_width)
	_update_tracking_mask(tracking_agents_mask)
	_update_radius(radius)
	_update_debug_color(debug_color)
	_update_visibility_in_editor(show_reach_area_in_editor)


func _update_angle_params() -> void:
	_angle_rad = deg_to_rad(angle_deg)
	_semiangle = _angle_rad / 2
	_update_angle_step()


func _update_angle_step() -> void:
	_angle_step = _angle_rad / rays_amount


func _update_area_color(new_col : Color) -> void:
	area_color = new_col
	_area_polygon.color = new_col


func _update_area_texture(new_text : Texture2D) -> void:
	if new_text:
		area_texture = new_text
		_area_polygon.texture = new_text


func _update_edge_color(new_col : Color) -> void:
	edge_color = new_col
	_edge.default_color = new_col


func _update_edge_width(new_width : float) -> void:
	edge_width = new_width
	_edge.width = new_width


func _update_tracking_mask(new_bitmask : int) -> void:
	tracking_agents_mask = new_bitmask
	_detecting_area.collision_mask = new_bitmask


func _update_radius(new_raduis : int) -> void:
	radius = new_raduis
	_detecting_cirlce_shape.radius = new_raduis


func _update_debug_color(new_col : Color):
	debug_color = new_col
	_detecting_shape.debug_color = debug_color
	

func _update_visibility_in_editor(new_val : bool):
	show_reach_area_in_editor = new_val
	_detecting_shape.visible = new_val


#endregion
