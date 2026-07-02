extends CanvasLayer

const _SPRITE = preload("res://Assets/AnimationSheets/JesterMovesetWDeathAnim.png")
const _HFRAMES = 78
const _ICON_FRAME = 18  # idle_down

var _title_lbl: Label
var _card_list: VBoxContainer
var _pts_to_win: int = 3

func _ready() -> void:
	layer = 10
	_build()
	hide()

func _build() -> void:
	var ctrl = Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ctrl)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	s.set_corner_radius_all(14)
	s.set_border_width_all(2)
	s.border_color = Color(0.35, 0.35, 0.6, 1.0)
	panel.add_theme_stylebox_override("panel", s)
	center.add_child(panel)

	var margin = MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(k, 28)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 26)
	vbox.add_child(_title_lbl)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	_card_list = VBoxContainer.new()
	_card_list.add_theme_constant_override("separation", 14)
	vbox.add_child(_card_list)

func show_scoreboard(title: String, pts_to_win: int) -> void:
	_pts_to_win = pts_to_win
	_title_lbl.text = title
	_rebuild_cards()
	show()

func update_title(title: String) -> void:
	_title_lbl.text = title

func _rebuild_cards() -> void:
	var old = _card_list.get_children()
	for child in old:
		child.free()
	for pv in GameManager.player_array:
		_add_card(pv)

func _add_card(pv: PlayerVars) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_card_list.add_child(row)

	row.add_child(_make_icon(pv.color_hex))

	var name_lbl = Label.new()
	name_lbl.text = "P" + str(pv.index + 1)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", pv.color_hex)
	name_lbl.custom_minimum_size = Vector2(36, 0)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_lbl)

	var dots = ""
	for i in range(_pts_to_win):
		dots += "●" if i < pv.points else "○"
		if i < _pts_to_win - 1:
			dots += "  "
	var dots_lbl = Label.new()
	dots_lbl.text = dots
	dots_lbl.add_theme_font_size_override("font_size", 24)
	dots_lbl.add_theme_color_override("font_color", pv.color_hex)
	dots_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(dots_lbl)

func _make_icon(color: Color) -> TextureRect:
	var fw = _SPRITE.get_width() / float(_HFRAMES)
	var atlas = AtlasTexture.new()
	atlas.atlas = _SPRITE
	atlas.region = Rect2(_ICON_FRAME * fw, 0.0, fw, _SPRITE.get_height())
	var tex = TextureRect.new()
	tex.texture = atlas
	tex.modulate = color
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(40, 40)
	return tex
