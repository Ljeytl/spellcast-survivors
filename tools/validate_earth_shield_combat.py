import copy
import json
import sys


def validate(data):
    assert not data['failures']
    assert data['casts'] == 3 and data['restored']
    assert len(data['blocks']) >= 2
    sources = []
    for block in data['blocks']:
        assert block['before'] - block['after'] == 1
        assert block['context']['blocked']
        assert block['health_before'] == block['health_after']
        assert len(block['consumed_sources']) == 1
        source = block['consumed_sources'][0]['cast_id']
        sources.append(source)
        eruptions = [e for e in data['eruptions'].values()
                     if e['source']['cast_id'] == source
                     and abs(e['spawn']['frame'] - block['frame']) <= 1]
        assert len(eruptions) == 1
        direct = [h for h in data['retaliation']
                  if h['source']['cast_id'] == source
                  and h['source'].get('via') != 'bleed'
                  and h['amount'] > 0 and h['frame'] >= block['frame'] - 1]
        assert direct
    assert len(set(sources)) == len(sources)
    assert any(e['charges'] == 0 and e['amount'] > 0 for e in data['damage_events'])
    assert len(data['secondary_contacts']) == 2
    assert all(data['secondary_contacts'].values())
    assert data['moving_enemies'] >= 2 and data['player_travel'] > 100 and data['warnings'] > 0
    assert data['frames'][-1]['health'] > 0
    assert all(not f['invincible'] and not f['paused'] and f['time_scale'] == 1 for f in data['frames'])


def main():
    data = json.load(open(sys.argv[1]))
    validate(data)
    controls = []
    bad = copy.deepcopy(data)
    bad['blocks'][0]['health_after'] -= 1
    controls.append(('damaging block', bad))
    bad = copy.deepcopy(data)
    bad['blocks'][0]['consumed_sources'][0]['cast_id'] = -1
    controls.append(('unrelated eruption', bad))
    bad = copy.deepcopy(data)
    bad['retaliation'] = [h for h in bad['retaliation'] if h['source'].get('via') == 'bleed']
    controls.append(('bleed without direct retaliation', bad))
    bad = copy.deepcopy(data)
    bad['damage_events'] = []
    controls.append(('no exhaustion damage', bad))
    bad = copy.deepcopy(data)
    bad['secondary_contacts'][next(iter(bad['secondary_contacts']))] = []
    controls.append(('one missing secondary contact', bad))
    for name, bad in controls:
        try:
            validate(bad)
        except AssertionError:
            continue
        raise AssertionError('Known-bad control passed: ' + name)
    print('Earth Shield: native evidence passed; %d known-bad controls rejected' % len(controls))


if __name__ == '__main__':
    main()
