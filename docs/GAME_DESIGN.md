# Evolution Zoo — Game Design Doc

Jam theme: **Evolution**. Team: 2 (1 programmer/designer, 1 dedicated pixel artist). Engine: **Godot 4.7** (2D only, no 3D).

## Pitch

Run a zoo where you mutate your creatures' DNA to change how they look and what they can do. Visitors are
attracted or repelled by specific physical traits; the same traits also determine what skills a creature has
(jumping, roaring, being a showpiece, etc). Push a creature too far in one direction and you gain a powerful
skill but risk scaring off a whole category of visitor.

## Core loop

```
Ticket revenue → Mutagen points → DNA Lab draft → Trait + tag update → Zoo opens → Visitors react → Revenue
```

Revenue earned from a day at the zoo converts into **mutagen points**, which are spent in the **DNA Lab** to
mutate one trait slot on a creature. The new trait immediately changes the creature's tag profile, which
immediately changes both its visitor approval and its dominant skill archetype. The zoo then opens and the
result plays out.

### Key architecture recommendation

Drive **visitor attraction/repulsion** and **skill archetype** from the *same* trait-tag system. One data
model to build and balance, not two — this matters a lot for a 2-person, sub-48-hour build.

## Tag vocabulary

Every trait option carries 1–2 of these tags. Tag totals across a creature's currently equipped traits drive
both visitor approval and its dominant skill archetype.

| Tag | Meaning |
| --- | --- |
| Cute | Soft, round, appealing to families |
| Elegant | Slender, graceful, enables agility |
| Majestic | Impressive, rare-feeling, a showpiece draw |
| Weird | Novel, unusual, a talking point |
| Scary | Threatening, thrilling, risky |
| Bulky | Heavy, slow, tanky |
| Gross | Off-putting, a liability if overused |
| Silly | Goofy, endearing, low stakes |

## MVP trait library

> **Update:** the base demo expanded this to 7 shape slots — Body, Head, Eyes, Mouth, Arms, Legs, Tail —
> instead of the original 6 below, plus a separate Color slot for skin/coat. See
> [`DEMO.md`](./DEMO.md) and [`ART_PIPELINE.md`](./ART_PIPELINE.md) for the implemented version. The table
> below is kept as the original tag-design reference; re-tag the new slot list against it before content
> (real trait balancing, visitor reactions) gets built on top of the demo.

Pure data — buildable before any art exists. Each option is one texture the artist draws once.

| Slot | Option | Tags | Design note |
| --- | --- | --- | --- |
| Head | Round Head | Cute | Safe baseline pick, favored by Families |
| Head | Horned Head | Scary, Majestic | Feeds Predator or Showpiece archetype |
| Head | Bulbous Head | Weird, Gross | Feeds Novelty archetype, risky with Families |
| Eyes | Big Round Eyes | Cute, Silly | Strong Families draw |
| Eyes | Beady Eyes | Scary | Cheap Predator tag, minimal visual cost |
| Eyes | Compound Multi-Eyes | Weird, Gross | High Novelty, disgust risk |
| Neck | Short Neck | Cute, Bulky | Pushes toward Bulky/Tanky archetype |
| Neck | Long Elegant Neck | Elegant, Weird | Pushes toward Nimble archetype |
| Neck | Extra Neck (2nd head) | Weird, Gross | High-risk Novelty swing |
| Body | Slim Body | Elegant | Core enabler for Nimble tricks |
| Body | Round Body | Cute, Bulky | Core enabler for Bulky/Tanky |
| Body | Spiky Body | Scary, Majestic | Core enabler for Predator/Showpiece |
| Limbs | Short Stubby Legs | Cute, Bulky | Locks out jump/trick ability |
| Limbs | Long Slender Legs | Elegant, Silly | Unlocks jump/trick ability |
| Limbs | Many Legs | Weird, Gross | Novelty swing, unsettles Families |
| Skin / Coat | Soft Fur | Cute | Cheapest, safest, lowest ceiling |
| Skin / Coat | Iridescent Scales | Majestic, Elegant | Best all-round crowd pleaser |
| Skin / Coat | Oozing Slime | Gross, Weird | Highest Novelty, highest Families risk |

