# Typed magic: core fantasy and possible directions

Date: September 26, 2026
Status: Historical discussion and saved alternatives. The creator has since explicitly chosen to retain the current survivors premise and not pivot now. Current agreed direction, including per-cast slowdown and Multicast, is recorded in [the core design](CORE_GAME_DESIGN.md). These notes do not implement mechanics.

## The idea worth preserving

The player types spells while a horde threatens them. Powerful magic promises a bigger payoff, but there is not enough time to do everything safely. The central tension is choosing between staying alive through movement and committing to damage through casting.

The creator specifically defended the panic of that choice when a defense-game alternative was proposed. Movement and typing competing for attention may be part of the appeal, rather than simply an inconvenience to eliminate.

A possible short pitch, synthesized from the discussion rather than quoted from a separate account given to friends:

> You're a wizard fighting a horde by typing spells. You can keep running, or stop long enough to cast something that might save you. The dangerous moment is deciding whether to finish the incantation or flee.

### Creator’s fuller explanation

The following records the creator’s subsequent four-part explanation; the short pitch above remains an assistant synthesis.

1. **Original loop:** hordes arrive, the player walks around and dodges them, and frantically types spells. Longer spells are intended to be more powerful while the player handles large crowds.
2. **Possible different format:** the same loop might work in a siege or a tower-defense-like game, with Plants vs. Zombies offered as a reference for the format. This is an exploration, not a selected pivot.
3. **Both emotional extremes matter:** panic when damage cannot keep up with the amount of enemies on screen, and a huge feeling of power when the right combination eradicates the crowd. The aim is to capture both through the pressure of typing—not merely to make casting stressful.
4. **New alchemist concept:** an alchemist defends a tower with roughly ten ingredients available in front of them. A potion might contain up to four or five ingredients. The proposed relationship is that more ingredients make a more potent potion but take longer to prepare, while opening more possible combinations. The player assembles and throws potions under pressure.

The ingredient counts and potency relationship are concept parameters to investigate, not implemented or finalized rules.

## Questions still open

- Is survivors-style movement essential to that panic, or can approaching enemies create enough pressure without movement?
- The original vision explicitly ties longer incantations to greater power. How should that payoff scale, and how much comes from damage, coverage, sustained effects, or safety?
- Is typing primarily execution of a known incantation, or could composing the phrase become part of choosing the spell?
- How much slowdown preserves a tense decision without making long spells unusable?
- How do we support different typing speeds without making fast typing the only viable way to play?

## Survivors direction: proposed experiments

These are assistant-proposed experiments, not settled requirements.

- Test a small kit consisting of a fast attack, a quick way to make space, and a long cast with a large payoff. Look for repeated moments of choosing whether to finish or escape.
- Give basic spells enduring value through speed and utility. A short attack can remove the runner about to interrupt the next opportunity; a pushback or trap might create that opportunity.
- Test cancellation and immediate return to movement. Abandoning a cast could cost the time already spent, while keeping retreat under the player's control. The exact cancellation cost and input behavior remain open.
- Make threats readable enough to estimate the time available. A close call should come from a chosen risk rather than an attack the player could not anticipate.
- Treat long spells as worthwhile commitments, not automatic replacements for short spells. More damage is one payoff; hitting a line, clearing an encirclement, or buying safety are other possibilities.

Current implementation context: typing stops movement, Escape cancels, and the prototype still has a shared three-second slowdown budget with a ten-second refill. The subsequent agreed design replaces that reserve with a fresh finite window per cast and duration upgrades; see the core design for the implementation boundary.

## Defense alternatives discussed

The creator raised tower-defense strategy as a possible pivot. The assistant suggested a wizard personally defending a gate as a smaller alternative to traditional tower defense.

- **Wizard holding a gate:** approaching enemies provide visible deadlines; typed spells remain the main combat action, potentially supported by wards, traps, or summons.
- **Traditional tower defense:** placement and economy become major decisions, with typed spells supporting defenses. Risk: the interesting decisions move away from casting and typing becomes a chore between them.
- **Possible prototype:** one gate, three approaches, five spells, and a short session before adding an economy or large upgrade tree.

No defense pivot was selected. The creator's counterpoint was that actively choosing between movement/survival and damage is what makes the current idea exciting. The assistant subsequently recommended testing that tension in the current survivors structure first. That recommendation is not a separate user-approved design commitment.

## Language and spell composition

The creator floated a language-related direction. The concrete vocabulary below was suggested by the assistant to illustrate it:

- `bolt`: a quick focused attack.
- `wide bolt`: more coverage.
- `piercing bolt`: reaches behind the front enemy.

Potentially, a small authored vocabulary could be learned or discovered during a run. Typing different words would change the effect, rather than merely unlock a preset attack through a longer name. Syntax, modifiers, costs, valid combinations, discovery rules, and UI are all undecided.

This is separate from the existing hidden-synergy system, where only authored recipes combine and discoveries appear in the collection. Phrase composition has not been implemented or approved as a replacement for that system.

