extends RefCounted

const VERSION := 7
const ROOM_GRACE := 0.72
const ENEMY_BASE_MATERIALIZE := 0.36
const ENEMY_STAGGER := 0.045
const ENEMY_MAX_MATERIALIZE := 0.76
const BOSS_MATERIALIZE := 0.82
const PLAYER_CLEARANCE := 152.0
const BOSS_CLEARANCE := 210.0

func materialize_delay(index: int, boss: bool) -> float:
	if boss:
		return BOSS_MATERIALIZE
	return minf(ENEMY_MAX_MATERIALIZE, ENEMY_BASE_MATERIALIZE + float(index) * ENEMY_STAGGER)

func clearance(boss: bool) -> float:
	return BOSS_CLEARANCE if boss else PLAYER_CLEARANCE

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"room_grace": ROOM_GRACE,
		"enemy_materialization": true,
		"staggered_activation": true,
		"spawn_clearance": PLAYER_CLEARANCE,
		"boss_clearance": BOSS_CLEARANCE,
	}
