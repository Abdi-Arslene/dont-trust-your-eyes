class_name BoardView
extends Node2D
## Draws the current room of a Board with plain shapes (no image assets),
## plus the juice: eased movement, squash, faces, particles, turning
## stairs, darkness with a lying memory, and the hint hand.

const C_DOOR := Color("ffc93c")
const C_DOOR_FRAME := Color("8a5a2b")
const C_LOCKED := Color("8fa3bf")
const C_CHALK := Color(1, 1, 1, 0.95)
const C_STAIRS := Color("ff9f1c")
const C_HUT := Color("f4a261")
const C_ROOF := Color("e76f51")
const C_PLANK := Color("b5793f")
const C_HOLE := Color("1e1b4b")
const C_INK := Color("2b2d42")
const C_HINT := Color("ff4d8d")
const C_WALL := Color("a78bfa")  # particles of a wall you walked through
const C_ICE := [Color("d4f1ff"), Color("c2e9fb")]  # checkerboard, like the floor
const C_CRATE := Color("d08c45")
const C_BUTTON := Color("ef476f")
const C_GATE := Color("4a5568")
const C_BLOCKS := {"y": Color("ffc93c"), "u": Color("9b5de5")}
const PAINT_COLORS := {"w": Color("ffffff"), "r": Color("ef233c"), "b": Color("3a86ff")}

var board: Board
var tile := 64.0
var show_fakes := false  # after the big reveal, fake (and cracked) walls show cracks
var dark := false  # only what the player looks at, or stands next to, is lit
var skin: Dictionary = Skins.ALL[0]  # the hero's costume
var theme: Dictionary = Look.THEMES[0]

var _player_px := Vector2.ZERO
var _squash := 0.0
var _shake := 0.0
var _fall := 0.0
var _won := 0.0
var _time := 0.0
var _mood := "idle"
var _mood_time := 0.0
var _particles: Array = []  # {p, v, life, max, color, size}
var _arrow_angles := {}  # Vector3i(x, y, room) -> displayed angle, eased towards the real one
var _memory := {}  # dark rooms: Vector3i(x, y, room) -> cell as last seen (it may have changed since)
var _crate_px := {}  # crate cell -> where it is drawn (it eases towards its cell)
var _sinking: Array = []  # crates going down into a hole: {p (px), cell, t}
var _gates := 0.0  # 0 closed .. 1 open, eased
var _boxes := {}  # rounded boxes for the current tile size (made once, not every frame)
var _hint_swipe := Vector2i.ZERO


## Centers the current room inside `area` with the biggest tiles that fit.
func fit(area: Rect2) -> void:
	var cells := Vector2(board.room_size())
	tile = floorf(minf(minf(area.size.x / cells.x, area.size.y / cells.y), 110.0))
	position = (area.position + (area.size - cells * tile) / 2.0).round()
	_player_px = _cell_center(board.pos)
	_crate_px.clear()
	_boxes = {
		"shadow": Look.box(Look.SHADOW, int(tile * 0.3), false),
		"hole": Look.box(C_HOLE, int(tile * 0.22), false),
		"hole_rim": Look.box(Color(1, 1, 1, 0.08), int(tile * 0.16), false),
		"stairs": Look.box(C_STAIRS, int(tile * 0.2), false),
		"crate": Look.box(C_CRATE.darkened(0.12), int(tile * 0.14), false),
		"crate_top": Look.box(C_CRATE, int(tile * 0.12), false),
	}


func reset() -> void:
	_particles.clear()
	_arrow_angles.clear()
	_memory.clear()
	_crate_px.clear()
	_sinking.clear()
	_gates = 1.0 if board.gates_open() else 0.0
	_fall = 0.0
	_won = 0.0
	_squash = 0.0
	_mood = "idle"
	clear_hint()


func cell_at(global_point: Vector2) -> Vector2i:
	var p := to_local(global_point) / tile
	return Vector2i(floori(p.x), floori(p.y))


func cell_to_global(cell: Vector2i) -> Vector2:
	return to_global(_cell_center(cell))


# --- Effects, triggered by the game -----------------------------------------

func set_mood(mood: String, seconds := 0.6) -> void:
	_mood = mood
	_mood_time = seconds


func step() -> void:
	_squash = 1.0
	burst(board.pos, Color(1, 1, 1, 0.7), 4, 0.6)


func nudge(dir: Vector2i) -> void:
	_player_px += Vector2(dir) * tile * 0.18
	set_mood("bump")


