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
- [`docs/godot-context/INDEX.md`](docs/godot-context/INDEX.md) — fetched Godot 4.7 manuals, forum notes, skill/MCP status, and a current implementation snapshot.

## Agent skills

Installed under `.cursor/skills/` so later chats pick them up automatically:

- `frontend-design` — official Anthropic GUI/visual-design skill
- `theme-factory` — official Anthropic theme/palette skill
- `godot-gui` — Godot 4.7 Control/Container/Theme rules for this project's HUD
- From [alexmeckes/godot-claude-skills](https://github.com/alexmeckes/godot-claude-skills) (MIT):
  - `godot-code-gen` — GDScript best practices, type hints, signals, state machines
  - `godot-scene-design` — `.tscn` hierarchies, collision layers, level layout
  - `godot-shader` — 2D/3D shader authoring patterns
  - `godot-live-edit` — lightweight live-editor guidance
  - `godot-interactive` — inspect/edit/run/debug loop (pairs with godot-mcp)

## Godot MCP

Vendored from [alexmeckes/godot-mcp](https://github.com/alexmeckes/godot-mcp) at `tools/godot-mcp`.
Project Cursor config is `.cursor/mcp.json` (bridge port **6550**). First clone on a new machine:
`cd tools/godot-mcp && npm install --omit=dev`.

The AI Bridge addon is already in this repo (`addons/godot_ai_bridge`, enabled in `project.godot`).
Godot must be open with this project so the plugin can listen on `127.0.0.1:6550`.

- Live editor / runtime tools: `godot_connect` then `godot_editor_*` / `godot_runtime_*`.
- After changing MCP config, reload MCP servers (or restart Cursor) and enable `godot-mcp` if Cursor asks.
- Companion skills are under `.cursor/skills/` (`godot-interactive`, etc.).
- Full notes: [`docs/godot-context/skills-and-mcp.md`](docs/godot-context/skills-and-mcp.md).

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
