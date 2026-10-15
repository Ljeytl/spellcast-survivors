from pathlib import Path
import json
import sys
import re
import unittest

ROOT = Path(__file__).parent
REPO = ROOT.parent.parent
sys.path.insert(0, str(REPO / 'tools'))
import spell_library  # noqa: E402  spell documents come from data/spells/<id>.json
ARCHIVE = ROOT / 'archive/2026-10-14'
OWNERS = {'03-spells.md', '15-development-order.md', '18-spell-system-rewrite.md',
          '19-engine-architecture.md', '20-game-systems-architecture.md',
          '21-damage-effects-keywords.md'}


def content(name):
    return (ROOT / name).read_text()


def authored_names():
    text = (ARCHIVE / '18-spell-system-rewrite.md').read_text()
    section = text.split('## 12. Approved design spells, specified', 1)[1].split('## 13. Art needed', 1)[0]
    return re.findall(r'^\*\*([^*]+)\*\*', section, re.M)


def validate_catalog(text):
    aliases = {'Ice Spear / Glacial Spear': 'Ice Spear / Glacial Spear / Glacial Lance',
               'Lightning Spear (rod)': 'Lightning Spear / Lightning Rod',
               'Frost Strike (falling icicle)': 'Frost Strike / falling icicle',
               'Vine ball': 'Vine Ball', 'Earth Golem': 'Earth Golem',
               'Sunbeam': 'Sunbeam', 'Homing Bolt': 'Homing Bolt'}
    identities = '\n'.join(line.split('|')[1].strip() for line in text.splitlines() if line.startswith('|') and len(line.split('|')) > 2)
    missing = [name for name in authored_names() if aliases.get(name, name) not in identities]
    if missing:
        raise ValueError('Missing authored identities: ' + ', '.join(missing))


def validate_feel_sequences(text):
    spells = spell_library.document('spells', REPO)['spells']
    recipes = spell_library.document('recipes', REPO)['recipes']
    expected = {key for key, row in spells.items() if row.get('preparable')}
    expected.update(key for key, row in recipes.items() if row.get('enabled', True))
    expected.update({'mana_bolt', 'atomic', 'spear', 'slash', 'nova', 'field', 'orbit', 'trap'})
    documented = set(re.findall(r'\*\*Runtime:\*\* `([^`]+)`', text))
    missing = expected - documented
    if missing:
        raise ValueError('Missing spell sequences: ' + ', '.join(sorted(missing)))


FEEL_POINTS = {'A+': 4.3, 'A': 4.0, 'A-': 3.7, 'B+': 3.3, 'B': 3.0,
               'B-': 2.7, 'C+': 2.3, 'C': 2.0, 'C-': 1.7,
               'D+': 1.3, 'D': 1.0, 'D-': 0.7, 'F': 0.0}


def feel_gate(grades):
    if len(grades) != 6 or any(grade == 'U' for grade in grades):
        return 'INCOMPLETE'
    values = [FEEL_POINTS[grade] for grade in grades]
    return 'PASS' if min(values) >= 1.7 and sum(values) / 6 >= 2.7 else 'BELOW TARGET'


