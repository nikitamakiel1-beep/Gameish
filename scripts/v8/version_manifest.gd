extends RefCounted

const PRODUCT_VERSION: String = "0.6.4"
const PRODUCT_REVISION: String = "0.6.4-authored-art4"
const CORE_ABI_VERSION: String = "0.6.0"
const VISUAL_REVISION: String = "0.6.4-art4"
const GODOT_VERSION: String = "4.7.1"
const GENERATION_MODE: String = "stochastic_condition_driven"

func report() -> Dictionary:
	return {
		"product_version": PRODUCT_VERSION,
		"product_revision": PRODUCT_REVISION,
		"core_abi_version": CORE_ABI_VERSION,
		"visual_revision": VISUAL_REVISION,
		"godot": GODOT_VERSION,
		"generation_mode": GENERATION_MODE,
		"fixed_seed_replay": false,
		"procedural_sprites": true,
		"procedural_biomes": true,
		"procedural_enemy_genomes": true,
		"canonical_hero_identity": true,
		"curated_enemy_families": true,
		"recipe_persistence_only": true,
	}
