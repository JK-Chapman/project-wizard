extends Node2D

# Subtle radial "warp charge" indicator drawn above the player. Purely visual — a plain Node2D
# with no collision, so it never touches physics. Drawn as a ring (donut): a full dark ring means
# the warp is ready; while on cooldown the ring empties and refills radially over the player's
# warp_cooldown_time, staying more transparent as it fills and firming up as it nears ready.

@export var radius := 5.0
@export var width := 2.0
@export var track_color := Color(0.0, 0.0, 0.0, 0.2)   # faint empty ring behind the fill
@export var filling_color := Color(0.08, 0.08, 0.08, 0.4)   # dark + transparent while filling
@export var ready_color := Color(0.08, 0.08, 0.08, 0.95)    # dark + solid once ready
@export var segments := 48

var _fraction := 1.0  # 0 = just used, 1 = ready

func _process(_delta):
	var player = get_parent()
	var frac := 1.0
	if player != null and player.warp_on_cooldown and player.warp_cooldown_time > 0.0:
		frac = 1.0 - clamp(player.warp_cooldown_remaining / player.warp_cooldown_time, 0.0, 1.0)
	if not is_equal_approx(frac, _fraction):
		_fraction = frac
		queue_redraw()

func _draw():
	# antialiased = false keeps the edges crisp for pixel art (no blurry blended pixels).
	# Empty track ring so the donut shape is visible even at 0%.
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, segments, track_color, width, false)
	if _fraction <= 0.0:
		return
	# Fill ring, sweeping clockwise from the top, blending from transparent (filling) to solid (ready).
	var col := filling_color.lerp(ready_color, _fraction)
	var start := -PI / 2.0
	var end := start + TAU * _fraction
	draw_arc(Vector2.ZERO, radius, start, end, segments, col, width, false)
