from pathlib import Path
from decimal import Decimal as D
import re
import unittest

ROOT = Path(__file__).parent


def content(name):
    return (ROOT / name).read_text()


def roster(text):
    return re.findall(r'^\| \*\*([^*]+)\*\* /', text, re.M)


def matrix(text):
    tail = text.split('| Spell | Accepted keywords |', 1)[1]
    return {row.split('|')[1].strip(): [v.strip() for v in row.split('|')[2].split(',')]
            for row in tail.splitlines() if row.startswith('|') and not row.startswith('|---')}


def validate_roster(text):
    names = roster(text)
    if len(names) != 36 or len(set(names)) != 36:
        raise ValueError('Expected exactly 36 distinct proposed campaign spells')
    return names


class DocumentationChecks(unittest.TestCase):
    def test_current_matrix_covers_live_bases(self):
        import json
        root = ROOT.parent.parent
        source = (root / 'scripts/SpellManager.gd').read_text()
        ids = json.loads(re.search(r'const BASE_SPELL_IDS = (\[.*?\])', source).group(1))
        spells = json.loads((root / 'data/spells.json').read_text())['spells']
        table = content('16-element-family-matrix.md')
        self.assertEqual(len(ids), 16)
        for spell_id in ids:
            if spell_id in spells:
                self.assertIn(spells[spell_id]['name'], table)
        for name in ('Ember Lance', 'Plague Seed', 'Cinder Field', 'Arcane Orbit',
                     'Lightning Bolt', 'Life Bolt', 'Meteor Lance', 'Soul Bloom',
                     'Steam Field', 'Prism Ray', 'Frost Sigil'):
            self.assertIn(name, table)
        selected = table.split('## Examples and historical proposals')[0]
        for name in ('Arcane Seed', 'Arcane Shield'):
            self.assertNotIn(name, selected)

    def test_component_reference_covers_roster(self):
        reference = content('14-spell-system-reference.md')
        section = reference.split('## 8. Named spell recipes', 1)[1].split('## 9.', 1)[0]
        names = re.findall(r'^\|\*\*([^*]+)\*\*\|', section, re.M)
        self.assertEqual(len(names), 36)
        self.assertEqual(set(names), set(roster(content('03-spells.md'))))

    def test_component_reference_starts_with_primitives(self):
        reference = content('14-spell-system-reference.md')
        section = reference.split('## 2. Foundational component table', 1)[1].split('## 3.', 1)[0]
        self.assertIn('Expanding front', section)
        self.assertIn('Infection', section)
        self.assertNotIn('Bolt', section)
        self.assertNotIn('Meteor Shower', section)

    def test_numbered_documents_are_indexed(self):
        index = content('README.md')
        documents = sorted(ROOT.glob('[0-9][0-9]-*.md'))
        self.assertEqual(len(documents), 16)
        for document in documents:
            self.assertIn(f']({document.name})', index, document.name)

    def test_development_plan_covers_named_roster(self):
        plan = content('15-development-order.md')
        for name in roster(content('03-spells.md')):
            self.assertIn(name, plan, name)
        self.assertIn('Level 1 starts with normal slimes', plan)
        self.assertIn('It is not a schedule for when a player unlocks', plan)

    def test_roster_count(self):
        self.assertEqual(len(validate_roster(content('03-spells.md'))), 36)

    def test_missing_spell_control(self):
        altered = re.sub(r'^\| \*\*Bolt\*\* /.*\n', '', content('03-spells.md'), flags=re.M)
        with self.assertRaisesRegex(ValueError, '36 distinct'):
            validate_roster(altered)

    def test_compatibility_covers_roster(self):
        self.assertEqual(set(roster(content('03-spells.md'))), set(matrix(content('04-composition.md'))))

    def test_keyword_vocabulary(self):
        expected = {'Big', 'Powerful', 'Swift', 'Seeking', 'Repulsing', 'Duplicating', 'Repeating',
                    'Delayed', 'Charged', 'Lasting', 'Fiery', 'Icy', 'Earthen', 'Venomous'}
        rows = matrix(content('04-composition.md'))
        self.assertEqual(set().union(*(set(v) for v in rows.values())), expected)
        for name, words in rows.items():
            self.assertEqual(len(words), len(set(words)), name)

    def test_key_compatibility_exclusions(self):
        rows = matrix(content('04-composition.md'))
        for name in ('Life', 'Regeneration'):
            self.assertNotIn('Big', rows[name])
        self.assertIn('Big', rows['Earth Shield'])
        self.assertNotIn('Lasting', rows['Yggdrasil'])
        for name in ('Focus Ray', 'Frost Ray', 'Prism Ray', 'Seeker', 'Summon Golem'):
            self.assertNotIn('Charged', rows[name])
        self.assertNotIn('Repeating', rows['Rune Trap'])

    def test_recipe_count_and_references(self):
        text = content('05-progression.md').split('| Recipe | Ingredients | Availability |')[1].split('Fire Bolt is')[0]
        rows = [r.split('|') for r in text.splitlines() if r.startswith('|') and not r.startswith('|---')]
        self.assertEqual(len(rows), 7)
        names = set(roster(content('03-spells.md')))
        for row in rows:
            self.assertIn(row[1].strip(), names)
            for ingredient in row[2].split('+'):
                self.assertIn(ingredient.strip(), names)

    def test_all_spell_names_have_acquisition(self):
        acquisition = content('05-progression.md') + content('06-levels.md')
        for name in roster(content('03-spells.md')):
            self.assertIn(name, acquisition)

    def test_local_links_exist(self):
        count = 0
        for path in ROOT.glob('*.md'):
            for link in re.findall(r'\]\(([^)]+)\)', path.read_text()):
                if '://' in link or link.startswith('#'):
                    continue
                target = link.split('#')[0]
                self.assertTrue((path.parent / target).exists(), f'{path.name}: {target}')
                count += 1
        self.assertGreaterEqual(count, 12)

    def test_fenced_json_examples_parse(self):
        import json
        examples = re.findall(r'```json\n(.*?)\n```', content('10-engineering.md'), re.S)
        self.assertEqual(len(examples), 2)
        for example in examples:
            self.assertEqual(json.loads(example)['schema_version'], 1)

    def test_worked_arithmetic(self):
        self.assertEqual(D(40) * D('1.5'), D(60))
        self.assertEqual(D(40) * D('.8') * 2 * D('1.4'), D('89.6'))
        self.assertEqual(D(80) * D('2.65'), D(212))
        self.assertEqual(D(60) * D('.8') * 5, D(240))
        self.assertEqual(D(4) * D('1.5') * D(6) * D('1.4'), D('50.4'))
        self.assertEqual(len('powerful big bolt') - len('bolt'), 13)

    def test_terminal_proration_is_specified(self):
        self.assertIn('final prorated payment', content('03-spells.md'))
        self.assertIn('earned fractional remainder', content('07-combat-balance.md'))
        self.assertNotIn('half-open', content('03-spells.md'))

    def test_markdown_table_shapes(self):
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
                    if width is None:
                        width = cells
                    self.assertEqual(cells, width, f'{path.name}: {line}')
                    count += 1
                else:
                    width = None
        self.assertGreater(count, 250)


if __name__ == '__main__':
    unittest.main(verbosity=2)
