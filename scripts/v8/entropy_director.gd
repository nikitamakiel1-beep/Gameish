extends RefCounted

const VERSION := "0.6.2-entropy"

var rng := RandomNumberGenerator.new()
var crypto := Crypto.new()
var entropy_counter := 0
var entropy_salt := 0
var entropy_nonce := ""
var context_counters: Dictionary = {}

func _init() -> void:
	reseed()

func reseed() -> void:
	rng.randomize()
	var bytes := crypto.generate_random_bytes(16)
	if bytes.size() >= 16:
		entropy_nonce = bytes.hex_encode()
	else:
		entropy_nonce = "%d:%d:%d" % [rng.randi(), Time.get_ticks_usec(), int(Time.get_unix_time_from_system() * 1000000.0)]
	entropy_salt = hash("%s:%d:%d" % [entropy_nonce, rng.randi(), Time.get_ticks_usec()])
	rng.seed = entropy_salt
	for _warmup in range(8):
		rng.randi()
	entropy_counter = 0
	context_counters.clear()

func token(context: String = "") -> int:
	var occurrence := _next_context_occurrence(context)
	return derive_seed(context, occurrence)

func fork(context: String = "") -> RandomNumberGenerator:
	var child := RandomNumberGenerator.new()
	child.seed = token(context)
	return child

func derive_seed(context: String, occurrence: int) -> int:
	# Forks are derived from a per-run cryptographic nonce + context + local
	# occurrence, so unrelated systems cannot perturb each other's substreams by
	# merely consuming the global RNG in a different order. The resulting PCG
	# stream is intentionally not treated as a cross-engine persistence ABI.
	var material := "%s|%s|%d|%s" % [VERSION, context, maxi(0, occurrence), entropy_nonce]
	var hashing := HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK:
		return hash(material)
	if hashing.update(material.to_utf8_buffer()) != OK:
		return hash(material)
	var digest := hashing.finish()
	if digest.size() < 8:
		return hash(material)
	var high := int(digest.decode_u32(0)) & 0x7fffffff
	var low := int(digest.decode_u32(4))
	var seed_value := (high << 32) | low
	return 1 if seed_value == 0 else seed_value

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
		"context_isolated_forks": true,
		"sha256_substream_derivation": true,
		"rng_algorithm_not_persistence_abi": true,
		"context_occurrence_counters": true,
	}

func _next_context_occurrence(context: String) -> int:
	entropy_counter += 1
	var occurrence := int(context_counters.get(context, 0)) + 1
	context_counters[context] = occurrence
	return occurrence
