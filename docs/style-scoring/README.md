# Style, combo and scoring — first playable specification

28 September 2026. Implementation authorized by “alright lets build it baby.” First playable implementation: 0.1.27. Applies to the current roguelike alpha, not the future expedition conversion. Numerical values below are the first-test defaults, still open to playtest tuning.

## Intent and agreed direction

Fight well enough to maximize a stylish casting combo. Long incantations, fast execution, clean typing and varied spells should feel rewarding. Repeated Bolt remains useful; repetition earns less extra reward rather than subtracting score. The inspiration is the pressure and celebration of action-game style ranks, not a literal copy of another game's rules.

- Rank ladder: **F, E, D, C, B, A, S, SS, SSS**.
- Separate current **combo score** from accumulated **run score**.
- Manual casting drives combo. Passive Magic Missile firing/hitting does not sustain it.
- Longer canonical incantations earn more; fast typing earns a bonus relative to their length.
- Typos reduce that cast's execution bonus, not the entire combo.
- Repetition has diminishing extra reward. Alternating only two or three spells must not fully restore freshness.
- Inactivity causes decay, stronger at higher ranks. Health damage drops one grade while preserving progress inside that grade.
- S rank provides access to **Atomic**, selected by the user as “a fucking nuke to the screen.”
- Approved Atomic cost: **10,000 combo points**. No separate charge meter.
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

## Scoring calculation — first-test defaults

All coefficients below are the tunable implementation defaults. They are not a claim of finished balance.

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

## Rank, decay and damage — first-test defaults

| Rank | C threshold | Run-score multiplier | Decay points/sec |
|---|---:|---:|---:|
| F | 0 | 1 | 5 |
| E | 100 | 1.25 | 8 |
| D | 300 | 1.5 | 12 |
| C | 700 | 2 | 18 |
| B | 1300 | 2.5 | 25 |
| A | 2100 | 3 | 35 |
| S | 3100 | 4 | 50 |
| SS | 4300 | 5 | 65 |
| SSS | 5700 | 6 | 80 |

Approved playtest revision: rank gaps are 100, 200, 400, 600, 800, 1,000, 1,200 and 1,400 unmultiplied combo points (0.1.41). The cast formula is unchanged; only banked run score receives the rank multiplier. Combo caps at 12,000 as an initial tunable ceiling, allowing 10,000-point Atomic purchases after reaching SSS. Human playtesting still determines final pacing.

- Proposed grace: 5 real seconds after successful manual release, then continuous decay at the current rank's rate. Integrate across rank boundaries; do not make results frame-rate dependent.
- **First playable:** decay continues during typing. Merely opening the editor cannot freeze the bar indefinitely. If long casts feel unfairly punished, compare a bounded typing grace, not infinite stalling.
- Finite active Focus Ray / Prism Ray channels suspend decay, including target-death and retarget gaps. After the final active channel ends, restart the normal five-second grace. Channel ticks award no additional cast points; traps, summons, fields and other lingering effects do not suspend decay.
- Pause, forced upgrade selection and non-combat menus suspend clock and input scoring. Slowdown does not suspend decay. No offline/background elapsed-time decay after a proper pause.
- Proposed actual damaging hit: drop one grade while preserving fractional within-grade progress. At F clear C. Fully absorbed damage does not drop rank. Invulnerability-rejected contacts are not multiple hits.
- Decay and damage never subtract banked run score. Record reasons so HUD and debug agree.

### Passive fire and kills

Magic Missile firing/hitting has no style award and does not reset grace or freshness. The first playable uses cast-only scoring. Kill points remain a possible later comparison. If kill points are enabled, they must be separate from cast awards, credit each death once, and passive kills must not sustain combo. Do not silently introduce per-HP, healing or control-efficiency scoring.

## S-rank special spell — Atomic

Gate: current rank S or higher AND at least **10,000 combo points**. Cost: **10,000 combo points**. Run score is not spent. Validate availability on release, spend once, then derive lower rank. If rank drops while typing, reject without spending and preserve entered text. Alternative eligibility locking at cast start requires a deliberate choice.

The special cast cannot directly generate combo points or score that repay its own cost. Any optional kill-score treatment needs its own decision. No free first charge, stored charges or independent charge meter in this candidate. Earlier charge-based discussion is retained as an alternative, not mixed into the same rules.

**Incantation:** `atomic`, through Space → type → Enter (also available in freeform mode). It takes no equipped slot. At release, capture the visible world rectangle. Draw a gold boundary and growing ritual seal for 0.65 game seconds, then clear ordinary enemies and hostile projectiles inside that locked footprint. Bosses take 60% maximum health as an initial tuning choice, which can kill an already wounded boss. Normal death/drop handling remains intact. Enemies outside the footprint survive.

The flash and rectangular shockwave last up to 0.85 seconds; the damage happens once on impact, not as an expanding second damage sweep. Camera movement does not move the damage region. Pause freezes warning/impact. Reduced effects suppress the bright flash and shake while keeping the warning boundary and impact visible. This is simple procedural placeholder VFX.

## HUD and art assembly

See [concept sheet](art/style-meter-stone-v2.png) and [art notes/prompt](art/README.md).

