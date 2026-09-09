extends RefCounted

const VERSION := "0.6.1-rc7"
const MIX_RATE := 22050
const LOOP_SECONDS := 8.0

const ROOTS := [55.0, 49.0, 65.41, 46.25, 41.20]
const FIFTHS := [82.41, 73.42, 98.00, 69.30, 61.74]
const PULSES := [1.70, 1.45, 1.90, 1.32, 1.18]

func synth_loop(index: int, ambience: bool) -> AudioStreamWAV:
	var safe_index := clampi(index, 0, ROOTS.size() - 1)
	var sample_count := int(float(MIX_RATE) * LOOP_SECONDS)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var root := float(ROOTS[safe_index])
	var fifth := float(FIFTHS[safe_index])
	var pulse_rate := float(PULSES[safe_index])
	for sample in range(sample_count):
		var time := float(sample) / float(MIX_RATE)
		var value := _ambience_sample(safe_index, time, root) if ambience else _music_sample(safe_index, time, root, fifth, pulse_rate)
		bytes.encode_s16(sample * 2, int(clampf(value, -0.96, 0.96) * 32767.0))
	return _stream(bytes, MIX_RATE, true, sample_count)

func _music_sample(index: int, time: float, root: float, fifth: float, pulse_rate: float) -> float:
	var slow := sin(TAU * root * time) * 0.115
	slow += sin(TAU * fifth * time + 0.35) * 0.060
	slow += sin(TAU * root * 0.5 * time + 0.8) * 0.070
	var choir_mod := sin(TAU * (0.08 + float(index) * 0.011) * time)
	var choir := sin(TAU * (root * 2.0 + choir_mod * 2.2) * time) * 0.025
	choir += sin(TAU * (fifth * 2.0 - choir_mod * 1.7) * time + 1.1) * 0.020
	var beat_phase := fposmod(time * pulse_rate, 1.0)
	var pulse_env := exp(-beat_phase * 11.0)
	var pulse := sin(TAU * (root * 0.50 + 14.0 * exp(-beat_phase * 8.0)) * time) * pulse_env * 0.095
	var alarm_phase := fposmod(time + float(index) * 0.37, 4.0)
	var alarm_env := exp(-alarm_phase * 6.0) if alarm_phase < 0.45 else 0.0
	var alarm := sin(TAU * (330.0 + float(index) * 41.0) * time) * alarm_env * (0.020 + float(index) * 0.003)
	var metallic := sin(TAU * (root * 6.97) * time + sin(time * 0.41) * 1.3) * 0.010
	return slow + choir + pulse + alarm + metallic

func _ambience_sample(index: int, time: float, root: float) -> float:
	var ventilation := sin(TAU * (22.0 + float(index) * 4.3) * time) * 0.080
	ventilation += sin(TAU * (31.0 + float(index) * 3.1) * time + sin(time * 0.23) * 1.8) * 0.045
	var turbine := sin(TAU * (root * 2.0) * time + sin(time * 0.17) * 2.1) * 0.022
	var grit := sin(float(int(time * 2400.0) * 17 + index * 101) * 0.173) * 0.010
	var event_phase := fposmod(time + float(index) * 0.61, 5.6)
	var event := 0.0
	if event_phase < 0.52:
		var envelope := sin(PI * event_phase / 0.52)
		match index:
			0: event = sin(TAU * 164.0 * time) * envelope * 0.024
			1: event = sin(TAU * 91.0 * time + sin(time * 8.0)) * envelope * 0.024
			2: event = sin(TAU * 246.0 * time) * envelope * 0.020
			3: event = (sin(TAU * 181.0 * time) + sin(TAU * 223.0 * time)) * envelope * 0.014
			_: event = sin(TAU * 72.0 * time) * envelope * 0.030
	return ventilation + turbine + grit + event

func synth_sfx(id: String) -> AudioStreamWAV:
	var duration := _sfx_duration(id)
	var sample_count := maxi(1, int(float(MIX_RATE) * duration))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var variant := posmod(id.hash(), 17)
	for sample in range(sample_count):
		var time := float(sample) / float(MIX_RATE)
		var progress := clampf(time / duration, 0.0, 1.0)
		var value := _sfx_sample(id, time, progress, variant)
		bytes.encode_s16(sample * 2, int(clampf(value, -0.96, 0.96) * 32767.0))
	return _stream(bytes, MIX_RATE, false, sample_count)

