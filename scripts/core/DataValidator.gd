extends RefCounted
## Validates every data file against its schema (doc 19 P3 and §8; doc 20 §9).
##
## Convention: data/<name>.json is described by data/schemas/<name>.schema.json.
## Schemas use a subset of JSON Schema (draft 2020-12) plus three extensions:
##   "x-registry": "<name>"  on an object: its keys (except "_" keys) are ids of that registry
##   "x-ref": "<name>" or ["<a>", "<b>"]  on a string (or in propertyNames): the value must be an id in that registry
##   "x-allow-empty": true   with x-ref: "" means "none" and is allowed
##   "x-key-field": "<field>" on an id-keyed map: each entry's <field> must equal its key
## Registries are collected from all files first, so references work across files.
## "_doc" keys are comments and allowed anywhere.
##
## Usage: DataValidator.validate_all() -> Array of error strings (empty when all data is valid).

const DATA_DIR = "res://data"
const SCHEMA_DIR = "res://data/schemas"
const SCHEMA_SUFFIX = ".schema.json"

const KEYWORDS = [
	"$schema", "$id", "$comment", "$defs", "$ref", "title", "description",
	"type", "properties", "required", "additionalProperties", "items", "enum", "const",
	"minimum", "maximum", "exclusiveMinimum", "minItems", "maxItems", "propertyNames",
	"x-registry", "x-ref", "x-allow-empty", "x-key-field",
]
const TYPES = ["object", "array", "string", "number", "integer", "boolean", "null"]

## Loads every data file and its schema from disk and validates them together.
## extra_registries: ids defined outside data, if any (see validate_documents).
static func validate_all(data_dir: String = DATA_DIR, schema_dir: String = SCHEMA_DIR, extra_registries: Dictionary = {}) -> Array:
	var errors: Array = []
	var docs := {}
	var schemas := {}
	for file in DirAccess.get_files_at(data_dir):
		if not file.ends_with(".json"):
			continue
		var name = file.get_basename()
		var doc = _load_json(data_dir.path_join(file), errors)
		var schema_path = schema_dir.path_join(name + SCHEMA_SUFFIX)
		if not FileAccess.file_exists(schema_path):
			errors.append("%s: no schema (expected %s)" % [file, schema_path])
			continue
		var schema = _load_json(schema_path, errors)
		if doc == null or schema == null:
			continue
		docs[file] = doc
		schemas[file] = schema
	for file in DirAccess.get_files_at(schema_dir):
		if file.ends_with(SCHEMA_SUFFIX) and not FileAccess.file_exists(data_dir.path_join(file.trim_suffix(SCHEMA_SUFFIX) + ".json")):
			errors.append("%s: schema without a data file" % file)
	errors.append_array(validate_documents(docs, schemas, extra_registries))
	return errors

## Validates parsed documents. docs and schemas are keyed by data file name ("spells.json").
## extra_registries: {"registry": ["id", ...]} for ids defined outside data (e.g. mechanics in code).
static func validate_documents(docs: Dictionary, schemas: Dictionary, extra_registries: Dictionary = {}) -> Array:
	var errors: Array = []
	var registries := {}
	for name in extra_registries:
		registries[name] = {}
		for id in extra_registries[name]:
			registries[name][str(id)] = "code"
	for file in schemas:
		_check_schema(schemas[file], "schema " + file, "#", errors)
	if not errors.is_empty():
		return errors
	for file in docs:
		_walk(docs[file], schemas[file], schemas[file], "$", file, registries, null)
	for file in docs:
		_walk(docs[file], schemas[file], schemas[file], "$", file, registries, errors)
	return errors

## Returns the ids registered under each registry name (for tests and tools).
static func registries_of(docs: Dictionary, schemas: Dictionary) -> Dictionary:
	var registries := {}
	for file in docs:
		_walk(docs[file], schemas[file], schemas[file], "$", file, registries, null)
	return registries