Display one large readable rank, multiplier, combo meter and a separate run-score number. A small combo value can accompany the bar. Each rank segment fills from its threshold to the next. Crossing a threshold changes the rank and restarts the visible bar with carried overflow; **C is not reset**. At SSS, fill to the cap and stay full there. Falling through a threshold reverses the same mapping. Show the special-spell seal only when both rank and cost requirements are met. Reaching S alone does not show Atomic as ready.

Layer order: stone rail/endcaps → dark trough → clipped luminous incision fill → optional threshold cuts → separate rank glyph → sparse ritual-circle arcs → short event accents. Decorative glow is separate from legible text/fill. Same core meter footprint across ranks; high-rank accents must not occlude combat. Actual score digits and labels are rendered text, not baked into an atlas.

Art uses the colored transparent [runtime atlas](../../assets/ui/style-runes/README.md): carved rank glyphs, clipped colored meter fill and Atomic seal. D/C/B/A retain color; higher ranks intensify it. Existing menu art is unchanged.

Direction: sharp angular marks scratched/chiseled into rough stone, broken magic-circle arcs, light through incisions. Simple pixel silhouettes and limited shades. Not ornate metallic Nordic bezels, keycaps or generic serif fantasy badges. Rank letters must remain readable; a real rune alphabet is not substituted for game information.

Rank-up and successful cast briefly accent the bar; hit gets a clear down-rank response; typos only affect the current execution-bonus cue. Never label repeated Bolt a punishment. Higher ranks intensify the same motif instead of covering more screen. Reduced motion/flash keeps rank and values immediate. Animation cannot hold up scoring or input.

The original opaque concept board remains design history. The separate transparent runtime atlas supplies named Godot regions; actual rank/score text is rendered dynamically.

## Local leaderboard and result record

V1 saves local score history and personal bests. Minimum record: unique run ID, scoring schema/rules version, build version, seed/level, gameplay settings, outcome, duration, run score, peak rank/combo, manual/clean cast counts, special uses and final build. Record settings, not raw typed mistakes. Different rulesets have separate comparison boards; debug and bot runs are excluded or separately labeled.

Finalize once on victory/death; retry/new run clears all run-local scoring state. Persist atomically with a recoverable prior save. Crash recovery and abandoned-run eligibility need a decision; proposed v1 submits only normal terminal outcomes. No accounts, network upload or multiplayer in v1. Future online score verification and daily challenges are separate scope.

## Implementation boundary and verification plan

Adapt current gameplay; do not rewrite spells or progression. Suggested responsibilities (not mandatory filenames): score configuration, pure scoring state, manual-cast receipt adapter, damage/pause adapter, HUD and local result store. Spell code reports events, not rank arithmetic. Deduplicate release events by cast receipt; triggered repeats, projectile children, passive attacks and workshop casts cannot masquerade as manual inputs. Inspect current dispatch/input paths before choosing hooks.

Implementation order after agreement: deterministic scoring state → real input/cast/damage hooks → basic HUD → local result board → one selected special spell → rendered art/feel pass. Each stage remains playable. Enemy-pressure tuning supports meaningful scoring but is a separate measured change.

Required cases: fast/slow same spell; typo/correction and ambiguous prefixes; no whitespace inflation; cancel/reopen; short/long casts; repeated Bolt; two-/three-/six-family rotations; inactive spell rejection; duplicate callbacks; passive-only run; pause/level-up/slowdown clocks; decay across ranks; cap/overflow; hit while casting; finisher cost/rejection; death/retry/save/reopen; debug exclusion; readable long text at narrow geometry. Prove deliberate bad implementations fail (passive refresh, doubled award, decay during pause).

Playtest comparison: existing game versus scoring build under comparable seeds/builds. Watch whether players vary casts voluntarily, chase longer casts, understand losses, recover from mistakes and care about their final score. Also test a fresh Bolt-only start: its limited variety must not prevent basic progress or make the opening feel scolded. Do not judge style by bot survival alone.

See [verification coverage and reproduction](VERIFICATION.md) for the operated release checks.

## First playable decisions and remaining tuning

- Additive bonuses, 4-letter/sec reference, 50% speed cap and the documented freshness schedule are implemented.
- Decay continues during typing after the 5-second grace; game pauses and upgrade selection freeze it.
- Health loss drops one grade preserving segment progress. Fully absorbed shield damage does not.
- Cast-only run score; no kill/heal/HP efficiency points.
- Current S rank is required at Atomic release; spending does not refresh grace or freshness and does not award score.
- Cancel/restart resets attempt mistakes and timing, but not existing combo decay or freshness.
- Bot runs, console mutations and invincibility are ineligible for the local board. Cosmetic debug display alone does not change eligibility. Eligibility cannot be restored by toggling cheats back off.
- The result record includes rules version, build version, outcome, duration, final kit, character level, presentation/gameplay mode settings and cast statistics. A reproducible map seed is not currently available in the game and is not invented for the record.
- No abandoned-run or crash recovery submission. Local score files are player-owned; online anti-cheat and server verification are deferred.

Next: human playtests of rank cadence, short starter-kit rewards, six-spell rotation, readability and whether Atomic feels worth sacrificing rank. Tune thresholds, decay and boss damage from those sessions. Online leaderboards, stored charges, additional finishers, final VFX/audio and richer score-detail browsing remain later work.

### Scoring revision 3

The progressive rank curve and unchanged 10,000-point Atomic use `user://style_scores_v3.json`. Prior revision-1 and revision-2 scores remain on disk and are not mixed into this balance revision.
