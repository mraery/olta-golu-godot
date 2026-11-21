extends Node

## Prosedürel 16-bit PCM AudioStreamWAV ses sentezleyici (harici .wav dosyası gerektirmez).

const SAMPLE_RATE := 22050
var sound_on: bool = true
var _players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}

func _ready() -> void:
	sound_on = bool(SaveManager.data.get("sound", true))
	for i in range(6):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_build_all_sfx()

func toggle_sound() -> bool:
	sound_on = not sound_on
	SaveManager.data["sound"] = sound_on
	SaveManager.save_game()
	return sound_on

func play(sfx_name: String) -> void:
	if not sound_on:
		return
	if not _streams.has(sfx_name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[sfx_name]
			p.play()
			return
	_players[0].stream = _streams[sfx_name]
	_players[0].play()

func _build_all_sfx() -> void:
	_streams["splash"]   = _make_noise(0.28, 0.28, 0.25)
	_streams["whoosh"]   = _make_tone(320.0, 620.0, 0.14, "sine", 0.16)
	_streams["perfect"]  = _make_arpeggio([660.0, 880.0, 1320.0], 0.08, "triangle", 0.22)
	_streams["bite"]     = _make_arpeggio([660.0, 880.0], 0.07, "square", 0.15)
	_streams["warn"]     = _make_tone(520.0, 700.0, 0.10, "saw", 0.14)
	_streams["click"]    = _make_tone(1200.0, 1100.0, 0.025, "square", 0.08)
	_streams["snap"]     = _make_tone(320.0, 70.0, 0.22, "saw", 0.24)
	_streams["escape"]   = _make_tone(420.0, 180.0, 0.25, "triangle", 0.18)
	_streams["catch"]    = _make_arpeggio([523.0, 659.0, 784.0, 1047.0], 0.09, "triangle", 0.22)
	_streams["treasure"] = _make_arpeggio([587.0, 740.0, 880.0, 1175.0, 1480.0], 0.08, "triangle", 0.22)
	_streams["level_up"] = _make_arpeggio([523.0, 659.0, 784.0, 1047.0, 1319.0], 0.085, "sine", 0.24)
	_streams["coin"]     = _make_arpeggio([988.0, 1319.0], 0.07, "square", 0.14)
	_streams["steal"]    = _make_tone(190.0, 90.0, 0.28, "saw", 0.2)
	_streams["buy"]      = _make_arpeggio([660.0, 990.0], 0.08, "triangle", 0.2)
	_streams["sonar"]    = _make_arpeggio([1400.0, 1750.0], 0.06, "sine", 0.12)
	_streams["boss"]     = _make_tone(120.0, 65.0, 0.45, "saw", 0.25)
	_streams["tourney"]  = _make_arpeggio([523.0, 659.0, 784.0, 1047.0, 1319.0, 1568.0], 0.07, "triangle", 0.22)
	_streams["thunder"]  = _make_noise(0.55, 0.25, 0.08)

func _make_wav(samples: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = samples
	return wav

func _osc(phase: float, wave: String) -> float:
	var p := fposmod(phase, TAU)
	match wave:
		"square":   return 1.0 if p < PI else -1.0
		"triangle": return (2.0 / PI) * asin(sin(p))
		"saw":      return (p / PI) - 1.0
	return sin(p)

func _make_tone(f0: float, f1: float, dur: float, wave: String, vol: float) -> AudioStreamWAV:
	var n := maxi(1, int(SAMPLE_RATE * dur))
	var buf := PackedByteArray()
	buf.resize(n * 2)
	var phase := 0.0
	for i in range(n):
		var k := float(i) / float(n)
		var freq := lerpf(f0, f1, k)
		phase += TAU * freq / float(SAMPLE_RATE)
		var env := (1.0 - k) * minf(1.0, float(i) / 80.0)
		var s := clampi(int(_osc(phase, wave) * vol * env * 32767.0), -32768, 32767)
		buf.encode_s16(i * 2, s)
	return _make_wav(buf)

func _make_arpeggio(freqs: Array, note_dur: float, wave: String, vol: float) -> AudioStreamWAV:
	var note_n := maxi(1, int(SAMPLE_RATE * note_dur))
	var total_n := note_n * freqs.size()
	var buf := PackedByteArray()
	buf.resize(total_n * 2)
	for ni in range(freqs.size()):
		var freq := float(freqs[ni])
		var phase := 0.0
		for i in range(note_n):
			var k := float(i) / float(note_n)
			phase += TAU * freq / float(SAMPLE_RATE)
			var env := (1.0 - k * 0.85) * minf(1.0, float(i) / 50.0)
			var s := clampi(int(_osc(phase, wave) * vol * env * 32767.0), -32768, 32767)
			buf.encode_s16((ni * note_n + i) * 2, s)
	return _make_wav(buf)

func _make_noise(dur: float, vol: float, lowpass_alpha: float) -> AudioStreamWAV:
	var n := maxi(1, int(SAMPLE_RATE * dur))
	var buf := PackedByteArray()
	buf.resize(n * 2)
	var filt := 0.0
	for i in range(n):
		var k := float(i) / float(n)
		var white := randf_range(-1.0, 1.0)
		filt = lerpf(filt, white, lowpass_alpha)
		var env := (1.0 - k)
		var s := clampi(int(filt * vol * env * 32767.0), -32768, 32767)
		buf.encode_s16(i * 2, s)
	return _make_wav(buf)
