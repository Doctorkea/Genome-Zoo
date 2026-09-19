# Godot context pack (Evolution Zoo)

Refetched **2026-09-19** (second pass). Summaries + links, not a dump of the Godot manual.

Use this folder when a later chat needs engine/API/community context without refetching.

| File | What it is |
| --- | --- |
| [project-snapshot.md](./project-snapshot.md) | What the repo actually implements right now |
| [official-manuals.md](./official-manuals.md) | Godot **4.7** docs that apply to this game (live-fetched) |
| [community.md](./community.md) | Forums, shaders, addons, Reddit threads (live-fetched) |
| [skills-and-mcp.md](./skills-and-mcp.md) | Installed Cursor skills vs upstream + MCP / AI Bridge status |

Existing design docs stay authoritative for *our* intended loop. If they disagree with [project-snapshot.md](./project-snapshot.md), the snapshot wins for “what Play does today.”

- [`../DEMO.md`](../DEMO.md) — intended playable demo notes (cash tick / “no visitors” lines are stale)
- [`../GAME_DESIGN.md`](../GAME_DESIGN.md) — loop, tags, visitors, 48h plan
- [`../ART_PIPELINE.md`](../ART_PIPELINE.md) — paper-doll + palette shader
- [`../references.md`](../references.md) — research links (also points here)

## Skills already in the repo

Installed under `.cursor/skills/`. Upstream pack: [alexmeckes/godot-claude-skills](https://github.com/alexmeckes/godot-claude-skills) (MIT). Diffed against `main` on 2026-09-19: **all five skills are present and current.** Local copies have a few extra header lines; `godot-interactive` matches upstream exactly. No extra skills exist in that pack.

| Skill | Role for this project |
| --- | --- |
| `godot-gui` | HUD / DNA Lab / dock. Control-rooted UI, Containers, Theme, `MOUSE_FILTER_IGNORE` |
| `godot-code-gen` | GDScript 4.x: types, signals, `@onready`, `await`, tweens |
| `godot-scene-design` | `.tscn` trees, collision layers, CanvasLayer HUD |
| `godot-shader` | `canvas_item` shaders (palette swap) |
| `godot-interactive` | Persistent `godot-mcp` inspect / edit / run / runtime loop |
| `godot-live-edit` | Lightweight AI Bridge notes (some tool names are stale — see skill drift) |
| `frontend-design` | Visual identity, not web layout |
| `theme-factory` | Palette / theme tokens |

Companion MCP: [alexmeckes/godot-mcp](https://github.com/alexmeckes/godot-mcp) (99 tools). Live editor needs the **Godot AI Bridge** plugin (`addons/godot_ai_bridge`, already enabled).

## MCP / live editor status (this machine)

Project config: `.cursor/mcp.json` launches vendored `tools/godot-mcp` with `--port 6550`.
User config: `C:\Users\Kea\.cursor\mcp.json` points at the same server (so this Cursor profile can load it immediately).

Connected 2026-09-19: `ws://127.0.0.1:6550` — **Evolution Zoo**, Godot **4.6-stable (official)**, capabilities `scene_tree` / `editor` / `runtime`.
The AI Bridge addon **is** in this repo and enabled in `project.godot`. Runtime autoload: `GodotAIBridgeRuntime`.

## Engine pin

- Docs and `ART_PIPELINE.md` target **Godot 4.7**.
- Live editor reports **Godot 4.6-stable (official)**. `project.godot` currently writes `config/features = PackedStringArray("4.6", "GL Compatibility")`. 4.6→4.7 GDScript breaks do **not** touch this project's APIs (`Sprite2D`, `CharacterBody2D`, canvas-item shaders, typed Arrays). Prefer `/en/4.7/` docs anyway; they still match this API surface.
- Renderer: Compatibility (`gl_compatibility`). Do not switch back to Forward+ (Intel HD 620 Vulkan crash).
- Viewport **1280×720**, stretch `viewport`. Runtime also sets `CONTENT_SCALE_ASPECT_KEEP` + `CONTENT_SCALE_STRETCH_FRACTIONAL` so a laptop editor tab letterboxes instead of cropping the HUD.
- Default texture filter **Nearest**, snap 2D transforms/vertices to pixel.
- Camera zoom is discrete: **`1.0 / 2.0`** (0.5 was removed — that view is wider than the 16×10 world plus parking/road).
