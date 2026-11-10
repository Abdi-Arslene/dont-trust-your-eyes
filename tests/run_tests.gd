extends SceneTree
## Headless test runner: rule checks + every level is solvable, and its par
## and secret flag in levels.json match what the solver finds.
##   godot --headless --import            (once, registers class names)
##   godot --headless -s tests/run_tests.gd

var _failures := 0


func _init() -> void:
	_test_rules()
	_test_solver()
	_test_levels()
	_test_generator()
	print("\n%s" % ("ALL TESTS PASSED" if _failures == 0 else "%d FAILURE(S)" % _failures))
	quit(1 if _failures else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		print("  FAIL  ", what)


func _board(lines: Array, items: Array = []) -> Board:
	return Board.from_level({"rooms": {"main": lines}, "items": items})


func _test_rules() -> void:
	print("Rules")
	var b := _board(["#####", "#@.D#", "#####"])
	_check(b.move(Vector2i.UP) == ["bump"], "walls block")
	b.move(Vector2i.RIGHT)
	b.move(Vector2i.RIGHT)
	_check(b.won, "reaching the door wins")

	b = _board(["####", "#@d#", "####"])
	_check(b.move(Vector2i.RIGHT) == ["painted_door"] and b.pos == Vector2i(1, 1), "painted doors are walls")

	b = _board(["####", "#@c#", "####"])
	b.move(Vector2i.RIGHT)
	_check(b.cell(Vector2i(2, 1)) == Board.DOOR, "chalk doors become real when touched")

	b = _board(["####", "#@X.", "####"])
	_check("fake_wall" in b.move(Vector2i.RIGHT) and b.pos == Vector2i(2, 1), "fake walls let you through")

	b = _board(["####", "#@x.", "####"])
	_check(b.move(Vector2i.RIGHT) == ["cracked"] and b.pos == Vector2i(1, 1), "cracked walls are solid")

	b = _board(["#####", "#@r.#", "#...#", "#####"])
	b.move(Vector2i.RIGHT)
	_check(b.steer(Vector2i.LEFT) == Vector2i.RIGHT, "red inverts controls")
	b.tint = "blue"
	_check(b.steer(Vector2i.UP) == Vector2i.RIGHT, "blue rotates controls clockwise")

	b = _board(["#####", "#@.^#", "#####"])
	b.move(Vector2i.RIGHT)
	_check(b.cell(Vector2i(3, 1)) == "^", "watched stairs do not turn")
	var before := b.stairs_signature()
	b.move(Vector2i.UP)
	_check(b.cell(Vector2i(3, 1)) == ">" and b.stairs_signature() != before, "unwatched stairs turn clockwise")
	_check(b.move(Vector2i.RIGHT) == ["step"], "stairs let you pass in their direction")

	b = _board(["######", "#@-_D#", "######"])
	_check(b.move(Vector2i.RIGHT) == ["step", "pickup"] and b.items == ["plank"] and b.cell(Vector2i(2, 1)) == Board.FLOOR, "walking on a plank picks it up")
	_check(b.move(Vector2i.RIGHT) == ["drop"] and b.pos == Vector2i(2, 1) and b.items.is_empty(), "walking into a hole with a plank lays it")
	_check(b.cell(Vector2i(3, 1)) == Board.BRIDGE and b.move(Vector2i.RIGHT) == ["step"], "a laid plank is a bridge")
	b = _board(["#####", "#@_D#", "#####"])
	b.move(Vector2i.RIGHT)
	_check(b.lost, "without a plank, you fall")
	b = _board(["######", "#k@LD#", "######"])
	_check(b.move(Vector2i.RIGHT) == ["locked"], "a locked door needs the key")
	b.move(Vector2i.LEFT)
	b.move(Vector2i.RIGHT)
	_check(b.move(Vector2i.RIGHT) == ["unlock"] and b.cell(Vector2i(3, 1)) == Board.DOOR and b.items.is_empty(), "walking into it with the key opens it")
	b = _board(["#######", "#@k-.#", "#######"])
	var other := _board(["#######", "#@k-.#", "#######"])
	b.items.assign(["plank", "key"])
	other.items.assign(["key", "plank"])
	_check(b.state_key() == other.state_key(), "the bag's order does not matter")

	b = Board.from_level({"rooms": {"a": ["###", "#@1", "###"], "b": ["#####", "#1.D#", "#####"]}})
	b.move(Vector2i.RIGHT)
	_check(b.room == "b" and b.pos == Vector2i(1, 1), "portals link rooms")

	b = _board(["#######", "#@iii.#", "#######"])
	b.move(Vector2i.RIGHT)
	_check(b.pos == Vector2i(5, 1), "ice slides you to the first cell that is not ice")
	b = _board(["######", "#@ii##", "######"])
	_check(b.move(Vector2i.RIGHT) == ["step", "slide"] and b.pos == Vector2i(3, 1), "a slide stops against a wall, on the ice")
	b = _board(["######", "#@ii_#", "######"])
	b.move(Vector2i.RIGHT)
	_check(b.lost, "sliding into a hole is a fall")

	b = _board(["######", "#@o.#", "######"])
	_check(b.move(Vector2i.RIGHT) == ["push", "step"] and b.has_crate(Vector2i(3, 1)) and b.pos == Vector2i(2, 1), "crates are pushed one cell")
	_check(b.move(Vector2i.RIGHT) == ["crate_blocked"] and b.pos == Vector2i(2, 1), "a crate against a wall does not move")
	b = _board(["######", "#@oo.#", "######"])
	_check(b.move(Vector2i.RIGHT) == ["crate_blocked"], "two crates in a row are too heavy")
	b = _board(["######", "#@o_D#", "######"])
	_check("crate_fill" in b.move(Vector2i.RIGHT) and b.cell(Vector2i(3, 1)) == Board.FILLED and not b.has_crates(), "a crate pushed into a hole fills it")
	b = _board(["#######", "#@oii.#", "#######"])
	b.move(Vector2i.RIGHT)
	_check(b.has_crate(Vector2i(5, 1)), "crates slide on ice")
	b = _board(["#####", "#@o^#", "#####"])
	_check(b.move(Vector2i.RIGHT) == ["crate_blocked"], "crates do not go on stairs")
	b = _board(["######", "#@.o^#", "######"])
	b.move(Vector2i.RIGHT)
	_check(b.cell(Vector2i(4, 1)) == ">", "a crate hides the stairs behind it")

	b = _board(["######", "#@f.D#", "######"])
	_check(b.move(Vector2i.RIGHT) == ["step"] and b.pos == Vector2i(2, 1), "cracked floor holds you")
	_check(b.move(Vector2i.RIGHT) == ["step", "crumble"] and b.cell(Vector2i(2, 1)) == Board.VOID and b.crumbled == Vector2i(2, 1), "it falls in once you leave it")
	_check(Solver.solve(b) != null and Solver.solve(_stuck_after_crumble()) == null, "no way back over it")

	b = _board(["#######", "#@yus.#", "#######"])
	_check(b.move(Vector2i.RIGHT) == ["block"] and b.watched_cells().size() == 1, "yellow blocks stand up at first, and hide what is behind")
	b = _board(["#######", "#.s@yu#", "#######"])
	_check(b.move(Vector2i.LEFT) == ["step", "toggle"] and b.switched, "a switch flips the blocks")
	b.move(Vector2i.RIGHT)
	_check(b.move(Vector2i.RIGHT) == ["step"] and b.move(Vector2i.RIGHT) == ["block"], "yellow down, purple up")
	var flipped := _board(["#######", "#.s@yu#", "#######"])
	flipped.move(Vector2i.LEFT)
	flipped.move(Vector2i.RIGHT)
	_check(flipped.state_key() != _board(["#######", "#.s@yu#", "#######"]).state_key(), "the switch is part of the state")

	b = _board(["######", "#@pg.#", "######"])
	_check(not b.gates_open(), "gates are closed while their button is up")
	_check(b.move(Vector2i.RIGHT) == ["step", "gates_open"], "standing on the button opens the gates")
	_check(b.move(Vector2i.RIGHT) == ["step", "gates_shut"] and b.pos == Vector2i(3, 1), "you can walk into an open gate")
	_check(b.move(Vector2i.RIGHT) == ["step"], "and out of it, even closed")
	b = _board(["######", "#@.g.#", "######"])
	_check(b.move(Vector2i.RIGHT) == ["step"] and b.move(Vector2i.RIGHT) == ["gate_closed"], "closed gates block")
	b = _board(["#######", "#@op#g#", "#..##.#", "#######"])
	_check("gates_open" in b.move(Vector2i.RIGHT) and b.gates_open(), "a crate on the button keeps the gates open")


## A dead end behind cracked floor: once in, the door is out of reach.
func _stuck_after_crumble() -> Board:
	var b := _board(["#######", "#D.@f.#", "#######"])
	b.move(Vector2i.RIGHT)
	b.move(Vector2i.RIGHT)
	return b


func _test_solver() -> void:
	print("Solver")
	var b := _board(["######", "#@..D#", "#X####", "#D####", "######"])
	_check(Solver.solve(b).size() == 2, "shortest route may use fake walls")
	_check(Solver.solve(b, ["fake_wall"]).size() == 3, "fake walls can be forbidden")
	_check(Solver.next_action(b, ["fake_wall"]) == "R", "next action follows the allowed route")
	var stuck := _board(["#####", "#@_D#", "#####"])
	_check(Solver.next_action(stuck) == "", "no next action when stuck")
	_check(Solver.solve(_board(["#######", "#-#@_D#", "#.#.###", "#...###", "#######"])).size() == 15, "the solver fetches the plank first")
	_check(Levels.goal({"par": 10}) == 12 and Levels.goal({"par": 30}) == 36, "the goal leaves a little slack")
	_check(Levels.stars({"par": 10}, 12, false) == 3 and Levels.stars({"par": 10}, 20, false) == 2 and Levels.stars({"par": 10}, 21, false) == 1, "star thresholds")
	_check(Levels.stars({"par": 10}, 8, true) == 2, "the bulb's help caps stars at 2")


func _test_levels() -> void:
	print("Levels")
	var levels := Levels.all()
	var ids := {}
	for i in levels.size():
		var level: Dictionary = levels[i]
		var name := "level %d (%s)" % [i + 1, level.id]
		_check(not ids.has(level.id), name + " has a unique id")
		ids[level.id] = true
		var starts := 0
		for r in level.rooms:
			for line in level.rooms[r]:
				starts += line.count(Board.START)
		_check(starts == 1, name + " has exactly one start")
		_check(level.has("chapter") and level.get("hints", []).size() >= 2, name + " has a chapter and 2 hints")
		var par = Solver.par_route(Board.from_level(level))
		var free = Solver.solve(Board.from_level(level))
		_check(par != null, name + " is solvable")
		if par == null:
			continue
		_check(par.size() == level.par, "%s par is %d (json says %d)" % [name, par.size(), level.par])
		_check((free.size() < par.size()) == level.get("secret", false), name + " secret flag matches")
		print("  %2d %-12s par %3d%s  %s" % [i + 1, level.id, par.size(), "  secret %d" % free.size() if free.size() < par.size() else "", " ".join(PackedStringArray(par))])


func _test_generator() -> void:
	print("Generator")
	var ids := Levels.all().map(func(l): return l.id)
	var everything := Levels.learned(ids)
	var early := Levels.learned(ids.slice(0, 6))
	_check(Levels.learned([]).is_empty(), "nothing is learned before playing")
	_check(Generator.make(7, 4, everything) == Generator.make(7, 4, everything), "same seed, same level")
	for depth in [0, 3, 6, 10]:
		for s in 3:
			var learned := early if s == 1 else everything
			var level := Generator.make(100 * depth + s, depth, learned)
			var name := "generated level (depth %d, seed %d)" % [depth, s]
			var route = Solver.solve(Board.from_level(level))
			_check(route != null and route.size() == level.par, name + " is solvable at its par")
			var unknown := []
			for line in level.rooms.main:
				for ch in line:
					var known: String = "^" if Board.ARROWS.has(ch) else ch
					if not (learned.has(known) or ch in [Board.START, Board.WALL, Board.FLOOR, Board.DOOR]):
						unknown.append(ch)
			_check(unknown.is_empty(), "%s only uses known rules (unknown: %s)" % [name, unknown])
	var run := DreamRun.new(everything, true)
	var first := run.take()
	_check(run.energy == first.par + DreamRun.margin(0) + DreamRun.START_BONUS, "survival: the first level brings its route, a margin and a bonus")
	run.energy = 40
	run.cleared(false)
	var second := run.take()
	_check(run.energy == DreamRun.CARRY_MAX + second.par + DreamRun.margin(1), "survival: leftover energy is capped when carried over")
	_check(run.spend(run.energy - 1) and not run.spend(1), "survival: the run is lost when the gauge is empty")
	_check(DreamRun.margin(0) == 6 and DreamRun.margin(30) == 1, "survival: the margin shrinks with depth, never below 1")
	run.stop()
	var save_script: GDScript = load("res://src/autoload/save.gd")
	_check(save_script.day_before("2026-03-01") == "2026-02-28", "the daily streak knows which day was yesterday")
