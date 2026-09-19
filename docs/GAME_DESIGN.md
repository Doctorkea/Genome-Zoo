# Evolution Zoo — Game Design Doc

Jam theme: **Evolution**. Team: 2 (1 programmer/designer, 1 dedicated pixel artist). Engine: **Godot 4.7** (2D only, no 3D).

## Pitch

Run a zoo where you mutate your creatures' DNA to change how they look and what they can do. Visitors are
attracted or repelled by specific physical traits; the same traits also determine what skills a creature has
(jumping, roaring, being a showpiece, etc). Push a creature too far in one direction and you gain a powerful
skill but risk scaring off a whole category of visitor.

## Core loop

```
Ticket revenue → Cash ($) → buy pens / animals / DNA vials → Trait + tag update → Zoo opens → Visitors react → Revenue
```

Revenue earned from a day at the zoo is **cash ($)**, spent on pens, base animals, and **DNA Lab** vials that
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

Implemented in `scripts/trait_library.gd`. Five shape slots (Body, Head, Front Legs,
Back Legs, Tail) plus a Color slot for skin/coat. Mouth/snout and eyes are drawn on the Head —
there is no Neck or Eyes slot; Tail carries the old Neck tag swings. Front and Back Legs are
independent picks with four silhouettes each.

Each option is one texture the artist draws once (or one palette strip, for Color).

| Slot | Option | Tags | Design note |
| --- | --- | --- | --- |
| Body | Slim Body | Elegant | Core enabler for Nimble tricks |
| Body | Round Body | Cute, Bulky | Core enabler for Tanky |
| Body | Spiky Body | Scary, Majestic | Core enabler for Predator/Showpiece |
| Body | Chimory Body | Weird, Bulky | Artist body model, 4th catalog option |
| Head | Round Head | Cute | Safe baseline pick, favored by Families. Eyes are painted on the head. |
| Head | Horned Head | Scary, Majestic | Feeds Predator or Showpiece |
| Head | Bulbous Head | Weird, Gross | Feeds Novelty, risky with Families |
| Head | Gorilla Head | Bulky, Cute | Chimory head |
| Front Legs | Stubby Front Legs | Cute, Bulky | Locks out jump/trick ability |
| Front Legs | Slender Front Legs | Elegant, Silly | Unlocks jump/trick ability |
| Front Legs | Many Front Legs | Weird, Gross | Novelty swing, unsettles Families |
| Front Legs | Frog Arms | Weird, Silly | Chimory front legs |
| Back Legs | Stubby Back Legs | Cute, Bulky | Same tags as front, independent pick |
| Back Legs | Slender Back Legs | Elegant, Silly | Same tags as front, independent pick |
| Back Legs | Many Back Legs | Weird, Gross | Same tags as front, independent pick |
| Back Legs | Sheep Legs | Cute, Bulky | Chimory back legs |
| Tail | Short Tail | Cute, Bulky | Replaces the old Short Neck swing |
| Tail | Long Tail | Elegant, Weird | Replaces the old Long Neck swing |
| Tail | Forked Tail | Weird, Gross | Replaces the old Extra Neck swing |
| Tail | Scorpion Tail | Scary, Weird | Chimory tail |
| Color | Soft Fur | Cute | Cheapest, safest, lowest ceiling |
| Color | Iridescent Scales | Majestic, Elegant | Best all-round crowd pleaser |
| Color | Oozing Slime | Gross, Weird | Highest Novelty, highest Families risk |

> Implementation note: `Color` is handled differently from the shape slots — see
> [`ART_PIPELINE.md`](./ART_PIPELINE.md). It's a palette applied via shader on top of every part, not a
> separate texture per shape combination.

## Visitor archetypes

Scores are live on the exhibit card. Arrival gates and side effects (crying, merch, hype) are data only until visitors walk the zoo.

| Type | Loves | Hates | Notes |
| --- | --- | --- | --- |
| Children | Cute, Silly | Scary | Cry if Scary ≥ 3 (later). |
| Parents | — | — | Neutral. Hate Goths socially (later). |
| Tourists | Majestic | — | Buy merchandise when happy (later). |
| Goths | Scary, Gross, Weird | Cute | Only arrive if the zoo is low-rated (later). |
| Content Creators | Weird, Majestic, Silly | Gross | Happy creators generate hype / extra visitors (later). |
| Thrill-Seekers | Scary | Cute | Pay more for Scary (later). |
| Scientists | uniqueness | mediocrity | Score = distinct tags − 3. Only arrive if the zoo is high-rated (later). |

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

## DNA Lab flow (the DNA-editing minigame)

Current demo (playable now): ticket **cash ($)** buys **tag serums** from the shop. A single
**quest** is always up; it names the job and the **reward** (cash, a new serum, or a park perk).
Claim it when the goal is met, and the next request appears. Open the lab, pick a body part,
drop a serum onto the empty ATGC rung. That slot jumps to a different option with the serum's tag.
Cute serum starts unlocked with one free charge. Later serums unlock from quests that ask for a
**committed look** (a Showpiece, a second enclosure, a Predator), not a single tag tick.

Target loop (later):

1. Convert ticket revenue to cash each day.
2. Open the DNA Lab, pick a trait slot to mutate.
3. Spend points to reveal a 3-option draft (rare pool costs more, unlocks later).
4. Pick one of the three — it replaces that slot's current trait instantly.
5. Tag profile, archetype, and silhouette recompute immediately.
6. Optional: pay extra to reroll the draft if all three options are duds.

## 48-hour build plan

### Day 1 — systems over art
- [x] Build trait/tag data table — 5 slots × 5 options, plus Chimory and Jimmothy part art
- [x] Build creature renderer that swaps parts per slot (placeholder shapes are fine)
- [x] Build the tag-scoring function → dominant archetype + per-visitor-type approval score
- [x] Build DNA Lab UI: ATGC strand + exhibit card, quest board, tag-serum shop, vial drop
- [x] Build a static zoo scene: background + creature display + revenue counter
- [ ] Wire the full loop once end-to-end (spend → mutate → rescore → visitors react)

### Day 2 — loop, feedback, polish
- [ ] Implement the day/round cycle: earn → spend → open zoo → react → repeat
- [ ] Add the seven visitor types with enter/leave logic and revenue tally
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
- **Cash earn formula** — flat dollars per visitor, or only from visitors who actually stayed and paid?
  The latter ties the DNA-editing loop more tightly to the attractiveness system (recommended default).
