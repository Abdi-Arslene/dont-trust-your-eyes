class_name Levels
extends RefCounted
## The level list (levels/levels.json) and the scoring rules.
## Progress lives in the Save autoload, not here, so tests can use this class.

const PATH := "res://levels/levels.json"

static var _cache: Array = []


static func all() -> Array:
	if _cache.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		assert(data is Array, "levels.json must be an array of levels")
		_cache = data
	return _cache


## The target shown to the player: a little slack over the perfect route (par),
## kids rarely find the very shortest path.
static func goal(level: Dictionary) -> int:
	var par: int = level.par
	return par + maxi(2, ceili(par * 0.2))


## 3 stars within the goal, 2 up to twice the par, 1 otherwise.
## Being shown the path by the bulb caps it at 2.
static func stars(level: Dictionary, moves: int, hinted: bool) -> int:
	var s := 3 if moves <= goal(level) else (2 if moves <= level.par * 2 else 1)
	return mini(s, 2) if hinted else s


## [[chapter title, [level indices]], ...] in play order.
static func chapters() -> Array:
	var result := []
	for i in all().size():
		var title: String = all()[i].chapter
		if result.is_empty() or result[-1][0] != title:
			result.append([title, []])
		result[-1][1].append(i)
	return result


static func secret_count() -> int:
	return all().filter(func(l): return l.get("secret", false)).size()


## Every cell, item and "dark" met in the finished levels: what generated levels may use.
## Stairs are filed under "^" whatever their direction.
static func learned(done_ids: Array) -> Dictionary:
	var known := {}
	for level in all():
		if not level.id in done_ids:
			continue
		for room in level.rooms.values():
			for line in room:
				for ch in line:
					known["^" if Board.ARROWS.has(ch) else ch] = true
		for item in level.get("items", []):
			known[item] = true
		if level.get("dark", false):
			known["dark"] = true
	return known
