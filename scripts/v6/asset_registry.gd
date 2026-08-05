extends RefCounted
class_name EdenFallAssetRegistry

const ENEMY_ALIASES := {
	"outlaw_gunner": "ritual_gunner",
}
const BIOME_ORDER := ["eden_biolab", "ash_wastes", "halo_ruins", "nephilim_pits", "serpent_depths"]

var pack: RefCounted
var data: Dictionary = {}

func _init(production_pack: RefCounted) -> void:
	pack = production_pack
	data = pack.get("registry")

func hero(id: String) -> Dictionary:
	var section: Dictionary = data.get("heroes", {})
	return section.get(id, {})

func enemy(id: String) -> Dictionary:
	var resolved := String(ENEMY_ALIASES.get(id, id))
	var section: Dictionary = data.get("enemies", {})
	return section.get(resolved, {})

func boss(id: String) -> Dictionary:
	var section: Dictionary = data.get("bosses", {})
	return section.get(id, {})

func biome(index: int) -> Dictionary:
	var id := BIOME_ORDER[clampi(index, 0, BIOME_ORDER.size() - 1)]
	var section: Dictionary = data.get("biomes", {})
	return section.get(id, {})

func elite(id: String) -> Dictionary:
	var section: Dictionary = data.get("elite_overlays", {})
	return section.get(id, {})

func ui(id: String) -> String:
	var section: Dictionary = data.get("ui", {})
	return String(section.get(id, ""))

func item(id: String) -> String:
	var section: Dictionary = data.get("items", {})
	return String(section.get(id, ""))

func vfx(id: String) -> String:
	var section: Dictionary = data.get("vfx", {})
	return String(section.get(id, ""))

func audio(kind: String, id: String) -> String:
	var audio_section: Dictionary = data.get("audio", {})
	var kind_section: Dictionary = audio_section.get(kind, {})
	return String(kind_section.get(id, ""))
