extends CharacterBody2D
class_name Player

# Spellpoint vars
@onready var spell_anim_player = $PlayerSpellPoint/SpellPointSprite/SpellPointAnimPlayer
var spell_blast_active = false

# Warp (deflect -> neutral -> flick) vars
@export var warp_neutral_threshold := 0.2  # aim magnitude at/below this counts as "stick at neutral"
@export var warp_flick_threshold := 0.6    # aim magnitude at/above this (while armed) completes the warp
@export var warp_arm_window := 0.2         # seconds allowed to reach neutral, then to flick, before the charge burns
@export var warp_time_to_flick := 0.35     # seconds allowed to reach neutral, then to flick, before the charge burns
@export var warp_cooldown_time := 10.0     # seconds between warps
var warp_state = WarpState.IDLE
var warp_candidate = null                  # the just-deflected missile eligible to be warped
var warp_timer = 0.0
var warp_on_cooldown = false
var warp_cooldown_remaining = 0.0          # seconds left on the cooldown (drives the UI indicator)

#Enums
enum PlayerState {
	IMMOBILIZED,
	DEAD,
	NORMAL
}

# Warp gesture phases: IDLE -> (deflect) WAIT_NEUTRAL -> (stick to neutral) ARMED -> (flick) warp
enum WarpState {
	IDLE,
	WAIT_NEUTRAL,
	ARMED
}

# Consts
const SPEED = 135
const ROTATE_SPEED = 100

# Player vars
var player_anim_dir = "left"
var player_anim_mode = "idle"
var aim_dir = Vector2.ZERO
var index
var animation
var player_state:PlayerState
var health = 1

func init(_index, _color_hex, _player_state=PlayerState.NORMAL):
	self.index = _index
	self.player_state = _player_state
	self.set_name("Player" + str(index))
	get_node("PlayerSprite").self_modulate = _color_hex

func _physics_process(_delta):
	if (player_state == PlayerState.NORMAL):
		MovementLoop()
	AimLoop()
	_warp_update(_delta)
	_tick_warp_cooldown(_delta)

func _process(_delta):
	if (player_state != PlayerState.DEAD):
		AnimationLoop()
		SpellAnimationLoop()

func _unhandled_input(_event):
	if !spell_blast_active and Input.is_action_just_pressed("blast" + str(index)) and aim_dir != Vector2.ZERO and player_state == PlayerState.NORMAL:
		spell_blast_active = true
		$DeflectSound.play()

func MovementLoop():
	# 360 degree movement! (with no deadzone)
	var input_dir = Input.get_vector("move_left" + str(index), "move_right" + str(index), "move_up" + str(index), "move_down" + str(index)).normalized()

	# 360 with deadzone
	#var input_dir = Vector2(Input.get_axis("move_left" + str(index), "move_right" + str(index)), Input.get_axis("move_up" + str(index), "move_down" + str(index)))
	velocity = input_dir * SPEED
	
	# traditional 8 direction movement
	#velocity.x = int(Input.is_action_pressed("move_right" + str(index))) - int(Input.is_action_pressed("move_left" + str(index)))
	#velocity.y = (int(Input.is_action_pressed("move_down" + str(index))) - int(Input.is_action_pressed("move_up" + str(index)))) / float(2)
	#velocity = velocity.normalized() * SPEED
	
	move_and_slide()


func AimLoop():
	aim_dir = Input.get_vector("aim_left" + str(index), "aim_right" + str(index), "aim_up" + str(index), "aim_down" + str(index))
	if aim_dir != Vector2.ZERO and !spell_blast_active:
		$PlayerSpellPoint.rotation = aim_dir.angle()
		#print(str(aim_dir))
		#lerp_angle($PlayerSpellPoint.rotation, aim_dir.angle(), 0.5)


func AnimationLoop():
	var move_dir = Vector2.ZERO
	move_dir.x = int(Input.is_action_pressed("move_right" + str(index))) - int(Input.is_action_pressed("move_left" + str(index)))
	move_dir.y = (int(Input.is_action_pressed("move_down" + str(index))) - int(Input.is_action_pressed("move_up" + str(index)))) / float(2)
	if move_dir != Vector2.ZERO:
		player_anim_mode = "run"
	else:
		player_anim_mode = "idle"
	match move_dir:
		Vector2(-1,0):
			player_anim_dir = "left"
		Vector2(1,0):
			player_anim_dir = "right"
		Vector2(0,.5):
			player_anim_dir = "down"
		Vector2(0,-.5):
			player_anim_dir = "up"
	animation = player_anim_mode + "_" + player_anim_dir
	$PlayerSprite/AnimationPlayer.play(animation)

