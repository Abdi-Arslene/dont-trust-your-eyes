class_name Solver
extends RefCounted
## Breadth-first search over board states. Proves levels can be finished,
## gives their par, and powers the in-game "show me the next move" hint.

const DIRS := {"U": Vector2i.UP, "R": Vector2i.RIGHT, "D": Vector2i.DOWN, "L": Vector2i.LEFT}


## Shortest list of actions ("U", "R", "plank@3,4"...) or null if unsolvable.
## Actions that trigger any event in `forbid` (e.g. "fake_wall") are not explored.
static func solve(start: Board, forbid: Array = [], max_states := 300000) -> Variant:
	var queue: Array = [[start, []]]
	var seen := {start.state_key(): true}
	var head := 0
	while head < queue.size() and seen.size() < max_states:
		var board: Board = queue[head][0]
		var path: Array = queue[head][1]
		head += 1
		for action in _actions(board):
			var next := board.clone()
			var events := apply(next, action)
			if forbid.any(func(e): return e in events):
				continue
			if next.won:
				return path + [action]
			if next.lost:
				continue
			var key := next.state_key()
			if not seen.has(key):
				seen[key] = true
				queue.append([next, path + [action]])
	return null


## The par route: avoids fake walls when the level can be done without them.
static func par_route(start: Board) -> Variant:
	var route = solve(start, ["fake_wall"])
	return route if route != null else solve(start)


## First action of the best route from here, or "" when the board is stuck.
static func next_action(board: Board, forbid: Array = []) -> String:
	var route = solve(board, forbid)
	if route == null and not forbid.is_empty():
		route = solve(board)
	return route[0] if route != null and not route.is_empty() else ""


static func is_drop(action: String) -> bool:
	return "@" in action


## "plank@3,4" -> ["plank", Vector2i(3, 4)]
static func parse_drop(action: String) -> Array:
	var parts := action.split("@")
	var xy := parts[1].split(",")
	return [parts[0], Vector2i(int(xy[0]), int(xy[1]))]


static func apply(board: Board, action: String) -> Array[String]:
	if DIRS.has(action):
		return board.move(DIRS[action])
	var drop := parse_drop(action)
	var events: Array[String] = []
	if board.drop(drop[0], drop[1]):
		events.append("drop")
	return events


static func _actions(board: Board) -> Array:
	var actions: Array = DIRS.keys()
	var grid: Array = board.rooms[board.room]
	for item in board.items:
		if not Board.ITEM_TARGETS.has(item):
			continue
		var target: String = Board.ITEM_TARGETS[item][0]
		for y in grid.size():
			var x: int = grid[y].find(target)
			while x != -1:
				actions.append("%s@%d,%d" % [item, x, y])
				x = grid[y].find(target, x + 1)
	return actions
