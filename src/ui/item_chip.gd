class_name ItemChip
extends Control
## An item Pico carries, shown in the top bar. It pops in when picked up.

const SIZE := Vector2(76, 76)

var item: String


func _init(item_name: String) -> void:
	item = item_name
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = SIZE / 2.0
	mouse_filter = MOUSE_FILTER_IGNORE


func _ready() -> void:
	scale = Vector2.ONE * 0.4
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	draw_circle(size / 2.0, size.x * 0.48, Color(1, 1, 1, 0.06), true, -1.0, true)
	BoardView.draw_item(self, item, Rect2(Vector2.ZERO, size).grow(-size.x * 0.12))
