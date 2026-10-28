class_name ModeCard
extends Button
## A big menu card: drawn icon, title, a line under it, a badge on the right,
## and an optional progress bar. Locked cards are dimmed and show a padlock.

const C_TEXT := Look.INK

var kind: String  # icon: "door", "daily", "dream" or "bolt"
var title := ""
var subtitle := ""
var badge := ""
var accent := Color("f2c14e")
var progress := -1.0  # 0..1, or -1 for none
var locked := false
var _time := 0.0


func _init(icon_kind: String, card_accent: Color) -> void:
	kind = icon_kind
	accent = card_accent
	custom_minimum_size.y = 128
	focus_mode = FOCUS_NONE


func _ready() -> void:
	add_theme_stylebox_override("pressed", get_theme_stylebox("hover"))  # no yellow flash: the card has its own colours
	add_theme_stylebox_override("hover_pressed", get_theme_stylebox("hover"))


func _process(delta: float) -> void:
	_time += delta
	if kind == "dream" and not locked:
		queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var dim := 0.35 if locked else 1.0
	var tile := Rect2(Vector2(22, (size.y - 84) / 2.0), Vector2(84, 84))
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(accent, 0.2 * dim)
	bg.set_corner_radius_all(20)
	draw_style_box(bg, tile)
	_draw_icon(tile, Color(accent, dim))

	var x := tile.end.x + 22.0
	var width := size.x - x - 24.0
	var line := size.y * 0.42
	draw_string(font, Vector2(x, line), title, HORIZONTAL_ALIGNMENT_LEFT, width, 36, Color(C_TEXT, dim))
	draw_string(font, Vector2(x, line + 34), subtitle, HORIZONTAL_ALIGNMENT_LEFT, width, 23, Color(C_TEXT, 0.6 if not locked else 0.45))
	if locked:
		var c := Vector2(size.x - 44, size.y * 0.42)
		draw_arc(c + Vector2(0, -6), 11, PI, TAU, 16, Color(C_TEXT, 0.4), 4.0, true)
		draw_rect(Rect2(c + Vector2(-15, -5), Vector2(30, 24)), Color(C_TEXT, 0.4))
	elif badge != "":
		draw_string(font, Vector2(x, line), badge, HORIZONTAL_ALIGNMENT_RIGHT, width, 26, accent)
	if progress >= 0.0 and not locked:
		var bar := Rect2(Vector2(x, size.y - 17), Vector2(width, 6))
		draw_rect(bar, Color(1, 1, 1, 0.08))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(progress, 0.0, 1.0), bar.size.y)), accent)


func _draw_icon(r: Rect2, color: Color) -> void:
	var c := r.get_center()
	match kind:
		"door":
			var d := Rect2(c + Vector2(-16, -24), Vector2(32, 46))
			draw_rect(d, color)
			draw_circle(d.position + Vector2(24, 25), 3.5, C_TEXT)
		"daily":
			var page := Rect2(c + Vector2(-24, -22), Vector2(48, 46))
			draw_rect(page, color, false, 4.0)
			draw_rect(Rect2(page.position, Vector2(page.size.x, 12)), color)
			var day := str(Time.get_date_dict_from_system().day)
			draw_string(get_theme_default_font(), Vector2(page.position.x, page.end.y - 7), day, HORIZONTAL_ALIGNMENT_CENTER, page.size.x, 24, color)
		"bolt":
			var pts := PackedVector2Array()
			for p in [Vector2(4, -26), Vector2(-14, 4), Vector2(-1, 4), Vector2(-6, 26), Vector2(14, -6), Vector2(1, -6), Vector2(8, -26)]:
				pts.append(c + p)
			draw_colored_polygon(pts, color)
		"dream":
			var moon := c + Vector2(-3, 0)
			draw_circle(moon, 22, color, true, -1.0, true)
			draw_circle(moon + Vector2(11, -7), 19, Color.WHITE.lerp(Color(accent, 1.0), 0.2), true, -1.0, true)  # the icon tile's colour
			for k in 3:
				var twinkle := 0.5 + 0.5 * sin(_time * 3.0 + k * 2.0)
				draw_circle(c + Vector2(16 + k * 6, -18 + k * 14), 2.0 + 1.5 * twinkle, Color(color, twinkle))
