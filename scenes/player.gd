extends CharacterBody2D
@onready var animation = $AnimationPlayer
@onready var player_sprite = $PlayerSprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@export var speed : float = 100
var direction : Vector2 = Vector2.ZERO

func _ready() -> void:
	animation_tree["active"] = true

func _process(delta: float) -> void:
	update_animation_parameter()

func _physics_process(delta):
	var direction = Input.get_vector("ui_left","ui_right","ui_up","ui_down").normalized()
	var mouse_position = get_global_mouse_position()
	if mouse_position.x > position.x:
		player_sprite.flip_h = false
	else:
		player_sprite.flip_h = true
	if direction:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO	
	move_and_slide()

func update_animation_parameter():
	if (velocity == Vector2.ZERO):
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/is_moving"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/is_moving"] = true
	
	if(Input.is_action_just_pressed("attack")):
		animation_tree["parameters/conditions/swing"] = true
	else:
		animation_tree["parameters/conditions/swing"] = false
	if (direction != Vector2.ZERO):
		animation_tree["parameters/idle/blend_position"] = direction
		animation_tree["parameters/atack/blend_position"] = direction
		animation_tree["parameters/walk/blend_position"] = direction
