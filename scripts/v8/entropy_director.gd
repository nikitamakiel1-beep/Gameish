extends RefCounted

const VERSION := "0.6.2-entropy"

var rng := RandomNumberGenerator.new()
var crypto := Crypto.new()
var entropy_counter := 0

func _init() -> void:
	reseed()

func reseed() -> void:
	rng.randomize()
	var bytes := crypto.generate_random_bytes(8)
	var secure_a := int(bytes.decode_u32(0)) if bytes.size() >= 4 else int(Time.get_ticks_usec())
	var secure_b := int(bytes.decode_u32(4)) if bytes.size() >= 8 else int(Time.get_unix_time_from_system() * 1000000.0)
	rng.seed = hash("%d:%d:%d:%d" % [rng.randi(), secure_a, secure_b, Time.get_ticks_usec()])
	for _warmup in range(6):
		rng.randi()
	entropy_counter = 0

func token(context: String = "") -> int:
	entropy_counter += 1
	var bytes := crypto.generate_random_bytes(4)
	var secure := int(bytes.decode_u32(0)) if bytes.size() >= 4 else int(Time.get_ticks_usec())
	return hash("%s:%d:%d:%d:%d" % [context, entropy_counter, rng.randi(), secure, Time.get_ticks_usec()])

func fork(context: String = "") -> RandomNumberGenerator:
	var child := RandomNumberGenerator.new()
	child.seed = token(context)
	return child

func chance(probability: float) -> bool:
	return rng.randf() < clampf(probability, 0.0, 1.0)

func pick(values: Array, fallback = null):
	if values.is_empty():
		return fallback
	return values[rng.randi_range(0, values.size() - 1)]

func weighted_index(weights: PackedFloat32Array) -> int:
	if weights.is_empty():
		return -1
	return rng.rand_weighted(weights)

func shuffled(values: Array) -> Array:
	var result := values.duplicate(true)
	for index in range(result.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var temp = result[index]
		result[index] = result[other]
		result[other] = temp
	return result

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"time_randomized": true,
		"crypto_mixed": true,
		"fixed_seed_replay": false,
		"fresh_context_tokens": true,
	}
