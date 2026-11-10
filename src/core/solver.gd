class_name Solver
extends RefCounted
## Shortest-route search over board states (A*, guided by Board.estimate()).
## Proves levels can be finished, gives their par, and powers the in-game
## "show me the next move" hint.

const DIRS := {"U": Vector2i.UP, "R": Vector2i.RIGHT, "D": Vector2i.DOWN, "L": Vector2i.LEFT}


## Shortest list of actions ("U", "R", "D", "L") or null if unsolvable.
## Actions that trigger any event in `forbid` (e.g. "fake_wall") are not explored.
## The estimate never overshoots and changes by at most 1 per action, so the
## first winning action found ends a shortest route.
static func solve(start: Board, forbid: Array = [], max_states := 300000) -> Variant:
	# Each state keeps its parent and the action that led to it: no path copies.
	var boards: Array[Board] = [start]
	var parents := PackedInt32Array([-1])
	var actions := PackedStringArray([""])
	var costs := PackedInt32Array([0])
	var best := {start.state_key(): 0}  # state -> fewest actions found to reach it
	var open: Array[Array] = []  # open[f]: states whose cost + estimate is f
	_push(open, start.estimate(), 0)
	var f := 0
	while f < open.size() and best.size() < max_states:
		if open[f].is_empty():
			f += 1
			continue
		var node: int = open[f].pop_back()
		var board := boards[node]
		boards[node] = null  # explored: free it
		var cost := costs[node] + 1
		for action in DIRS:
			var next := board.clone()
			var events := apply(next, action)
			if events.is_empty() or (not forbid.is_empty() and forbid.any(func(e): return e in events)):
				continue
			if next.won:
				var route := [action]
				var i := node
				while parents[i] != -1:
					route.push_front(actions[i])
					i = parents[i]
				return route
			if next.lost:
				continue
			var key := next.state_key()
			if best.get(key, cost + 1) <= cost:
				continue
			best[key] = cost
			_push(open, cost + next.estimate(), boards.size())
			boards.append(next)
			parents.append(node)
			actions.append(action)
			costs.append(cost)
	return null


static func _push(open: Array[Array], f: int, node: int) -> void:
	while open.size() <= f:
		open.append([])
	open[f].append(node)


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


static func apply(board: Board, action: String) -> Array[String]:
	return board.move(DIRS[action])
