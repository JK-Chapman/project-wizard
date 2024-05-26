extends Sprite2D

var missile = preload("res://GameObjects/Enemies/TrackingMissile.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_timer_timeout():
	var missile_inst = missile.instantiate()
	get_parent().add_child(missile_inst)
	missile_inst.start(position)
