extends CharacterBody2D


const SPEED = 150
var anim_dir = "L"
var anim_mode = "Idle"
var index

func init(index):
	self.index = index
	self.set_name("Player" + str(index))
	get_node("PlayerSprite").self_modulate = GameManager.player_dicts[index][0]

func _physics_process(_delta):
	MovementLoop()

func MovementLoop():
	velocity.x = int(Input.is_action_pressed("move_right" + str(index))) - int(Input.is_action_pressed("move_left" + str(index)))
	velocity.y = (int(Input.is_action_pressed("move_down" + str(index))) - int(Input.is_action_pressed("move_up" + str(index)))) / float(2)
	velocity = velocity.normalized() * SPEED
	
	move_and_slide()
