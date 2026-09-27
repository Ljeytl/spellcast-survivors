import argparse
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--folder', type=Path, default=root / 'builds/spell-gallery')
args = parser.parse_args()
folder = args.folder
entries = json.loads((folder / 'catalog.json').read_text())
assert len([e for e in entries if e['group'] == 'Spells']) == 24
assert len([e for e in entries if e['group'] == 'Particles']) == 28
for entry in entries:
    for key in ('video', 'gif', 'poster'):
        assert (folder / entry[key]).is_file(), (entry['id'], key)
payload = json.dumps(entries).replace('</', '<\\/')
template = (root / 'tools/gallery/index.html').read_text()
(folder / 'index.html').write_text(template.replace('__DATA__', payload))
print(f'Built animated gallery: {len(entries)} complete loops with GIF downloads')
