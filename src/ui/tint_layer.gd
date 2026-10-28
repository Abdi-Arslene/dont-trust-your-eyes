class_name TintLayer
extends ColorRect
## Colours the whole screen (the colour decides what a swipe means).
## A new colour arrives with a ring spreading from the player.

var _ring := 1.0
var _ring_center := Vector2.ZERO
var _ring_color := Color.WHITE


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	color = Color(1, 1, 1, 0)


func snap(to: Color) -> void:
	color = to
	_ring = 1.0
	queue_redraw()


func change(to: Color, from_point: Vector2) -> void:
	create_tween().tween_property(self, "color", to, 0.35)
	_ring = 0.0
	_ring_center = from_point
	_ring_color = Color(to, 0.9) if to.a > 0.0 else Color(1, 1, 1, 0.6)


func _process(delta: float) -> void:
	if _ring < 1.0:
		_ring = minf(1.0, _ring + delta * 1.8)
		queue_redraw()


func _draw() -> void:
	if _ring < 1.0:
		var radius := size.length() * ease(_ring, 0.5)
		draw_arc(_ring_center, radius, 0, TAU, 96, Color(_ring_color, _ring_color.a * (1.0 - _ring)), 2.0 + 40.0 * (1.0 - _ring), true)