class DocumentationChecks(unittest.TestCase):
    def test_audit_scorecard(self):
        audit = json.loads(content('spell-feel-audit-2026-10-15.json'))
        rows = audit['rows']
        self.assertEqual(len(rows), 31)
        self.assertEqual(len({row['id'] for row in rows}), len(rows))
        sequence_text = '\n'.join('**Runtime:** `' + row['id'] + '`' for row in rows)
        validate_feel_sequences(sequence_text)
        document = content('18-spell-system-rewrite.md')
        for row in rows:
            self.assertEqual(len(row['grades']), 6)
            self.assertTrue(all(grade in FEEL_POINTS or grade == 'U' for grade in row['grades']))
            values = [FEEL_POINTS[grade] for grade in row['grades'] if grade != 'U']
            self.assertAlmostEqual(row['partial_mean'], round(sum(values) / len(values), 2))
            self.assertEqual(row['verdict'], feel_gate(row['grades']))
            expected = '| `' + row['id'] + '` | ' + row['name'] + ' | ' + ' | '.join(row['grades']) + ' | ' + format(row['partial_mean'], '.2f') + ' |'
            self.assertIn(expected, document)

    def test_feel_grade_controls(self):
        self.assertEqual(feel_gate(['B'] * 6), 'PASS')
        self.assertEqual(feel_gate(['A+', 'A', 'A', 'A', 'A', 'C-']), 'PASS')
        self.assertEqual(feel_gate(['A+'] * 5 + ['D+']), 'BELOW TARGET')
        self.assertEqual(feel_gate(['B-'] * 6), 'PASS')
        self.assertEqual(feel_gate(['B-'] * 5 + ['C+']), 'BELOW TARGET')
        self.assertEqual(feel_gate(['A+'] * 5 + ['U']), 'INCOMPLETE')
        self.assertEqual(feel_gate(['A+'] * 5), 'INCOMPLETE')

    def test_runtime_feel_coverage(self):
        validate_feel_sequences(content('18-spell-system-rewrite.md'))

    def test_missing_feel_sequence_control(self):
        text = content('18-spell-system-rewrite.md').replace('**Runtime:** `lightning`', '')
        with self.assertRaisesRegex(ValueError, 'lightning'):
            validate_feel_sequences(text)

    def test_live_bases(self):
        spells = spell_library.document('spells', REPO)['spells']   # data/spells/<id>.json
        ids = [key for key, spell in spells.items() if spell.get('preparable')]   # 0.3.2: the list is data
        table = content('03-spells.md').split('### Existing combinations')[0]
        for key in ids:
            self.assertIn(f'| `{key}` | {spells[key]["name"]} | Implemented manual base |', table)
        self.assertEqual(len(re.findall(r'Implemented manual base', table)), len(ids))

    def test_enabled_recipes(self):
        recipes = spell_library.document('recipes', REPO)['recipes']
        table = content('03-spells.md').split('### Existing combinations')[1].split('## Full authored')[0]
        enabled = [key for key, row in recipes.items() if row.get('enabled', True)]
        self.assertEqual(len(re.findall(r'^\| `', table, re.M)), len(enabled))
        for key in enabled:
            self.assertIn(f'`{key}`', table)
            self.assertIn(recipes[key]['name'], table)

    def test_full_authored_catalog(self):
        self.assertGreater(len(authored_names()), 60)
        validate_catalog(content('03-spells.md'))

    def test_missing_spell_control(self):
        text = re.sub(r'^\| Mana Storm \|.*\n', '', content('03-spells.md'), flags=re.M)
        with self.assertRaisesRegex(ValueError, 'Mana Storm'):
            validate_catalog(text)

    def test_latest_decisions(self):
        catalog = content('03-spells.md')
        for token in ['radius and band thickness scale proportionally',
                      'each level adds one slash', 'final level adds a small explosion',
                      'Separate lingering beams aim at enemies',
                      'rooting line or trail', 'pull enemies into it']:
            self.assertIn(token, catalog)
        for prefix in ['Ice Spear / Glacial Spear / Glacial Lance', 'Lightning Spear / Lightning Rod']:
            self.assertIn(f'| {prefix} | Paused |', catalog)
        self.assertEqual(catalog.count('| Shillelagh / Life Spear |'), 1)
        self.assertIn('New combination recipes and acquisition will be decided later', catalog)
        self.assertNotIn('Fire + Life candidate', catalog)

    def test_preserved_older_ideas(self):
        catalog = content('03-spells.md')
        for name in ['Arcane Orb', 'Pulse', 'Gravity Well', 'Plague / Plague Nut',
                     'Thorn Volley', 'Venom Mark', 'Spore Bloom', 'Seeking Spirit',
                     'Reaping Spirit', 'Undertow', 'Tidal Wave', 'Thunder Spear',
                     'Tempest', 'Crescent', 'Daybreak', 'Solar Flare', 'Explosion',
                     'Super Extreme Meteor Shower Deluxe', 'Boots of Hermes',
                     'Personal storm aura', 'Swiftness', 'Tidal Push', 'Divine Aura',
                     'Frost Ray / Ice Ray', 'Plague Spear, Nova, Shower, Field, Wall, Trail, Trap']:
            self.assertIn(name, catalog)

    def test_single_owners(self):
        index = content('README.md')
        for name in OWNERS:
            self.assertIn(f']({name})', index)
        retired = [p for p in ROOT.glob('[0-9][0-9]-*.md') if p.name not in OWNERS]
        self.assertGreater(len(retired), 10)
        for path in retired:
            self.assertIn('not a second active specification', path.read_text())
            self.assertTrue((ARCHIVE / path.name).exists())
        plan = content('15-development-order.md')
        self.assertIn('Release goals agreed with Aditya on 14 October 2026', plan)
        self.assertIn('No subset or fixed spell count', plan)
        self.assertIn('Level 1 starts with normal slimes', plan)

    def test_retained_decisions(self):
        catalog = content('03-spells.md')
        for text in ['earned by combo, like Atomic', 'No cooldowns for now',
                     'deliberately weak', 'not gods or faith']:
            self.assertIn(text, catalog)
        presentation = content('18-spell-system-rewrite.md')
        for text in ['whole circular room', 'without a return journey or exit interaction',
                     'never delays input or loses rapid characters', 'reduced motion']:
            self.assertIn(text, presentation)
        self.assertIn('per-cast slowdown, not a shared meter', content('15-development-order.md'))
        engine = content('19-engine-architecture.md')
        self.assertEqual(len(re.findall(r'^## 14\.', engine, re.M)), 1)
        self.assertNotIn('spawns 48', engine)

    def test_links(self):
        count = 0
        paths = list(ROOT.rglob('*.md')) + [REPO / 'README.md', REPO / 'ROGUELITE_ROADMAP.md']
        for path in paths:
            for link in re.findall(r'\]\(([^)]+)\)', path.read_text()):
                if '://' in link or link.startswith('#'):
                    continue
                self.assertTrue((path.parent / link.split('#')[0]).exists(), f'{path}: {link}')
                count += 1
        self.assertGreater(count, 100)

    def test_active_tables(self):
        count = 0
        for path in ROOT.glob('*.md'):
            width = None
            fenced = False
            for line in path.read_text().splitlines():
                if line.startswith('```'):
                    fenced = not fenced
                if fenced:
                    continue
                if line.startswith('|'):
                    cells = len(line.split('|'))
                    width = cells if width is None else width
                    self.assertEqual(cells, width, f'{path.name}: {line}')
                    count += 1
                else:
                    width = None
        self.assertGreater(count, 200)


if __name__ == '__main__':
    unittest.main(verbosity=2)
