# Typed magic: core fantasy and possible directions

Date: September 26, 2026
Status: Discussion notes for later design and playtesting. This records the conversation; it does not approve a pivot or change the current game rules.

## The idea worth preserving

The player types spells while a horde threatens them. Powerful magic promises a bigger payoff, but there is not enough time to do everything safely. The central tension is choosing between staying alive through movement and committing to damage through casting.

The creator specifically defended the panic of that choice when a defense-game alternative was proposed. Movement and typing competing for attention may be part of the appeal, rather than simply an inconvenience to eliminate.

A possible short pitch, synthesized from the discussion rather than quoted from a separate account given to friends:

> You're a wizard fighting a horde by typing spells. You can keep running, or stop long enough to cast something that might save you. The dangerous moment is deciding whether to finish the incantation or flee.

The exact wording used with friends has not been supplied separately; add it here if shared later.

## Questions still open

- Is survivors-style movement essential to that panic, or can approaching enemies create enough pressure without movement?
- Should stronger spells generally take longer to type? What payoff earns that commitment: damage, coverage, sustained effects, or safety?
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

Current implementation context: typing stops movement, Escape cancels, and a shared three-second slowdown budget recharges over ten seconds outside typing. Those existing numbers are a starting point for experiments, not newly confirmed design targets.

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

## What to observe before committing

- Do players deliberately make space before a large cast?
- Do they sometimes abandon a cast to survive, without feeling trapped by the controls?
- Does completing a risky cast visibly repay the commitment?
- Do short spells stay useful after stronger magic becomes available?
- Does slowdown preserve a gamble, or remove it entirely?
- Is panic exciting and readable across different typing speeds?

Bot runs can reveal mechanical failures and patterns of damage. They cannot establish the human feeling of panic, satisfaction, or control. Any broader pivot should follow a small comparison prototype and actual player feedback.
