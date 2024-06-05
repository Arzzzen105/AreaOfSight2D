# Description🧾
A plugin which adds an AOS (Area of Sight) node for 2D. Often used of showing a danger area in stealth games.
## Exapmle
![Example gif](https://github.com/Arzzzen105/AreaOfVision/blob/main/images/preview.gif)

# Contents📰
This plugin adds two nodes:
- AreaOfSight2D (extends Node2D)
- AreaOfSightAgent2D (extends Area2D)
  
### AreaOfSight2D
This node is an AOS itself. You can see all the properties below:\
![AreaOfSight2D](https://github.com/Arzzzen105/AreaOfVision/blob/main/images/area_of_sight_props.png)\
All this parameters are desribed in the docs and in the comments in the code.\
The procedurally generetion is made with raycasting. I didn't use Ray2D, it would be too slow. Instead I used [PhysicsDirectSpaceState2D.intersect_ray](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html#class-physicsdirectspacestate2d-method-intersect-ray). 
### AreaOfSightAgent2D
This is an interesting one. AreaOfSight2D doesn't work with any CollisionObject2D (like Area2D, CharacterBody2D ect.) Instead you have to use AreaOfSight2D. The node itself is just an Area2D but with some additional parameters.

Agents has a member target_points, which is a PackedVector2Array. This array contains points which the AreaOfSight2D will use to consider if the agent is seen or not.\
![AreaOfSight2D insturction](https://github.com/Arzzzen105/AreaOfVision/blob/main/images/agent%20target_points.png)\
The red points are contained in target_points. As you can see, they are located in a cirlce (the center of this circle is also in target_points). The target_points_amount will change the size of target_points. The larger the value, the more accurate the calculations will be. But don't increase the target_points_amount, it can result in lags. In my opinion, the value of 8 is perfect for small objects. It's better to set the values that are a power of 2 (4, 8, 16, 32...). To decide if the agent is in the area of sight I iterated over target_points and applied [Geometry2D.is_point_in_polygon](https://docs.godotengine.org/en/stable/classes/class_geometry2d.html#class-geometry2d-method-is-point-in-polygon) to each target point.

# Why agents?🤔
At first a planned to make an AreaOfSight extend Area2D and change its CollisionPolygon2D shape in the process. Although this method is obvious, it had a huge problem: when the area shape is redrawn, the collisions of Area2D are recalculated. This contributed to some problems with tracking other areas and bodies while changing area's shape. That's why a decided to create an agent node.

# Getting started✅
- Install the plugin;
- Enable the plugin in project setiings;
- Create a simple enemy scene:\
  ![Enemy scene node screenshot](https://github.com/Arzzzen105/AreaOfVision/blob/main/images/scene%20inspector.png)
- Add some walls (using Tilemap or CollisionObject2D) and player scene;
- Add AreaOfSightAgent2D to player's scene;
- Configure collision layers and masks;
- Have fun with AreaOfSight2D parameters!

It's also recommended to check the example scene. You can struggle with agents or collision layers, so check how I did it.
