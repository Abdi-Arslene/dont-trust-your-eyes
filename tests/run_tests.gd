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

	b = _board(["#####", "#@_D#", "#####"], ["plank"])
	_check(not b.can_drop("plank", Vector2i(1, 1)), "planks only go on the void")
	_check(b.drop("plank", Vector2i(2, 1)) and b.items.is_empty(), "plank bridges the void")

	b = Board.from_level({"rooms": {"a": ["###", "#@1", "###"], "b": ["#####", "#1.D#", "#####"]}})
	b.move(Vector2i.RIGHT)
	_check(b.room == "b" and b.pos == Vector2i(1, 1), "portals link rooms")


func _test_solver() -> void:
	print("Solver")
	var b := _board(["######", "#@..D#", "#X####", "#D####", "######"])
	_check(Solver.solve(b).size() == 2, "shortest route may use fake walls")
	_check(Solver.solve(b, ["fake_wall"]).size() == 3, "fake walls can be forbidden")
	_check(Solver.next_action(b, ["fake_wall"]) == "R", "next action follows the allowed route")
	var stuck := _board(["#####", "#@_D#", "#####"])
	_check(Solver.next_action(stuck) == "", "no next action when stuck")
	_check(Solver.next_action(_board(["#####", "#@_D#", "#####"], ["plank"])) == "plank@2,1", "next action can be a drop")
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
			for item in level["items"]:
				if not learned.has(item):
					unknown.append(item)
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
