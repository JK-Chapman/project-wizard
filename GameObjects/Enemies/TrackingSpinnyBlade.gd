extends CharacterBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
@export var steering_force = 20.0
var damage = 1
var speed = 150
var max_speed = 250
var acceleration = Vector2()
var target = null
var curr_target = null
var hit_sound_fx = load("res://SoundEffects/flesh_hit.mp3")


func start(pos, dir):
	rotation = dir
	position = pos
	velocity = Vector2(speed, 0).rotated(rotation)

func _ready():
	set_random_target()

func _physics_process(delta):
	velocity = transform.x * speed
	# Add: add velocity to steer to acceleration
	acceleration += steer()
	# Add: add the velocity plus the acceleration x delta value to the velocity
	velocity += acceleration * delta
	# Add: limit the length of the velocity vector so that it does not exceed the speed
	position += velocity * delta
	rotation = velocity.angle()

func steer():
	# Define as velocity to steer
	var steering = Vector2()
	# Define ideal velocity (direction x speed towards player character from current position)
	var ideal_velocity = (target.position - position).normalized() * speed
	# speed to steer = direction vector obtained by ideal_velocity - current_velocity x force to steer
	steering = (ideal_velocity - velocity).normalized() * steering_force
	# output velocity to steer
	return steering
		
func deflect(dir):
	speed *= 1.2
	if speed > max_speed: speed = max_speed
	set_random_target()

func set_random_target():
	var p_dicts_copy = GameManager.player_dicts.duplicate(true)
	
	# If curr_index is null, we just instantiated the object and need to set an initial target.
	# This if statement excludes the current target if it exists.
	if (curr_target != null):
		p_dicts_copy.erase(curr_target)

	var rand_index:int = randi() % p_dicts_copy.size()
	curr_target = p_dicts_copy[rand_index]
	
	target = get_parent().get_parent().get_node("Player" + str(curr_target[0]))

func destroy():
	GameManager.play_sound(hit_sound_fx)
	queue_free()

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
