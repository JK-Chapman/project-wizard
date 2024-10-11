extends CharacterBody2D

#@export var speed_stage = 0
#@export var steer_force = 130.0
@export var missile_stage = 0

# missile stages
var MAX_STAGE = 3
var speed_stages = [100.0, 180.0, 275.0, 300.0]
var steer_forces = [125.0, 165.0, 165.0, 300.0]

# missile vars
var current_velocity = Vector2.ZERO
var acceleration = Vector2.ZERO
var target = null
var target_index = null
var deflect_dir
var drag = 0.12


func init():
	set_random_target()

func start(_position):
	position = _position
	rotation += randf_range(-0.09, 0.09)
	current_velocity = transform.x * speed_stages[missile_stage] * 3
	set_random_target()

func _physics_process(delta):
	var direction = transform.x
	
	if target:
		direction = global_position.direction_to(target.global_position)
	
	var desired_velocity = direction * speed_stages[missile_stage]
	var previous_velocity = current_velocity
	var change = (desired_velocity - current_velocity) * drag
	
	current_velocity += change
	
	var collision = move_and_collide(current_velocity * delta)
	if collision:
		var collider = collision.get_collider()
		
		if collider.is_in_group("player"):
			explode()
		else:
			print("the current")
			print(current_velocity)
			print("the normal")
			print(collision.get_normal())
			current_velocity = current_velocity.bounce(collision.get_normal())
			print("after bounce")
			print(current_velocity)
	
	#position += velocity * delta
	look_at(global_position + current_velocity)
	

	
	#acceleration += seek()
	#velocity += acceleration * delta
	#velocity = velocity.limit_length(speed_stages[missile_stage])
	#rotation = velocity.angle()
	#position += velocity * delta

func _on_Missile_body_entered(body):
	explode()

func deflect(direction):
	target = null
	
	rotation += randf_range(-15, 15)
	current_velocity = current_velocity.abs() * direction.normalized()
	acceleration = acceleration.abs() * direction.normalized()
	
	if (missile_stage < MAX_STAGE):
		missile_stage += 1
	
	$TrackingTimer.start()

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
	if (target_index != null and p_dicts_copy.size() > 1):
		p_dicts_copy.erase(target_index)
		target_index = null
	
	target_index = p_dicts_copy.keys()[randi() % p_dicts_copy.size()]
	player = p_dicts_copy[target_index]
	
	target = get_parent().get_node(player[1])


func _on_tracking_timer_timeout():
	set_random_target()
