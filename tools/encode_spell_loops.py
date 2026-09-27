import argparse
import json
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--folder', type=Path, default=Path(__file__).resolve().parents[1] / 'builds/workshop-project/builds/spell-gallery')
parser.add_argument('--movie', type=Path, required=True)
args = parser.parse_args()
folder = args.folder
entries = json.loads((folder / 'loops.json').read_text())
for entry in entries:
    start = entry['start_frame'] / 30
    duration = entry['duration']
    base = ['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-ss', str(start), '-i', str(args.movie), '-t', str(duration), '-an']
    subprocess.run(base + ['-c:v', 'libx264', '-crf', '20', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(folder / entry['video'])], check=True)
    subprocess.run(base + ['-filter_complex', 'fps=15,scale=640:-1:flags=neighbor,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=none', '-loop', '0', str(folder / entry['gif'])], check=True)
    assert (folder / entry['poster']).is_file()
    print('Encoded', entry['id'], flush=True)
(folder / 'catalog.json').write_text(json.dumps(entries, indent=2))
