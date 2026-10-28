class_name Skins
extends RefCounted
## The hero and its costumes: how each one looks, and the goal that unlocks it.
## The goal reads a number from Save.stats() ("stat") and needs at least "need".

const ALL := [
	{"id": "classic", "name": "Pico", "goal": "", "stat": "", "need": 0, "body": Color("4fc3f7"), "hat": ""},
	{"id": "cap", "name": "Casquette", "goal": "15 étoiles", "stat": "stars", "need": 15, "body": Color("ff8fab"), "hat": "cap"},
	{"id": "cat", "name": "Chaton", "goal": "30 étoiles", "stat": "stars", "need": 30, "body": Color("ffb347"), "hat": "cat"},
	{"id": "ghost", "name": "Fantôme", "goal": "Tomber 10 fois", "stat": "falls", "need": 10, "body": Color(0.93, 0.95, 1.0, 0.85), "hat": "ghost"},
	{"id": "jester", "name": "Bouffon", "goal": "Croire 15 portes dessinées", "stat": "painted", "need": 15, "body": Color("ef476f"), "hat": "jester"},
	{"id": "robot", "name": "Robot", "goal": "Trouver un passage secret", "stat": "secrets", "need": 1, "body": Color("a8b5c8"), "hat": "antenna"},
	{"id": "wizard", "name": "Magicien", "goal": "Défi du jour 3 jours de suite", "stat": "streak", "need": 3, "body": Color("9b7bf0"), "hat": "wizard"},
	{"id": "sleepy", "name": "Dormeur", "goal": "8 rêves d'affilée", "stat": "dreams", "need": 8, "body": Color("7fb5ff"), "hat": "nightcap"},
	{"id": "king", "name": "Roi", "goal": "Finir l'histoire", "stat": "story", "need": 1, "body": Color("e63946"), "hat": "crown"},
	{"id": "flower", "name": "Tournesol", "goal": "Défi du jour 7 jours de suite", "stat": "streak", "need": 7, "body": Color("7ed957"), "hat": "flower"},
	{"id": "ninja", "name": "Ninja", "goal": "20 rêves d'affilée", "stat": "dreams", "need": 20, "body": Color("33334d"), "hat": "headband"},
	{"id": "rainbow", "name": "Arc-en-ciel", "goal": "Toutes les étoiles", "stat": "all_stars", "need": 1, "body": Color("ffffff"), "hat": "star"},
]
const C_INK := Color("2b2d42")


static func get_skin(id: String) -> Dictionary:
	for skin in ALL:
		if skin.id == id:
			return skin
	return ALL[0]


static func is_unlocked(skin: Dictionary, stats: Dictionary) -> bool:
	return skin.stat == "" or stats.get(skin.stat, 0) >= skin.need


## "12 / 30" for goals that count something, "" for one-time goals.
static func progress(skin: Dictionary, stats: Dictionary) -> String:
	if skin.need <= 1:
		return ""
	return "%d / %d" % [mini(stats.get(skin.stat, 0), skin.need), skin.need]


