extends SceneTree
## Plays every level through the real UI (menu -> game screen), feeding it the
## solver's route, then checks the win card. Also exercises the hint eye, the
## daily challenge, an endless run down to its last life, and the collection.
## Catches UI/runtime errors the rule tests can't see.
##   godot --headless -s tests/smoke_test.gd

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var save: Node = root.get_node("Save")
	var real_save := FileAccess.get_file_as_bytes(save.PATH) if FileAccess.file_exists(save.PATH) else PackedByteArray()
	# play from a blank profile; the real one is restored below
	save.results = {}
	save.secrets = {}
	save.walls_revealed = false
	save.daily = {}
	save.last_daily = ""
	save.streak = 0
	save.best_dreams = 0
	save.best_survival = 0
	change_scene_to_file("res://scenes/main.tscn")
	await _wait(0.6)
	var main := current_scene
	var levels := Levels.all()

	for i in levels.size():
		main._play(i)
		await _wait(0.6)
		var game = main._screen  # untyped: typing it would compile game.gd before the autoloads exist
		await _play_route(game)
		var fills_screen: bool = game.size == main.size and game._view.tile > 30.0
		_report("%2d %-14s" % [i + 1, levels[i].id], fills_screen and game._board.won and game._win.visible)

	# The bulb: two written hints, then it points at the next move (computed on a thread).
	main._play(levels.map(func(l): return l.id).find("top_bar"))
	await _wait(0.6)
	var game = main._screen
	for k in 3:
		game._on_hint()
	await _wait(0.5)
	_report("hint bulb", game._view._hint_swipe == Vector2i.RIGHT and game._hinted)

	# Daily challenge: generated, played, streak counted.
	main._start_daily()
	game = await _next_game(main)
	await _play_route(game)
	_report("daily challenge", game._board.won and game._win.visible and save.streak == 1 and save.daily_done())

	# Dreams: cross two, then lose every life.
	main._start_dreams()
	for k in 2:
		game = await _next_game(main)
		await _play_route(game)
		var crossed: bool = game._board.won and game._win.visible and game._run.depth == k + 1
		_report("dream %d" % (k + 1), crossed)
		game._on_win_right()
	game = await _next_game(main)
	for k in 3:
		game._moves = 1  # restarting a level already started costs a life
		game._on_restart_pressed()
		await process_frame
	_report("waking up", game._over and game._win.visible and save.best_dreams == 2)
	game._on_win_left()
	await _wait(0.6)

	# Survival: cross one level, then bump into walls until the energy runs out.
	main._start_dreams(true)
	game = await _next_game(main)
	await _play_route(game)
	_report("survival 1", game._board.won and game._win.visible and game._run.depth == 1)
	game._on_win_right()
	game = await _next_game(main)
	var full: int = game._run.energy
	for k in 400:
		if game._over:
			break
		if game._board.lost:
			await _wait(0.2)  # a fall: wait for the level to restart
			continue
		game._on_swipe([Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT][k % 4])
		await process_frame
	await _wait(0.8)
	_report("out of energy", full > 0 and game._over and game._win.visible and save.best_survival == 1)
	game._on_win_left()
	await _wait(0.6)

	main._show_collection()
	await _wait(0.6)
	_report("collection", main._screen.get("_cards") != null and main._screen._cards.size() == Skins.ALL.size())
	main._show_levels()
	await _wait(0.6)
	main._show_menu()
	await _wait(0.6)
	main._screen._on_settings()
	await _wait(0.3)

	if real_save.is_empty():
		DirAccess.remove_absolute(save.PATH)
	else:
		FileAccess.open(save.PATH, FileAccess.WRITE).store_buffer(real_save)
	print("\n%s" % ("SMOKE TEST PASSED" if _failures == 0 else "%d FAILURE(S)" % _failures))
	quit(1 if _failures else 0)


func _play_route(game) -> void:
	for action in Solver.par_route(Board.from_level(game._level)):
		if Solver.is_drop(action):
			var drop := Solver.parse_drop(action)
			game._on_item_dropped(drop[0], game._view.cell_to_global(drop[1]))
		else:
			game._on_swipe(Solver.DIRS[action])
		await process_frame
	await _wait(1.0)


## Waits for the next game screen (levels may first be generated).
func _next_game(main):
	var before = main._screen
	for k in 600:
		await process_frame
		if main._screen != before and main._screen.has_method("_on_swipe") and not main._busy:
			await _wait(0.3)
			return main._screen
		if main._screen != before and not main._screen.has_method("_on_swipe"):
			before = main._screen  # the dozing eye: keep waiting
	return main._screen


func _report(what: String, ok: bool) -> void:
	print("  %-18s %s" % [what, "OK" if ok else "FAIL"])
	_failures += 0 if ok else 1


func _wait(seconds: float) -> Signal:
	return create_timer(seconds).timeout