func shake() -> void:
	_shake = 1.0


func fall() -> void:
	_fall = 0.01
	set_mood("fall", 2.0)
	shake()


func win() -> void:
	_won = 0.01
	set_mood("win", 99.0)
	for color in [C_DOOR, C_HINT, Color("3a86ff"), Color("2ec27e")]:
		burst(board.pos, color, 14, 3.0)


func burst(cell: Vector2i, color: Color, count: int, speed := 1.5) -> void:
	var center := _cell_center(cell)
	for i in count:
		var dir := Vector2.from_angle(randf() * TAU)
		_particles.append({
			"p": center + dir * tile * 0.2,
			"v": dir * tile * randf_range(0.5, 1.0) * speed,
			"life": randf_range(0.35, 0.8), "max": 0.8,
			"color": color, "size": tile * randf_range(0.04, 0.08),
		})


## The last move pushed a crate: it slides from its old cell (and may sink into a hole).
func crate_moved(from: Vector2i, to: Vector2i, sank: bool) -> void:
	var px: Vector2 = _crate_px.get(from, _cell_center(from))
	_crate_px.erase(from)
	if sank:
		_sinking.append({"p": px, "cell": to, "t": 0.0})
	else:
		_crate_px[to] = px


func show_hint_swipe(dir: Vector2i) -> void:
	clear_hint()
	_hint_swipe = dir


func clear_hint() -> void:
	_hint_swipe = Vector2i.ZERO


# --- Animation ---------------------------------------------------------------

func _process(delta: float) -> void:
	if board == null:
		return
	_time += delta
	var target := _cell_center(board.pos)
	_player_px = _player_px.lerp(target, minf(1.0, delta * 18.0))
	if _player_px.distance_to(target) < 0.5:
		_player_px = target
	_squash = move_toward(_squash, 0.0, delta * 6.0)
	_shake = maxf(0.0, _shake - delta * 3.0)
	if _fall > 0.0:
		_fall = minf(1.0, _fall + delta * 1.4)
	if _won > 0.0:
		_won = minf(1.0, _won + delta * 2.5)
	if _mood_time > 0.0:
		_mood_time -= delta
		if _mood_time <= 0.0:
			_mood = "idle"

	for p in _particles:
		p.p += p.v * delta
		p.v *= 0.9
		p.life -= delta
	_particles = _particles.filter(func(p): return p.life > 0.0)

	for p in board.stairs_here():
		var key := _key(p)
		var goal := Vector2(Board.ARROWS[board.cell(p)]).angle()
		var shown: float = _arrow_angles.get(key, goal)
		_arrow_angles[key] = shown + wrapf(goal - shown, -PI, PI) * minf(1.0, delta * 14.0)

	if board.has_crates() or not _sinking.is_empty():
		var eased := {}
		for c in board.crates():
			var shown: Vector2 = _crate_px.get(c, _cell_center(c))
			eased[c] = shown.lerp(_cell_center(c), minf(1.0, delta * 16.0))
		_crate_px = eased
		for s in _sinking:
			s.t += delta * 2.5
			s.p = s.p.lerp(_cell_center(s.cell), minf(1.0, delta * 16.0))
		_sinking = _sinking.filter(func(s): return s.t < 1.0)
	_gates = move_toward(_gates, 1.0 if board.gates_open() else 0.0, delta * 5.0)
	queue_redraw()


func _cell_center(p: Vector2i) -> Vector2:
	return (Vector2(p) + Vector2.ONE * 0.5) * tile


func _key(p: Vector2i) -> Vector3i:
	return Vector3i(p.x, p.y, board.room_index())


# --- Drawing -----------------------------------------------------------------