func _sfx_duration(id: String) -> float:
	if id in ["boss_phase", "victory", "death"]:
		return 0.72
	if id in ["door", "portal", "relic", "shop"]:
		return 0.46
	if id.begins_with("warning_"):
		return 0.34
	if id in ["dash", "hurt", "shield", "critical"]:
		return 0.30
	return 0.22

func _sfx_sample(id: String, time: float, progress: float, variant: int) -> float:
	var decay := exp(-progress * 5.8)
	var noise := sin(float(int(time * 15000.0) * 13 + variant * 37) * 0.119)
	if id.begins_with("shot"):
		var base := 215.0 + float(variant % 5) * 38.0
		return sin(TAU * (base + progress * 510.0) * time) * decay * 0.42 + noise * decay * 0.075
	match id:
		"enemy_shot":
			return sin(TAU * (430.0 - progress * 190.0) * time) * decay * 0.36 + noise * decay * 0.045
		"impact_01", "impact", "kill":
			return sin(TAU * (110.0 + progress * 70.0) * time) * exp(-progress * 9.0) * 0.34 + noise * exp(-progress * 12.0) * 0.16
		"critical":
			return (sin(TAU * 690.0 * time) + sin(TAU * 1035.0 * time)) * exp(-progress * 7.0) * 0.22
		"dash":
			return sin(TAU * (90.0 + progress * 520.0) * time) * exp(-progress * 4.0) * 0.22 + noise * (1.0 - progress) * 0.14
		"hurt":
			return sin(TAU * (185.0 - progress * 105.0) * time) * exp(-progress * 4.5) * 0.36
		"shield":
			return (sin(TAU * 530.0 * time) + sin(TAU * 795.0 * time)) * exp(-progress * 5.0) * 0.18
		"door":
			return sin(TAU * (62.0 + progress * 44.0) * time) * exp(-progress * 3.0) * 0.34 + noise * exp(-progress * 8.0) * 0.08
		"portal":
			return sin(TAU * (145.0 + progress * 420.0) * time) * sin(PI * progress) * 0.26
		"boss_phase":
			return sin(TAU * (48.0 + progress * 138.0) * time) * exp(-progress * 2.0) * 0.38 + sin(TAU * 370.0 * time) * sin(PI * progress) * 0.13
		"pickup", "ui_confirm", "shop", "relic":
			return sin(TAU * (440.0 + progress * 360.0) * time) * exp(-progress * 5.0) * 0.26
		"ui_cancel":
			return sin(TAU * (330.0 - progress * 120.0) * time) * exp(-progress * 5.0) * 0.23
		"warning_melee":
			return sin(TAU * (118.0 + progress * 45.0) * time) * sin(PI * progress) * 0.31
		"warning_aimed":
			return sin(TAU * (510.0 + progress * 170.0) * time) * sin(PI * progress) * 0.22
		"warning_radial":
			return (sin(TAU * 248.0 * time) + sin(TAU * 372.0 * time)) * sin(PI * progress) * 0.17
		"warning_phase":
			return sin(TAU * (82.0 + progress * 310.0) * time) * sin(PI * progress) * 0.28
		"victory":
			return (sin(TAU * 220.0 * time) + sin(TAU * 330.0 * time) + sin(TAU * 440.0 * time)) * sin(PI * progress) * 0.12
		"death":
			return sin(TAU * (165.0 - progress * 108.0) * time) * exp(-progress * 1.7) * 0.32
		_:
			var base := 210.0 + float(variant) * 23.0
			return sin(TAU * (base + progress * 180.0) * time) * decay * 0.28

func _stream(bytes: PackedByteArray, rate: int, looping: bool, sample_count: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"mix_rate": MIX_RATE,
		"loop_seconds": LOOP_SECONDS,
		"biome_motifs": ROOTS.size(),
		"warning_families": 4,
		"deterministic": true,
		"external_samples": false,
	}
