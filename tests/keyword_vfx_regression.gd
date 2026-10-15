extends "res://tests/keyword_contract_regression.gd"
## timeout: 160
## Keyword casts are drawn by the VFX layer: for every shipping spell, one accepted keyword per
## category is cast and every part it spawns must be presented (no placeholder art).

func _init():
	VFX_PASS = true