func SpellAnimationLoop():
	if (player_state == PlayerState.DEAD):
		aim_dir = Vector2.ZERO
	else:
		aim_dir = Input.get_vector("aim_left" + str(index), "aim_right" + str(index), "aim_up" + str(index), "aim_down" + str(index))
	
	var spell_animation = "inactive"
	
	if spell_blast_active:
		spell_animation = "blast"
		spell_anim_player.play(spell_animation)
		await spell_anim_player.animation_finished
		spell_blast_active = false
		return
	elif aim_dir != Vector2.ZERO && !spell_blast_active:
		spell_animation = "cast"
	
	spell_anim_player.play(spell_animation)

func set_player_state(state):
	player_state = state

func _on_area_2d_area_entered(area):
	if not area.is_in_group("projectile"):
		return
	# Always a normal deflect first.
	area.deflect(aim_dir)
	# Off cooldown, that deflect opens a warp opportunity on this missile: once the stick
	# returns to neutral the warp arms, then a flick redirects the missile (see _warp_update).
	if not warp_on_cooldown and warp_state == WarpState.IDLE:
		warp_candidate = area
		warp_state = WarpState.WAIT_NEUTRAL
		warp_timer = warp_arm_window

func _warp_update(delta):
	if warp_state == WarpState.IDLE:
		return
	# Missile is gone (exploded/freed) — nothing left to warp.
	if not is_instance_valid(warp_candidate):
		_reset_warp()
		return

	var aim_mag = aim_dir.length()
	match warp_state:
		WarpState.WAIT_NEUTRAL:
			# Waiting for the player to let the stick return to neutral, which arms the warp
			# and freezes the missile for the duration of the wait.
			if aim_mag <= warp_neutral_threshold:
				warp_state = WarpState.ARMED
				warp_timer = warp_time_to_flick
				#warp_candidate.freeze_for_warp()
			else:
				warp_timer -= delta
				if warp_timer <= 0.0:
					_reset_warp()  # never returned to neutral; opportunity lapses, charge kept
		WarpState.ARMED:
			# Armed: a flick to a new direction completes the warp; doing nothing burns the charge.
			if aim_mag >= warp_flick_threshold:
				var flick := aim_dir.normalized()
				# Where the spell point would sit if the player were aiming the flicked direction.
				$PlayerSpellPoint.rotation = flick.angle()
				var warp_pos = $PlayerSpellPoint/SpellPointSprite/Area2D.global_position
				warp_candidate.warp_redirect(flick, warp_pos)
				_start_warp_cooldown()
				_reset_warp()
			else:
				warp_timer -= delta
				if warp_timer <= 0.0:
					warp_candidate.release_warp()  # did nothing — unfreeze, charge is spent
					_start_warp_cooldown()
					_reset_warp()

func _reset_warp():
	warp_state = WarpState.IDLE
	warp_candidate = null
	warp_timer = 0.0

func _start_warp_cooldown():
	warp_on_cooldown = true
	warp_cooldown_remaining = warp_cooldown_time

func _tick_warp_cooldown(delta):
	if warp_on_cooldown:
		warp_cooldown_remaining = max(warp_cooldown_remaining - delta, 0.0)
		if warp_cooldown_remaining <= 0.0:
			warp_on_cooldown = false

func take_damage(damage):
	health -= damage
	
	if (health <= 0 && player_state != PlayerState.DEAD):
		kill_player()

func kill_player():
	player_state = PlayerState.DEAD
	$DeathSound.play()
	$PlayerSprite/AnimationPlayer.play("death")
	spell_anim_player.play("inactive")
	$PlayerHitbox.disabled = true
	GameManager.SetPlayerIsDead(self.index, true)
	if $PlayerSprite/AnimationPlayer.is_playing():
		await $PlayerSprite/AnimationPlayer.animation_finished
	if $DeathSound.playing:
		await $DeathSound.finished
	queue_free()
	#GameManager.player_array[GameManager.player_array.find(func(p): return p.index == self.index)].player_dead = true

func reset_player():
	player_state = PlayerState.IMMOBILIZED
	$PlayerHitbox.disabled = false
	GameManager.SetPlayerIsDead(self.index, false)
	#GameManager.player_array[GameManager.player_array.find(func(p): return p.index == self.index)].player_dead = false
