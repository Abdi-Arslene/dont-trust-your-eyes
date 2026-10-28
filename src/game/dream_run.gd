class_name DreamRun
extends RefCounted
## One endless run of generated levels that grow harder. Two sets of rules:
## - dreams: three lives. A fall or a restart costs one; finishing within the goal gives one back.
## - survival: an energy gauge carried from level to level. Every action costs 1, a fall costs
##   FALL_COST. Each new level brings what its perfect route needs plus a margin that shrinks
##   with depth, so wasted moves pile up. Empty gauge: the run is over.
## The next level is generated on a thread while the current one is played.

const LIVES := 3
const FALL_COST := 3
const CARRY_MAX := 15  # leftover energy carried into the next level, at most
const START_BONUS := 6  # a softer first level

var survival := false
var depth := 0  # levels crossed so far (= the depth of the one being played)
var lives := LIVES
var energy := 0
var energy_full := 1  # the gauge when the current level started

var _learned: Dictionary
var _seed := randi()
var _task := -1
var _next := {}


func _init(learned: Dictionary, survival_rules := false) -> void:
	_learned = learned
	survival = survival_rules
	_prepare(0)


func is_ready() -> bool:
	return _task == -1 or WorkerThreadPool.is_task_completed(_task)


## The level to play now (waits for the generator if needed). The next one starts generating.
## Survival: the gauge is topped up for it.
func take() -> Dictionary:
	_wait()
	var level := _next
	_prepare(depth + 1)
	if survival:
		energy = mini(energy, CARRY_MAX) + level.par + margin(depth) + (START_BONUS if depth == 0 else 0)
		energy_full = energy
	return level


## Spare moves granted on top of the perfect route: 6 at first, down to 1.
static func margin(at_depth: int) -> int:
	return maxi(1, 6 - at_depth / 3)


func cleared(perfect: bool) -> void:
	depth += 1
	if perfect and not survival:
		lives = mini(lives + 1, LIVES)


## Dreams: returns false when that was the last life.
func lose_life() -> bool:
	lives -= 1
	return lives > 0


## Survival: pays for actions. Returns false once the gauge is empty.
func spend(amount := 1) -> bool:
	energy = maxi(0, energy - amount)
	return energy > 0


## Call when leaving the run: never leave a generator thread behind.
func stop() -> void:
	_wait()


func _prepare(for_depth: int) -> void:
	_wait()
	var learned := _learned
	var seed_value := _seed + for_depth * 7919
	_task = WorkerThreadPool.add_task(func(): _next = Generator.make(seed_value, for_depth, learned))


func _wait() -> void:
	if _task != -1:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
