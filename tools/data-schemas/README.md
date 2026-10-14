# Data schemas

Every `data/<name>.json` has `data/schemas/<name>.schema.json` (doc 19 P3). `scripts/core/DataValidator.gd` checks them: at load in debug builds and in `tests/data_validation_regression.gd`.

**Adding a data file:** draft its schema, then annotate it.

```
python3 tools/data-schemas/draft_schema.py data/foo.json [comma,separated,map,keys] > data/schemas/foo.schema.json
```

The draft closes every object, types every value and marks keys present everywhere as required. Id-keyed maps are detected (4+ similar objects) or forced by naming their key (use `$` for a root map). Then add by hand:

| Keyword | Meaning |
|---|---|
| `"x-registry": "spell"` | on an object: its keys are ids of that registry (files register into the same registry) |
| `"x-ref": "status"` or `["element", "element_alias"]` | on a string: must be a known id |
| `"propertyNames": {"type": "string", "x-ref": "damage_type"}` | on a map: its keys must be known ids |
| `"x-allow-empty": true` | with `x-ref`: `""` means none |
| `"x-key-field": "id"` | on an id-keyed map: each entry's `id` equals its key |
| `enum`, `minimum`, `maximum`, `minItems`, `maxItems`, `$ref`, `$defs`, `$comment` | as in JSON Schema |

**Adding a key to existing data:** add it to the schema in the same commit. An unknown key is an error on purpose: it is how typos are caught. Unknown schema keywords are errors too.