func _draw() -> void:
	if board == null:
		return
	var offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * tile * 0.08
	draw_set_transform(offset)
	var cells := board.room_size()
	if not dark:  # the room sits on the table like a toy
		draw_style_box(_boxes.shadow, Rect2(Vector2(0, tile * 0.18), Vector2(cells) * tile))
	var seen := board.watched_cells()
	var lit := _lit_cells(seen)
	var night := Color(theme.bg[1], 0.68)
	for y in cells.y:
		for x in cells.x:
			var p := Vector2i(x, y)
			var r := Rect2(Vector2(p) * tile, Vector2.ONE * tile)
			if not dark or lit.has(p):
				var ch := board.cell(p)
				_memory[_key(p)] = ch
				_draw_cell(ch, p, r, _arrow_angles.get(_key(p), 0.0))
			elif _memory.has(_key(p)):
				var remembered: String = _memory[_key(p)]
				var angle := Vector2(Board.ARROWS[remembered]).angle() if Board.ARROWS.has(remembered) else 0.0
				_draw_cell(remembered, p, r, angle)
				draw_rect(r, night)

	for s in _sinking:  # a crate going down into its hole
		_draw_crate(s.p, 1.0 - s.t * 0.3)
	for c in _crate_px:
		if not dark or lit.has(c):
			if board.cell(c) == Board.PLATE:  # the button under it shows through, pressed
				draw_rect(Rect2(_cell_center(c) - Vector2.ONE * tile * 0.47, Vector2.ONE * tile * 0.94), C_BUTTON, false, tile * 0.06)
			_draw_crate(_crate_px[c])

	for i in range(1, seen.size()):  # the gaze: a soft beam of light ahead
		var fade := 1.0 - float(i) / (seen.size() + 2)
		draw_rect(Rect2(Vector2(seen[i]) * tile, Vector2.ONE * tile).grow(-tile * 0.06), Color(Look.GOLD, 0.22 * fade))

	for p in _particles:
		var k: float = p.life / p.max
		draw_circle(p.p, p.size * (0.5 + k), Color(p.color, p.color.a * k))
	_draw_player(offset)
	_draw_hints()
	draw_set_transform(Vector2.ZERO)


func _lit_cells(seen: Array[Vector2i]) -> Dictionary:
	var lit := {}
	if not dark:
		return lit
	for p in seen:
		lit[p] = true
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			lit[board.pos + Vector2i(dx, dy)] = true
	return lit


func _draw_player(offset: Vector2) -> void:
	var size := 1.0 - _fall
	if size <= 0.01:
		return
	var hop := -absf(sin(_time * 9.0)) * tile * 0.22 if _won > 0.0 else 0.0  # happy jumps at the door
	var squash := Vector2(1.0 + 0.18 * _squash, 1.0 - 0.14 * _squash) * size
	var xf := Transform2D(_fall * 7.0, squash, 0.0, _player_px + offset + Vector2(0, hop))
	draw_set_transform_matrix(xf)
	if dark:
		draw_circle(Vector2.ZERO, tile * 0.95, Color(Look.GOLD, 0.08), true, -1.0, true)
	Skins.draw_hero(self, Vector2.ZERO, tile * 0.4, Vector2(board.facing), skin, _time, _mood)
	draw_set_transform(offset)


func _draw_hints() -> void:
	var pulse := 0.55 + 0.45 * sin(_time * 6.0)
	if _hint_swipe != Vector2i.ZERO:
		var dir := Vector2(_hint_swipe)
		var from := _player_px + dir * tile * 0.5
		var to := _player_px + dir * tile * (1.2 + 0.12 * pulse)
		var side := dir.orthogonal() * tile * 0.24
		draw_line(from, to, C_HINT, tile * 0.12, true)
		draw_colored_polygon(PackedVector2Array([to + dir * tile * 0.26, to + side, to - side]), C_HINT)
		var k := fmod(_time * 0.9, 1.0)  # a fingertip showing the swipe, again and again
		_draw_touch(_player_px + dir * tile * 1.4 * ease(k, 0.6), 1.0 - k * 0.7)


## Where a finger touches the screen: a white dot in a pink ring.
func _draw_touch(p: Vector2, alpha: float) -> void:
	draw_circle(p, tile * 0.24, Color(C_HINT, 0.35 * alpha), true, -1.0, true)
	draw_circle(p, tile * 0.15, Color(1, 1, 1, alpha), true, -1.0, true)
	draw_arc(p, tile * 0.15, 0, TAU, 24, Color(C_HINT, alpha), tile * 0.04, true)


