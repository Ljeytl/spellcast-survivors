# Style, combo and scoring — review draft

28 September 2026. Design and concept art only. No scoring implementation is authorized by this document; review the unresolved choices before coding. Applies to the current roguelike alpha, not the future expedition conversion.

## Intent and agreed direction

Fight well enough to maximize a stylish casting combo. Long incantations, fast execution, clean typing and varied spells should feel rewarding. Repeated Bolt remains useful; repetition earns less extra reward rather than subtracting score. The inspiration is the pressure and celebration of action-game style ranks, not a literal copy of another game's rules.

- Rank ladder: **F, E, D, C, B, A, S, SS, SSS**.
- Separate current **combo score** from accumulated **run score**.
- Manual casting drives combo. Passive Mana Bolt firing/hitting does not sustain it.
- Longer canonical incantations earn more; fast typing earns a bonus relative to their length.
- Typos reduce that cast's execution bonus, not the entire combo.
- Repetition has diminishing extra reward. Alternating only two or three spells must not fully restore freshness.
- Inactivity causes decay, stronger at higher ranks. Taking damage can drop a grade; exact treatment is a proposal.
- S rank provides access to a special spell. Doom, Nuke and Atomic are name ideas, not selected spells.
- A special-spell cost around **1,000–2,000 points** is desired for exploration. Which resource pays it remains to be agreed; direct combo spending is the latest candidate, replacing the earlier charge proposal unless chosen otherwise.
- V1 leaderboard is local. Online competition and verification are deferred.

These are scoring rules. No ordinary combat-stat changes are part of this feature.

## State model

| State | Meaning | Lifetime |
|---|---|---|
| Combo score C | Current style meter; determines rank and multiplier | Builds on manual casts; decays and can fall on hits; resets each run |
| Run score R | Banked points for the leaderboard | Only increases during the run; finalized on death or victory |
| Rank | Lookup of C in threshold table | Derived, not a second independent meter |
| Spell freshness f[id] | Available variety bonus for each canonical spell family | Run-local; consumed by using that family, recovers through other successful casts |
| Cast attempt | Start/completion time, mistake episodes, canonical ID, receipt ID | One manual casting attempt |
| Statistics | Peak rank/combo, clean casts, manual casts, special casts | Run-local, saved with result |

Do not add a third permanent currency or a charge meter by accident. Charge storage, direct combo cost and run-score cost are alternatives; the proposed first test below uses combo cost only.

## Proposed scoring calculation

All coefficients below are tunable candidates, not user-approved balance values.

**Length points B = 10 + 2L + 0.5L².** L counts letters in the canonical accepted incantation. Spaces/case, extra whitespace, correction keystrokes and submission keys contribute nothing. Known stronger incantation tiers can have different lengths; convenience aliases use canonical identity. Future modifier words count only when actually accepted and applied.

| Example | L | B |
|---|---:|---:|
| Bolt | 4 | 26 |
| Ice Blast | 8 | 58 |
| Cross Blade | 10 | 80 |
| Regeneration | 12 | 106 |
| Meteor Shower | 12 | 106 |

### Speed relative to length

Measure active, unpaused real seconds T from the first letter until the final valid spelling is completed, including correction time. Snapshot timing for the final text revision; editing afterward recomputes completion. Submit delay does not earn speed but remains exposed to decay. Rejected input/cancel does not award points. Slowdown does not stretch the scoring clock.

Candidate reference pace: **p = 4 letters/second**. First-to-last-letter timing spans L−1 intervals: reference time is (L−1)/p and measured pace v = (L−1)/max(T, 0.25), while commitment still uses all L letters. Single-letter incantations, if introduced, need a separate timing rule; they receive no speed bonus by this draft. Proposed speed bonus fraction:

**s = clamp((v/p − 1) × 0.5, 0, 0.5).**

At 4 letters/sec or slower, no speed bonus is lost from base points. At 6 letters/sec, add 25% of B; at 8 or faster, add 50%. Because it scales B, executing a longer spell at the same pace yields more bonus points. Reference pace/cap need testing across real players, especially short-spell timing noise.

### Clean execution

Candidate clean bonus c: **0.25 for no mistake episodes, 0.10 for one, 0 for two or more**. A mistake episode begins when an edit leaves no valid prefix among currently castable incantations; additional letters in that invalid episode do not each count as new errors. Returning to a valid prefix closes it. Backspace alone is not a mistake. Partial words shared by multiple spells remain valid. IME composition is assessed after committed text. Misspellings that happen to form another valid spell cannot reliably be inferred as mistakes.

Cancel/restart awards nothing. Proposed, explicitly open: restarting resets attempt execution statistics, but not the combo clock or freshness. A player can abandon a typo attempt to retry for a clean bonus, paying time/decay instead; compare retaining mistakes across restarts if this becomes an exploit. Correction time also reduces speed, so mistakes affect both execution bonuses naturally; assess whether that feels fair. No negative cast points.

