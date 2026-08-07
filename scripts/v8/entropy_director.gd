extends RefCounted

const VERSION := "0.6.2-entropy"

var rng := RandomNumberGenerator.new()
var crypto := Crypto.new()
var entropy_counter := 0
var entropy_salt := 0

func _init() -> void:
	reseed()

func reseed() -> void:
	rng.randomize()
	var bytes := crypto.generate_random_bytes(8)
	var secure_a := int(bytes.decode_u32(0)) if bytes.size() >= 4 else int(Time.get_ticks_usec())
	var secure_b := int(bytes.decode_u32(4)) if bytes.size() >= 8 else int(Time.get_unix_time_from_system() * 1000000.0)
	entropy_salt = hash("%d:%d:%d:%d" % [rng.randi(), secure_a, secure_b, Time.get_ticks_usec()])
	rng.seed = entropy_salt
	for _warmup in range(8):
		rng.randi()
	entropy_counter = 0

func token(context: String = "") -> int:
	entropy_counter += 1
	# Crypto is intentionally mixed only at reseed. Per-token entropy comes from
	# the already crypto-mixed PCG stream, monotonic ticks and a monotonic counter.
	# This keeps room/enemy/reward generation non-replayable without putting an
	# OS cryptographic RNG call on gameplay hot paths.
	return hash("%s:%d:%d:%d:%d" % [context, entropy_counter, rng.randi(), entropy_salt, Time.get_ticks_usec()])

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
		"crypto_mixed_at_reseed": true,
		"crypto_on_hot_path": false,
		"fixed_seed_replay": false,
		"fresh_context_tokens": true,
	}
