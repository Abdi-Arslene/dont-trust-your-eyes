class_name Generator
extends RefCounted
## Random levels for the daily challenge and the endless dreams, in the same
## format as levels.json. The Solver proves each one can be finished and gives
## its par. A level only uses what the player already met in the story.

const TITLES := ["Couloir", "Écho", "Mirage", "Insomnie", "Vertige", "Brume", "Déjà-vu", "Somnambule", "Pénombre", "Paupière", "Reflet", "Labyrinthe", "Sablier", "Marée", "Fièvre", "Murmure"]
const START_LINES := ["~Celui-ci est super facile.", "Trouve la porte ! Hi hi !", "~Rien ne bouge, ici.", "Tu dors encore ?", "~Toutes mes portes sont des vraies.", "Un nouveau rêve, un nouveau piège !", "~Je n'ai rien caché ici.", "Bonne chance... hi hi !"]
const HINTS := {
	"paint": "La couleur de l'écran change le sens de tes glissements.",
	"stairs": "Un escalier que tu regardes ne tourne pas.",
	"plank": "La planche, en haut, comble un trou.",
	"key": "La clé se glisse sur la porte grise.",
	"chalk": "Une porte à la craie s'ouvre quand tu la touches.",
	"decoy": "Attention : certaines portes sont des dessins !",
}
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const MAX_ATTEMPTS := 12
const MAX_STATES := 5000


