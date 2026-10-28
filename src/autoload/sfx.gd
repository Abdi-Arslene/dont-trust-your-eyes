extends Node
## Autoload "Sfx": every sound and the ambient music are synthesized at
## startup (no audio files), plus short phone vibrations.

const RATE := 22050
const MUSIC_RATE := 11025

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music := AudioStreamPlayer.new()
var _music_task := -1
var _music_stream: AudioStreamWAV


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music.volume_db = -14.0
	_music.finished.connect(_music.play)  # loop by replaying: WAV loop points crashed the Android mixer
	add_child(_music)
	_build_sounds()
	_music_task = WorkerThreadPool.add_task(func(): _music_stream = _render_music())


func _process(_delta: float) -> void:
	if _music_task != -1 and WorkerThreadPool.is_task_completed(_music_task):
		WorkerThreadPool.wait_for_task_completion(_music_task)
		_music_task = -1
		_music.stream = _music_stream
		update_music()


func _exit_tree() -> void:
	if _music_task != -1:
		WorkerThreadPool.wait_for_task_completion(_music_task)


func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not Save.sound or not _streams.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[sound]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


func vibrate(ms: int) -> void:
	if Save.haptics and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func update_music() -> void:
	if _music.stream == null:
		return
	if Save.music and not _music.playing:
		_music.play()
	elif not Save.music:
		_music.stop()


func _build_sounds() -> void:
	var s := {}
	s.step = _mix([[0, 0.07, 240, 150, 45, 0.35, "sine", 0.12]])
	s.bump = _mix([[0, 0.14, 120, 55, 22, 0.6, "sine", 0.25]])
	s.blocked = _mix([[0, 0.12, 200, 160, 25, 0.3, "square"]])
	s.cracked = _mix([[0, 0.14, 120, 55, 22, 0.5, "sine", 0.25], [0.02, 0.12, 0, 0, 30, 0.2, "hiss"]])
	s.lie = _mix([[0, 0.45, 311, 294, 5, 0.16, "square"], [0, 0.45, 330, 300, 5, 0.16, "square"], [0, 0.1, 110, 60, 30, 0.4, "sine"]])
	s.chalk = _mix([[0, 0.3, 0, 0, 8, 0.25, "hiss"], [0.18, 0.6, 1320, 1320, 6, 0.18, "sine"]])
	s.win = _mix([[0, 0.7, 523.25, 523.25, 5, 0.22, "tri"], [0.07, 0.7, 659.25, 659.25, 5, 0.2, "tri"], [0.14, 0.7, 783.99, 783.99, 5, 0.2, "tri"], [0.21, 0.9, 1046.5, 1046.5, 4, 0.2, "tri"]])
	s.fall = _mix([[0, 0.8, 520, 70, 2.5, 0.35, "tri"]])
	s.tint = _mix([[0, 0.45, 0, 0, 4, 0.12, "hiss"], [0, 0.45, 180, 420, 4, 0.2, "sine"]])
	s.portal = _mix([[0, 0.6, 300, 1100, 3, 0.2, "tri"], [0.05, 0.6, 450, 1650, 3, 0.12, "sine"]])
	s.drop = _mix([[0, 0.12, 150, 90, 30, 0.5, "sine", 0.3], [0.08, 0.12, 150, 90, 30, 0.4, "sine", 0.3]])
	s.unlock = _mix([[0, 0.25, 1200, 1200, 14, 0.15, "square"], [0.09, 0.4, 1800, 1800, 10, 0.12, "square"]])
	s.turn = _mix([[0, 0.04, 1400, 1100, 80, 0.06, "tri"]])
	s.type = _mix([[0, 0.02, 900, 700, 150, 0.05, "square"]])
	s.ui = _mix([[0, 0.08, 660, 700, 30, 0.25, "tri"]])
	s.star = _mix([[0, 0.5, 1046.5, 1046.5, 6, 0.25, "tri"], [0, 0.5, 1568, 1568, 7, 0.1, "sine"]])
	s.hint = _mix([[0, 0.5, 880, 1320, 5, 0.15, "sine"], [0.1, 0.5, 1320, 1760, 5, 0.1, "sine"]])
	var arpeggio := []
	for i in 6:
		var f: float = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5][i]
		arpeggio.append([i * 0.06, 0.6, f, f, 5, 0.16, "tri"])
	s.secret = _mix(arpeggio)
	var giggle := []  # Filou: "hi hi hi"
	for i in 4:
		giggle.append([i * 0.09, 0.08, 1250.0 + i * 90.0, 1500.0 + i * 90.0, 30, 0.13, "tri"])
	s.giggle = _mix(giggle)
	s.boing = _mix([[0, 0.35, 160, 520, 7, 0.3, "sine"], [0.02, 0.3, 320, 1040, 9, 0.08, "tri"]])
	_streams = s


## Each voice: [start s, duration s, freq from, freq to, decay, gain, wave, noise].
static func _mix(voices: Array) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	for v in voices:
		_voice(out, v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7] if v.size() > 7 else 0.0)
	return _wav(out, RATE)


static func _voice(out: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, decay: float, gain: float, wave: String, noise: float) -> void:
	var first := int(start * RATE)
	var n := int(dur * RATE)
	if out.size() < first + n:
		out.resize(first + n)
	var phase := 0.0
	var last_noise := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += TAU * lerpf(f0, f1, t / dur) / RATE
		var s := 0.0
		if wave == "sine":
			s = sin(phase)
		elif wave == "tri":
			s = 2.0 / PI * asin(sin(phase))
		elif wave == "square":
			s = 0.5 * signf(sin(phase))
		else:  # "hiss": high-passed noise, sounds like chalk or wind
			var r := randf_range(-1.0, 1.0)
			s = r - last_noise
			last_noise = r
		if noise > 0.0:
			s = lerpf(s, randf_range(-1.0, 1.0), noise)
		out[first + i] += s * gain * minf(1.0, t / 0.004) * exp(-decay * t)


static func _wav(samples: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	samples.resize(samples.size() + 256)  # trailing silence: the resampler reads a little past the end
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav


## A 16 s ambient loop: four slow breathing chords (Am F C G) and a few glassy notes.
static func _render_music() -> AudioStreamWAV:
	const CHORDS := [[130.81, 164.81, 196.0], [98.0, 123.47, 146.83], [110.0, 130.81, 164.81], [87.31, 110.0, 130.81]]  # C G Am F: bright and friendly
	const BAR := 4.0
	var bar_len := int(BAR * MUSIC_RATE)
	var out := PackedFloat32Array()
	out.resize(bar_len * CHORDS.size())
	for c in CHORDS.size():
		for f in CHORDS[c]:
			for detune in [1.0, 1.004]:
				var w: float = TAU * f * detune / MUSIC_RATE
				for i in bar_len:
					out[c * bar_len + i] += sin(w * i) * sin(PI * i / bar_len) * 0.07
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var notes := [440.0, 523.25, 587.33, 659.25, 783.99]
	for k in 7:
		var start := int(rng.randf_range(0.5, BAR * CHORDS.size() - 2.0) * MUSIC_RATE)
		var w: float = TAU * notes[rng.randi() % notes.size()] / MUSIC_RATE
		for i in int(1.8 * MUSIC_RATE):
			out[start + i] += sin(w * i) * exp(-2.2 * i / MUSIC_RATE) * 0.05
	return _wav(out, MUSIC_RATE)