### Spell freshness, not a last-two-casts window

Proposed f range **0–1**, initially 1 for every family. Read f before the cast, then reduce the used family by **0.50**, floored at zero. Each successful cast of another family restores **0.10** to each other family, capped at 1. Time alone does not refresh spells. Five intervening other casts replace the freshness spent by one use; ten are needed to restore a completely exhausted family.

Freshness bonus fraction **q = 0.5 × f**. Consecutive uses earn +50%, then +25%, then no freshness bonus. Two-spell alternation eventually settles near +5%; a three-spell rotation near +10%; six distinct spells can sustain +50%. This rewards a broader kit without demanding it. Aliases, passive fire, canceled casts and automatic repeat children do not restore freshness. Future modifiers of the same base spell share a family unless a deliberate exception is approved.

### Final cast award

**P = round_half_up(B × (1 + s + c + q)).**

Bonuses are additive fractions of length points to avoid accidental multiplicative inflation. Formula shape is a proposal; the length formula is the accepted starting point.

On exactly one successful manual release: calculate P; add P to C; derive the new rank; add **round_half_up(P × new-rank multiplier)** to R. Rank does not multiply its own growth. Cap overflow may still award run score. Damage, healing amount, missed targets and overkill do not recalculate this casting reward. No active-combat radius gate; enemy pressure and decay provide the context.

| Worked cast | B | Speed | Clean | Freshness | P before rank multiplier |
|---|---:|---:|---:|---:|---:|
| Bolt, 0.75 s, clean, fresh | 26 | 0 | .25 | .50 | 46 |
| Bolt, 0.5 s, clean, fresh | 26 | .25 | .25 | .50 | 52 |
| Regeneration, 2.75 s, clean, fresh | 106 | 0 | .25 | .50 | 186 |
| Regeneration, 11/6 s, clean, fresh | 106 | .25 | .25 | .50 | 212 |
| Regeneration, 11/6 s, one error, fresh | 106 | .25 | .10 | .50 | 196 |
| Repeated Bolt, 0.75 s, clean, no freshness | 26 | 0 | .25 | 0 | 33 |

## Rank, decay and damage — first-test proposal

| Rank | C threshold | Run-score multiplier | Decay points/sec |
|---|---:|---:|---:|
| F | 0 | 1 | 5 |
| E | 150 | 1.25 | 8 |
| D | 350 | 1.5 | 12 |
| C | 650 | 2 | 18 |
| B | 1000 | 2.5 | 25 |
| A | 1450 | 3 | 35 |
| S | 2000 | 4 | 50 |
| SS | 2700 | 5 | 65 |
| SSS | 3500 | 6 | 80 |

Candidate cap C=4500. These thresholds replace earlier example numbers and give a 1,000–2,000 point finisher cost a meaningful scale. They must be tested alongside actual cast cadence; they are not an approved difficulty curve.

- Proposed grace: 3 real seconds after successful manual release, then continuous decay at the current rank's rate. Integrate across rank boundaries; do not make results frame-rate dependent.
- **Open choice:** initially test decay continuing during typing. Merely opening the editor cannot freeze the bar indefinitely. If long casts feel unfairly punished, compare a bounded typing grace, not infinite stalling.
- Pause, forced upgrade selection and non-combat menus suspend clock and input scoring. Slowdown does not suspend decay. No offline/background elapsed-time decay after a proper pause.
- Proposed actual damaging hit: drop one grade while preserving fractional within-grade progress. At F clear C. Fully absorbed damage versus any hit is still open; recommendation is no drop for a fully absorbed hit. Invulnerability-rejected contacts are not multiple hits.
- Decay and damage never subtract banked run score. Record reasons so HUD and debug agree.

### Passive fire and kills

Mana Bolt firing/hitting has no style award and does not reset grace or freshness. Whether kills add ordinary run score remains **open**; the simplest initial comparison has cast-only scoring. If kill points are enabled, they must be separate from cast awards, credit each death once, and passive kills must not sustain combo. Do not silently introduce per-HP, healing or control-efficiency scoring.

## S-rank special spell — candidate, not finalized

Proposed gate: current rank S or higher; proposed cost **1500 combo points**, test against 1000 and 2000. Run score is not spent. Validate availability on release, spend once, then derive lower rank. If rank drops while typing, reject without spending and preserve entered text. Alternative eligibility locking at cast start requires a deliberate choice.

The special cast cannot directly generate combo points or score that repay its own cost. Any optional kill-score treatment needs its own decision. No free first charge, stored charges or independent charge meter in this candidate. Earlier charge-based discussion is retained as an alternative, not mixed into the same rules.

