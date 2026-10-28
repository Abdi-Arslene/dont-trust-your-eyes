extends Node
## Autoload "Save": progress, collection and settings on disk.

signal skin_unlocked(skin: Dictionary)

const PATH := "user://save.cfg"

var results := {}  # level id -> {"moves": fewest moves, "stars": best stars}
var secrets := {}  # level id -> true once finished under par (only fake walls allow it)
var walls_revealed := false
var daily := {}  # today's challenge: {"date", "level", "stars"} (generated once per day)
var last_daily := ""  # date of the last finished daily challenge
var streak := 0  # daily challenges finished on consecutive days, up to last_daily
var best_streak := 0
var best_dreams := 0  # most dreams crossed in one run
var best_survival := 0  # most levels crossed in one survival run
var falls := 0
var painted := 0  # times a painted door was believed
var skin := "classic"
var skins_seen := {}  # skin id -> true once announced
var sound := true
var music := true
var haptics := true

const _KEYS := {
	"progress": ["results", "secrets", "walls_revealed"],
	"modes": ["daily", "last_daily", "streak", "best_streak", "best_dreams", "best_survival"],
	"collection": ["falls", "painted", "skin", "skins_seen"],
	"settings": ["sound", "music", "haptics"],
}


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for section in _KEYS:
			for key in _KEYS[section]:
				set(key, cfg.get_value(section, key, get(key)))
	skins_seen["classic"] = true  # the starting eye is never "new"


func is_done(id: String) -> bool:
	return results.has(id)


func is_unlocked(index: int) -> bool:
	return index == 0 or is_done(Levels.all()[index - 1].id)


func first_unfinished() -> int:
	var levels := Levels.all()
	for i in levels.size():
		if not is_done(levels[i].id):
			return i
	return 0


func stars_of(id: String) -> int:
	return results.get(id, {}).get("stars", 0)


func total_stars() -> int:
	var total := 0
	for r in results.values():
		total += r.stars
	return total


func record(level: Dictionary, moves: int, stars: int) -> void:
	var previous: Dictionary = results.get(level.id, {})
	results[level.id] = {"moves": mini(moves, previous.get("moves", moves)), "stars": maxi(stars, previous.get("stars", 0))}
	if moves < level.par:
		secrets[level.id] = true
	_changed()


func reveal_walls() -> void:
	walls_revealed = true
	_changed()


# --- Daily challenge and dreams ---------------------------------------------

static func today() -> String:
	return Time.get_date_string_from_system()


static func day_before(date: String) -> String:
	return Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(date) - 86400)


## Today's challenge if it was already generated, else {}.
func daily_level() -> Dictionary:
	return daily.level if daily.get("date", "") == today() else {}


func set_daily_level(level: Dictionary) -> void:
	daily = {"date": today(), "level": level, "stars": 0}
	_write()


func daily_done() -> bool:
	return last_daily == today()


## The streak still alive today (it breaks after a day without challenge).
func current_streak() -> int:
	return streak if last_daily == today() or last_daily == day_before(today()) else 0


func record_daily(stars: int) -> void:
	daily.stars = maxi(stars, daily.get("stars", 0))
	if last_daily != today():
		streak = current_streak() + 1
		last_daily = today()
		best_streak = maxi(best_streak, streak)
	_changed()


## Returns true for a new record.
func record_dreams(crossed: int) -> bool:
	if crossed <= best_dreams:
		return false
	best_dreams = crossed
	_changed()
	return true


## Returns true for a new record.
func record_survival(crossed: int) -> bool:
	if crossed <= best_survival:
		return false
	best_survival = crossed
	_changed()
	return true


# --- Collection --------------------------------------------------------------

## What the collection goals read (see Skins.ALL).
func stats() -> Dictionary:
	var levels := Levels.all()
	return {
		"stars": total_stars(),
		"all_stars": int(total_stars() >= levels.size() * 3),
		"story": int(is_done(levels[-1].id)),
		"secrets": secrets.size(),
		"streak": best_streak,
		"dreams": best_dreams,
		"falls": falls,
		"painted": painted,
	}


## Counts a fall or a painted door believed.
func count(stat: String) -> void:
	set(stat, get(stat) + 1)
	_changed()


func set_skin(id: String) -> void:
	skin = id
	_write()


## Announces (once) every eye whose goal is now reached.
func check_unlocks() -> void:
	var s := stats()
	for entry in Skins.ALL:
		if not skins_seen.has(entry.id) and Skins.is_unlocked(entry, s):
			skins_seen[entry.id] = true
			_write()
			skin_unlocked.emit(entry)


func set_setting(setting: String, value: bool) -> void:
	set(setting, value)
	_write()


func _changed() -> void:
	_write()
	check_unlocks()


func _write() -> void:
	var cfg := ConfigFile.new()
	for section in _KEYS:
		for key in _KEYS[section]:
			cfg.set_value(section, key, get(key))
	cfg.save(PATH)
