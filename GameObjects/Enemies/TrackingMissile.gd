extends Area2D

#@export var speed_stage = 0
#@export var steer_force = 130.0
@export var missile_stage = 0
@export var missile_damage = 1
# When retargeting, how much a player behind the missile is de-weighted vs one ahead of it.
# 1.0 = ignore direction (pure proximity); lower = stronger pull toward players in the
# direction the missile is heading. Proximity still dominates either way.
@export var direction_bias_min := 0.35
# Speed multiplier applied to a missile the instant it's warp-launched; drag settles it back down.
@export var warp_launch_boost := 1.0

# missile stages
var MAX_STAGE = 9
var speed_stages = [125.0, 150.0, 175.0, 200.0, 215.0, 230.0, 245.0, 280.0, 320.0, 360.0, 410.0, 450.0, 500.0, 550.0, 610.0, 680.0, 730.0, 800.0, 850.0, 910.0, 960.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1000.0, 1100.0, 1200.0, 1300.0, 1400.0, 1500.0]
var steer_forces = [125.0, 165.0, 165.0, 300.0, 300.0, 300.0, 300.0, 300.0, 330.0, 330.0, 350.0, 370.0, 380.0, 480.0, 580.0, 580.0, 580.0, 580.0]

# missile vars
var velocity = Vector2.ZERO
var acceleration = Vector2.ZERO
var target = null
var target_vars = null
var last_warper_vars = null  # player who last warped us; excluded from the very next retarget too
var deflect_dir
var drag = 0.12
var bouncing = true  # true while the missile should bounce off walls instead of explode
var dead = false
var has_target = false
var warp_frozen = false  # true while a player has an armed warp on this missile (held in place)

func init():
	missile_stage = randi_range(0, 4);
	set_random_target()

func start(_position):
	position = _position
	rotation += randf_range(-0.09, 0.09)
	velocity = transform.x * speed_stages[missile_stage] * 3
	set_random_target()

func _physics_process(delta):
	if warp_frozen:
		# Held while a player's warp is armed. Velocity is preserved, so if the warp lapses
		# the missile resumes exactly where it left off.
		return

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
	# Drop the current target so the missile holds its clean reflected angle (like a pool ball off a
	# cushion) instead of instantly curving toward a player. It re-acquires when TrackingTimer lapses.
	target = null
	has_target = false
	$MissileDeflected.play()
	$TrackingTimer.start()
	$BounceTimer.start()
	increaseMissileStage()

func _on_Missile_body_entered(_body):
	if warp_frozen:
		# Suspended mid-warp — can't collide/explode until it's released or redirected.
		return

	if _body.is_in_group("player"):
		_body.take_damage(missile_damage)
		explode()
		return
		
	if bouncing:
		# The movement raycast missed this wall (already overlapping it); cast again to read the
		# wall's real surface normal so the bounce angle matches the face it hit.
		velocity = velocity.bounce(_wall_bounce_normal(_body))
		_on_wall_bounce()
	else:
		explode()

func _wall_bounce_normal(body: Node2D) -> Vector2:
	# Ray along our travel direction to find the wall surface normal (accounts for angled tiles).
	# Falls back to a body-centre approximation only if the ray somehow misses.
	var dir = velocity.normalized()
	if dir != Vector2.ZERO:
		var query = PhysicsRayQueryParameters2D.create(global_position - dir * 16.0, global_position + dir * 16.0, 1)
		var result = get_world_2d().direct_space_state.intersect_ray(query)
		if not result.is_empty():
			return result.normal
	return (global_position - body.global_position).normalized()

func freeze_for_warp():
	# Player's warp just armed (stick hit neutral) — hold this missile in place during the wait.
	warp_frozen = true

func release_warp():
	# Warp lapsed without a flick — let the missile carry on where it left off.
	warp_frozen = false

func carry_at(carry_position: Vector2, carry_direction: Vector2):
	# Held on a player's spellpoint while they carry it: frozen, pinned to the given position
	# and pointing outward like a fresh deflect. Driven each frame by the carrying player.
	warp_frozen = true
	global_position = carry_position
	if carry_direction.length() > 0.001:
		look_at(global_position + carry_direction)

func warp_redirect(direction: Vector2, warp_position: Vector2, warper_vars = null):
	# Warp completed: teleport to the spell point in the flicked direction and fire off that way
	# with a speed burst (drag settles it back down). Plays the warp animation so it reads
	# distinctly from a normal deflect, and resets tracking so it flies straight before re-homing.
	warp_frozen = false
	target = null
	has_target = false
	last_warper_vars = warper_vars
	global_position = warp_position
	velocity = direction.normalized() * speed_stages[missile_stage] * warp_launch_boost
	$TrackingTimer.start()
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("warp")
	$MissileDeflected.play()
	look_at(global_position + velocity)

func deflect(direction: Vector2):
	warp_frozen = false  # in case it was grabbed for a warp that resolved into a plain deflect
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

	# Never immediately re-target the player we were just chasing, nor the player who last warped
	# us — unless excluding them would leave no valid candidates, in which case they're allowed back.
	var excluded = []
	if target_vars != null:
		excluded.append(target_vars)
	if last_warper_vars != null and last_warper_vars != target_vars:
		excluded.append(last_warper_vars)
	last_warper_vars = null
	for ex in excluded:
		if candidates.size() > 1:
			candidates.erase(ex)

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
	bouncing = true
