extends RefCounted

func synth_loop(index: int, ambience: bool) -> AudioStreamWAV:
	var rate := 11025
	var sample_count := rate * 4
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var roots: Array[float] = [55.0, 61.74, 65.41, 73.42, 49.0]
	var root := roots[clampi(index, 0, roots.size() - 1)]
	for sample in range(sample_count):
		var time := float(sample) / float(rate)
		var value := sin(TAU * root * time) * 0.20 + sin(TAU * root * 1.5 * time + 0.6) * 0.10
		if ambience:
			value = sin(TAU * (28.0 + index * 7.0) * time) * 0.11 + sin(TAU * (180.0 + index * 43.0) * time + sin(time * 0.7) * 2.0) * 0.03
		bytes.encode_s16(sample * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream

func synth_sfx(id: String) -> AudioStreamWAV:
	var rate := 11025
	var sample_count := int(rate * 0.26)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var frequency := 240.0 + float(posmod(id.hash(), 9)) * 61.0
	for sample in range(sample_count):
		var time := float(sample) / float(rate)
		var decay := 12.0 if id.begins_with("shot") else 18.0
		var envelope := exp(-time * decay)
		var value := sin(TAU * (frequency + time * 380.0) * time) * envelope * 0.48
		bytes.encode_s16(sample * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream
