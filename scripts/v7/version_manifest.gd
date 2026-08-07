extends RefCounted

const PRODUCT_VERSION := "0.6.1"
const RELEASE_CANDIDATE := "rc7"
const PRODUCT_REVISION := "0.6.1-rc7"
const CORE_ABI_VERSION := "0.6.0"
const GODOT_VERSION := "4.7.1"
const VISUAL_VERSION := "0.6.1"

func report() -> Dictionary:
	return {
		"product_version": PRODUCT_VERSION,
		"release_candidate": RELEASE_CANDIDATE,
		"product_revision": PRODUCT_REVISION,
		"core_abi_version": CORE_ABI_VERSION,
		"godot": GODOT_VERSION,
		"visual_version": VISUAL_VERSION,
	}
