"""One-time migration (0.3.2): split the per-concern spell files into one file per spell.

data/spells.json, recipes.json, spell_shapes.json, spell_damage.json and generic_spells.json become
data/spells/<id>.json with sections "spell", "recipe", "shape", "damage" and "generic", plus
data/spells/_book.json for what is not about one spell (preparation, categories, unlock text, docs).
scripts/core/SpellLibrary.gd reassembles the old documents exactly; tests/spell_library_regression.gd
proves it against the old files recorded in tests/fixtures/spell_documents_0_3_2.bin.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
load = lambda name: json.loads((DATA / name).read_text())

spells, recipes, shapes, damage, generic = (load(n) for n in ["spells.json", "recipes.json", "spell_shapes.json", "spell_damage.json", "generic_spells.json"])
order = list(spells["spells"]) + [k for k in recipes["recipes"] if k not in spells["spells"]]
order += [k for k in list(damage["spells"]) + list(shapes["shapes"]) if k not in order]
generic_ids = list(generic["spells"])
order += [k for k in generic_ids if k not in order]

out = DATA / "spells"
out.mkdir(exist_ok=True)
for index, sid in enumerate(order):
    entry = {"id": sid, "order": (index + 1) * 10}
    if sid in generic["spells"]:
        entry["generic_order"] = (generic_ids.index(sid) + 1) * 10
    for section, doc, key in [("spell", spells, "spells"), ("recipe", recipes, "recipes"), ("shape", shapes, "shapes"), ("damage", damage, "spells"), ("generic", generic, "spells")]:
        if sid in doc[key]:
            entry[section] = doc[key][sid]
    (out / f"{sid}.json").write_text(json.dumps(entry, indent=2, ensure_ascii=False) + "\n")

book = {
    "_doc": "Spell data that is not about one spell. Each spell lives in data/spells/<id>.json (sections: spell = identity, numbers, ranks, presentation; recipe = combination; shape = parts and cast rules; damage = damage types and statuses per part; generic = bare/draft definition). Reassembled by scripts/core/SpellLibrary.gd.",
    "docs": {"spells": spells.get("_doc", ""), "recipes": recipes.get("_doc", ""), "spell_shapes": shapes.get("_doc", ""), "spell_damage": damage.get("_doc", ""), "generic_spells": generic.get("_doc", "")},
    "spell_categories": spells["spell_categories"],
    "unlock_conditions": spells["unlock_conditions"],
    "preparation": spells["preparation"],
}
for k in ["spells", "recipes", "spell_shapes", "spell_damage", "generic_spells"]:
    if not book["docs"][k]:
        del book["docs"][k]
(out / "_book.json").write_text(json.dumps(book, indent=2, ensure_ascii=False) + "\n")
print(len(order), "spell files")
