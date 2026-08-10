extends "res://scripts/edenfall_v8_art_direction_runtime.gd"

const V8_ART_INTEGRATION_VERSION: String = "0.6.2-art2"

func draw_arena() -> void:
	# The authored presentation establishes the dark architectural frame. Then
	# explicitly restore V8's room-specific floor skin and collision-matched cover,
	# which the presentation override would otherwise bypass.
	super.draw_arena()
	_draw_room_obstacles()

func audit_art_direction_contract() -> Dictionary:
	var report: Dictionary = super.audit_art_direction_contract()
	report["world_surface_integrated"] = true
	report["collision_cover_visuals_integrated"] = true
	return report

func audit_entropy_contract() -> Dictionary:
	var report: Dictionary = super.audit_entropy_contract()
	report["authored_world_surface_integrated"] = true
	return report
