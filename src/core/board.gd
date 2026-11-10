class_name Board
extends RefCounted
## Pure game rules: the grid state and what one action does to it.
## No rendering, no input: the view reads it, the solver clones it.
##
## Each room is a grid of 1-char cells (see docs/LEVELS.md for the legend).
## The grids never change: what does (opened doors, filled holes, turned stairs,
## pushed crates) lives in small overlays, so cloning a board is cheap.

const WALL := "#"
const FLOOR := "."
const VOID := "_"
const DOOR := "D"
const PAINTED_DOOR := "d"
const CHALK_DOOR := "c"
const FAKE_WALL := "X"
const CRACKED_WALL := "x"  # looks like a revealed fake wall, but is solid
const LOCKED_DOOR := "L"
const START := "@"
const ICE := "i"  # you slide until something stops you
const CRATE := "o"  # pushed one cell; it fills a hole it is pushed into
const PLATE := "p"  # a button: pressed while Pico or a crate stands on it
const GATE := "g"  # bars, open while every button of its room is pressed
const FILLED := "="  # a hole filled by a crate: floor from now on
const PLANK := "-"  # a plank lying there: walk on it to take it
const KEY := "k"  # a key lying there: walk on it to take it
const BRIDGE := "+"  # a hole with a plank laid over it: floor from now on
const FRAGILE := "f"  # cracked floor: it holds once, then falls in behind you (a hole)
const SWITCH := "s"  # stepping on it flips every block: yellow ones go down, purple ones up (or back)
const YELLOW := "y"  # a block, down (walkable) while the switches are on
const PURPLE := "u"  # a block, down (walkable) while the switches are off

const ARROWS := {"^": Vector2i.UP, ">": Vector2i.RIGHT, "v": Vector2i.DOWN, "<": Vector2i.LEFT}
const ARROW_ORDER := ["^", ">", "v", "<"]  # clockwise
const PAINTS := {"w": "white", "r": "red", "b": "blue"}
const TINT_CODES := {"white": 0, "red": 1, "blue": 2}
const PICKUPS := {PLANK: "plank", KEY: "key"}  # cell -> item it gives
const CRATE_GROUND := [FLOOR, FILLED, BRIDGE, ICE, PLATE, VOID]  # where a crate can be pushed (and open gates)

var room := ""
var pos := Vector2i.ZERO
var facing := Vector2i.DOWN
var tint := "white"
var items: Array[String] = []  # what Pico carries (shown in the top bar)
var won := false
var lost := false
var last_push: Array[Vector2i] = []  # [from, to] of the crate pushed by the last move, for the view
var crumbled := Vector2i(-1, -1)  # the cracked floor that fell in during the last move, for the view

var _layout: Layout  # what never changes, shared by all clones
var _ri := 0  # index of the current room
var _over: Dictionary  # Vector3i -> cell that replaced the grid's (chalk opened, hole filled, lock used)
var _turns: PackedByteArray  # per stair: index in ARROW_ORDER
var _crates: Dictionary  # Vector3i -> true
var switched := false  # flipped by every switch Pico steps on


## The level as loaded. Positions are Vector3i(x, y, room index).
class Layout:
	var names := PackedStringArray()  # room names, in level order
	var grids := []  # per room: Array of PackedStringArray rows
	var stairs: Array[Vector3i] = []  # they turn but never move
	var stair_at := {}  # Vector3i -> index in stairs
	var plates: Array[Vector3i] = []
	var exits: Array[Vector2i] = []  # cells that are or may become doors (one room, no ice), for estimate()


static func from_level(level: Dictionary) -> Board:
	var b := Board.new()
	var l := Layout.new()
	b._layout = l
	var found_start := false
	for room_name in level.rooms:
		var ri := l.names.size()
		l.names.append(room_name)
		var grid := []
		var lines: Array = level.rooms[room_name]
		for y in lines.size():
			var row := PackedStringArray()
			var line: String = lines[y]
			for x in line.length():
				var ch := line[x]
				var at := Vector3i(x, y, ri)
				if ch == START:
					b.room = room_name
					b._ri = ri
					b.pos = Vector2i(x, y)
					found_start = true
					ch = FLOOR
				elif ch == CRATE:
					b._crates[at] = true
					ch = FLOOR
				elif ARROWS.has(ch):
					l.stair_at[at] = l.stairs.size()
					l.stairs.append(at)
					b._turns.append(ARROW_ORDER.find(ch))
				elif ch == PLATE:
					l.plates.append(at)
				row.append(ch)
			grid.append(row)
		l.grids.append(grid)
	b.items.assign(level.get("items", []))
	assert(found_start, "level has no start '@'")
	if l.grids.size() == 1:
		var exits: Array[Vector2i] = []
		var ice := false
		for y in l.grids[0].size():
			var row: PackedStringArray = l.grids[0][y]
			for x in row.size():
				ice = ice or row[x] == ICE
				if row[x] in [DOOR, CHALK_DOOR, LOCKED_DOOR]:
					exits.append(Vector2i(x, y))
		if not ice:
			l.exits = exits
	return b


