class_name Game
extends Control
## One level being played: input -> Board rules -> view, sound, narrator, score.
## Modes: "story" (levels.json), "daily" (today's challenge), "dream" (endless, lives),
## "survival" (endless, an energy gauge that each action drains).

signal menu_requested
signal next_requested
signal retry_requested  # dreams and survival: start a new run after losing

## Narrator lines when the level doesn't define its own (see "say" in levels.json).
const DEFAULT_SAY := {
	"painted_door": "Hi hi ! C'est juste un dessin !",
	"locked": "Fermée à clé !",
	"chalk_open": "Oh non ! Le dessin devient une vraie porte !",
	"fake_wall": "~Hé ! Tu n'as rien vu !",
	"cracked": "Hi hi ! Celui-là est solide !",
	"arrow_blocked": "Pas dans ce sens !",
	"fall": "Plouf ! On recommence !",
	"win": "Grrr... Tu as trouvé la sortie !",
}
## How Filou reacts: he laughs when you fall for a trick, sulks when you win.
const FILOU_MOODS := {
	"painted_door": "laugh", "fall": "laugh", "cracked": "laugh", "arrow_blocked": "laugh", "locked": "laugh",
	"fake_wall": "surprised", "chalk_open": "surprised", "win": "grumpy",
}
const CHEERS := ["Bravo !", "Génial !", "Super !", "Trop fort !", "Bien joué !"]
const C_HINT_TEXT := Color("1d6fd8")
const TINTS := {"white": Color(1, 1, 1, 0), "red": Color(1, 0.1, 0.15, 0.22), "blue": Color(0.15, 0.4, 1, 0.22)}
const SOUNDS := {
	"step": "step", "bump": "bump", "cracked": "cracked", "arrow_blocked": "blocked", "painted_door": "lie",
	"locked": "bump", "chalk_open": "chalk", "fake_wall": "secret", "tint": "tint", "portal": "portal",
	"fall": "fall", "win": "win",
}
const VIBRATIONS := {"bump": 12, "cracked": 12, "painted_door": 40, "locked": 12, "arrow_blocked": 12, "chalk_open": 30, "fall": 120, "win": 60}
const NARRATOR_HEIGHT := 240.0
const FAILS_BEFORE_HELP := 3

var _level: Dictionary
var _index := 0
var _mode := "story"
var _run: DreamRun
var _board: Board
var _moves := 0
var _hinted := false  # the eye showed a move: stars capped at 2
var _hint_step := 0  # how many written hints were read (kept across restarts)
var _hint_task := -1
var _hint_result := ""
var _fails := 0
var _offered_help := false
var _over := false  # dreams and survival: the run is lost
var _warned := false  # survival: Filou already said the gauge is nearly empty
var _said := {}  # event -> times its line list was used, kept across restarts
var _fall_tween: Tween
var _top := 0.0

var _theme: Dictionary
var _view := BoardView.new()
var _swipe := SwipeArea.new()
var _bar := TopBar.new()
var _narrator := Narrator.new()
var _filou := Filou.new()
var _tint := TintLayer.new()
var _win := WinPanel.new()
var _card := Label.new()


