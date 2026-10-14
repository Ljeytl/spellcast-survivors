#!/usr/bin/env python3
"""Draft a strict schema from an existing data file (doc 19 §8).

    python3 tools/data-schemas/draft_schema.py data/foo.json [force,map,keys] > data/schemas/foo.schema.json

The draft closes every object (unknown keys fail), types every value, marks keys
present in every instance as required, collapses id-keyed maps (4+ keys, all
objects) into `additionalProperties`, and turns frame animations into a shared
`$defs/animation`. Review it by hand afterwards: add `x-registry`, `x-ref`,
`propertyNames` and enums. Never regenerate an annotated schema blindly.
"""
import json, sys

ANIM_KEYS = {"frames", "fps", "loop", "duration"}

def jtype(v):
    if isinstance(v, bool): return "boolean"
    if isinstance(v, (int, float)): return "number"
    if isinstance(v, str): return "string"
    if isinstance(v, list): return "array"
    if isinstance(v, dict): return "object"
    return "null"

FORCE_MAPS = set()

def is_map(d, name=""):
    keys = [k for k in d if not k.startswith("_")]
    if name in FORCE_MAPS:
        return bool(keys) and all(isinstance(d[k], dict) for k in keys)
    if len(keys) < 4 or not all(isinstance(d[k], dict) for k in keys):
        return False
    # id-keyed maps hold similar records; a record holding different sections does not
    sets = [set(d[k]) for k in keys]
    union = set().union(*sets)
    shared = set.intersection(*sets)
    return bool(union) and len(shared) / len(union) >= 0.3

def is_anim(d):
    return isinstance(d, dict) and "frames" in d and set(d) <= ANIM_KEYS

def infer(values, name=""):
    values = [v for v in values]
    types = sorted({jtype(v) for v in values})
    if types == ["object"]:
        if all(is_anim(v) for v in values):
            return {"$ref": "#/$defs/animation"}
        if (name != "$" or "$" in FORCE_MAPS) and any(is_map(v, name) for v in values):
            fixed = sorted({k for v in values for k in v if k.startswith("_") and k != "_doc"})
            out = {"type": "object"}
            if fixed:
                out["properties"] = {k: infer([v[k] for v in values if k in v], k) for k in fixed}
            out["additionalProperties"] = infer([x for v in values for k, x in v.items() if not k.startswith("_")], name + "*")
            return out
        keys = []
        for v in values:
            for k in v:
                if k != "_doc" and k not in keys: keys.append(k)
        out = {"type": "object", "properties": {k: infer([v[k] for v in values if k in v], k) for k in keys}}
        req = [k for k in keys if all(k in v for v in values)]
        if req: out["required"] = req
        out["additionalProperties"] = False
        return out
    if types == ["array"]:
        items = [x for v in values for x in v]
        return {"type": "array", "items": infer(items, name + "[]")} if items else {"type": "array"}
    if len(types) == 1:
        return {"type": types[0]}
    return {"type": types}

def main(path, force=""):
    FORCE_MAPS.update(k for k in force.split(",") if k)
    data = json.load(open(path))
    schema = {"$schema": "https://json-schema.org/draft/2020-12/schema",
              "title": path.split("/")[-1],
              "$defs": {"animation": {"type": "object", "properties": {
                  "frames": {"type": "array", "items": {"type": "string"}}, "fps": {"type": "number", "minimum": 0},
                  "loop": {"type": "boolean"}, "duration": {"type": "number", "minimum": 0}},
                  "required": ["frames"], "additionalProperties": False}}}
    schema.update(infer([data], "$"))
    if '"#/$defs/animation"' not in json.dumps(schema):
        del schema["$defs"]
    print(json.dumps(schema, indent=2))

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "")
