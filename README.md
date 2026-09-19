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

Installed from `godot-mcp-0.2.0.zip` at `C:\Users\Docto\godot-mcp` and registered in Cursor's
`~/.cursor/mcp.json` as `godot-mcp`, pointed at this project.

- File tools (scenes/scripts/shaders/UI) work anytime Cursor can launch the MCP.
- Live editor / runtime tools need Godot open with the **Godot AI Bridge** plugin enabled
  (`addons/godot_ai_bridge` — already in this repo; enabled in `project.godot`).
- After changing MCP config, restart Cursor (or reload MCP servers) so the tools show up.
- Companion skills are already under `.cursor/skills/` (`godot-interactive`, etc.).

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
