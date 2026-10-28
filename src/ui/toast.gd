class_name Toast
extends Control
## "New costume" banner that slides in from the top. Several queue up.

const HEIGHT := 120.0

var _queue := []
var _skin := {}
var _time := 0.0
var _busy := false
var _font := Look.font()


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	offset_left = 32
	offset_right = -32
	offset_bottom = HEIGHT
	mouse_filter = MOUSE_FILTER_IGNORE
	position.y = -HEIGHT - 20


func show_skin(skin: Dictionary) -> void:
	_queue.append(skin)
	if not _busy:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	_skin = _queue.pop_front()
	Sfx.play("secret")
	Sfx.vibrate(30)
	var top := 90.0  # below the status bar and the notch
	var t := create_tween()
	t.tween_property(self, "position:y", top, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(2.4)
	t.tween_property(self, "position:y", -HEIGHT - 20, 0.3).set_ease(Tween.EASE_IN)
	t.tween_callback(_next)


func _process(delta: float) -> void:
	_time += delta
	if _busy:
		queue_redraw()


func _draw() -> void:
	if _skin.is_empty():
		return
	var bg := StyleBoxFlat.new()
	bg.bg_color = Look.CARD
	bg.border_color = Look.GOLD
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(24)
	bg.shadow_color = Color(0, 0, 0, 0.5)
	bg.shadow_size = 16
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	Skins.draw_hero(self, Vector2(70, size.y / 2.0 + 4), 36, Vector2.from_angle(_time * 2.0) * 0.5, _skin, _time, "win")
	var font := _font
	draw_string(font, Vector2(130, size.y / 2.0 - 8), "Nouveau costume !", HORIZONTAL_ALIGNMENT_LEFT, size.x - 150, 26, Color(Look.INK, 0.65))
	draw_string(font, Vector2(130, size.y / 2.0 + 32), _skin.name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 150, 36, Color("8e6bff"))