func _draw_cell(ch: String, p: Vector2i, r: Rect2, arrow_angle: float) -> void:
	match ch:
		Board.WALL, Board.FAKE_WALL, Board.CRACKED_WALL:
			_draw_wall(r)
			if ch != Board.WALL and show_fakes:
				_draw_crack(r)
		Board.DOOR, Board.PAINTED_DOOR:  # identical on purpose
			_draw_wall(r)
			var glow := 0.5 + 0.5 * sin(_time * 2.6)
			draw_circle(r.get_center(), tile * (0.42 + 0.05 * glow), Color(C_DOOR, 0.18 + 0.12 * glow), true, -1.0, true)
			_draw_door(r, C_DOOR)
			if fmod(_time * 0.7 + p.x * 0.31 + p.y * 0.17, 1.0) < 0.25:  # sparkle
				_sparkle(r.position + r.size * Vector2(0.78, 0.2), tile * 0.08)
		Board.LOCKED_DOOR:
			_draw_wall(r)
			_draw_door(r, C_LOCKED)
			var lock := r.position + r.size * Vector2(0.5, 0.52)
			draw_arc(lock + Vector2(0, -tile * 0.08), tile * 0.09, PI, TAU, 10, C_INK, tile * 0.04, true)
			draw_rect(Rect2(lock + Vector2(-tile * 0.12, -tile * 0.08), Vector2(tile * 0.24, tile * 0.18)), Look.GOLD)
		Board.CHALK_DOOR:
			_draw_wall(r)
			_draw_chalk(r)
		Board.ICE:
			draw_rect(r, C_ICE[(p.x + p.y) % 2])
			for streak in [[Vector2(0.18, 0.3), Vector2(0.42, 0.18)], [Vector2(0.5, 0.78), Vector2(0.82, 0.6)]]:
				draw_line(r.position + r.size * streak[0], r.position + r.size * streak[1], Color(1, 1, 1, 0.85), tile * 0.05, true)
		_:
			draw_rect(r, theme.floor[(p.x + p.y) % 2])
			if ch == Board.VOID:
				draw_style_box(_boxes.hole, r.grow(-tile * 0.08))
				draw_style_box(_boxes.hole_rim, r.grow(-tile * 0.22))
			elif C_BLOCKS.has(ch):
				_draw_block(r, C_BLOCKS[ch], board.is_raised(ch))
			elif ch == Board.SWITCH:
				_draw_switch(r)
			elif ch == Board.FRAGILE:  # the floor, crossed with cracks
				draw_rect(r.grow(-tile * 0.04), Color(C_INK, 0.06))
				for crack in [[0.15, 0.3, 0.42, 0.45, 0.5, 0.2], [0.42, 0.45, 0.58, 0.7, 0.85, 0.62], [0.58, 0.7, 0.45, 0.9, 0.3, 0.82]]:
					draw_polyline(PackedVector2Array([r.position + r.size * Vector2(crack[0], crack[1]), r.position + r.size * Vector2(crack[2], crack[3]), r.position + r.size * Vector2(crack[4], crack[5])]), Color(C_INK, 0.55), maxf(2.0, tile * 0.035), true)
			elif ch == Board.BRIDGE:  # the hole, with Pico's plank laid over it
				draw_style_box(_boxes.hole, r.grow(-tile * 0.08))
				draw_item(self, "plank", r)
			elif Board.PICKUPS.has(ch):  # bobbing, to say "take me"
				var bob := Vector2(0, sin(_time * 3.0 + p.x) * tile * 0.05)
				draw_circle(r.get_center(), tile * 0.36, Color(Look.GOLD, 0.25), true, -1.0, true)
				draw_item(self, Board.PICKUPS[ch], Rect2(r.position + bob, r.size).grow(-tile * 0.12))
			elif ch == Board.FILLED:  # the crate, sunk level with the floor
				draw_style_box(_boxes.crate, r.grow(-tile * 0.08))
				draw_rect(r.grow(-tile * 0.22), C_CRATE.darkened(0.3), false, tile * 0.05)
			elif ch == Board.PLATE:
				_draw_button(r, board.has_crate(p) or board.pos == p)
			elif ch == Board.GATE:
				_draw_gate(r, 1.0 if board.pos == p or board.has_crate(p) else _gates)  # it cannot close on someone
			elif Board.ARROWS.has(ch):
				_draw_stairs(r, arrow_angle)
			elif Board.PAINTS.has(ch):
				_draw_puddle(r, PAINT_COLORS[ch], ch == "w")
			elif ch.is_valid_int():
				_draw_hut(r)


func _draw_wall(r: Rect2) -> void:
	draw_rect(r, theme.wall[1])
	draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.8)), theme.wall[0])
	draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.08)), Color(1, 1, 1, 0.18))


func _door_rect(r: Rect2) -> Rect2:
	return Rect2(r.position + r.size * Vector2(0.2, 0.16), r.size * Vector2(0.6, 0.64))