## The hero, centered on `c`, about 2·`s` wide. `look` (-1..1) moves its eyes.
## mood: "idle", "bump" (ouch), "fall" (help!), "win" (yay!).
static func draw_hero(ci: CanvasItem, c: Vector2, s: float, look: Vector2, skin: Dictionary, t: float, mood := "idle", alpha := 1.0) -> void:
	var body: Color = skin.body
	if skin.hat == "star":
		body = Color.from_hsv(fmod(t * 0.15, 1.0), 0.45, 1.0)
	body.a *= alpha
	var dark := Color(body.darkened(0.25), body.a)
	var ink := Color(C_INK, alpha)
	var white := Color(1, 1, 1, alpha)

	ellipse(ci, c + Vector2(0, s * 0.92), Vector2(s * 0.75, s * 0.16), Color(0, 0, 0, 0.13 * alpha))
	if skin.hat != "ghost":
		for side in [-1, 1]:
			ellipse(ci, c + Vector2(side * s * 0.4, s * 0.8), Vector2(s * 0.24, s * 0.15), dark)
	if skin.hat == "cat":
		for side in [-1, 1]:
			var ear := c + Vector2(side * s * 0.5, -s * 0.62)
			ci.draw_colored_polygon(PackedVector2Array([ear + Vector2(-s * 0.26, s * 0.12), ear + Vector2(side * s * 0.08, -s * 0.42), ear + Vector2(s * 0.26, s * 0.12)]), body)
			ci.draw_colored_polygon(PackedVector2Array([ear + Vector2(-s * 0.12, s * 0.06), ear + Vector2(side * s * 0.05, -s * 0.24), ear + Vector2(s * 0.12, s * 0.06)]), Color(Look.PINK, alpha))
	ellipse(ci, c, Vector2(s * 0.95, s * 0.86), body)
	if skin.hat == "ghost":  # wavy hem instead of feet
		for k in 4:
			ci.draw_circle(c + Vector2(lerpf(-s * 0.7, s * 0.7, k / 3.0), s * 0.72), s * 0.24, body, true, -1.0, true)
	ellipse(ci, c + Vector2(-s * 0.4, -s * 0.45), Vector2(s * 0.22, s * 0.12), Color(1, 1, 1, 0.35 * alpha))

	# Cheeks, eyes, mouth.
	for side in [-1, 1]:
		ci.draw_circle(c + Vector2(side * s * 0.62, s * 0.22), s * 0.13, Color(Look.PINK, 0.45 * alpha), true, -1.0, true)
	var blink := fmod(t + skin.id.length(), 3.7) < 0.12
	for side in [-1, 1]:
		var eye := c + Vector2(side * s * 0.34, -s * 0.12)
		match mood:
			"win":
				ci.draw_arc(eye + Vector2(0, s * 0.06), s * 0.17, PI * 1.15, PI * 1.85, 10, ink, s * 0.09, true)
			"bump":
				var a := eye + Vector2(-side * s * 0.12, -s * 0.12)
				ci.draw_polyline(PackedVector2Array([a, eye + Vector2(side * s * 0.1, 0), a + Vector2(0, s * 0.24)]), ink, s * 0.08, true)
			_:
				if blink and mood == "idle":
					ci.draw_line(eye - Vector2(s * 0.18, 0), eye + Vector2(s * 0.18, 0), ink, s * 0.08, true)
					continue
				var r := s * (0.32 if mood == "fall" else 0.28)
				ci.draw_circle(eye, r, white, true, -1.0, true)
				var pupil := eye + look.limit_length(1.0) * r * 0.42
				ci.draw_circle(pupil, r * (0.32 if mood == "fall" else 0.55), ink, true, -1.0, true)
				ci.draw_circle(pupil + Vector2(-r * 0.2, -r * 0.22), r * 0.18, white, true, -1.0, true)
	var mouth := c + Vector2(0, s * 0.36)
	match mood:
		"win":
			var pts := PackedVector2Array([mouth + Vector2(-s * 0.28, -s * 0.04)])
			for k in 9:
				pts.append(mouth + Vector2.from_angle(PI * k / 8.0) * Vector2(s * 0.28, s * 0.3))
			ci.draw_colored_polygon(pts, ink)
			ci.draw_circle(mouth + Vector2(0, s * 0.18), s * 0.1, Color(Look.PINK, alpha), true, -1.0, true)
		"bump":
			ci.draw_circle(mouth, s * 0.08, ink, true, -1.0, true)
		"fall":
			ellipse(ci, mouth + Vector2(0, s * 0.04), Vector2(s * 0.14, s * 0.2), ink)
		_:
			ci.draw_arc(mouth - Vector2(0, s * 0.1), s * 0.18, PI * 0.15, PI * 0.85, 10, ink, s * 0.07, true)
	_draw_hat(ci, c, s, skin.hat, t, alpha)


