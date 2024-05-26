extends Area2D

@export var speed = 125.0
@export var steer_force = 95.0

var velocity = Vector2.ZERO
var acceleration = Vector2.ZERO
var target = null


func init():
	set_random_target()

func start(_position):
	position = _position
	rotation += randf_range(-0.09, 0.09)
	velocity = transform.x * speed
	set_random_target()

func seek():
	var steer = Vector2.ZERO
	if target:
		var desired = (target.position - position).normalized() * speed
		steer = (desired - velocity).normalized() * steer_force
	return steer

func _physics_process(delta):
	acceleration += seek()
	velocity += acceleration * delta
	velocity = velocity.limit_length(speed)
	rotation = velocity.angle()
	position += velocity * delta

func _on_Missile_body_entered(body):
	explode()

func explode():
	#$Particles2D.emitting = false
	set_physics_process(false)
	#$AnimationPlayer.play("explode")
	#await $AnimationPlayer.animation_finished
	queue_free()

func set_random_target():
	var p_dicts_copy = GameManager.player_dicts.duplicate(true)
	var player
	
	# If curr_index is null, we just instantiated the object and need to set an initial target.
	# This if statement excludes the current target if it exists.
	if (target != null):
		p_dicts_copy.erase(target)
	
	var rand_index:int = p_dicts_copy.keys()[randi() % p_dicts_copy.size()]
	player = p_dicts_copy[rand_index]
	
	target = get_parent().get_node(player[1])