Name, canonical incantation, effect, timing and visual are open. Doom, Nuke, Atomic are ideas. One special spell is sufficient for the first playable scoring loop. Its production art is not required for scoring validation.

## HUD and art assembly

See [concept sheet](art/style-meter-stone-v2.png) and [art notes/prompt](art/README.md).

Display one large readable rank, multiplier, combo meter and a separate run-score number. A small combo value can accompany the bar. Each rank segment fills from its threshold to the next. Crossing a threshold changes the rank and restarts the visible bar with carried overflow; **C is not reset**. At SSS, fill to the cap and stay full there. Falling through a threshold reverses the same mapping. At S, show the special-spell seal and cost, not charge pips unless that design is selected.

Layer order: stone rail/endcaps → dark trough → clipped luminous incision fill → optional threshold cuts → separate rank glyph → sparse ritual-circle arcs → short event accents. Decorative glow is separate from legible text/fill. Same core meter footprint across ranks; high-rank accents must not occlude combat. Actual score digits and labels are rendered text, not baked into an atlas.

Latest art feedback: retain v2 stone/circle shapes, restore richer color, and give D/C/B/A visible but restrained color too. See the art notes for the proposed palette; the saved image is not yet recolored. Implementation remains pending agreement.

Direction: sharp angular marks scratched/chiseled into rough stone, broken magic-circle arcs, light through incisions. Simple pixel silhouettes and limited shades. Not ornate metallic Nordic bezels, keycaps or generic serif fantasy badges. Rank letters must remain readable; a real rune alphabet is not substituted for game information.

Rank-up and successful cast briefly accent the bar; hit gets a clear down-rank response; typos only affect the current execution-bonus cue. Never label repeated Bolt a punishment. Higher ranks intensify the same motif instead of covering more screen. Reduced motion/flash keeps rank and values immediate. Animation cannot hold up scoring or input.

The sheet is one opaque concept board with isolated parts and assembled examples, not a validated transparent sprite atlas. Components need manual slicing/redrawing and in-game scale review before use. No generated graphics are installed in runtime by this task.

## Local leaderboard and result record

V1 saves local score history and personal bests. Minimum record: unique run ID, scoring schema/rules version, build version, seed/level, gameplay settings, outcome, duration, run score, peak rank/combo, manual/clean cast counts, special uses and final build. Record settings, not raw typed mistakes. Different rulesets have separate comparison boards; debug and bot runs are excluded or separately labeled.

Finalize once on victory/death; retry/new run clears all run-local scoring state. Persist atomically with a recoverable prior save. Crash recovery and abandoned-run eligibility need a decision; proposed v1 submits only normal terminal outcomes. No accounts, network upload or multiplayer in v1. Future online score verification and daily challenges are separate scope.

## Implementation boundary and verification plan

Adapt current gameplay; do not rewrite spells or progression. Suggested responsibilities (not mandatory filenames): score configuration, pure scoring state, manual-cast receipt adapter, damage/pause adapter, HUD and local result store. Spell code reports events, not rank arithmetic. Deduplicate release events by cast receipt; triggered repeats, projectile children, passive attacks and workshop casts cannot masquerade as manual inputs. Inspect current dispatch/input paths before choosing hooks.

Implementation order after agreement: deterministic scoring state → real input/cast/damage hooks → basic HUD → local result board → one selected special spell → rendered art/feel pass. Each stage remains playable. Enemy-pressure tuning supports meaningful scoring but is a separate measured change.

Required cases: fast/slow same spell; typo/correction and ambiguous prefixes; no whitespace inflation; cancel/reopen; short/long casts; repeated Bolt; two-/three-/six-family rotations; inactive spell rejection; duplicate callbacks; passive-only run; pause/level-up/slowdown clocks; decay across ranks; cap/overflow; hit while casting; finisher cost/rejection; death/retry/save/reopen; debug exclusion; readable long text at narrow geometry. Prove deliberate bad implementations fail (passive refresh, doubled award, decay during pause).

Playtest comparison: existing game versus scoring build under comparable seeds/builds. Watch whether players vary casts voluntarily, chase longer casts, understand losses, recover from mistakes and care about their final score. Also test a fresh Bolt-only start: its limited variety must not prevent basic progress or make the opening feel scolded. Do not judge style by bot survival alone.

## Decisions to approve before implementation

1. Additive bonus formula, pace reference/cap and clean-bonus schedule.
2. Freshness recovery per other cast (proposed depletion .50, recovery .10), and canonical family mapping.
3. Thresholds, grace, decay during typing and fully absorbed-hit treatment.
4. Cast-only run score versus separate kill points.
5. Direct combo cost versus stored charge model; exact special spell identity and cost.
6. Art legibility, scale and slicing; the revised sheet is not automatically approved.

All numbers are initial proposals; no runtime scoring is claimed implemented or tested by this document.