## An arched door: a rectangle with a round top, in a wooden frame.
func _draw_door(r: Rect2, color: Color) -> void:
	var d := _door_rect(r)
	var top := d.position + Vector2(d.size.x / 2.0, d.size.x / 2.0)
	for layer in [[C_DOOR_FRAME, tile * 0.05], [color, 0.0]]:
		var grow: float = layer[1]
		draw_circle(top, d.size.x / 2.0 + grow, layer[0], true, -1.0, true)
		draw_rect(Rect2(d.position + Vector2(-grow, d.size.x / 2.0), Vector2(d.size.x + grow * 2.0, d.size.y - d.size.x / 2.0 + grow)), layer[0])
	draw_circle(d.position + d.size * Vector2(0.75, 0.62), tile * 0.05, C_DOOR_FRAME)


func _draw_chalk(r: Rect2) -> void:
	var d := _door_rect(r)
	var radius := d.size.x / 2.0
	var top := d.position + Vector2(radius, radius)
	draw_arc(top, radius, PI, TAU, 14, C_CHALK, 3.0, true)
	for side in [d.position.x, d.end.x]:
		draw_dashed_line(Vector2(side, top.y), Vector2(side, d.end.y), C_CHALK, 3.0, tile * 0.07)
	draw_dashed_line(Vector2(d.position.x, d.end.y), d.end, C_CHALK, 3.0, tile * 0.07)
	draw_arc(d.position + d.size * Vector2(0.75, 0.62), tile * 0.05, 0, TAU, 12, C_CHALK, 2.0)


func _draw_crack(r: Rect2) -> void:
	var pts := PackedVector2Array()
	for p in [Vector2(0.3, 0.05), Vector2(0.45, 0.32), Vector2(0.35, 0.5), Vector2(0.6, 0.75)]:
		pts.append(r.position + r.size * p)
	draw_polyline(pts, Color(C_INK, 0.7), maxf(3.0, tile * 0.05), true)


func _draw_stairs(r: Rect2, angle: float) -> void:
	draw_style_box(_boxes.stairs, r.grow(-tile * 0.08))
	var c := r.get_center()
	var fwd := Vector2.from_angle(angle) * tile
	var side := fwd.orthogonal()
	for step: float in [-0.14, 0.12]:
		var tip := c + fwd * (step + 0.14)
		draw_polyline(PackedVector2Array([tip - fwd * 0.2 + side * 0.24, tip, tip - fwd * 0.2 - side * 0.24]), Color.WHITE, tile * 0.09, true)


## A wooden crate centred on `center` (smaller while it sinks into a hole).
func _draw_crate(center: Vector2, scale := 1.0) -> void:
	var half := tile * 0.42 * scale
	var r := Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0)
	draw_style_box(_boxes.crate, r)
	var top := Rect2(r.position, Vector2(r.size.x, r.size.y * 0.84))
	draw_style_box(_boxes.crate_top, top)
	var plank := C_CRATE.darkened(0.3)
	var inner := top.grow(-half * 0.2)
	draw_rect(inner, plank, false, tile * 0.05)
	draw_line(inner.position, inner.end, plank, tile * 0.06, true)


## A switch block: up, it is a coloured wall; down, a flat tile with its outline.
func _draw_block(r: Rect2, color: Color, raised: bool) -> void:
	if raised:
		var block := r.grow(-tile * 0.04)
		draw_rect(block, color.darkened(0.25))
		draw_rect(Rect2(block.position, Vector2(block.size.x, block.size.y * 0.8)), color)
		draw_rect(block.grow(-tile * 0.16), Color(1, 1, 1, 0.25), false, tile * 0.05)
	else:
		draw_rect(r.grow(-tile * 0.1), Color(color, 0.25))
		draw_rect(r.grow(-tile * 0.1), Color(color, 0.8), false, tile * 0.05)


## A lever on a plate: it leans towards the colour of the blocks that are down.
func _draw_switch(r: Rect2) -> void:
	var c := r.get_center()
	draw_circle(c, tile * 0.34, Color("8d99ae"), true, -1.0, true)
	var down: Color = C_BLOCKS.y if board.switched else C_BLOCKS.u
	var tip := c + Vector2(tile * (0.2 if board.switched else -0.2), -tile * 0.22)
	draw_line(c + Vector2(0, tile * 0.1), tip, C_INK, tile * 0.07, true)
	draw_circle(tip, tile * 0.1, down, true, -1.0, true)


