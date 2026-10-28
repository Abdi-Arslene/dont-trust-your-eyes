class_name Board
extends RefCounted
## Pure game rules: the grid state and what one action does to it.
## No rendering, no input: the view reads it, the solver clones it.
##
## Each room is a grid of 1-char cells (see docs/LEVELS.md for the legend).

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

const ARROWS := {"^": Vector2i.UP, ">": Vector2i.RIGHT, "v": Vector2i.DOWN, "<": Vector2i.LEFT}
const TURN_CW := {"^": ">", ">": "v", "v": "<", "<": "^"}
const PAINTS := {"w": "white", "r": "red", "b": "blue"}
## item -> [cell it can be dropped on, what that cell becomes]
const ITEM_TARGETS := {"plank": [VOID, FLOOR], "key": [LOCKED_DOOR, DOOR]}

var rooms := {}  # room name -> Array of rows, each row an Array of 1-char Strings
var room := ""
var pos := Vector2i.ZERO
var facing := Vector2i.DOWN
var tint := "white"
var items: Array[String] = []  # items still sitting in the top bar
var won := false
var lost := false
var _stairs: Array = []  # [room, Vector2i] of every stair: they turn but never move, so clones share it


static func from_level(level: Dictionary) -> Board:
	var b := Board.new()
	for room_name in level.rooms:
		var grid := []
		var lines: Array = level.rooms[room_name]
		for y in lines.size():
			var row := []
			var line: String = lines[y]
			for x in line.length():
				var ch := line[x]
				if ch == START:
					b.room = room_name
					b.pos = Vector2i(x, y)
					ch = FLOOR
				elif ARROWS.has(ch):
					b._stairs.append([room_name, Vector2i(x, y)])
				row.append(ch)
			grid.append(row)
		b.rooms[room_name] = grid
	b.items.assign(level.get("items", []))
	assert(b.room != "", "level has no start '@'")
	return b


func clone() -> Board:
	var b := Board.new()
	b.rooms = rooms.duplicate(true)
	b.room = room
	b.pos = pos
	b.facing = facing
	b.tint = tint
	b.items = items.duplicate()
	b.won = won
	b.lost = lost
	b._stairs = _stairs
	return b


## Everything that can change, flattened: two boards with the same key behave the same.
## Facing only matters to stairs (what you look at stays still).
func state_key() -> String:
	var key := "%s|%s|%s|%s|%s" % [room, pos, facing if not _stairs.is_empty() else Vector2i.ZERO, tint, ",".join(PackedStringArray(items))]
	for r in rooms:
		for row in rooms[r]:
			key += "|" + "".join(PackedStringArray(row))
	return key


## Orientation of every stair, flattened: changes whenever one turns.
func stairs_signature() -> String:
	var signature := ""
	for stair in _stairs:
		signature += cell(stair[1], stair[0])
	return signature


func cell(p: Vector2i, in_room: String = "") -> String:
	var grid: Array = rooms[in_room if in_room != "" else room]
	if p.y < 0 or p.y >= grid.size() or p.x < 0 or p.x >= grid[p.y].size():
		return WALL
	return grid[p.y][p.x]


func room_size(in_room: String = "") -> Vector2i:
	var grid: Array = rooms[in_room if in_room != "" else room]
	var w := 0
	for row in grid:
		w = maxi(w, row.size())
	return Vector2i(w, grid.size())


## The screen colour decides what a swipe means.
func steer(swipe: Vector2i) -> Vector2i:
	match tint:
		"red":
			return -swipe
		"blue":
			return Vector2i(-swipe.y, swipe.x)
	return swipe


## One swipe. Returns the events that happened, in order, for the view and narrator.
func move(swipe: Vector2i) -> Array[String]:
	var events: Array[String] = []
	if won or lost:
		return events
	var dir := steer(swipe)
	facing = dir
	var target := pos + dir
	var ch := cell(target)

	if ch == WALL:
		events.append("bump")
	elif ch == CRACKED_WALL:
		events.append("cracked")
	elif ch == PAINTED_DOOR:
		events.append("painted_door")
	elif ch == LOCKED_DOOR:
		events.append("locked")
	elif ch == CHALK_DOOR:
		_set_cell(target, DOOR)
		events.append("chalk_open")
	elif ARROWS.has(ch) and ARROWS[ch] != dir:
		events.append("arrow_blocked")
	else:
		pos = target
		events.append("step")
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

	_turn_unwatched_arrows()
	return events


func can_drop(item: String, p: Vector2i) -> bool:
	return item in items and ITEM_TARGETS.has(item) and cell(p) == ITEM_TARGETS[item][0]


## An item dragged out of the top bar lands in the level.
func drop(item: String, p: Vector2i) -> bool:
	if won or lost or not can_drop(item, p):
		return false
	items.erase(item)
	_set_cell(p, ITEM_TARGETS[item][1])
	return true


## The cell under the player, then straight ahead until something opaque.
func watched_cells() -> Array[Vector2i]:
	var seen: Array[Vector2i] = [pos]
	var p := pos + facing
	while not is_opaque(cell(p)):
		seen.append(p)
		p += facing
	return seen


static func is_opaque(ch: String) -> bool:
	return ch in [WALL, FAKE_WALL, CRACKED_WALL, DOOR, PAINTED_DOOR, CHALK_DOOR, LOCKED_DOOR] or ch.is_valid_int()


## Stairs you are not looking at turn a quarter clockwise, in every room.
func _turn_unwatched_arrows() -> void:
	if _stairs.is_empty():
		return
	var seen := watched_cells()
	for stair in _stairs:
		var p: Vector2i = stair[1]
		if not (stair[0] == room and p in seen):
			var row: Array = rooms[stair[0]][p.y]
			row[p.x] = TURN_CW[row[p.x]]


## A digit links two cells in two different rooms.
func _teleport(link: String) -> void:
	for r in rooms:
		if r == room:
			continue
		var grid: Array = rooms[r]
		for y in grid.size():
			for x in grid[y].size():
				if grid[y][x] == link:
					room = r
					pos = Vector2i(x, y)
					return


func _set_cell(p: Vector2i, ch: String) -> void:
	rooms[room][p.y][p.x] = ch
