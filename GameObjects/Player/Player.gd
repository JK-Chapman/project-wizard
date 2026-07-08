extends CharacterBody2D
class_name Player

# Spellpoint vars
@onready var spell_anim_player = $PlayerSpellPoint/SpellPointSprite/SpellPointAnimPlayer
var spell_blast_active = false

# Warp (SPECIAL / left-trigger) vars
@export var warp_window_time := 0.3        # how long the catch window stays open after activating (matches the anim)
@export var warp_carry_time := 0.35        # how long a caught missile rides the spellpoint before auto-launching
@export var warp_cooldown_time := 10.0     # seconds between warps
var warp_state = WarpState.IDLE
var warp_candidate = null                  # the missile currently caught on the spellpoint
var warp_timer = 0.0                        # carry countdown while CARRYING
var warp_window_timer = 0.0                 # catch-window countdown while ACTIVE
var special_active = false                  # true while a warp is engaged (window open or carrying)
var warp_on_cooldown = false
var warp_cooldown_remaining = 0.0          # seconds left on the cooldown (drives the UI indicator)

#Enums
enum PlayerState {
	IMMOBILIZED,
	DEAD,
	NORMAL
}

# Warp phases: IDLE -> (SPECIAL pressed) ACTIVE catch window -> (missile caught) CARRYING -> launch
enum WarpState {
	IDLE,
	ACTIVE,
	CARRYING
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
	# Blast and SPECIAL are mutually exclusive — can't blast while a warp is engaged or the trigger is held.
	if !spell_blast_active and not special_active and not Input.is_action_pressed("SPECIAL_" + str(index)) \
			and Input.is_action_just_pressed("blast" + str(index)) and aim_dir != Vector2.ZERO and player_state == PlayerState.NORMAL:
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
	
	# While a warp is engaged, hold the warp animation and don't let cast/inactive override it.
	if special_active:
		if spell_anim_player.has_animation("warp") and spell_anim_player.current_animation != "warp":
			spell_anim_player.play("warp")
		return

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
	# Blast deflect (right trigger) — unchanged and independent of the warp.
	if area.is_in_group("projectile"):
		area.deflect(aim_dir)

func _warp_update(delta):
	match warp_state:
		WarpState.IDLE:
			# Activate on a fresh SPECIAL press, if the charge is ready and we're not blasting
			# (blast and SPECIAL are mutually exclusive — both committal).
			if Input.is_action_just_pressed("SPECIAL_" + str(index)) and not warp_on_cooldown \
					and not spell_blast_active and not Input.is_action_pressed("blast" + str(index)) \
					and player_state == PlayerState.NORMAL:
				_activate_warp()
		WarpState.ACTIVE:
			_update_warp_active(delta)
		WarpState.CARRYING:
			_update_warp_carrying(delta)

func _activate_warp():
	# Holding SPECIAL opens the catch window and spends the charge immediately (pressing at all
	# always costs it). The warp animation is driven by special_active in SpellAnimationLoop.
	warp_state = WarpState.ACTIVE
	warp_window_timer = warp_window_time
	special_active = true
	_set_warp_area_enabled(true)
	_start_warp_cooldown()

func _update_warp_active(delta):
	if aim_dir != Vector2.ZERO:
		$PlayerSpellPoint.rotation = aim_dir.angle()
	# Catch a missile sitting in the warp zone.
	for a in $PlayerSpellPoint/SpellPointSprite/WarpArea.get_overlapping_areas():
		if a.is_in_group("projectile") and not a.warp_frozen:
			_grab_for_warp(a)
			return
	# Window closes on release or timeout — nothing caught, charge already spent.
	warp_window_timer -= delta
	if not Input.is_action_pressed("SPECIAL_" + str(index)) or warp_window_timer <= 0.0:
		_end_warp()

func _grab_for_warp(missile):
	warp_candidate = missile
	warp_state = WarpState.CARRYING
	warp_timer = warp_carry_time
	missile.freeze_for_warp()

func _update_warp_carrying(delta):
	# Missile is gone (exploded/freed) — nothing left to carry.
	if not is_instance_valid(warp_candidate):
		_end_warp()
		return

	# Steer the spellpoint and keep the missile pinned to it, pointing outward.
	if aim_dir != Vector2.ZERO:
		$PlayerSpellPoint.rotation = aim_dir.angle()
	var carry_dir = $PlayerSpellPoint.global_transform.x.normalized()
	var carry_pos = $PlayerSpellPoint/SpellPointSprite/WarpArea.global_position
	warp_candidate.carry_at(carry_pos, carry_dir)

	# Auto-launch when the carry time runs out, or instantly if the trigger is released.
	warp_timer -= delta
	if warp_timer <= 0.0 or not Input.is_action_pressed("SPECIAL_" + str(index)):
		warp_candidate.warp_redirect(carry_dir, carry_pos, _get_own_player_vars())
		_end_warp()

func _get_own_player_vars():
	var matches = GameManager.player_array.filter(func(p): return p.index == index)
	return matches[0] if matches.size() > 0 else null

func _end_warp():
	warp_state = WarpState.IDLE
	warp_candidate = null
	warp_timer = 0.0
	warp_window_timer = 0.0
	special_active = false
	_set_warp_area_enabled(false)

func _set_warp_area_enabled(enabled):
	$PlayerSpellPoint/SpellPointSprite/WarpArea/CollisionPolygon2D.disabled = not enabled

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
	
	#if (health <= 0 && player_state != PlayerState.DEAD):
		#kill_player()

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