func clone() -> Board:
	var b := Board.new()
	b.room = room
	b.pos = pos
	b.facing = facing
	b.tint = tint
	b.items = items.duplicate()
	b.won = won
	b.lost = lost
	b._layout = _layout
	b._ri = _ri
	b._over = _over.duplicate()
	b._turns = _turns.duplicate()
	b._crates = _crates.duplicate()
	b.switched = switched
	return b


## Everything that can change, packed: two boards with the same key behave the same.
## Facing only matters to stairs (what you look at stays still).
func state_key() -> PackedInt32Array:
	var dir := facing if not _layout.stairs.is_empty() else Vector2i.ZERO
	var key := PackedInt32Array([_ri, pos.x, pos.y, dir.x, dir.y, TINT_CODES[tint], items.size()])
	var carried := PackedInt32Array()
	for item in items:
		carried.append(item.hash())
	carried.sort()  # a plank then a key, or a key then a plank: the same bag
	key.append_array(carried)
	key.append_array(_packed(_over))
	key.append(-1)
	key.append_array(_packed(_crates))
	key.append(-1)
	key.append(int(switched))
	for t in _turns:
		key.append(t)
	return key


static func _packed(cells: Dictionary) -> PackedInt32Array:
	var out := PackedInt32Array()
	for c: Vector3i in cells:
		out.append((c.z << 16) | (c.y << 8) | c.x)
	out.sort()
	return out


## Orientation of every stair, flattened: changes whenever one turns.
func stairs_signature() -> String:
	return _turns.hex_encode()


func cell(p: Vector2i, in_room: String = "") -> String:
	var ri := _ri if in_room == "" else _layout.names.find(in_room)
	var grid: Array = _layout.grids[ri]
	if p.y < 0 or p.y >= grid.size() or p.x < 0 or p.x >= grid[p.y].size():
		return WALL
	var at := Vector3i(p.x, p.y, ri)
	if _over.has(at):
		return _over[at]
	if _layout.stair_at.has(at):
		return ARROW_ORDER[_turns[_layout.stair_at[at]]]
	return grid[p.y][p.x]


func room_size(in_room: String = "") -> Vector2i:
	var grid: Array = _layout.grids[_ri if in_room == "" else _layout.names.find(in_room)]
	var w := 0
	for row: PackedStringArray in grid:
		w = maxi(w, row.size())
	return Vector2i(w, grid.size())


## A lower bound on the actions left: the walk to the nearest way out.
## One action moves one cell at most, except on ice or through a hut: there it says 0.
func estimate() -> int:
	if _layout.exits.is_empty():
		return 0
	var best := 1 << 20
	for e in _layout.exits:
		best = mini(best, absi(e.x - pos.x) + absi(e.y - pos.y))
	return best


## Which room is shown: changes when Pico goes through a hut.
func room_index() -> int:
	return _ri


## Stairs of the current room, wherever they point.
func stairs_here() -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for at in _layout.stairs:
		if at.z == _ri:
			found.append(Vector2i(at.x, at.y))
	return found


func has_crate(p: Vector2i) -> bool:
	return _crates.has(Vector3i(p.x, p.y, _ri))


func crates() -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for c: Vector3i in _crates:
		if c.z == _ri:
			found.append(Vector2i(c.x, c.y))
	return found


func has_crates() -> bool:
	return not _crates.is_empty()


## The gates of this room are open while every button of the room is pressed (by Pico or a crate).
func gates_open() -> bool:
	var any := false
	for plate in _layout.plates:
		if plate.z != _ri:
			continue
		any = true
		if not (_crates.has(plate) or Vector2i(plate.x, plate.y) == pos):
			return false
	return any


## The screen colour decides what a swipe means.
func steer(swipe: Vector2i) -> Vector2i:
	match tint:
		"red":
			return -swipe
		"blue":
			return Vector2i(-swipe.y, swipe.x)
	return swipe


## One swipe. Returns the events that happened, in order, for the view and narrator.
## On ice, Pico keeps sliding in the same direction until something stops him.
func move(swipe: Vector2i) -> Array[String]:
	var events: Array[String] = []
	if won or lost:
		return events
	var dir := steer(swipe)
	facing = dir
	last_push = []
	crumbled = Vector2i(-1, -1)
	var left := Vector3i(pos.x, pos.y, _ri)
	var on_fragile := cell(pos) == FRAGILE
	var moved := _step(dir, events)
	while moved and not (won or lost) and cell(pos) == ICE:
		moved = _step(dir, events, true)
	if moved and on_fragile:  # no way back over it
		_over[left] = VOID
		if left.z == _ri:
			crumbled = Vector2i(left.x, left.y)
		events.append("crumble")
	_turn_unwatched_arrows()
	return events


