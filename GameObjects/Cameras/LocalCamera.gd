extends Camera2D


var targets = []
var margin

@export var move_speed:float = 30
@export var zoom_speed:float = 3.0
@export var min_zoom:float = 5.0
@export var max_zoom:float = 0.5

@onready var screen_size = DisplayServer.window_get_size()

func _ready():
	make_current()

func add_target(t):
	if not t in targets:
		targets.append(t)

func remove_target(t):
	if t in targets:
		targets.erase(t)

func _process(delta):
	screen_size = DisplayServer.window_get_size()
	margin = Vector2(screen_size.x * .05, screen_size.y * .05)
	
	if !targets:
		return
	
	# Keep the camera centered among all targets
	var p = Vector2.ZERO
	for target in targets:
		p += target.position
	p /= targets.size()
	position = lerp(position, p, move_speed * delta)
	
	# Find the zoom that will contain all targets
	var r = Rect2(position, Vector2.ONE)
	for target in targets:
		r = r.expand(target.position)
	r = r.grow_individual(margin.x, margin.y, margin.x, margin.y)
	var z
	if r.size.x > r.size.y * screen_size.aspect():
		z = 1 / clamp(r.size.x / screen_size.x, max_zoom, min_zoom)
	else:
		z = 1 / clamp(r.size.y / screen_size.y, max_zoom, min_zoom)
	zoom = lerp(zoom, Vector2.ONE * z, zoom_speed * delta)
	
	# For debug
	#get_parent().draw_cam_rect(r)
