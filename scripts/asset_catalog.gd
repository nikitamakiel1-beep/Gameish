class_name AssetCatalog
extends RefCounted

const ROOT := "res://assets/generated/"
const BOSS_IDS := ["watcher_engine", "seraph_reactor", "nephilim_king", "eden_warden", "void_archon"]
const ITEM_ROWS := {
	"seraph_lens": 0,
	"cherub_coil": 1,
	"bone_orchard": 2,
	"cains_mark": 3,
	"salt_genome": 4,
	"eden_valve": 5,
	"black_manna": 6,
	"industrial_halo": 7,
	"watcher_gland": 8,
	"nephilim_marrow": 9,
}
const EFFECT_ROWS := {
	"muzzle": 0,
	"impact": 1,
	"dash": 2,
	"heal": 3,
	"shield": 4,
	"critical": 5,
	"pickup": 6,
	"death": 7,
	"portal": 8,
	"boss_phase": 9,
}

var _textures: Dictionary = {}

func available() -> bool:
	return FileAccess.file_exists(ROOT + "manifest.json")

func texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	if not ResourceLoader.exists(path):
		return null
	var resource := load(path)
	if resource is Texture2D:
		_textures[path] = resource
		return resource
	return null

func player(id: String) -> Texture2D:
	return texture(ROOT + "players/%s.png" % id)

func enemy(category: String, variant: int) -> Texture2D:
	var safe_variant := posmod(variant, 5) + 1
	return texture(ROOT + "enemies/%s_%02d.png" % [category, safe_variant])

func boss(index: int) -> Texture2D:
	return texture(ROOT + "bosses/%s.png" % BOSS_IDS[posmod(index, BOSS_IDS.size())])

func effects() -> Texture2D:
	return texture(ROOT + "effects/effects.png")

func relics() -> Texture2D:
	return texture(ROOT + "items/relics.png")

func tiles(biome: int) -> Texture2D:
	return texture(ROOT + "tiles/biome_%02d.png" % (posmod(biome, 5) + 1))

func item_row(id: String) -> int:
	return int(ITEM_ROWS.get(id, 0))

func effect_row(id: String) -> int:
	return int(EFFECT_ROWS.get(id, 0))
