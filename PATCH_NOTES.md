# Patch notes

Player-facing changes, newest first. The current project version is **0.1.36**. **Unreleased** changes are merged into the project but have not been assigned a new version or packaged in a fresh shareable export. Older entries describe changes at the time of that version; later entries supersede their balance values.

## Unreleased — Make it MEGA

### New

- **Your first keyword: MEGA.** Type `mega bolt`, `mega life`, or another learned spell with `mega` in front for **50% more Spell Power and 50% more Spell Size**.
- MEGA works with learned spells and combinations through numbered casting or Space casting. Healing gets stronger too; larger damaging effects have matching hitboxes.
- The spellbook explains how to use MEGA. Ordinary casts remain available, and adding MEGA twice does not stack the bonus.

### Changed

- The automatic attack is now called **Magic Missile**, with **Missile Mastery** upgrades. Your manually typed **Bolt** remains a separate spell. This rename does not change the attack's behavior.
- MEGA's extra letters contribute to style rewards, but ordinary and MEGA versions share the same repetition history.
- Duration-extending spells keep one effect: recasts add their own strength and size after the current portion finishes. Existing Firewalk patches retain the strength they were created with.

Magic Missile and Atomic do not accept MEGA. Speed, duration and projectile count are unchanged by the keyword. Balance is deliberately bold for playtesting.

## 0.1.36 — Earth Shield fights back

- **Earth Shield now blocks one hit per charge**, instead of providing extra health.
- A blocked hit sends a damaging stone eruption and knockback toward the attacker, while protecting your style combo.
- Recasting adds another charge. Charges have their own lifetimes rather than refreshing the whole stack.
- Visible stone shields and updated spell descriptions make the protection easier to read.

## 0.1.35 — Bigger spells, better combinations

- Added **Spell Duration**, extending useful spell lifetimes by **10% per upgrade** without making impacts or trap arming slower.
- Spell Power improves healing as well as damage. Size and Velocity affect supported spell geometry and movement.
- All seven combinations benefit from ingredient spell levels as well as their own upgrades. Ingredients stay available and combinations use no extra active slot.
- **Lightning Bolt** creates a small lightning explosion on every hit.
- **Prism Ray** is a broad, piercing laser that rotates very slowly.
- **Soul Bloom** leaves healing areas when infected enemies die, while the infection can continue spreading.
- Ordinary enemy health-potion drops are **1%**. A separate **1%** roll can drop a style rune worth **200 combo points**, plus **200 × your current multiplier** in run score.
- Updated upgrade descriptions to make the benefits clearer.

## 0.1.31 — Seekers spread out

- Seekers choose different visible enemies when possible and retarget when an enemy dies or leaves view.
- With no target, Seekers return to the wizard; with only one enemy, they can share it.
- Combo decay now waits **five seconds** after a successful cast or the end of an active ray channel.

## 0.1.3 — Playtest checkpoint

- Unified the version shown in menus, gameplay and results, and attached it to new score records.

## 0.1.28 — Keep the pressure on

- At this version, each style-rank step required **800 raw combo points**. Rank multipliers increased run score rather than speeding rank progression.
- Raised Atomic's cost to **10,000 combo points**.
- Improved enemy refill after clearing crowds. Spawn cadence and group sizes ramp together.
- Simultaneous Focus and Prism rays choose different targets when available. Prism's piercing beam reliably damages enemies along its width.
- Combo decay pauses during active ray channels, including retargeting gaps.
- Lightning Bolt starts with **four additional bounces** and gains another with each rank.
- Refined the carved-stone style meter and ray endings.

A subsequent unversioned tuning change disabled extra difficulty escalation from sustained clearing. Timed difficulty and normal enemy refill remain active; clearing quickly does not currently add that extra escalation.

## 0.1.27 — Style, score, and Atomic

- Added **F–SSS style ranks**, a combo meter, and separately banked run score.
- Longer incantations, clean execution, typing speed and spell variety contribute to style. Repeated spells earn less; taking health damage drops a grade, and inactivity causes decay.
- Added **Atomic**, an S-rank screen-clearing spell with a visible warning. Its initial cost was later increased in 0.1.28.
- Added local high scores and end-of-run summaries. Assisted runs are excluded from the leaderboard.

## 0.1.26 — Extract or keep going

- At **20 minutes**, choose to extract with a victory or continue the same run under increasing pressure.
- Firewalk and other ground effects render beneath the wizard.
- Removed routine instructional clutter from the normal HUD while retaining the casting reference and duration indicators.

## 0.1.25 — Keep your spells going

- Recasting Arcane Orbit, Firewalk and Regeneration extends their active time instead of unnecessarily replacing them.
- Firewalk extends the time you leave fire behind; old patches keep their existing lifetime.
- Added active-duration, instance-count and trap-state information to the casting reference.
- Earth Shield also used duration extension in this version; its charge-based redesign arrived in 0.1.36.

---

This player-facing history starts with the recent reliably versioned playtests. It preserves recorded version labels—including `0.1.3`—without inventing missing releases. Development details and older history remain in [Changelog.md](Changelog.md).

For future updates: add implemented player-visible changes under **Unreleased** as they land. When preparing a release, assign the agreed version, move those notes under it, and verify the packaged build carries that version. Keep unreleased design ideas in the roadmap.
