"""Python twin of scripts/core/SpellLibrary.gd: reassembles the spell documents from data/spells/<id>.json."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SECTIONS = {"spell": "spells", "recipe": "recipes", "shape": "spell_shapes", "damage": "spell_damage", "generic": "generic_spells"}


def entries(root=ROOT):
    folder = Path(root) / "data" / "spells"
    items = [json.loads(p.read_text()) for p in folder.glob("*.json") if p.name != "_book.json"]
    return sorted(items, key=lambda e: e.get("order", 0))


def document(name, root=ROOT):
    book = json.loads((Path(root) / "data" / "spells" / "_book.json").read_text())
    section = next(s for s, n in SECTIONS.items() if n == name)
    found = [e for e in entries(root) if section in e]
    if section == "generic":
        found.sort(key=lambda e: e.get("generic_order", 0))
    items = {e["id"]: e[section] for e in found}
    docs = book.get("docs", {})
    if name == "spells":
        return {"spells": items, "spell_categories": book.get("spell_categories", {}), "unlock_conditions": book.get("unlock_conditions", {}), "preparation": book.get("preparation", {})}
    if name == "recipes":
        return {"_doc": docs.get("recipes", ""), "recipes": items}
    if name == "spell_shapes":
        return {"_doc": docs.get("spell_shapes", ""), "shapes": items}
    return {"_doc": docs.get(name, ""), "spells": items}
