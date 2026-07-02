extends Camera2D

var targets = []

@export var move_speed: float = 30.0
@export var zoom_speed: float = 3.0
@export var min_zoom: float = 0.4   # most zoomed out (smaller = wider view)
@export var max_zoom: float = 1.5   # most zoomed in
@export var padding: float = 100.0  # world-space clearance around outermost players

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

	targets = targets.filter(func(t): return is_instance_valid(t))

	if !targets:
		return

	# Center on the midpoint of all targets
	var bounds = Rect2(targets[0].position, Vector2.ZERO)
	for target in targets:
		bounds = bounds.expand(target.position)

	position = lerp(position, bounds.get_center(), move_speed * delta)

	# Zoom to fit all targets with padding
	bounds = bounds.grow(padding)
	var target_zoom = clamp(
		minf(screen_size.x / bounds.size.x, screen_size.y / bounds.size.y),
		min_zoom, max_zoom
	)
	zoom = lerp(zoom, Vector2.ONE * target_zoom, zoom_speed * delta)

	# For debug
	#get_parent().draw_cam_rect(bounds)
