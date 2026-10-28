class_name Filou
extends Control
## Filou, the imp who owns the house of tricks and narrates the game.
## His nose grows while he lies (lines starting with "~")... most of the time.
## Moods: "idle", "laugh" (you fell for it), "grumpy" (you won), "surprised".

const C_SKIN := Color("6cc070")
const C_HAT := Color("8e44ad")
const C_INK := Color("2b2d42")

var talking := false  # set while his line is being typed
var _mood := "idle"
var _mood_time := 0.0
var _nose := 0.0  # 0 = normal, 1 = long liar's nose
var _nose_goal := 0.0
var _time := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(150, 170)
	mouse_filter = MOUSE_FILTER_IGNORE


func set_mood(mood: String, seconds := 1.6) -> void:
	_mood = mood
	_mood_time = seconds


func set_lying(on: bool) -> void:
	_nose_goal = 1.0 if on else 0.0


func _process(delta: float) -> void:
	_time += delta
	_nose = move_toward(_nose, _nose_goal, delta * 2.5)
	if _mood_time > 0.0:
		_mood_time -= delta
		if _mood_time <= 0.0:
			_mood = "idle"
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y) * 0.32
	var c := Vector2(size.x * 0.5, size.y * 0.6 + sin(_time * 2.2) * 3.0)
	if _mood == "laugh":
		c += Vector2(sin(_time * 40.0) * 2.5, -absf(sin(_time * 12.0)) * 6.0)
	elif _mood == "grumpy":
		c.x += sin(_time * 30.0) * 1.5

	# Ears, head, hat.
	for side in [-1, 1]:
		var base := c + Vector2(side * s * 0.85, -s * 0.1)
		draw_colored_polygon(PackedVector2Array([base + Vector2(0, -s * 0.3), base + Vector2(side * s * 0.7, -s * 0.55), base + Vector2(0, s * 0.25)]), C_SKIN.darkened(0.1))
	draw_circle(c, s, C_SKIN, true, -1.0, true)
	var tip := c + Vector2(s * 0.9, -s * 1.9 + sin(_time * 3.0) * s * 0.08)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.9, -s * 0.55), c + Vector2(s * 0.2, -s * 1.7), tip, c + Vector2(s * 0.9, -s * 0.55)]), C_HAT)
	draw_rect(Rect2(c + Vector2(-s * 0.95, -s * 0.68), Vector2(s * 1.9, s * 0.22)), C_HAT.darkened(0.2))
	draw_circle(tip, s * 0.17, Look.GOLD, true, -1.0, true)

	# Eyes and eyebrows.
	for side in [-1, 1]:
		var eye := c + Vector2(side * s * 0.38, -s * 0.12)
		match _mood:
			"laugh":
				draw_arc(eye + Vector2(0, s * 0.05), s * 0.16, PI * 1.1, PI * 1.9, 10, C_INK, s * 0.09, true)
			"surprised":
				draw_circle(eye, s * 0.24, Color.WHITE, true, -1.0, true)
				draw_circle(eye, s * 0.09, C_INK, true, -1.0, true)
			_:
				draw_circle(eye, s * 0.2, Color.WHITE, true, -1.0, true)
				draw_circle(eye + Vector2(s * 0.07, 0), s * 0.1, C_INK, true, -1.0, true)  # looks at the level, on his right
		var tilt := 0.25 if _mood == "grumpy" else -0.2  # mischievous by default, angry when you win
		var brow := eye + Vector2(0, -s * 0.32)
		var dir := Vector2.from_angle(tilt * side) * s * 0.2
		draw_line(brow - dir, brow + dir, C_INK, s * 0.08, true)

	# Nose (grows when lying) and mouth.
	var nose_len := s * (0.12 + 1.1 * _nose)
	var nose := c + Vector2(0, s * 0.12)
	draw_line(nose, nose + Vector2(nose_len, -nose_len * 0.08), Color("ff9f5a"), s * 0.2, true)
	draw_circle(nose + Vector2(nose_len, -nose_len * 0.08), s * 0.13, Color("ff8a3d"), true, -1.0, true)
	var mouth := c + Vector2(0, s * 0.5)
	var open := talking and fmod(_time, 0.24) < 0.12
	match _mood:
		"laugh":
			var pts := PackedVector2Array([mouth + Vector2(-s * 0.4, -s * 0.08)])
			for k in 9:
				pts.append(mouth + Vector2.from_angle(PI * k / 8.0) * Vector2(s * 0.4, s * 0.3))
			draw_colored_polygon(pts, C_INK)
		"grumpy":
			draw_arc(mouth + Vector2(0, s * 0.18), s * 0.25, PI * 1.2, PI * 1.8, 10, C_INK, s * 0.08, true)
		"surprised":
			draw_circle(mouth, s * 0.12, C_INK, true, -1.0, true)
		_:
			if open:
				Skins.ellipse(self, mouth, Vector2(s * 0.22, s * 0.14), C_INK)
			else:
				draw_arc(mouth - Vector2(0, s * 0.18), s * 0.35, PI * 0.2, PI * 0.8, 12, C_INK, s * 0.08, true)
