# Wizard tower home

## Approved scope

Title Play → walkable tower → selected Level 1 doorway → run → death/extraction results → tower. Endless Continue stays inside the current run. Pause Retry remains a direct fresh-run restart; pause Menu still opens the title. This preserves the existing pause semantics deliberately.

The central floor, room-sized red carpet, cyan orb pedestal, tome, bed and table stay fixed. Twelve outer arches, continuous masonry and doorway book blockers rotate together. The top doorway is selected; only the woodland Level 1 portal is available. Blank destinations cannot start runs. Bookcase/pile removal on future unlocks is reserved, with no invented unlock rules.

WASD/arrows move. E near the orb enters rotation control; Left/Right or A/D steps one doorway at a time. Repeated presses during a turn are ignored. E or Escape leaves the orb after it settles. Movement is disabled while operating it, keeping the player on the safe central floor. The selected Woodland corridor extends through its physical arch; crossing the top threshold starts the run once. E at the tome opens existing Necronomicon; its controls consume input and room movement stops until it closes. Escape elsewhere returns to title.

## Structure

- `Tower.gd`: room assembly, independent hub avatar, interaction/input, camera fit, doorway selection and departure.
- `TowerArt.gd`: cached atlas regions; upright sprites switch view rather than spinning flat images.
- `TowerRing.gd`: low continuous stone rim with moving mortar joints behind authored arches.
- `Tower.tscn`: hub scene entry.
- `Game.gd`: separate result-return callback, leaving pause retry behavior intact.

Furniture uses static collision bodies on the existing scenery layer. The circular perimeter constrains walking except the active top exit corridor. Decorative outer book blockers move with their arch; they are outside the traversable boundary rather than dynamic pushable bodies.

## Art provenance and limits

`assets/tower/tower-atlas.png` is a transparent sprite atlas derived from both approved concept sheets: grey mossy stone, crimson/gold carpet, cyan orb, colorful books and modest pixel detail. Generated layout did not follow exact grid spacing, so explicit measured regions avoid adjacent-cell bleeding. Regions are cached and updated only during rotation. Transparent RGB can look like shaded fog in preview tools, but runtime alpha is respected.

Generation brief: preserve the approved simple pixel style; isolate bare round floor, crimson carpet, orb, tome, blank arch front/diagonal/rear, woodland arch front/diagonal/rear, shelf, book pile, table and bed on transparent alpha; no labels or assembled preview. A second rear-only arch (`rear-arch.png`) removes the projecting front sill and emphasizes overhead stone tops.

Approved source references were `exec-dd92b541-9c9c-483a-9c15-4fd2546dd987.png` and `exec-ac003ca2-23db-4ea4-90b3-38ca604daa17.png` from the conversation's generated-image library. The project contains the usable derived assets, with no runtime dependency on that external library.

Remaining art work: more intermediate perspective frames for smoother rotating architecture, authored curved wall segments instead of the simple joining rim, and additional room dressing. This implementation intentionally uses discrete views and placeholder joining masonry; it does not claim a fully animated 3D tower.

## Verification

Run tests with the isolated `SpellCast Survivors Synergy Test` custom user directory. Remove override.cfg afterwards.

- `tests/tower_regression.gd`: collisions plus deliberately disabled-mask negative control; ring selection; invalid doorway rejection; tome state; death/extraction and fresh repeated runs; duplicate-finalization progression guard.
- `tests/tower_journeys.gd`: real key events through title, walking to orb, turning, tome, walking into the top arch, results and home/title. Native screenshots at desktop and 480×720 include rotation, archive, doorway and results.
- `tests/ui_ux_journeys.gd`: adapted expected results routes; existing menu/pause/casting/upgrade journeys remain.
- `tests/run_ending_regression.gd`: extraction versus endless continuation and existing result persistence. Updated its obsolete strictly-growing cadence assertion: cadence respects the existing cap while group size and enemy stats continue growing. MonsterManager and encounter data are unchanged from the integration baseline.

Native screenshots and command logs are retained under ignored builds/tower-evidence for candidate review. Browser/itch, Windows and touch input are not verified by these native tests. No refreshed export is included in this change.

### Verification disposition

On implementation revision `ae23c3c`, the tower regression passed 27 checks, run-ending regression passed 65 checks, and native operated tower journeys passed 17 checks (109 total). The sibling `ui_ux_journeys.gd` sweep passed 119 of 120 checks: **`Options Back fits (480, 640)` remains failed/open**. That Options layout is outside this tower implementation and its source is unchanged from main; the sweep is not reported as fully passed. Evidence: `builds/tower-evidence/ui-sibling-sweep.log`. The actual tower desktop/narrow journeys, archive heading and result transitions pass.

The later integration of main's version-only 0.1.42 change is verified with fresh tower regression and operated journey runs; final candidate/revision and logs accompany the retained evidence directory. Windows/browser/itch remain unverified. This is a scoped tower gate, not a claim that every existing application surface is free of layout defects.

Native journey input uses a non-focusing offscreen window and logs/reasserts injected held keys if OS focus events release their physical state. This avoids lost synthetic holds during resize/archive transitions without bypassing movement, collision, input handlers or route-distance assertions. Initial native reruns exposed this harness issue; those failures were investigated before rerunning the full operated route.
