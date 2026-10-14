extends RefCounted
## Combination recipes, from data/recipes.json.

const GameData = preload("res://scripts/core/GameData.gd")

static var RECIPES: Dictionary = GameData.file("recipes").get("recipes", {})