static func _load_json(path: String, errors: Array):
	var text = FileAccess.get_file_as_string(path)
	if text.is_empty():
		errors.append("%s: missing or empty" % path)
		return null
	var json = JSON.new()
	if json.parse(text) != OK:
		errors.append("%s:%d: JSON parse error: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data

## Schema self-check: unknown keywords are errors, so a typo in a schema cannot switch a rule off.
static func _check_schema(schema, file: String, at: String, errors: Array) -> void:
	if typeof(schema) != TYPE_DICTIONARY:
		errors.append("%s %s: schema must be an object" % [file, at])
		return
	for key in schema:
		if not key in KEYWORDS:
			errors.append("%s %s: unknown schema keyword '%s'" % [file, at, key])
	if schema.has("type"):
		var types = schema.type if typeof(schema.type) == TYPE_ARRAY else [schema.type]
		for t in types:
			if not t in TYPES:
				errors.append("%s %s: unknown type '%s'" % [file, at, t])
	for key in ["properties", "$defs"]:
		for child in schema.get(key, {}):
			_check_schema(schema[key][child], file, "%s/%s/%s" % [at, key, child], errors)
	for key in ["items", "propertyNames"]:
		if schema.has(key):
			_check_schema(schema[key], file, "%s/%s" % [at, key], errors)
	if typeof(schema.get("additionalProperties", false)) == TYPE_DICTIONARY:
		_check_schema(schema.additionalProperties, file, at + "/additionalProperties", errors)

static func _resolve(schema: Dictionary, root: Dictionary) -> Dictionary:
	var guard = 0
	while schema.has("$ref") and guard < 16:
		var ref: String = schema["$ref"]
		var target = root
		for part in ref.trim_prefix("#/").split("/"):
			target = target.get(part, {}) if typeof(target) == TYPE_DICTIONARY else {}
		schema = target
		guard += 1
	return schema

static func _type_of(value) -> String:
	match typeof(value):
		TYPE_DICTIONARY: return "object"
		TYPE_ARRAY: return "array"
		TYPE_STRING, TYPE_STRING_NAME: return "string"
		TYPE_INT, TYPE_FLOAT: return "number"
		TYPE_BOOL: return "boolean"
		TYPE_NIL: return "null"
	return "unknown"

static func _type_ok(value, wanted) -> bool:
	var actual = _type_of(value)
	for t in (wanted if typeof(wanted) == TYPE_ARRAY else [wanted]):
		if t == actual:
			return true
		if t == "integer" and actual == "number" and is_equal_approx(float(value), round(float(value))):
			return true
	return false

## One walker for both passes: errors == null collects registries, otherwise checks.
static func _walk(value, schema: Dictionary, root: Dictionary, path: String, file: String, registries: Dictionary, errors) -> void:
	schema = _resolve(schema, root)
	var checking = errors != null
	if schema.has("type") and not _type_ok(value, schema.type):
		if checking:
			_fail(errors, file, path, "expected %s, got %s" % [schema.type, _type_of(value)])
		return
	if checking:
		if schema.has("enum") and not value in schema.enum:
			_fail(errors, file, path, "'%s' is not one of %s" % [value, schema.enum])
		if schema.has("const") and value != schema.const:
			_fail(errors, file, path, "must be %s" % [schema.const])
		if _type_of(value) == "number":
			if schema.has("minimum") and value < schema.minimum:
				_fail(errors, file, path, "%s is below the minimum %s" % [value, schema.minimum])
			if schema.has("exclusiveMinimum") and value <= schema.exclusiveMinimum:
				_fail(errors, file, path, "%s must be above %s" % [value, schema.exclusiveMinimum])
			if schema.has("maximum") and value > schema.maximum:
				_fail(errors, file, path, "%s is above the maximum %s" % [value, schema.maximum])
		if schema.has("x-ref") and not (str(value) == "" and bool(schema.get("x-allow-empty", false))):
			_check_ref(str(value), schema["x-ref"], registries, errors, file, path)
	match _type_of(value):
		"object":
			_walk_object(value, schema, root, path, file, registries, errors)
		"array":
			if checking:
				if schema.has("minItems") and value.size() < schema.minItems:
					_fail(errors, file, path, "needs at least %d items" % schema.minItems)
				if schema.has("maxItems") and value.size() > schema.maxItems:
					_fail(errors, file, path, "allows at most %d items" % schema.maxItems)
			if schema.has("items"):
				for i in value.size():
					_walk(value[i], schema.items, root, "%s[%d]" % [path, i], file, registries, errors)

static func _walk_object(value: Dictionary, schema: Dictionary, root: Dictionary, path: String, file: String, registries: Dictionary, errors) -> void:
	var checking = errors != null
	var props: Dictionary = schema.get("properties", {})
	var extra = schema.get("additionalProperties", true)
	if schema.has("x-registry") and not checking:
		var reg: String = schema["x-registry"]
		if not registries.has(reg):
			registries[reg] = {}
		for key in value:
			if not str(key).begins_with("_"):
				registries[reg][str(key)] = file
	if checking:
		for key in schema.get("required", []):
			if not value.has(key):
				_fail(errors, file, path, "missing required '%s'" % key)
	for key in value:
		var child_path = "%s.%s" % [path, key]
		if key == "_doc":
			if checking and typeof(value[key]) != TYPE_STRING:
				_fail(errors, file, child_path, "_doc must be a string")
			continue
		if checking and schema.has("propertyNames") and not props.has(key):
			_walk(key, schema.propertyNames, root, child_path + " (key)", file, registries, errors)
		if props.has(key):
			_walk(value[key], props[key], root, child_path, file, registries, errors)
		elif typeof(extra) == TYPE_DICTIONARY:
			_walk(value[key], extra, root, child_path, file, registries, errors)
			if checking and schema.has("x-key-field") and typeof(value[key]) == TYPE_DICTIONARY:
				var field: String = schema["x-key-field"]
				if str(value[key].get(field, "")) != str(key):
					_fail(errors, file, child_path, "%s must equal its key '%s'" % [field, key])
		elif extra == false and checking:
			_fail(errors, file, child_path, "unknown key '%s' (typo? if intended, add it to data/schemas/%s%s)" % [key, file.get_basename(), SCHEMA_SUFFIX])

## registry may be one name or a list (the id must be in any of them).
static func _check_ref(id: String, registry, registries: Dictionary, errors: Array, file: String, path: String) -> void:
	var names: Array = registry if typeof(registry) == TYPE_ARRAY else [registry]
	for name in names:
		if not registries.has(name):
			_fail(errors, file, path, "unknown registry '%s' (no x-registry declares it)" % name)
			return
		if registries[name].has(id):
			return
	_fail(errors, file, path, "'%s' is not a known %s" % [id, " or ".join(names)])

static func _fail(errors: Array, file: String, path: String, message: String) -> void:
	errors.append("%s %s: %s" % [file, path, message])
