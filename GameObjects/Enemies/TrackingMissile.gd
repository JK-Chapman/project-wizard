extends Area2D

#@export var speed_stage = 0
#@export var steer_force = 130.0
@export var missile_stage = 0
@export var missile_damage = 1
# When retargeting, how much a player behind the missile is de-weighted vs one ahead of it.
# 1.0 = ignore direction (pure proximity); lower = stronger pull toward players in the
# direction the missile is heading. Proximity still dominates either way.
@export var direction_bias_min := 0.35

# missile stages
var MAX_STAGE = 9
var speed_stages = [125.0, 150.0, 175.0, 200.0, 215.0, 230.0, 245.0, 280.0, 320.0, 360.0, 410.0, 450.0, 500.0, 550.0, 610.0, 680.0, 730.0, 800.0, 850.0, 910.0, 960.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1100.0, 1200.0, 1300.0, 1400.0, 1500.0]
var steer_forces = [125.0, 165.0, 165.0, 300.0, 300.0, 300.0, 300.0, 300.0, 330.0, 330.0, 350.0, 370.0, 380.0, 480.0, 580.0, 580.0, 580.0, 580.0]

# missile vars
var velocity = Vector2.ZERO
var acceleration = Vector2.ZERO
var target = null
var target_vars = null
var deflect_dir
var drag = 0.12
var bouncing = false  # true while the missile should bounce off walls instead of explode
var dead = false
var has_target = false

func init():
	missile_stage = randi_range(0, 4);
	set_random_target()

func start(_position):
	position = _position
	rotation += randf_range(-0.09, 0.09)
	velocity = transform.x * speed_stages[missile_stage] * 3
	set_random_target()

func _physics_process(delta):
	var direction = transform.x

	if is_instance_valid(target) and target.player_state != Player.PlayerState.DEAD:
		has_target = true
		direction = global_position.direction_to(target.global_position)
	elif has_target:
		# Target was removed from the scene — retarget immediately
		has_target = false
		set_random_target()
	elif $TrackingTimer.is_stopped():
		set_random_target()

	var desired_velocity = direction * speed_stages[missile_stage]
	var change = (desired_velocity - velocity) * drag

	velocity += change

	_move_with_wall_check(delta)

func _move_with_wall_check(delta):
	if dead:
		return
	var movement = velocity * delta
	if movement.length_squared() < 0.001:
		global_position += movement
		look_at(global_position + velocity)
		return

	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + movement, 1)
	var result = get_world_2d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		global_position += movement
	elif bouncing:
		global_position = result.position + result.normal * 2.0
		velocity = velocity.bounce(result.normal)
		_on_wall_bounce()
	else:
		explode()
		return

	look_at(global_position + velocity)

func _on_wall_bounce():
	$MissileDeflected.play()
	$TrackingTimer.start()
	$BounceTimer.start()
	increaseMissileStage()

func _on_Missile_body_entered(_body):
	if _body.is_in_group("player"):
		_body.take_damage(missile_damage)
		explode()
		return
		
	if bouncing:
		# Raycast missed this wall; approximate the normal from body position
		var approx_normal = (global_position - _body.global_position).normalized()
		velocity = velocity.bounce(approx_normal)
		_on_wall_bounce()
	else:
		explode()

func deflect(direction: Vector2):
	target = null
	has_target = false
	$MissileDeflected.play()

	var dir: Vector2 = direction.normalized()
	var speed: float = velocity.length()

	velocity = dir * speed
	acceleration = Vector2.ZERO
	bouncing = true

	increaseMissileStage()
	$TrackingTimer.start()
	$BounceTimer.start()

func increaseMissileStage():
	if missile_stage < speed_stages.size() - 1:
		missile_stage += 1

func explode():
	if dead:
		return
	dead = true
	$MissileExplode.play()
	#$Particles2D.emitting = false
	set_physics_process(false)
	#$AnimationPlayer.play("explode")
	#await $AnimationPlayer.animation_finished
	queue_free()

func set_random_target():
	var candidates = GameManager.player_array.filter(func(p): return p.player_dead == false)

	# If target_vars is null, we just instantiated the object and need to set an initial target.
	# This if statement excludes the current target (the one that just deflected it) if it exists.
	if (target_vars != null and candidates.size() > 1):
		candidates.erase(target_vars)

	# Score each candidate by proximity (dominant) with a bias toward players in the direction
	# the missile is currently heading, then pick weighted-randomly.
	var heading = velocity.normalized()
	var scored = []  # each entry: [player_vars, node, weight]
	for pv in candidates:
		var node = get_parent().get_node_or_null("Player" + str(pv.index))
		if node == null:
			continue
		var to_player = node.global_position - global_position
		var dist = max(to_player.length(), 1.0)
		var weight = 1.0 / dist  # proximity dominates
		if heading.length() > 0.01:
			var align = heading.dot(to_player / dist)  # -1 behind .. 1 ahead
			weight *= lerp(direction_bias_min, 1.0, (align + 1.0) / 2.0)
		scored.append([pv, node, weight])

	if scored.is_empty():
		target = null
		return

	var total = 0.0
	for s in scored:
		total += s[2]
	var roll = randf() * total
	for s in scored:
		roll -= s[2]
		if roll <= 0.0:
			target_vars = s[0]
			target = s[1]
			return
	# Fallback for float rounding
	target_vars = scored[-1][0]
	target = scored[-1][1]


func _on_tracking_timer_timeout():
	set_random_target()

func _on_bounce_timer_timeout():
	bouncing = false
