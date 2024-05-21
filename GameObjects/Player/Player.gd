extends CharacterBody2D

const SPEED = 135
const ROTATE_SPEED = 100
var anim_dir = "L"
var anim_mode = "Idle"
var index


func init(index):
	self.index = index
	self.set_name("Player" + str(index))
	get_node("PlayerSprite").self_modulate = GameManager.player_dicts[index][0]


func _physics_process(delta):
	MovementLoop()
	AimLoop()
	AnimationLoop()


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
	var aim_dir = Input.get_vector("aim_left" + str(index), "aim_right" + str(index), "aim_up" + str(index), "aim_down" + str(index))
	if aim_dir != Vector2.ZERO:
		$PlayerSpellPoint.rotation = lerp_angle($PlayerSpellPoint.rotation, aim_dir.angle(), 0.5)


func AnimationLoop():
	pass
