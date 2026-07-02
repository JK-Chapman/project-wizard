extends Sprite2D

var missile = preload("res://GameObjects/Enemies/TrackingMissile.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_timer_timeout():
	var max_missiles_alive = GameManager.player_array.filter(func(p): return p.player_dead == false).size() * 2
	var missiles_alive = get_tree().get_nodes_in_group("projectile").size()
	
	if (missiles_alive < max_missiles_alive):
		var missile_inst = missile.instantiate()
		get_parent().add_child(missile_inst)
		missile_inst.start(position)
