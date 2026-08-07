extends RefCounted

const PRODUCT_REVISION := "0.6.2-entropy"
const CORE_ABI_VERSION := "0.6.0"
const VISUAL_REVISION := "0.6.2"
const GENERATION_MODE := "stochastic_condition_driven"

func report() -> Dictionary:
	return {
		"product_revision":PRODUCT_REVISION,
		"core_abi_version":CORE_ABI_VERSION,
		"visual_revision":VISUAL_REVISION,
		"generation_mode":GENERATION_MODE,
		"fixed_seed_replay":false,
		"procedural_sprites":true,
		"procedural_biomes":true,
		"procedural_enemy_genomes":true,
		"recipe_persistence_only":true,
	}
