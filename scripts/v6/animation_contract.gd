extends RefCounted
class_name EdenFallAnimationContract

const DIRECTIONS := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const HERO_ACTIONS := ["idle", "walk", "aim", "attack", "dash", "hurt", "death", "cast", "interact", "guard", "victory"]
const ENEMY_ACTIONS := ["idle", "walk", "attack", "hurt", "death"]
const BOSS_ACTIONS := ["intro", "idle", "move", "attack_primary", "attack_secondary", "phase", "hurt", "death"]

static func hero_row(action: String, direction: int) -> int:
	return maxi(0, HERO_ACTIONS.find(action)) * 8 + posmod(direction, 8)

static func enemy_row(action: String, direction: int) -> int:
	return maxi(0, ENEMY_ACTIONS.find(action)) * 8 + posmod(direction, 8)

static func boss_row(action: String, direction: int) -> int:
	return maxi(0, BOSS_ACTIONS.find(action)) * 8 + posmod(direction, 8)