func setup(level: Dictionary, index: int, mode := "story", run: DreamRun = null) -> void:
	_level = level
	_index = index
	_mode = mode
	_run = run


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_top = _safe_top() + 16.0
	_theme = _pick_theme()
	add_child(Look.gradient_rect(_theme.bg[0], _theme.bg[1]))

	_view.dark = _level.get("dark", false)
	_view.skin = Skins.get_skin(Save.skin)
	_view.theme = _theme
	add_child(_view)

	_swipe.swiped.connect(_on_swipe)
	_swipe.can_drop = _can_drop
	_swipe.item_dropped.connect(_on_item_dropped)
	add_child(_swipe)

	_bar.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	_bar.offset_left = 20
	_bar.offset_right = -20
	_bar.offset_top = _top
	_bar.offset_bottom = _top + TopBar.HEIGHT
	_bar.menu_pressed.connect(menu_requested.emit)
	_bar.hint_pressed.connect(_on_hint)
	_bar.restart_pressed.connect(_on_restart_pressed)
	add_child(_bar)
	_bar.set_ink(_theme.ink)
	_bar.set_title(_heading())
	_bar.set_hint_visible(_run == null)  # endless runs are played without help

	_card.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card.add_theme_font_size_override("font_size", 68)
	_card.add_theme_color_override("font_color", _theme.ink)
	_card.mouse_filter = MOUSE_FILTER_IGNORE
	_card.modulate.a = 0.0
	add_child(_card)

	_win.left_pressed.connect(_on_win_left)
	_win.right_pressed.connect(_on_win_right)
	add_child(_win)

	# Filou and his speech bubble, at the bottom.
	var bottom := HBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	bottom.offset_left = 8
	bottom.offset_right = -20
	bottom.offset_top = -NARRATOR_HEIGHT
	bottom.offset_bottom = -24
	bottom.add_theme_constant_override("separation", 14)
	bottom.mouse_filter = MOUSE_FILTER_IGNORE
	_filou.size_flags_vertical = SIZE_SHRINK_END
	bottom.add_child(_filou)
	var bubble := PanelContainer.new()
	bubble.size_flags_horizontal = SIZE_EXPAND_FILL
	bubble.size_flags_vertical = SIZE_SHRINK_CENTER
	bubble.add_theme_stylebox_override("panel", Look.box(Look.CARD, 30, true, 22))
	bubble.mouse_filter = MOUSE_FILTER_IGNORE
	bubble.draw.connect(func(): bubble.draw_colored_polygon(PackedVector2Array([Vector2(2, bubble.size.y * 0.5), Vector2(-20, bubble.size.y * 0.5 + 22), Vector2(2, bubble.size.y * 0.5 + 30)]), Look.CARD))
	bottom.add_child(bubble)
	_narrator.glitch_lies = false  # Filou's nose shows the lies
	_narrator.add_theme_font_size_override("font_size", 30)
	_narrator.add_theme_color_override("font_color", Look.INK)
	_narrator.started.connect(_filou.set_lying)
	bubble.add_child(_narrator)
	add_child(bottom)
	add_child(_tint)

	resized.connect(_layout)
	_restart()
	_show_title_card()


func _exit_tree() -> void:
	if _hint_task != -1:
		WorkerThreadPool.wait_for_task_completion(_hint_task)


func _process(_delta: float) -> void:
	_filou.talking = _narrator.is_typing()
	if _hint_task != -1 and WorkerThreadPool.is_task_completed(_hint_task):
		WorkerThreadPool.wait_for_task_completion(_hint_task)
		_hint_task = -1
		_show_path_hint(_hint_result)


## Story: the theme of the act. Generated levels: the night when dark, else one from the seed.
func _pick_theme() -> Dictionary:
	if _level.get("dark", false):
		return Look.THEMES[5]
	if _mode == "story":
		var chapters := Levels.chapters()
		for i in chapters.size():
			if _index in chapters[i][1]:
				return Look.THEMES[i % Look.THEMES.size()]
	var day_themes := [0, 1, 2, 3, 4, 6]
	return Look.THEMES[day_themes[absi(str(_level.get("id", "")).hash()) % day_themes.size()]]


func _heading() -> String:
	match _mode:
		"daily":
			return "Défi du jour · %s" % _level.title
		"dream":
			return "Rêve %d · %s" % [_index + 1, _level.title]
		"survival":
			return "Survie %d · %s" % [_index + 1, _level.title]
	return "%d. %s" % [_index + 1, _level.title]


func _restart() -> void:
	if _fall_tween:
		_fall_tween.kill()
	_board = Board.from_level(_level)
	_view.board = _board
	_view.show_fakes = Save.walls_revealed
	_view.reset()
	_moves = 0
	_hinted = false
	_win.hide()
	_bar.set_items(_board.items)
	_bar.set_moves(0, Levels.goal(_level))
	_warned = false
	_show_run()
	_tint.snap(TINTS.white)
	_layout()
	if _run == null and _fails >= FAILS_BEFORE_HELP and not _offered_help:
		_offered_help = true
		_bar.pulse_hint(true)
		_tell("Besoin d'aide ? Touche l'ampoule, en haut !", true)
	else:
		_say("start")
	if _mode == "story" and _index == 0 and not Save.is_done(_level.id):
		_view.show_hint_swipe(Vector2i.RIGHT)  # first-time tutorial: which way to swipe


