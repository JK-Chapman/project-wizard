extends Area2D

#@export var speed_stage = 0
#@export var steer_force = 130.0
@export var missile_stage = 0
@export var missile_damage = 1

# missile stages
var MAX_STAGE = 9
var speed_stages = [150.0, 180.0, 275.0, 300.0, 320.0, 340.0, 360.0, 400.0, 500.0, 600.0, 900.0]
var steer_forces = [125.0, 165.0, 165.0, 300.0, 300.0, 300.0, 300.0, 300.0, 340.0, 400.0, 500.0]

# missile vars
var velocity = Vector2.ZERO
var acceleration = Vector2.ZERO
var target = null
var target_vars = null
var deflect_dir
var drag = 0.12


func init():
	set_random_target()

func start(_position):
	position = _position
	rotation += randf_range(-0.09, 0.09)
	velocity = transform.x * speed_stages[missile_stage] * 3
	set_random_target()

func _physics_process(delta):
	var direction = transform.x
	
	if is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)
	elif $TrackingTimer.is_stopped(): # our target is gone, pick a new one
		set_random_target()
	
	var desired_velocity = direction * speed_stages[missile_stage]
	#var previous_velocity = velocity
	var change = (desired_velocity - velocity) * drag
	
	velocity += change
	
	position += velocity * delta
	look_at(global_position + velocity)
	
	#acceleration += seek()
	#velocity += acceleration * delta
	#velocity = velocity.limit_length(speed_stages[missile_stage])
	#rotation = velocity.angle()
	#position += velocity * delta

func _on_Missile_body_entered(_body):
	if (_body.is_in_group("player")):
		_body.take_damage(missile_damage)
		pass
	explode()

func deflect(direction):
	target = null
	
	$MissileDeflected.play()
	
	rotation += randf_range(-15, 15)
	velocity = velocity.abs() * direction.normalized()
	acceleration = acceleration.abs() * direction.normalized()
	
	if (missile_stage < MAX_STAGE):
		missile_stage += 1
	
	$TrackingTimer.start()

func explode():
	#$Particles2D.emitting = false
	set_physics_process(false)
	$MissileExplode.play()
	#$AnimationPlayer.play("explode")
	#await $AnimationPlayer.animation_finished
	queue_free()

func set_random_target():
	var p_array_copy = GameManager.player_array.duplicate(true).filter(func(p): return p.player_dead == false)
	
	# If target_vars is null, we just instantiated the object and need to set an initial target.
	# This if statement excludes the current target if it exists.
	if (target_vars != null and p_array_copy.size() > 1):
		p_array_copy.erase(target_vars)
	
	# can't have a target if there are no possible targets! :D
	if p_array_copy.size() == 0:
		target = null
	else: # otherwise set a new target based on a random player index
		target_vars = p_array_copy.pick_random()
		target = get_parent().get_node("Player" + str(target_vars.index))


func _on_tracking_timer_timeout():
	set_random_target()