## A round button in a grey ring; pressed down when something stands on it.
func _draw_button(r: Rect2, pressed: bool) -> void:
	var c := r.get_center()
	draw_circle(c, tile * 0.32, Color("8d99ae"), true, -1.0, true)
	if pressed:
		draw_circle(c, tile * 0.22, C_BUTTON.darkened(0.25), true, -1.0, true)
	else:
		draw_circle(c + Vector2(0, tile * 0.05), tile * 0.22, C_BUTTON.darkened(0.35), true, -1.0, true)
		draw_circle(c, tile * 0.22, C_BUTTON, true, -1.0, true)
		draw_circle(c + Vector2(-tile * 0.07, -tile * 0.07), tile * 0.06, Color(1, 1, 1, 0.6), true, -1.0, true)


## Bars that slide up into the top of the cell as the gates open (`open` 0..1).
func _draw_gate(r: Rect2, open: float) -> void:
	var top := r.position.y + tile * 0.06
	var bottom := lerpf(r.end.y - tile * 0.06, top + tile * 0.14, open)
	draw_rect(Rect2(r.position.x + tile * 0.06, top - tile * 0.02, tile * 0.88, tile * 0.12), C_GATE)
	for k in 4:
		var x := r.position.x + tile * (0.2 + k * 0.2)
		draw_line(Vector2(x, top), Vector2(x, bottom), C_GATE, tile * 0.08, true)
	if open < 0.5:
		draw_line(Vector2(r.position.x + tile * 0.1, bottom - tile * 0.12), Vector2(r.end.x - tile * 0.1, bottom - tile * 0.12), C_GATE, tile * 0.06, true)


func _draw_puddle(r: Rect2, paint: Color, white: bool) -> void:
	var c := r.get_center()
	var blobs := [[Vector2.ZERO, 0.3], [Vector2(0.22, 0.12), 0.16], [Vector2(-0.2, 0.14), 0.14], [Vector2(0.05, -0.24), 0.12]]
	if white:  # a white puddle would vanish on a light floor
		for b in blobs:
			draw_circle(c + b[0] * tile, tile * (b[1] + 0.03), Color("b8c0cc"), true, -1.0, true)
	for b in blobs:
		draw_circle(c + b[0] * tile, tile * b[1], paint, true, -1.0, true)
	Skins.ellipse(self, c + Vector2(-0.1, -0.08) * tile, Vector2(tile * 0.09, tile * 0.05), Color(1, 1, 1, 0.6))


func _draw_hut(r: Rect2) -> void:
	var at := func(x: float, y: float) -> Vector2: return r.position + r.size * Vector2(x, y)
	draw_rect(Rect2(at.call(0.2, 0.45), r.size * Vector2(0.6, 0.42)), C_HUT)
	draw_colored_polygon(PackedVector2Array([at.call(0.08, 0.5), at.call(0.5, 0.12), at.call(0.92, 0.5)]), C_ROOF)
	draw_rect(Rect2(at.call(0.42, 0.62), r.size * Vector2(0.16, 0.25)), C_INK)
	draw_rect(Rect2(at.call(0.26, 0.55), r.size * Vector2(0.11, 0.11)), Look.GOLD)


func _sparkle(p: Vector2, s: float) -> void:
	draw_line(p - Vector2(s, 0), p + Vector2(s, 0), Color.WHITE, s * 0.35, true)
	draw_line(p - Vector2(0, s), p + Vector2(0, s), Color.WHITE, s * 0.35, true)


## Item art, shared by the top bar and the items lying in the level.
static func draw_item(ci: CanvasItem, item: String, r: Rect2) -> void:
	var at := func(x: float, y: float) -> Vector2: return r.position + r.size * Vector2(x, y)
	match item:
		"plank":
			ci.draw_rect(Rect2(at.call(0.08, 0.34), r.size * Vector2(0.84, 0.32)), C_PLANK)
			ci.draw_rect(Rect2(at.call(0.08, 0.58), r.size * Vector2(0.84, 0.08)), C_PLANK.darkened(0.25))
			for x in [0.3, 0.7]:
				ci.draw_circle(at.call(x, 0.46), r.size.x * 0.04, C_INK)
		"key":
			ci.draw_arc(at.call(0.3, 0.5), r.size.x * 0.14, 0, TAU, 24, Look.GOLD, r.size.x * 0.08, true)
			ci.draw_rect(Rect2(at.call(0.42, 0.46), r.size * Vector2(0.48, 0.09)), Look.GOLD)
			ci.draw_rect(Rect2(at.call(0.74, 0.5), r.size * Vector2(0.07, 0.17)), Look.GOLD)
			ci.draw_rect(Rect2(at.call(0.84, 0.5), r.size * Vector2(0.06, 0.13)), Look.GOLD)
