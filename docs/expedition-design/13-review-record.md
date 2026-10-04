# Review record and remaining gates

**28 September update:** the review below is historical evidence for the original draft. Its 17-spell first-slice schedule is superseded by [development order](15-development-order.md): modify existing spells in the current fun game first. Current direction uses readable inscriptions and wizard fantasy. This documentation review is not a new gameplay validation.

27 September 2026. Documentation-only review against prototype baseline `0cb22e90f4d4a2e8416c1d3e2dfe5c73d1c1ca6c`.

## Completed

- Read-only source audit distinguished 16 learnable bases, seven enabled combinations, one automatic attack and inactive data definitions.
- Independent inventory review confirmed all old spell-table names and recorded modifier phrases remain represented.
- Proposed campaign reconciles 29 prepared bases plus seven derived combinations, with all acquisition sources accounted for and 14 words distributed through tutorial/realms.
- Three independent review passes addressed tick settlement, compatibility authority, repeat clocks, workload units, coherent healing refresh, starting-loadout deadlock, variant gates, tutorial access, first-slice grants and repeated-reward policy.
- Same-role incantation review caught Firestorm incorrectly outperforming the longer Cinder Field; its proposal is now a shorter moving field with lower total dwell damage. Yggdrasil's stronger healing is positional and destructible; that tradeoff still needs player evidence.
- Twelve documentation tests pass, including a known-bad missing-spell control. Python syntax and whitespace checks pass. No gameplay tests were run because this task does not change gameplay.

## Not proven or approved by this document

1. D01–D14 remain product-review choices. Most sensitive: automatic Magic Missile, death retention, six prepared pages, all learned words versus prepared words, the three-second abandoned-attempt fallback, bounded map interpretation and the hard boss deadline.
2. The opening mana curve is not feasible at its optimistic target pace for a slow Bolt → Life route. The progression chapter records the arithmetic and requires a comparison of threshold/pickup alternatives before production tuning.
3. The route-length target requires a substantial detour factor. Validate in a plain blockout and shorten it if it creates filler walking.
4. Spell coefficients, boss HP, spawn budgets, modifier caps and impact timings are concrete hypotheses. They have not been playtested in the new mode.
5. Duplicating on native volleys can reduce per-target damage for only modest coverage. Test and revise if it becomes a trap choice.
6. Three art directions are described; no new visual board, animation sheet or sound asset has been produced or approved. Existing generated assets are not removed.
7. The full 36-spell campaign is expansion scope. First slice is 17 identities: real tutorial/Verdant content plus a separately labeled Meteor Shower and later-keyword test profile.

The implementation team should be able to build a coherent experiment from this package once the product decisions are reviewed. The document does not claim the entire campaign is already balanced, implemented or ready to export.

## Alignment review — 28 September 2026

Reviewed all 15 numbered design documents, the package index, current roadmap, root README and publishing entry point against the latest conversation and read-only local working diffs. Historical runtime reports remain evidence of earlier builds, not target-design authority. Source inspection is not a new playtest.

Resolved: fresh-build milestones, separate-mode prerequisite, obsolete 17-spell migration gate, keycap presentation requirements, working-title discoverability, current-fun versus future-validation distinction. The current first increment is Big/Powerful on existing representative spells in actual combat; existing content stays available.

Explicit reconciliation queue before dependent implementation:

| Topic | Current truth / remaining decision |
|---|---|
| XP and mana | Local GDD calls mana accumulated experience; local decision notes keep XP for upgrades. Resolve whether these are one resource or two and what each unlocks; do not remove progression during M1. Numeric progression tables remain candidates. |
| Roster count | Present catalog has 29 base rows and seven derived rows. Local intention asks for 36 independent spells plus combinations; completing that scope requires a separate catalog decision, not relabeling 36 existing rows. |
| Soul Bloom / infection | Existing runtime leeches. New working identity lets player carry healing infection; root ceiling removed in proposal, host refresh and finite orphan lifetime retained. Tuning, reinfection loops and workload limits remain open; old leech numbers describe baseline only. |
| Big infection | Recent preference is actual AoE sizing; old spread-radius mapping in component tables is not an approved rule. Choose an actual visible area or explicitly reject unsupported Big before migration. |
| Meteor Spear | Impact explosion, second-hit explosion, and trailing meteorites are alternatives; select before changing its existing behavior. |
| Focus Ray | Smooth visible target tracking proposed; full-circle rotating laser is a separate deferred idea. |
| Arcane conversion | Candidate critical-hit bonus exists in local notes; amount and eligibility remain open, not implicit conversion behavior. |
| Incantation tiers | Ice Spear/Glacial Spear shared family accepted; generic Wall plus stronger elemental synonyms remains an experiment. |
| Art | Inscription direction confirmed; exact font, palette, floor layout and animation require a small visual sample/user sketch. No requirement to replace all assets now. |

Local uncommitted working notes were read as context, not copied into or overwritten by this branch. Where they contain unresolved alternatives, this record keeps the conflict visible instead of treating the older numeric draft as settled.

### Mana framing clarification — 2026-09-28

The latest [accumulated mana proposal](03-spells.md#accumulated-mana-as-progression) frames mana as unspent magical power gained toward upgrade/tier thresholds, not casting fuel. This narrows the XP/mana question above; do not introduce cast costs or an extra resource bar. Presentation, threshold details, run persistence and future expedition reconciliation are still open. No current progression behavior changed.