static func _draw_hat(ci: CanvasItem, c: Vector2, s: float, hat: String, t: float, alpha: float) -> void:
	var top := c + Vector2(0, -s * 0.78)
	var a := func(col: Color) -> Color: return Color(col, col.a * alpha)
	match hat:
		"cap":
			var dome := PackedVector2Array()
			for k in 17:
				dome.append(top + Vector2(0, s * 0.22) + Vector2.from_angle(PI + PI * k / 16.0) * Vector2(s * 0.62, s * 0.5))
			ci.draw_colored_polygon(dome, a.call(Color("3a86ff")))
			ellipse(ci, top + Vector2(s * 0.5, s * 0.1), Vector2(s * 0.42, s * 0.1), a.call(Color("265fc9")))
		"crown":
			var pts := PackedVector2Array()
			for k in 7:
				var x := lerpf(-s * 0.5, s * 0.5, k / 6.0)
				pts.append(top + Vector2(x, -s * (0.42 if k % 2 == 0 else 0.12)))
			pts.append(top + Vector2(s * 0.5, s * 0.08))
			pts.append(top + Vector2(-s * 0.5, s * 0.08))
			ci.draw_colored_polygon(pts, a.call(Look.GOLD))
			for k in 3:
				ci.draw_circle(top + Vector2(lerpf(-s * 0.3, s * 0.3, k / 2.0), -s * 0.04), s * 0.06, a.call(Color("e63946")), true, -1.0, true)
		"wizard":
			ci.draw_colored_polygon(PackedVector2Array([top + Vector2(-s * 0.55, s * 0.1), top + Vector2(s * 0.12, -s * 0.95), top + Vector2(s * 0.55, s * 0.1)]), a.call(Color("5a3fc0")))
			star(ci, top + Vector2(0, -s * 0.25), s * 0.13, a.call(Look.GOLD))
		"nightcap":
			ci.draw_colored_polygon(PackedVector2Array([top + Vector2(-s * 0.55, s * 0.1), top + Vector2(s * 0.7, -s * 0.35), top + Vector2(s * 0.5, s * 0.1)]), a.call(Color("3a6ea5")))
			ci.draw_circle(top + Vector2(s * 0.72, -s * 0.33), s * 0.13, a.call(Color.WHITE), true, -1.0, true)
		"jester":
			for side in [-1, 1]:
				var tip := top + Vector2(side * s * 0.62, -s * 0.5)
				ci.draw_colored_polygon(PackedVector2Array([top + Vector2(-s * 0.15 * -side, s * 0.1), tip, top + Vector2(side * s * 0.45, s * 0.1)]), a.call(Color("ffd166") if side < 0 else Color("06d6a0")))
				ci.draw_circle(tip, s * 0.1, a.call(Look.GOLD), true, -1.0, true)
		"antenna":
			ci.draw_line(top + Vector2(0, s * 0.1), top + Vector2(0, -s * 0.35), a.call(Color("5c677d")), s * 0.07, true)
			var glow := 0.6 + 0.4 * sin(t * 6.0)
			ci.draw_circle(top + Vector2(0, -s * 0.4), s * 0.12, a.call(Color(1.0, 0.3, 0.3, glow)), true, -1.0, true)
		"flower":
			var center := top + Vector2(s * 0.3, -s * 0.05)
			for k in 6:
				ci.draw_circle(center + Vector2.from_angle(k * TAU / 6.0 + t * 0.5) * s * 0.17, s * 0.12, a.call(Color("ffd60a")), true, -1.0, true)
			ci.draw_circle(center, s * 0.11, a.call(Color("9c6644")), true, -1.0, true)
		"headband":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.92, -s * 0.48), Vector2(s * 1.84, s * 0.18)), a.call(Color("e63946")))
			ci.draw_line(c + Vector2(s * 0.85, -s * 0.4), c + Vector2(s * 1.2, -s * 0.2 + sin(t * 5.0) * s * 0.08), a.call(Color("e63946")), s * 0.1, true)
		"star":
			star(ci, top + Vector2(0, -s * 0.18), s * 0.24, a.call(Look.GOLD))


## A five-pointed star (hats, win card).
static func star(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		pts.append(c + Vector2.from_angle(-PI / 2.0 + k * PI / 5.0) * (r if k % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, color)


static func ellipse(ci: CanvasItem, c: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	var count := clampi(int(maxf(radii.x, radii.y) * 0.8), 16, 64)  # smooth even when big
	for k in count:
		var angle := k * TAU / count
		pts.append(c + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	ci.draw_colored_polygon(pts, color)
