# Expedition design and release plan

Updated 14 October 2026 for **0.3.0**. Start with the complete spell catalog and release plan below. The earlier overlapping catalogs and milestone descriptions have been consolidated; old numbered URLs remain navigation links, and their original content is retained in a clearly dated archive.

## Current documents

| Document | Owns |
|---|---|
| [Full spell catalog](03-spells.md) | Every implemented, authored, paused, open, reserved and rejected identity; aliases and deferred new combination themes. |
| [Release plan and expedition roadmap](15-development-order.md) | Agreed release goals and version numbers, combat-feel work, the full catalog implementation track, enemies/tutorial, expedition loop, dependencies and open product decisions. |
| [Spell feel and shared mechanics](18-spell-system-rewrite.md) | Complete caster-to-aftermath spell scripts, sound, camera, motion, readability, open behavior decisions and review criteria. |
| [Spell engine architecture](19-engine-architecture.md) | Signed-off engine construction, data ownership and reusable behavior. |
| [Game systems architecture](20-game-systems-architecture.md) | Signed-off actor/enemy/boss, level/objective, save/progression and run-flow design. |
| [Damage, effects and keywords](21-damage-effects-keywords.md) | Current damage splits, elemental effects, statuses and keyword semantics. |
| [Enemy design](22-enemy-design.md) | Draft (16 October 2026): what each enemy asks of the player and its answer, the roster rules, assessment of the current roster and the proposed core roster. Architecture stays in doc 20. |
| [Expedition and director](23-expedition-and-director.md) | Agreed 16 October 2026: expedition shape (days, nightfall as the teleporter event, camp, death) and the Risk of Rain–style threat director (credits, cards, elite cost multipliers, champions, realms). |

## How to use the plan

The full catalog is preserved; no smaller spell pack has been selected. New combinations will be discussed later. Existing seven combinations remain playable. Ice/Glacial Spear and Lightning Spear/Rod are paused. The catalog directly incorporates the latest Flame Wall, Arcane Slash, Scorching Ray and Shillelagh decisions.

Implementation status and design approval are different. Runtime and data own shipped behavior; the [changelog](../../Changelog.md) records changes. Architecture approval does not mean every subsystem is implemented. The release goals and version assignments are agreed; they do not mean a release has shipped, select a smaller spell catalog or settle open mechanics. Good existing visuals remain open to timing and feel improvements.

When a decision changes, update its owning document and the changelog. Other pages link to that owner instead of copying its table. Damage/effect rules in doc 21 supersede older numbers; catalog identities in doc 3 supersede old spell descriptions. Do not use an archived campaign roster or inactive JSON as a current shipping requirement.

## Historical material

The [14 October archive](archive/2026-10-14/README.md) preserves the pre-consolidation package, including earlier realm layouts, naming provenance, component experiments, balance examples and rejected alternatives. Historical content is not active guidance. In particular, the old 36-row campaign, 14-keyword matrix and “MEGA only” roadmap are superseded.

## Documentation validation

Run `python3 docs/expedition-design/validate_documentation.py`. It checks current runtime roster/recipe coverage, preservation of authored catalog identities, paused and corrected decisions, navigation ownership, local links and table structure. A missing-catalog-entry control must fail. These checks do not certify game balance or visual quality.