func _layout() -> void:
	if _board == null or size.x <= 0.0:
		return
	var top := _top + TopBar.HEIGHT + 20.0
	_view.fit(Rect2(24, top, size.x - 48, size.y - top - NARRATOR_HEIGHT - 20))


func _show_title_card() -> void:
	var number: String = {"daily": "Défi du jour", "dream": "Rêve %d" % (_index + 1), "survival": "Survie %d" % (_index + 1)}.get(_mode, str(_index + 1))
	_card.text = "%s\n%s" % [number, _level.title]
	_view.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_card, "modulate:a", 1.0, 0.25)
	t.tween_interval(0.5)
	t.tween_property(_card, "modulate:a", 0.0, 0.4)
	t.parallel().tween_property(_view, "modulate:a", 1.0, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	for action in ["ui_up", "ui_right", "ui_down", "ui_left"]:
		if event.is_action_pressed(action, true):
			_on_swipe({"ui_up": Vector2i.UP, "ui_right": Vector2i.RIGHT, "ui_down": Vector2i.DOWN, "ui_left": Vector2i.LEFT}[action])
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		menu_requested.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # Android back button
		menu_requested.emit()


# --- Playing -------------------------------------------------------------------

func _on_swipe(dir: Vector2i) -> void:
	if _board.won or _board.lost or _win.visible:
		return
	_clear_hints()
	_moves += 1
	var stairs_before := _board.stairs_signature()
	var events := _board.move(dir)
	_pay(1)
	for event in events:
		_react(event)
	if not "step" in events or "tint" in events or "portal" in events:
		_swipe.stop_hold()  # holding the finger walks on, but never into a wall or a new colour
	if _board.stairs_signature() != stairs_before:
		Sfx.play("turn", randf_range(0.9, 1.1))
	_bar.set_moves(_moves, Levels.goal(_level))


func _react(event: String) -> void:
	match event:
		"step":
			_view.step()
		"bump", "cracked", "painted_door", "locked", "arrow_blocked":
			_view.nudge(_board.facing)
			if event == "painted_door":
				Save.count("painted")
		"chalk_open":
			_view.burst(_board.pos + _board.facing, Color.WHITE, 26, 1.5)
		"fake_wall":
			_view.burst(_board.pos, BoardView.C_WALL, 20, 1.2)
		"tint":
			var color: Color = TINTS[_board.tint]
			_tint.change(color, _view.cell_to_global(_board.pos))
			_view.burst(_board.pos, Color(color, 1.0) if color.a > 0.0 else Color.WHITE, 18, 1.6)
		"portal":
			_layout()  # the new room may be a completely different size
			_view.burst(_board.pos, BoardView.C_HUT, 22, 1.6)
		"fall":
			_view.fall()
			_fails += 1
			Save.count("falls")
			var alive := _lose_life()
			_fall_tween = create_tween()
			_fall_tween.tween_interval(1.1)
			_fall_tween.tween_callback(_restart if alive else _game_over)
		"win":
			_view.win()
			_finish()
	if SOUNDS.has(event):
		Sfx.play(SOUNDS[event])
	if VIBRATIONS.has(event):
		Sfx.vibrate(VIBRATIONS[event])
	if FILOU_MOODS.has(event):
		_filou.set_mood(FILOU_MOODS[event])
		if FILOU_MOODS[event] == "laugh":
			Sfx.play("giggle", randf_range(0.95, 1.1), -4.0)
	_say(event)


func _finish() -> void:
	var stars := Levels.stars(_level, _moves, _hinted)
	var info := "%d pas · objectif %d" % [_moves, Levels.goal(_level)]
	var cheer: String = CHEERS[randi() % CHEERS.size()]
	var notes := []
	var t := create_tween()
	t.tween_interval(0.7)
	match _mode:
		"story":
			var record: bool = _moves < _level.par
			Save.record(_level, _moves, stars)
			if _level.get("reveals_walls", false):
				Save.reveal_walls()
			if record:
				Sfx.play("secret")
				notes.append("Incroyable ! Tu as trouvé un passage secret !")
			elif _hinted:
				notes.append("L'ampoule t'a aidé : 2 étoiles maximum.")
			elif stars < 3:
				notes.append("Fais l'objectif pour avoir 3 étoiles !")
			var last := _index + 1 >= Levels.all().size()
			t.tween_callback(_win.open.bind(cheer, stars, info, notes, "Rejouer", "Fin" if last else "Suivant"))
		"daily":
			Save.record_daily(stars)
			notes.append("Série : %d jour%s d'affilée. Reviens demain !" % [Save.streak, "s" if Save.streak > 1 else ""])
			if stars < 3:
				notes.append("Rejoue pour avoir 3 étoiles !" if not _hinted else "L'ampoule t'a aidé : 2 étoiles maximum.")
			t.tween_callback(_win.open.bind("Défi réussi !", stars, info, notes, "Rejouer", "Menu"))
		"dream":
			var perfect: bool = _moves <= Levels.goal(_level)
			var regained := perfect and _run.lives < DreamRun.LIVES
			_run.cleared(perfect)
			_bar.set_lives(_run.lives, DreamRun.LIVES)
			if regained:
				notes.append("Parfait : un cœur en plus !")
			elif not perfect:
				notes.append("Fais l'objectif pour gagner un cœur.")
			t.tween_callback(_win.open.bind(cheer, stars, info, notes, "Menu", "Rêve suivant"))
		"survival":
			_run.cleared(false)
			notes.append("Énergie restante : %d" % _run.energy)
			if _run.energy > DreamRun.CARRY_MAX:
				notes.append("Tu en gardes %d pour la suite." % DreamRun.CARRY_MAX)
			t.tween_callback(_win.open.bind(cheer, stars, info, notes, "Menu", "Niveau suivant"))


## Dreams: a fall or a restart costs a life. Survival: a fall costs energy.
## Returns false when the run is lost.
func _lose_life() -> bool:
	if _run == null:
		return true
	var alive := _run.spend(DreamRun.FALL_COST) if _run.survival else _run.lose_life()
	_show_run()
	return alive


## Survival: every action drains the gauge. Running dry before the door ends the run.
func _pay(amount: int) -> void:
	if _run == null or not _run.survival:
		return
	var alive := _run.spend(amount)
	_show_run()
	if _board.won or _board.lost:  # a fall is handled by _lose_life
		return
	if not alive:
		_swipe.stop_hold()
		_board.lost = true  # no more moves
		_fall_tween = create_tween()
		_fall_tween.tween_interval(0.5)
		_fall_tween.tween_callback(_game_over)
	elif _run.energy <= 5 and not _warned:
		_warned = true
		_filou.set_mood("laugh")
		Sfx.play("giggle")
		_tell("Hi hi ! Tu n'as presque plus d'énergie !")


func _show_run() -> void:
	if _run == null:
		return
	if _run.survival:
		_bar.set_energy(_run.energy, _run.energy_full)
	else:
		_bar.set_lives(_run.lives, DreamRun.LIVES)


func _game_over() -> void:
	_over = true
	var plural := "s" if _run.depth > 1 else ""
	var record: bool
	var best: int
	if _run.survival:
		record = Save.record_survival(_run.depth)
		best = Save.best_survival
	else:
		record = Save.record_dreams(_run.depth)
		best = Save.best_dreams
	var crossed := ("%d niveau%s traversé%s" % [_run.depth, "x" if _run.depth > 1 else "", plural]) if _run.survival else ("%d rêve%s traversé%s" % [_run.depth, plural, plural])
	var note := "Nouveau record !" if record else "Record : %d" % best
	Sfx.play("secret" if record else "fall")
	_filou.set_mood("laugh", 3.0)
	Sfx.play("giggle")
	_narrator.say("Hi hi hi ! Tu es tout épuisé !" if _run.survival else "Hi hi hi ! Tu t'es réveillé !")
	_win.open("Plus d'énergie !" if _run.survival else "Fin du rêve !", -1, crossed, [note], "Menu", "Recommencer")


func _on_restart_pressed() -> void:
	if _over or (_win.visible and _run != null):
		return
	if not _board.won:
		_fails += 1
	Sfx.play("ui")
	if _mode == "dream" and _moves > 0 and not _board.won and not _board.lost and not _lose_life():
		_game_over()
		return
	_restart()


func _on_win_left() -> void:
	Sfx.play("ui")
	if _run != null:
		menu_requested.emit()
	else:
		_restart()


func _on_win_right() -> void:
	Sfx.play("ui")
	if _over:
		retry_requested.emit()
	elif _mode == "daily":
		menu_requested.emit()
	else:
		next_requested.emit()


func _can_drop(item: String, global_point: Vector2) -> bool:
	return not _board.won and not _board.lost and _board.can_drop(item, _view.cell_at(global_point))


func _on_item_dropped(item: String, global_point: Vector2) -> void:
	var cell := _view.cell_at(global_point)
	if not _board.drop(item, cell):
		return
	_clear_hints()
	_moves += 1
	_pay(1)
	_bar.set_moves(_moves, Levels.goal(_level))
	_bar.set_items(_board.items)
	_view.burst(cell, BoardView.C_PLANK if item == "plank" else BoardView.C_DOOR, 20, 1.2)
	Sfx.play("unlock" if item == "key" else "drop")
	Sfx.vibrate(25)
	_say("drop")


# --- Help: written hints first, then the eye shows the next move -----------

func _on_hint() -> void:
	_bar.pulse_hint(false)
	if _board.won or _board.lost or _hint_task != -1:
		return
	Sfx.play("hint")
	var hints: Array = _level.get("hints", [])
	if _hint_step < hints.size():
		_tell("Indice : " + hints[_hint_step], true)
		_hint_step += 1
		return
	_hinted = true
	var snapshot := _board.clone()
	var forbid := [] if Save.walls_revealed else ["fake_wall"]
	_hint_task = WorkerThreadPool.add_task(func(): _hint_result = Solver.next_action(snapshot, forbid))
	_tell("L'ampoule cherche le chemin...", true)


func _show_path_hint(action: String) -> void:
	if _board.won or _board.lost:
		return
	if action == "":
		_tell("Oups, c'est bloqué. Recommence !", true)
		return
	if Solver.is_drop(action):
		var drop := Solver.parse_drop(action)
		_view.show_hint_cell(drop[1])
		_bar.highlight_item(drop[0])
		_tell("Glisse cet objet sur la case rose !", true)
	else:
		_view.show_hint_swipe(Solver.DIRS[action])
		_tell("Glisse dans le sens de la flèche. Touche encore l'ampoule pour la suite !", true)


func _clear_hints() -> void:
	_view.clear_hint()
	_bar.clear_highlights()


## A level line can be a string or a list (shown in order, the last one repeats).
func _say(event: String) -> void:
	var line: Variant = _level.get("say", {}).get(event, DEFAULT_SAY.get(event, ""))
	if line is Array:
		var n: int = _said.get(event, 0)
		_said[event] = n + 1
		line = line[mini(n, line.size() - 1)]
	if line != "":
		_tell(line)


## Filou talks; help lines are blue (they come from the bulb and never lie), and he sulks.
func _tell(line: String, help := false) -> void:
	_narrator.add_theme_color_override("font_color", C_HINT_TEXT if help else Look.INK)
	_narrator.say(line)
	if help:
		_filou.set_mood("grumpy", 1.2)


## Keeps the top bar below the notch / status bar on phones.
func _safe_top() -> float:
	var screen := DisplayServer.screen_get_size()
	if screen.y <= 0:
		return 0.0
	return DisplayServer.get_display_safe_area().position.y * get_viewport_rect().size.y / screen.y