## A level built from `seed_value`. `depth` (0, 1, 2...) sets its size and difficulty.
## `learned` is Levels.learned(): the cells and items the player already knows.
static func make(seed_value: int, depth: int, learned: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var min_par := mini(5 + depth, 16)
	var best := {}
	var best_score := -1
	for attempt in MAX_ATTEMPTS + 1:
		# the last attempt is a plain maze: always solvable, never empty-handed
		var plain := attempt == MAX_ATTEMPTS
		if plain and not best.is_empty():
			break
		var built := _build(rng, depth, {} if plain else learned)
		var level: Dictionary = built[0]
		var wanted: int = built[1]
		var route = Solver.solve(Board.from_level(level), [], MAX_STATES)
		if route == null:
			continue
		level.par = route.size()
		var used := mini(_mechanics_used(level, route), wanted)
		var score := mini(route.size(), min_par) + 10 * used
		if score > best_score:
			best = level
			best_score = score
		if route.size() >= min_par and used == wanted:
			break
	best.id = "gen-%d-%d" % [seed_value, depth]
	return best


## [level, how many bypassable mechanics (paint, stairs) the route should use]
static func _build(rng: RandomNumberGenerator, depth: int, learned: Dictionary) -> Array:
	var cw := 2 + int(depth >= 2) + int(depth >= 6 and rng.randf() < 0.6)
	var ch := 3 + int(depth >= 4) + int(depth >= 9 and rng.randf() < 0.6)
	var w := cw * 2 + 1
	var h := ch * 2 + 1
	var grid := []
	for y in h:
		var row := []
		row.resize(w)
		row.fill(Board.WALL)
		grid.append(row)

	# A maze between odd cells (randomized depth-first), then a few loops.
	var first := Vector2i(1 + 2 * rng.randi_range(0, cw - 1), 1 + 2 * rng.randi_range(0, ch - 1))
	grid[first.y][first.x] = Board.FLOOR
	var stack: Array[Vector2i] = [first]
	while not stack.is_empty():
		var p: Vector2i = stack[-1]
		var options: Array[Vector2i] = []
		for d in DIRS:
			var q := p + d * 2
			if q.x > 0 and q.y > 0 and q.x < w - 1 and q.y < h - 1 and grid[q.y][q.x] == Board.WALL:
				options.append(d)
		if options.is_empty():
			stack.pop_back()
			continue
		var d := options[rng.randi() % options.size()]
		grid[p.y + d.y][p.x + d.x] = Board.FLOOR
		grid[p.y + d.y * 2][p.x + d.x * 2] = Board.FLOOR
		stack.append(p + d * 2)
	var loops := 1 + cw * ch / 4 + depth / 4
	for k in loops * 6:
		if loops <= 0:
			break
		var p := Vector2i(rng.randi_range(1, w - 2), rng.randi_range(1, h - 2))
		if grid[p.y][p.x] != Board.WALL:
			continue
		var across_x: bool = grid[p.y][p.x - 1] == Board.FLOOR and grid[p.y][p.x + 1] == Board.FLOOR
		var across_y: bool = grid[p.y - 1][p.x] == Board.FLOOR and grid[p.y + 1][p.x] == Board.FLOOR
		if across_x or across_y:
			grid[p.y][p.x] = Board.FLOOR
			loops -= 1

	# Start anywhere, exit through the outer wall, as far as possible from the start.
	var floors: Array[Vector2i] = []
	for y in h:
		for x in w:
			if grid[y][x] == Board.FLOOR:
				floors.append(Vector2i(x, y))
	var start := floors[rng.randi() % floors.size()]
	var came_from := _bfs(grid, start)
	var exits := []  # [distance, exit cell, cell just inside]
	for y in h:
		for x in w:
			var on_border := x == 0 or y == 0 or x == w - 1 or y == h - 1
			var corner := (x == 0 or x == w - 1) and (y == 0 or y == h - 1)
			if not on_border or corner:
				continue
			var inside := Vector2i(clampi(x, 1, w - 2), clampi(y, 1, h - 2))
			if came_from.has(inside):
				exits.append([_path(came_from, inside).size(), Vector2i(x, y), inside])
	exits.sort_custom(func(a, b): return a[0] > b[0])
	var exit: Array = exits[rng.randi() % mini(3, exits.size())]
	var path := _path(came_from, exit[2])  # start ... cell before the exit

	# Mechanics the player knows, placed on the obvious path so they matter.
	var pool := []
	if learned.has("r") or learned.has("b"):
		pool.append("paint")
	if learned.has("^"):
		pool.append("stairs")
	if learned.has("_"):
		pool.append("void")
	if learned.has("c") or learned.has("key"):
		pool.append("exit")
	_shuffle(pool, rng)
	var chosen := pool.slice(0, mini(1 + depth / 3, 4))
	var items: Array[String] = []
	var hints := []
	var wanted := 0
	var used_cells := {start: true}
	var exit_cell: Vector2i = exit[1]
	grid[exit_cell.y][exit_cell.x] = Board.DOOR

	for feature in chosen:
		match feature:
			"paint":
				var colors := []
				for c in ["r", "b"]:
					if learned.has(c):
						colors.append(c)
				var cell := _free_cell(path, 1, path.size() / 2, used_cells, rng)
				if cell.x >= 0:
					grid[cell.y][cell.x] = colors[rng.randi() % colors.size()]
					wanted += 1
					hints.append(HINTS.paint)
					if learned.has("w") and rng.randf() < 0.5:
						var white := _free_cell(path, path.size() / 2 + 1, path.size() - 1, used_cells, rng)
						if white.x >= 0:
							grid[white.y][white.x] = "w"
			"stairs":
				for k in 1 + int(depth >= 5):
					var cell := _free_cell(path, 2, path.size() - 1, used_cells, rng)
					if cell.x >= 0:
						grid[cell.y][cell.x] = Board.ARROWS.keys()[rng.randi() % 4]
				wanted += 1
				hints.append(HINTS.stairs)
			"void":
				for k in 1 + depth / 4:
					var cell: Vector2i = floors[rng.randi() % floors.size()]
					if not used_cells.has(cell) and not cell in path:
						used_cells[cell] = true
						grid[cell.y][cell.x] = Board.VOID
				if learned.has("plank") and rng.randf() < 0.6:
					var cell := _free_cell(path, 2, path.size() - 1, used_cells, rng)
					if cell.x >= 0:
						grid[cell.y][cell.x] = Board.VOID
						items.append("plank")
						hints.append(HINTS.plank)
			"exit":
				var kinds := []
				if learned.has("c"):
					kinds.append("chalk")
				if learned.has("key"):
					kinds.append("key")
				var kind: String = kinds[rng.randi() % kinds.size()]
				grid[exit_cell.y][exit_cell.x] = Board.CHALK_DOOR if kind == "chalk" else Board.LOCKED_DOOR
				if kind == "key":
					items.append("key")
				hints.append(HINTS[kind])

	if learned.has("d"):  # painted doors: they look exactly like the way out
		for k in 1 + int(rng.randf() < 0.4):
			var e: Array = exits[rng.randi() % exits.size()]
			var cell: Vector2i = e[1]
			if grid[cell.y][cell.x] == Board.WALL:
				grid[cell.y][cell.x] = Board.PAINTED_DOOR
		hints.append(HINTS.decoy)
	hints.append("Prends ton temps et regarde bien avant de glisser.")

	var lines := []
	for y in h:
		var line := "".join(PackedStringArray(grid[y]))
		if y == start.y:
			line = line.substr(0, start.x) + Board.START + line.substr(start.x + 1)
		lines.append(line)
	var level := {
		"title": TITLES[rng.randi() % TITLES.size()],
		"par": 0,
		"items": items,
		"hints": hints,
		"say": {"start": START_LINES[rng.randi() % START_LINES.size()]},
		"dark": learned.has("dark") and depth >= 4 and rng.randf() < 0.3,
		"rooms": {"main": lines},
	}
	return [level, wanted]


## Paint stepped on, stairs climbed: how many bypassable mechanics the route really uses.
static func _mechanics_used(level: Dictionary, route: Array) -> int:
	var b := Board.from_level(level)
	var tinted := false
	var climbed := false
	for action in route:
		if Solver.DIRS.has(action):
			var on_stairs := Board.ARROWS.has(b.cell(b.pos + b.steer(Solver.DIRS[action])))
			var events := b.move(Solver.DIRS[action])
			climbed = climbed or (on_stairs and "step" in events)
			tinted = tinted or "tint" in events
		else:
			Solver.apply(b, action)
	return int(tinted) + int(climbed)


## Breadth-first over plain floor: cell -> the cell it was reached from.
static func _bfs(grid: Array, start: Vector2i) -> Dictionary:
	var came_from := {start: start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		for d in DIRS:
			var q := p + d
			if q.y >= 0 and q.y < grid.size() and q.x >= 0 and q.x < grid[q.y].size() and grid[q.y][q.x] == Board.FLOOR and not came_from.has(q):
				came_from[q] = p
				queue.append(q)
	return came_from


static func _path(came_from: Dictionary, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [to]
	while came_from[path[0]] != path[0]:
		path.push_front(came_from[path[0]])
	return path


## A random path cell between indices `from` and `to`, not used yet; (-1, -1) if none.
static func _free_cell(path: Array[Vector2i], from: int, to: int, used: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var options := []
	for i in range(maxi(from, 1), mini(to, path.size() - 1) + 1):
		if not used.has(path[i]):
			options.append(path[i])
	if options.is_empty():
		return Vector2i(-1, -1)
	var cell: Vector2i = options[rng.randi() % options.size()]
	used[cell] = true
	return cell


## Fisher-Yates with our own generator, so a seed always gives the same level.
static func _shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
