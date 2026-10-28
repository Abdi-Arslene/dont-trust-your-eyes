class_name ItemChip
extends Control
## An item in the top bar. It looks like interface; it is actually an
## object you can drag into the level.

const SIZE := Vector2(76, 76)

var item: String
var highlighted := false:  # the hint eye points at it
	set(value):
		highlighted = value
		queue_redraw()


func _init(item_name: String) -> void:
	item = item_name
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	if highlighted:
		queue_redraw()


func _draw() -> void:
	draw_circle(size / 2.0, size.x * 0.48, Color(1, 1, 1, 0.06), true, -1.0, true)
	if highlighted:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
		draw_arc(size / 2.0, size.x * (0.44 + 0.05 * pulse), 0, TAU, 32, BoardView.C_HINT, 4.0, true)
	BoardView.draw_item(self, item, Rect2(Vector2.ZERO, size).grow(-size.x * 0.12))


func _get_drag_data(_at_position: Vector2) -> Variant:
	var art := ItemChip.new(item)
	art.position = -SIZE / 2.0
	var holder := Control.new()  # keeps the preview centered under the finger
	holder.add_child(art)
	set_drag_preview(holder)
	modulate.a = 0.25
	return {"item": item}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
