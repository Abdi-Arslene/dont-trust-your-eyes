class_name IconButton
extends Button
## A square button with a drawn icon: "levels", "hint", "restart", "back" or "gear".

var icon_name: String


func _init(icon_id: String) -> void:
	icon_name = icon_id
	custom_minimum_size = Vector2(84, 84)
	focus_mode = FOCUS_NONE


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) * 0.26
	var col := get_theme_color("font_pressed_color" if button_pressed or is_pressed() else "font_color")
	match icon_name:
		"levels":
			for i in 4:
				var off := Vector2(i % 2 * 2 - 1, floori(i / 2.0) * 2 - 1) * r * 0.55
				draw_rect(Rect2(c + off - Vector2.ONE * r * 0.38, Vector2.ONE * r * 0.76), col)
		"hint":  # a light bulb
			var bulb := c + Vector2(0, -r * 0.25)
			draw_circle(bulb, r * 0.72, Look.GOLD, true, -1.0, true)
			draw_rect(Rect2(bulb + Vector2(-r * 0.32, r * 0.55), Vector2(r * 0.64, r * 0.5)), col)
			draw_line(bulb + Vector2(-r * 0.32, r * 0.8), bulb + Vector2(r * 0.32, r * 0.8), get_theme_stylebox("normal").bg_color, 3.0)
			draw_arc(bulb, r * 0.4, PI * 0.9, PI * 1.4, 8, Color(1, 1, 1, 0.8), 4.0, true)
		"restart":
			var start := -PI * 0.3
			var end := PI * 1.35
			draw_arc(c, r, start, end, 24, col, 5.0, true)
			var p := c + Vector2.from_angle(end) * r
			var along := Vector2.from_angle(end + PI / 2.0)
			var out := Vector2.from_angle(end)
			draw_colored_polygon(PackedVector2Array([p + along * r * 0.45, p + out * r * 0.35, p - out * r * 0.35]), col)
		"back":
			draw_polyline(PackedVector2Array([c + Vector2(r * 0.4, -r * 0.8), c + Vector2(-r * 0.4, 0), c + Vector2(r * 0.4, r * 0.8)]), col, 6.0, true)
		"gear":
			for k in 8:
				var dir := Vector2.from_angle(k * TAU / 8.0)
				draw_line(c + dir * r * 0.6, c + dir * r * 1.05, col, r * 0.36)
			draw_circle(c, r * 0.72, col, true, -1.0, true)
			draw_circle(c, r * 0.3, get_theme_stylebox("normal").bg_color, true, -1.0, true)
