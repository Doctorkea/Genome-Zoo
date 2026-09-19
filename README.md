# Evolution Zoo

Game jam project — theme: **Evolution**. Godot 4.7, 2D pixel art, team of 2.

Base resolution 1280×720, 100×100px floor tiles, integer-scaled (`viewport` stretch mode), Compatibility (OpenGL) renderer — see
[`docs/ART_PIPELINE.md`](docs/ART_PIPELINE.md#engine-version-godot-47) for why.

Run a zoo, mutate your creatures' DNA in a lab minigame, and watch the same trait changes both attract or
repel visitors and unlock new skills.

## Docs

- [`docs/DEMO.md`](docs/DEMO.md) — **start here.** What's actually playable, controls, and what's still a
  placeholder in the base demo.
- [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) — full game design doc: core loop, trait/tag system, visitor
  archetypes, skill archetypes, 48-hour build plan, open questions.
- [`docs/ART_PIPELINE.md`](docs/ART_PIPELINE.md) — how creature trait art actually gets rendered in Godot
  (layered swappable parts + a shared palette-swap shader for skin/coat).
- [`docs/references.md`](docs/references.md) — research sources behind the art pipeline decisions.

## Project layout

```
scenes/     Godot scenes (Creature.tscn is the trait-rendering rig)
scripts/    GDScript, including scripts/shaders/palette_swap.gdshader
art/
  creatures/
    parts/      grayscale shape art per trait slot, one file per option
    palettes/   1px-tall color-strip textures, one per skin/coat trait
  ui/         zoo/UI art
docs/       design + pipeline docs
```

## Team

- Programmer/design: DNA Lab systems, zoo economy, visitor logic
- Artist: all pixel art (parts + palettes + UI), no 3D
