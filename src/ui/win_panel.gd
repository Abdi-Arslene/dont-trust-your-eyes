class_name WinPanel
extends Control
## End-of-level card: confetti, stars pop in one by one, then two choices
## (replay / next...). Also the card that ends a dream run (no stars).

signal left_pressed
signal right_pressed

const C_STAR := Look.GOLD
const C_STAR_OFF := Color(0.17, 0.18, 0.26, 0.12)
const CONFETTI := [Color("ff4d8d"), Color("ffb703"), Color("3a86ff"), Color("2ec27e"), Color("8e6bff"), Color("ff8a3d")]

var _stars := 0
var _pop := [0.0, 0.0, 0.0]
var _title := Label.new()
var _star_row := Control.new()
var _info := Label.new()
var _extra := Label.new()
var _left := Button.new()
var _right := Button.new()
var _confetti := []  # {p, v, color, spin, angle}
var _layer := Control.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP  # no swiping behind the card
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.05, 0.25, 0.45)
	dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	dim.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 580
	panel.add_theme_stylebox_override("panel", Look.box(Look.CARD, 36, true, 36))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 56)
	_title.add_theme_font_override("font", Look.font(700))
	_title.add_theme_color_override("font_color", Color("8e6bff"))
	box.add_child(_title)
	_star_row.custom_minimum_size.y = 130
	_star_row.draw.connect(_draw_stars)
	box.add_child(_star_row)
	for label in [_info, _extra]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(label)
	_info.add_theme_color_override("font_color", Look.INK)
	_extra.add_theme_font_size_override("font_size", 28)
	_extra.add_theme_color_override("font_color", Color("1d6fd8"))

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	for button in [_left, _right]:
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 30)
		buttons.add_child(button)
	_left.pressed.connect(left_pressed.emit)
	_right.pressed.connect(right_pressed.emit)
	_right.add_theme_stylebox_override("normal", Look.box(Look.GOLD, 26))
	_right.add_theme_stylebox_override("hover", Look.box(Look.GOLD.lightened(0.15), 26))
	box.add_child(buttons)
	_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_layer.mouse_filter = MOUSE_FILTER_IGNORE
	_layer.draw.connect(_draw_confetti)
	add_child(_layer)
	hide()


## `stars` -1 hides the star row.
func open(title: String, stars: int, info: String, notes: Array, left: String, right: String) -> void:
	_title.text = title
	_stars = maxi(stars, 0)
	_star_row.visible = stars >= 0
	_pop = [0.0, 0.0, 0.0]
	_info.text = info
	_extra.text = "\n".join(notes)
	_extra.visible = not notes.is_empty()
	_left.text = left
	_right.text = right
	_confetti.clear()
	if stars >= 0:
		for i in 90:
			_confetti.append({
				"p": Vector2(randf() * size.x, -randf() * size.y * 0.5),
				"v": Vector2(randf_range(-60, 60), randf_range(250, 520)),
				"color": CONFETTI[i % CONFETTI.size()], "spin": randf_range(-8, 8), "angle": randf() * TAU,
			})
	show()
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.25)
	for i in 3 if stars >= 0 else 0:
		t.tween_method(_set_pop.bind(i), 0.0, 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if i < stars:
			t.parallel().tween_callback(Sfx.play.bind("star", 1.0 + 0.15 * i))
			t.parallel().tween_callback(Sfx.vibrate.bind(20))


func _process(delta: float) -> void:
	if not visible or _confetti.is_empty():
		return
	for c in _confetti:
		c.p += c.v * delta
		c.v.x += sin(c.angle) * 40.0 * delta
		c.angle += c.spin * delta
	_confetti = _confetti.filter(func(c): return c.p.y < size.y + 20.0)
	_layer.queue_redraw()


func _draw_confetti() -> void:
	for c in _confetti:
		_layer.draw_set_transform(c.p, c.angle, Vector2(1.0, absf(sin(c.angle * 1.7)) + 0.2))
		_layer.draw_rect(Rect2(-9, -5, 18, 10), c.color)
	_layer.draw_set_transform(Vector2.ZERO)


func _set_pop(value: float, i: int) -> void:
	_pop[i] = value
	_star_row.queue_redraw()


func _draw_stars() -> void:
	var w := _star_row.size.x
	for i in 3:
		var c := Vector2(w / 2.0 + (i - 1) * 140.0, 65.0 - (12.0 if i == 1 else 0.0))
		var r: float = 52.0 * _pop[i]
		if r <= 0.5:
			continue
		var pts := PackedVector2Array()
		for k in 10:
			var a := -PI / 2.0 + k * PI / 5.0
			pts.append(c + Vector2.from_angle(a) * (r if k % 2 == 0 else r * 0.45))
		_star_row.draw_colored_polygon(pts, C_STAR if i < _stars else C_STAR_OFF)