> Implementation note: `Skin / Coat` is handled differently from the other five slots — see
> [`ART_PIPELINE.md`](./ART_PIPELINE.md). It's a color palette applied via shader on top of every part, not a
> separate texture per shape combination.

## Visitor archetypes

| Type | Status | Loves | Hates | Behavior |
| --- | --- | --- | --- | --- |
| Families | MVP | Cute, Elegant, Majestic | Scary, Gross | Standard fee + tip bonus on high Cute score; refund and leave early if Scary/Gross is too high. |
| Thrill-Seekers | MVP | Scary, Weird, Majestic | Cute | Pay a premium and tip extra for Showtime tricks; bored (pay less) by a purely Cute creature. |
| Scientists / Collectors | Stretch | Weird | — | Pay based on trait rarity/uniqueness score rather than tag totals; indifferent to Scary or Cute. |

## Skill archetypes (derived from dominant tag)

No separate skill-assignment system — whichever tag totals the highest across the creature's equipped traits
determines its archetype automatically.

| Archetype | Dominant tag | Ability | Trade-off |
| --- | --- | --- | --- |
| Nimble | Elegant | Jumps and performs tricks during Showtime — big payout multiplier with Thrill-Seekers. | Low Bulky score means fragile approval if paired with any Gross trait. |
| Bulky / Tanky | Bulky | Can't perform tricks, but is immune to being scared off and draws a steady passive crowd. | Flat, low-ceiling income — never spikes like Nimble or Predator can. |
| Predator | Scary | "Roar" Showtime move — the single highest per-visit payout from Thrill-Seekers. | Real risk of permanently scaring Families away if the enclosure isn't upgraded first. |
| Novelty | Weird | Passive "gawk & photo" bonus — visitors linger and pay extra regardless of type. | Any paired Gross trait risks a disgust penalty that cancels the bonus. |
| Showpiece | Majestic | No active trick, but a large flat rating boost favored by both Families and Scientists. | Needs rarer trait options to reach — expensive to build early on. |

## Mutagen Lab flow (the DNA-editing minigame)

1. Convert ticket revenue to Mutagen Points each day.
2. Open the DNA Lab, pick a trait slot to mutate.
3. Spend points to reveal a 3-option draft (rare pool costs more, unlocks later).
4. Pick one of the three — it replaces that slot's current trait instantly.
5. Tag profile, archetype, and silhouette recompute immediately.
6. Optional: pay extra to reroll the draft if all three options are duds.

## 48-hour build plan

### Day 1 — systems over art
- [ ] Build trait/tag data table — 6 slots × 3 options, data only, no art needed yet
- [ ] Build creature renderer that swaps parts per slot (placeholder shapes are fine)
- [ ] Build the tag-scoring function → dominant archetype + per-visitor-type approval score
- [ ] Build DNA Lab UI: 3-option draft picker wired to a mutagen point currency
- [ ] Build a static zoo scene: background + creature display + revenue counter
- [ ] Wire the full loop once end-to-end (spend → mutate → rescore), even if it looks ugly

### Day 2 — loop, feedback, polish
- [ ] Implement the day/round cycle: earn → spend → open zoo → react → repeat
- [ ] Add Families + Thrill-Seekers with enter/leave logic and revenue tally
- [ ] Add a Showtime bonus per archetype (trick popup or animation + payout)
- [ ] Swap placeholder shapes for real trait art, if time allows
- [ ] Add a scoring target or end condition (e.g. reach a rating by day 5)
- [ ] Title screen, restart flow, SFX pass, and export a build for submission

## Stretch goals (only if ahead of schedule)

- Third visitor type: Scientists / Collectors, driven by trait rarity instead of tags
- A rare/legendary mutation tier with bigger visual and tag swings
- A permanent "scared off" state after a visitor type flees repeatedly
- Multiple enclosures or creatures instead of just one
- Randomized visitor requests ("bring me a Majestic creature") for bonus payouts

## Open questions

- **Session length target** — jam judges typically play 3–5 minutes. Is the loop tuned to reach a
  trait-swap → visitor-reaction moment inside that window?
- **Fail state** — hard bankruptcy loss, soft scoring sandbox with no lose condition, or a fixed day-limit
  high-score run?
- **Mutagen earn formula** — flat points per visitor, or only from visitors who actually stayed and paid?
  The latter ties the DNA-editing loop more tightly to the attractiveness system (recommended default).
