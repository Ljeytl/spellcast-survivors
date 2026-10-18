import argparse
import copy
import json
from pathlib import Path


def validate(data):
    errors = list(data.get('failures', []))
    def require(ok, message):
        if not ok:
            errors.append(message)
    require(data.get('spell') == 'meteor_shower' and data.get('rank') == 8, 'wrong spell/rank')
    frames = data.get('frames', [])
    require(len(frames) == 240, 'missing frames')
    require(all(f['camera_processing'] and not f['paused'] and f['time_scale'] == 1 for f in frames), 'invalid camera/runtime')
    require(len({tuple(f['camera']) for f in frames}) > 30, 'camera did not follow')
    reduced = data.get('reduced_effects')
    require(all(v == reduced for v in data.get('actual_reduced', {}).values()) and len(data.get('actual_reduced', {})) == 3, 'mode mismatch')
    release_frame = data.get('primary', {}).get('release', {}).get('frame', 999999)
    offsets = [abs(f['camera_offset'][0]) + abs(f['camera_offset'][1]) for f in frames if f['frame'] >= release_frame]
    require(bool(offsets) and (max(offsets) < 0.001 if reduced else max(offsets) > 1), 'shake mode not observed')
    require(data.get('damage_events', 0) > 0 and data.get('warnings', 0) > 0 and data.get('moving_enemies', 0) >= 6 and data.get('player_travel', 0) > 100, 'missing live combat')
    require(len(data.get('configured_enemies', [])) == 14 and all(e['physics'] and e['health'] == e['expected_health'] > 0 for e in data.get('configured_enemies', [])), 'invalid native-health AI')
    primary = data.get('primary', {})
    source = primary.get('source', {})
    require(source.get('spell') == 'meteor_shower' and bool(source.get('cast_id')), 'missing explicit primary source')
    require(bool(primary.get('exit')) and bool(primary.get('hits')), 'primary did not complete/contact')
    secondary = data.get('secondary', {})
    require(bool(secondary.get('hits')) and secondary.get('source', {}).get('cast_id') != source.get('cast_id'), 'secondary missing/distinctness')
    require(any(e['amount'] > 0 and e['source'].get('cast_id') == source.get('cast_id') for e in data.get('resolved', [])), 'no resolved primary damage')
    grouped = {kind: sorted([p for p in data.get('parts', []) if p['part'] == kind], key=lambda p: p['birth']['clock']) for kind in ('mark', 'impact', 'crater')}
    require(all(len(v) == 6 for v in grouped.values()), 'six lifecycles missing')
    for part in data.get('parts', []):
        require(part.get('source') == source, 'unbound part')
        require(bool(part.get('exit')) and part.get('exit', {}).get('done') is True, 'unfinished part')
    if all(len(v) == 6 for v in grouped.values()):
        for index, (mark, impact, crater) in enumerate(zip(grouped['mark'], grouped['impact'], grouped['crater'])):
            warning_life = mark['definition']['timing']['duration'] + index * primary['plan']['arrangement']['stagger_life']
            require(abs(impact['birth']['clock'] - mark['birth']['clock'] - warning_life) < 0.04, 'warning timing')
            require(abs(crater['birth']['clock'] - impact['birth']['clock']) < 0.02, 'impact/crater timing')
            require(mark['position'] == impact['position'] == crater['position'], 'landing position changed')
            if not reduced:
                window = [f for f in frames if 0 <= f['movie_frame'] - impact['birth']['movie_frame'] <= 4]
                require(any(f['shake_timer'] > 0 and f['shake_intensity'] > 6 and sum(abs(x) for x in f['camera_offset']) > 0.001 for f in window), 'missing Meteor-strength shake at impact')
            require(0.98 <= crater.get('exit', {}).get('age', 0) <= 1.04, 'crater lifetime')
            if index:
                require(abs(impact['birth']['clock'] - grouped['impact'][index - 1]['birth']['clock'] - 0.3) < 0.04, 'stagger timing')
    return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('manifest', type=Path)
    parser.add_argument('--paired', type=Path)
    parser.add_argument('--known-bad', action='store_true')
    args = parser.parse_args()
    data = json.loads(args.manifest.read_text())
    errors = validate(data)
    controls = []
    if args.known_bad:
        for label, mutation in [
            ('disabled-camera', lambda d: d['frames'][0].update(camera_processing=False)),
            (('forbidden-reduced-shake' if data['reduced_effects'] else 'missing-meteor-shake'), lambda d: [f.update(camera_offset=[1, 1] if d['reduced_effects'] else [0, 0], shake_intensity=0) for f in d['frames']]),
            ('wrong-reduced-label', lambda d: d.update(reduced_effects=not d['reduced_effects'])),
            ('missing-impact', lambda d: d.update(parts=[p for p in d['parts'] if p['part'] != 'impact'])),
            ('unbound-damage', lambda d: d.update(resolved=[])),
            ('missing-secondary-contact', lambda d: d['secondary'].update(hits=[])),
        ]:
            bad = copy.deepcopy(data)
            mutation(bad)
            caught = bool(validate(bad))
            controls.append({'control': label, 'rejected': caught})
            if not caught:
                errors.append('control escaped: ' + label)
    parity = None
    if args.paired:
        other = json.loads(args.paired.read_text())
        errors.extend(validate(other))
        parity = {'plan_equal': data['primary']['plan'] == other['primary']['plan'],
                  'distinct_modes': data['reduced_effects'] != other['reduced_effects'],
                  'lifecycle_counts': [len(data['parts']), len(other['parts'])],
                  'positive_meteor_events': [sum(e['amount'] > 0 and e['source'].get('spell') == 'meteor_shower' for e in d['resolved']) for d in (data, other)],
                  'resolved_meteor_totals': [sum(e['amount'] for e in d['resolved'] if e['source'].get('spell') == 'meteor_shower') for d in (data, other)]}
        if not parity['plan_equal'] or not parity['distinct_modes']:
            errors.append('paired gameplay plan/modes invalid')
    print(json.dumps({'errors': errors, 'known_bad': controls, 'parity': parity}, indent=2))
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