Risks to test: remembering syntax while tracking threats, arbitrary guessing, unclear invalid phrases, and long inputs that never justify their danger. Known phrases should be easy to reference if this direction is explored.

## Alchemist defending a tower

**Source: creator-proposed concept.** This is a third expression of the same desired panic-to-power loop, alongside roaming typed magic and siege defense. It has not been selected for implementation.

### Proposed loop

Watch the approaching horde → choose ingredients → spend time preparing a potion → throw it → see whether the combination buys enough safety to prepare the next one.

Roughly ten available ingredients and four or five ingredients per potion were suggested. A more complex potion is intended to offer greater potency at a greater preparation-time cost. Combination variety and the possibility of a spectacular crowd-clearing result are central to the appeal.

### Still undecided

- Does the player type ingredient names, press ingredient hotkeys, click ingredients, or use another interaction? The concept does not yet settle how typing carries over.
- Does order matter? Can an ingredient repeat? Are recipes authored, assembled from consistent properties, or a mixture of both?
- Are ingredients always available, consumed, replenished, or discovered during a run?
- Can a partially prepared potion be thrown early, changed, or abandoned? What happens to the invested time or ingredients?
- Does the player move, aim at locations, choose lanes, or operate from a fixed position?
- What protects the tower while preparing, and how is failure determined?
- Do short recipes remain useful through speed even when longer recipes are more potent?

### Assistant assessment and possible experiment

The promising distinction is that preparation could contain strategic choices: the player constructs a response while time runs out, rather than only reproducing a spell name. That is a hypothesis, not demonstrated fun.

The main risks are too much recipe memorization, outcomes that feel arbitrary, and one best long recipe crowding out the rest. Having many possible combinations does not automatically mean having many worthwhile decisions. More ingredients can improve raw potency while short recipes retain practical value because they are ready sooner.

One possible small prototype would use a single threatened gate, a handful of ingredients, and a few deliberately understandable interactions. Test the choice between throwing a simple potion immediately and taking the time to finish a stronger one. No crafting economy, full recipe catalog, or pivot is approved by recording this suggestion.

## What to observe before committing

- Do players deliberately make space before a large cast?
- Do they sometimes abandon a cast to survive, without feeling trapped by the controls?
- Does completing a risky cast visibly repay the commitment?
- Do short spells stay useful after stronger magic becomes available?
- Does slowdown preserve a gamble, or remove it entirely?
- Is panic exciting and readable across different typing speeds?
- Does a successful combination produce the intended swing from being overwhelmed to feeling overwhelmingly powerful?
- For alchemy, are ingredients chosen because of their effects, or does the player simply repeat the longest memorized recipe?

Bot runs can reveal mechanical failures and patterns of damage. They cannot establish the human feeling of panic, satisfaction, or control. Any broader pivot should follow a small comparison prototype and actual player feedback.

## Saved friend concepts — September 26, 2026

Status: documentation only, saved at the creator’s request. These are future ideas, not approved implementation or changes to the current twenty-minute immediate-win rule.

### Discoverable map locations and typing rituals

The creator’s framing: reach a point on the map, unlock it, and earn something exciting. This could make traversal lead to optional rewards in addition to surviving the horde.

- **The Floorman:** an ability or ritual prompts the player to type roughly five difficult, unusually long words in sequence within a time limit, potentially laying down leylines.
- **Fro:** the difficult-word sequence could be `incomprehensible → photosynthesis → circumstantial → electromagnetism → misinterpretation`.
- **The Floorman:** `antidisestablishmentarianism` is another example of an extreme typing challenge.
- **Fro:** attach risk to the reward, potentially delaying XP gain or losing XP entirely. These are alternative penalty ideas, not an agreed rule. The original suggestion does not specify which XP is at stake, how much, or whether the cost comes from starting, failing, or abandoning the challenge.

Open decisions: what is unlocked or awarded; how locations are discovered; what leylines do; whether the challenge is optional; whether enemies keep moving and existing casting slowdown applies; the time limit and word selection; cancellation and retry rules; the exact XP risk. No answers are implied by saving the concept.

### Mouse final boss and keyboard-versus-mouse lore

- **Fro:** make the computer mouse the final boss.
- **The Floorman:** contrast a mouse boss with unrestricted movement direction and only two kinds of attacks against a keyboard-controlled player with four directional inputs and many attacks.
- The four-direction comparison is the friend’s conceptual framing, not a request to remove diagonal movement or change current controls. The two mouse attacks are not yet specified.
- **The Floorman:** possible keyboard Easter egg—have as many spells as there are keys on a normal keyboard. The keyboard layout, number of spells, and whether this means the total catalog remain undecided; this does not alter the five-equipped-spell limit.
- **Fro:** use the matchup as a skill-versus-speed motif: keyboard/player as skill, mouse/boss as speed. The protagonist ultimately wins through skill, while the faster mouse puts up a strong fight. Preserve this as proposed lore, not a guarantee of player victory or a claim about real input devices.

The boss’s appearance, movement, attacks, unlock conditions, and placement are all open. This idea does not replace the current twenty-minute immediate victory or commit the game to a final-boss implementation.