## One cell forward: blocked, pushed into, or walked onto. Returns true if Pico moved.
func _step(dir: Vector2i, events: Array[String], sliding := false) -> bool:
	var target := pos + dir
	var ch := cell(target)

	if has_crate(target):
		if not _push_crate(target, dir, events):
			if not sliding:
				events.append("crate_blocked")
			return false
	elif ch == WALL:
		if not sliding:
			events.append("bump")
		return false
	elif ch == CRACKED_WALL:
		events.append("cracked")
		return false
	elif ch == PAINTED_DOOR:
		events.append("painted_door")
		return false
	elif ch == LOCKED_DOOR:
		if "key" in items:  # Pico unlocks it, then walks in with the next move
			items.erase("key")
			_set_cell(target, DOOR)
			events.append("unlock")
		else:
			events.append("locked")
		return false
	elif ch == VOID and "plank" in items:  # Pico lays his plank over the hole instead of falling
		items.erase("plank")
		_set_cell(target, BRIDGE)
		events.append("drop")
		return false
	elif ch == CHALK_DOOR:
		_set_cell(target, DOOR)
		events.append("chalk_open")
		return false
	elif ARROWS.has(ch) and ARROWS[ch] != dir:
		events.append("arrow_blocked")
		return false
	elif is_raised(ch):
		events.append("block")
		return false
	elif ch == GATE and not gates_open():
		events.append("gate_closed")
		return false

	var was_pressed := gates_open()
	pos = target
	events.append("slide" if sliding else "step")
	if ch == FAKE_WALL:
		events.append("fake_wall")
	elif ch == VOID:
		lost = true
		events.append("fall")
	elif ch == DOOR:
		won = true
		events.append("win")
	elif PAINTS.has(ch):
		tint = PAINTS[ch]
		events.append("tint")
	elif ch.is_valid_int():
		_teleport(ch)
		events.append("portal")
	elif ch == SWITCH:
		switched = not switched
		events.append("toggle")
	elif PICKUPS.has(ch):
		items.append(PICKUPS[ch])
		_set_cell(target, FLOOR)
		events.append("pickup")
	if gates_open() != was_pressed and not _layout.plates.is_empty():
		events.append("gates_open" if gates_open() else "gates_shut")
	return true


## A crate moves one cell (and keeps sliding on ice). Into a hole, it fills it.
func _push_crate(at: Vector2i, dir: Vector2i, events: Array[String]) -> bool:
	var was_open := gates_open()
	var to := at + dir
	if not _crate_can_enter(to):
		return false
	_crates.erase(Vector3i(at.x, at.y, _ri))
	while cell(to) == ICE and _crate_can_enter(to + dir):
		to += dir
	last_push = [at, to]
	if cell(to) == VOID:
		_set_cell(to, FILLED)
		events.append("crate_fill")
	else:
		_crates[Vector3i(to.x, to.y, _ri)] = true
		events.append("push")
	if gates_open() != was_open:
		events.append("gates_open" if gates_open() else "gates_shut")
	return true


func _crate_can_enter(p: Vector2i) -> bool:
	if has_crate(p) or p == pos:
		return false
	var ch := cell(p)
	return ch in CRATE_GROUND or (ch == GATE and gates_open())


## The cell under the player, then straight ahead until something opaque.
func watched_cells() -> Array[Vector2i]:
	var seen: Array[Vector2i] = [pos]
	var p := pos + facing
	while not is_opaque(cell(p)) and not has_crate(p) and not is_raised(cell(p)):
		seen.append(p)
		p += facing
	return seen


## A switch block standing up: a wall for now.
func is_raised(ch: String) -> bool:
	return (ch == YELLOW and not switched) or (ch == PURPLE and switched)


static func is_opaque(ch: String) -> bool:
	return ch in [WALL, FAKE_WALL, CRACKED_WALL, DOOR, PAINTED_DOOR, CHALK_DOOR, LOCKED_DOOR] or ch.is_valid_int()


## Stairs you are not looking at turn a quarter clockwise, in every room.
func _turn_unwatched_arrows() -> void:
	if _layout.stairs.is_empty():
		return
	var seen := watched_cells()
	for i in _layout.stairs.size():
		var at := _layout.stairs[i]
		if not (at.z == _ri and Vector2i(at.x, at.y) in seen):
			_turns[i] = (_turns[i] + 1) % 4


## A digit links two cells in two different rooms.
func _teleport(link: String) -> void:
	for ri in _layout.grids.size():
		if ri == _ri:
			continue
		var grid: Array = _layout.grids[ri]
		for y in grid.size():
			var x: int = grid[y].find(link)
			if x != -1:
				_ri = ri
				room = _layout.names[ri]
				pos = Vector2i(x, y)
				return


func _set_cell(p: Vector2i, ch: String) -> void:
	_over[Vector3i(p.x, p.y, _ri)] = ch
