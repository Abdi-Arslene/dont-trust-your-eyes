extends Control
## App flow between screens, with fades. Owns the theme, the background,
## the endless run in progress and the "new eye" banner.

const DAILY_DEPTH := 5  # how hard the daily challenge is, on the dream scale

var _screen: Control
var _fade := ColorRect.new()
var _toast := Toast.new()
var _busy := false
var _run: DreamRun
var _daily_task := -1
var _daily_level := {}


func _ready() -> void:
	theme = _make_theme()
	add_child(_make_background())
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade.color = Color("2b1d5c")
	_fade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	layer.add_child(_fade)
	layer.add_child(_toast)
	Save.skin_unlocked.connect(_toast.show_skin)
	_show_menu()
	Save.check_unlocks.call_deferred()  # eyes earned before this version existed


func _exit_tree() -> void:
	_end_dreams()
	if _daily_task != -1:
		WorkerThreadPool.wait_for_task_completion(_daily_task)


func _show_menu() -> void:
	var menu := Menu.new()
	menu.play_pressed.connect(func(): _play(Save.first_unfinished()))
	menu.daily_pressed.connect(_start_daily)
	menu.dreams_pressed.connect(_start_dreams.bind(false))
	menu.survival_pressed.connect(_start_dreams.bind(true))
	menu.levels_pressed.connect(_show_levels)
	menu.collection_pressed.connect(_show_collection)
	_swap(menu)


func _show_levels() -> void:
	var select := LevelSelect.new()
	select.level_chosen.connect(_play)
	select.back_pressed.connect(_show_menu)
	_swap(select)


func _show_collection() -> void:
	var collection := Collection.new()
	collection.back_pressed.connect(_show_menu)
	_swap(collection)


func _play(index: int) -> void:
	var game := Game.new()
	game.setup(Levels.all()[index], index)
	game.menu_requested.connect(_show_levels)
	game.next_requested.connect(_after_level.bind(index))
	_swap(game)


func _after_level(index: int) -> void:
	if index + 1 < Levels.all().size():
		_play(index + 1)
	else:
		var ending := Ending.new()
		ending.done.connect(_show_menu)
		_swap(ending)


# --- Daily challenge: generated once a day, then kept in the save -----------

func _start_daily() -> void:
	if not Save.daily_level().is_empty():
		_play_daily()
		return
	if _daily_task == -1:
		var learned := Levels.learned(Save.results.keys())
		var seed_value := Save.today().hash()
		_daily_task = WorkerThreadPool.add_task(func(): _daily_level = Generator.make(seed_value, DAILY_DEPTH, learned))
	_wait_for(func(): return WorkerThreadPool.is_task_completed(_daily_task), _on_daily_generated)


func _on_daily_generated() -> void:
	WorkerThreadPool.wait_for_task_completion(_daily_task)
	_daily_task = -1
	Save.set_daily_level(_daily_level)
	_play_daily()


func _play_daily() -> void:
	var game := Game.new()
	game.setup(Save.daily_level(), 0, "daily")
	game.menu_requested.connect(_show_menu)
	_swap(game)


# --- Endless runs: dreams (lives) and survival (energy) ---------------------

func _start_dreams(survival := false) -> void:
	_end_dreams()
	_run = DreamRun.new(Levels.learned(Save.results.keys()), survival)
	_wait_for(_run.is_ready, _play_dream)


func _play_dream() -> void:
	if _run == null:
		return
	var game := Game.new()
	game.setup(_run.take(), _run.depth, "survival" if _run.survival else "dream", _run)
	game.menu_requested.connect(_leave_dreams)
	game.next_requested.connect(func(): _wait_for(_run.is_ready, _play_dream))
	game.retry_requested.connect(_start_dreams.bind(_run.survival))
	_swap(game)


func _leave_dreams() -> void:
	if _run and _run.survival:
		Save.record_survival(_run.depth)
	elif _run:
		Save.record_dreams(_run.depth)
	_end_dreams()
	_show_menu()


func _end_dreams() -> void:
	if _run:
		_run.stop()
		_run = null


## Plays `then` now if `check` already says ready, else after a dozing eye.
func _wait_for(check: Callable, then: Callable) -> void:
	if check.call():
		then.call()
		return
	var dreaming := Dreaming.new()
	dreaming.check = check
	dreaming.done.connect(then)
	_swap(dreaming)


## Fade out, replace the screen, fade in. Input is blocked meanwhile.
func _swap(screen: Control) -> void:
	if _busy:
		screen.queue_free()
		return
	_busy = true
	_fade.mouse_filter = MOUSE_FILTER_STOP
	var t := create_tween()
	if _screen:
		t.tween_property(_fade, "color:a", 1.0, 0.15)
	t.tween_callback(_replace.bind(screen))
	t.tween_property(_fade, "color:a", 0.0, 0.25)
	t.tween_callback(_end_swap)


func _replace(screen: Control) -> void:
	if _screen:
		_screen.queue_free()
	_screen = screen
	add_child(screen)


func _end_swap() -> void:
	_busy = false
	_fade.mouse_filter = MOUSE_FILTER_IGNORE


static func _make_background() -> Control:
	var bg := Look.gradient_rect(Look.SKY[0], Look.SKY[1])
	bg.add_child(FloatingStars.new())
	return bg


static func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = Look.font()
	t.default_font_size = 34
	t.set_color("font_color", "Label", Color.WHITE)

	var styles := {
		"normal": Look.box(Look.CARD, 26),
		"hover": Look.box(Color("f3f0ff"), 26),
		"pressed": Look.box(Look.GOLD, 26),
		"disabled": Look.box(Color(1, 1, 1, 0.35), 26, false),
	}
	for state in styles:
		t.set_stylebox(state, "Button", styles[state])
	t.set_stylebox("hover_pressed", "Button", styles.pressed)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(state, "Button", Look.INK)
	t.set_color("font_disabled_color", "Button", Color(Look.INK, 0.4))
	return t


## Soft stars and bubbles drifting up behind the menus.
class FloatingStars:
	extends Control

	var _things := []
	var _time := 0.0

	func _ready() -> void:
		set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE
		for i in 18:
			_things.append({"x": randf(), "y": randf(), "speed": randf_range(0.01, 0.035), "size": randf_range(6.0, 18.0), "star": i % 3 == 0, "phase": randf() * TAU})

	func _process(delta: float) -> void:
		_time += delta
		for thing in _things:
			thing.y -= thing.speed * delta
			if thing.y < -0.05:
				thing.y = 1.05
				thing.x = randf()
		queue_redraw()

	func _draw() -> void:
		for thing in _things:
			var p := Vector2((thing.x + sin(_time * 0.5 + thing.phase) * 0.02) * size.x, thing.y * size.y)
			if thing.star:
				Skins.star(self, p, thing.size, Color(1, 1, 1, 0.35))
			else:
				draw_circle(p, thing.size * 0.6, Color(1, 1, 1, 0.14), true, -1.0, true)
