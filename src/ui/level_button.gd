class_name LevelButton
extends Button
## A level in the level select: number, best stars, and an eye once its secret is found.

const C_STAR := Look.GOLD

var index: int
var _stars := 0
var _secret := false
var _locked := false


func _init(level_index: int) -> void:
	index = level_index
	custom_minimum_size = Vector2(130, 120)
	focus_mode = FOCUS_NONE
	mouse_filter = MOUSE_FILTER_PASS  # lets the scroll container scroll from a button too


func _ready() -> void:
	var level: Dictionary = Levels.all()[index]
	_locked = not Save.is_unlocked(index)
	_stars = Save.stars_of(level.id)
	_secret = Save.secrets.has(level.id)
	disabled = _locked


func _draw() -> void:
	var font := get_theme_default_font()
	var col := get_theme_color("font_disabled_color" if _locked else "font_color")
	if _locked:
		var c := Vector2(size.x / 2.0, size.y * 0.45)
		draw_arc(c + Vector2(0, -8), 13, PI, TAU, 16, col, 5.0, true)
		draw_rect(Rect2(c + Vector2(-18, -6), Vector2(36, 28)), col)
		return
	draw_string(font, Vector2(0, size.y * 0.52), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, size.x, 44, col)
	for i in 3:
		var c := Vector2(size.x / 2.0 + (i - 1) * 26.0, size.y * 0.78)
		var pts := PackedVector2Array()
		for k in 10:
			pts.append(c + Vector2.from_angle(-PI / 2.0 + k * PI / 5.0) * (10.0 if k % 2 == 0 else 4.5))
		draw_colored_polygon(pts, C_STAR if i < _stars else Color(Look.INK, 0.12))
	if _secret:
		var e := Vector2(size.x - 22, 20)
		draw_arc(e, 9, 0, TAU, 16, BoardView.C_HINT, 3.0, true)
		draw_circle(e, 4, BoardView.C_HINT)
