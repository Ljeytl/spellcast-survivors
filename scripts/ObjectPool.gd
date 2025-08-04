extends Node
class_name ObjectPool

# Generic object pooling system for frequently spawned objects

var pools: Dictionary = {}
var max_pool_sizes: Dictionary = {}

func _ready():
	# Set default pool sizes
	max_pool_sizes["SpellProjectile"] = 50
	max_pool_sizes["DamageNumber"] = 30
	max_pool_sizes["XPOrb"] = 20

func register_pool(type_name: String, scene: PackedScene, max_size: int = 20):
	# Register a new object pool for a specific type
	if not pools.has(type_name):
		pools[type_name] = {
			"scene": scene,
			"available": [],
			"in_use": []
		}
		max_pool_sizes[type_name] = max_size

func get_object(type_name: String) -> Node:
	# Get an object from the pool or create a new one
	if not pools.has(type_name):
		print("Warning: No pool registered for type ", type_name)
		return null
	
	var pool = pools[type_name]
	var obj = null
	
	# Try to reuse an available object
	if pool["available"].size() > 0:
		obj = pool["available"].pop_back()
		# Reset the object for reuse
		if obj.has_method("reset_for_pool"):
			obj.reset_for_pool()
	else:
		# Create a new object if pool is empty and under limit
		if get_total_pool_size(type_name) < max_pool_sizes[type_name]:
			obj = pool["scene"].instantiate()
			# Setup pooling methods if available
			if obj.has_method("setup_for_pool"):
				obj.setup_for_pool()
	
	if obj:
		pool["in_use"].append(obj)
		# Connect to return signal if object supports it
		if obj.has_signal("pool_return_requested") and not obj.pool_return_requested.is_connected(_on_object_return_requested):
			obj.pool_return_requested.connect(_on_object_return_requested.bind(obj, type_name))
	
	return obj

func return_object(obj: Node, type_name: String):
	# Return an object to the pool for reuse
	if not pools.has(type_name):
		# Disconnect signals before freeing
		if obj.has_signal("pool_return_requested") and obj.pool_return_requested.is_connected(_on_object_return_requested):
			obj.pool_return_requested.disconnect(_on_object_return_requested)
		obj.queue_free()
		return
	
	var pool = pools[type_name]
	var in_use_index = pool["in_use"].find(obj)
	
	if in_use_index >= 0:
		pool["in_use"].remove_at(in_use_index)
		
		# Reset object state
		if obj.has_method("reset_for_pool"):
			obj.reset_for_pool()
		
		# Remove from scene tree but don't free
		if obj.get_parent():
			obj.get_parent().remove_child(obj)
		
		pool["available"].append(obj)

func _on_object_return_requested(obj: Node, type_name: String):
	# Handle object requesting to be returned to pool
	return_object(obj, type_name)

func get_total_pool_size(type_name: String) -> int:
	# Get total number of objects in pool (available + in use)
	if not pools.has(type_name):
		return 0
	
	var pool = pools[type_name]
	return pool["available"].size() + pool["in_use"].size()

func get_pool_stats(type_name: String) -> Dictionary:
	# Get statistics about a specific pool
	if not pools.has(type_name):
		return {}
	
	var pool = pools[type_name]
	return {
		"available": pool["available"].size(),
		"in_use": pool["in_use"].size(),
		"total": get_total_pool_size(type_name),
		"max_size": max_pool_sizes[type_name]
	}

func cleanup_invalid_objects():
	# Remove invalid objects from pools
	for type_name in pools.keys():
		var pool = pools[type_name]
		
		# Clean available objects
		for i in range(pool["available"].size() - 1, -1, -1):
			if not is_instance_valid(pool["available"][i]):
				pool["available"].remove_at(i)
		
		# Clean in-use objects
		for i in range(pool["in_use"].size() - 1, -1, -1):
			if not is_instance_valid(pool["in_use"][i]):
				pool["in_use"].remove_at(i)

func get_all_pool_stats() -> Dictionary:
	# Get statistics for all pools
	var stats = {}
	for type_name in pools.keys():
		stats[type_name] = get_pool_stats(type_name)
	return stats