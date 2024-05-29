extends CharacterBody2D

# Simple player movement script.
# Use arrwos to move.

## Speed of the player.
@export var speed : int = 54

var direction : Vector2 = Vector2.ZERO

@warning_ignore("unused_parameter")
func _physics_process(delta):
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	velocity = direction.normalized() * speed
	
	move_and_slide()
