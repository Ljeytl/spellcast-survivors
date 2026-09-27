import argparse
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = '/Applications/Godot.app/Contents/MacOS/Godot'


def build(godot=GODOT):
    stage = ROOT / 'builds/workshop-project'
    output = ROOT / 'builds/visual-workshop'
    stage.mkdir(parents=True, exist_ok=True)
    output.mkdir(parents=True, exist_ok=True)
    for folder in ('scripts', 'scenes', 'assets', 'sprites', 'audio', 'themes', 'data', 'Actual Art we made', 'tools/workshop'):
        shutil.copytree(ROOT / folder, stage / folder, dirs_exist_ok=True)
    for pattern in ('*.json', '*.tres', '*.png', '*.svg'):
        for path in ROOT.glob(pattern):
            shutil.copy2(path, stage / path.name)
    project = (ROOT / 'project.godot').read_text()
    project = project.replace('config/name="SpellCast Survivors"', 'config/name="SpellCast Survivors Visual Workshop"')
    project = project.replace('run/main_scene="res://scenes/MainMenu.tscn"', 'run/main_scene="res://tools/workshop/VisualWorkshop.tscn"')
    project = project.replace('window/size/mode=2', 'window/size/mode=0')
    project = project.replace('window/size/viewport_width=1920', 'window/size/viewport_width=1280').replace('window/size/viewport_height=1080', 'window/size/viewport_height=800')
    if '[rendering]' not in project:
        project += '\n[rendering]\n'
    project += '\nrenderer/rendering_method="gl_compatibility"\nrenderer/rendering_method.mobile="gl_compatibility"\n'
    (stage / 'project.godot').write_text(project)
    (stage / 'export_presets.cfg').write_text('''[preset.0]
name="Workshop"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter="data/*.json"
exclude_filter="builds/*"
export_path=""
[preset.0.options]
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/canvas_resize_policy=2
html/focus_canvas_on_start=false
progressive_web_app/enabled=false
''')
    shutil.rmtree(stage / '.godot/exported', ignore_errors=True)
    with (output / 'export.log').open('w') as log:
        for args in (['--editor', '--import'], ['--export-release', 'Workshop', str(output / 'engine.html')]):
            subprocess.run([godot, '--headless', '--path', str(stage), *args], stdout=log, stderr=subprocess.STDOUT, check=True)
    log_text = re.sub(r'\x1b\[[0-9;]*m', '', (output / 'export.log').read_text())
    if 'SCRIPT ERROR' in log_text or 'ERROR:' in log_text:
        raise RuntimeError('Godot export reported errors; inspect builds/visual-workshop/export.log')
    for name in ('index.html', 'workshop.css', 'workshop.js'):
        shutil.copy2(ROOT / 'tools/workshop' / name, output / name)
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    (output / 'build.json').write_text(json.dumps({'revision': revision, 'renderer': 'Godot compatibility', 'profile': 'SpellCast Survivors Visual Workshop'}, indent=2))
    print(output / 'index.html')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', default=GODOT)
    build(parser.parse_args().godot)
