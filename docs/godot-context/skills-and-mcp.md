# Skills and MCP (Evolution Zoo)

Fetched 2026-09-19. Knowledge lives in `.cursor/skills/`. Tools live in Cursor MCP `user-godot-mcp` (from `.cursor/mcp.json` + `~/.cursor/mcp.json`).

## Installed Cursor skills

Compared to [alexmeckes/godot-claude-skills](https://github.com/alexmeckes/godot-claude-skills) `main` (shallow clone). That pack contains **exactly five** Godot skills. All five are already in this repo.

| Path | Source | Status vs upstream |
| --- | --- | --- |
| `.cursor/skills/godot-interactive/` | alexmeckes | Identical `SKILL.md`. Extra local refs: `live-editor-tool-map.md`, `fast-probe-presets.md`, `runtime-automation-extension-points.md`, `agents/openai.yaml` |
| `.cursor/skills/godot-code-gen/` | alexmeckes | Present; local has a few extra header lines |
| `.cursor/skills/godot-scene-design/` | alexmeckes | Present; local has a few extra header lines |
| `.cursor/skills/godot-shader/` | alexmeckes | Present; local has a few extra header lines |
| `.cursor/skills/godot-live-edit/` | alexmeckes | Present; **tool names drift** — see below |
| `.cursor/skills/godot-gui/` | **this project** | HUD / DNA Lab / dock rules. Not in the upstream pack |
| `.cursor/skills/frontend-design/` | Anthropic | Visual identity. Do not treat as web CSS |
| `.cursor/skills/theme-factory/` | Anthropic | Artifact palettes. Not a Godot Theme |

No additional Godot skills were missing from the official companion pack. Do not invent a sixth alexmeckes skill.

## Which live skill to use

- Prefer **`godot-interactive`** whenever `godot-mcp` is actually connected.
- Use **`godot-live-edit`** only as a lighter checklist. It still mentions tools that **are not** on the current MCP surface:
  - `godot_editor_get_node_properties`
  - `godot_editor_get_node_types`
  - `godot_editor_list_assets_by_type`
- Current add/modify args are `parentPath`, `nodePath`, `scenePath` (see `godot-interactive/references/live-editor-tool-map.md`).

## godot-mcp (connected)

Upstream: [alexmeckes/godot-mcp](https://github.com/alexmeckes/godot-mcp) v0.2.0, vendored at `tools/godot-mcp`. ~99 tools.

Live attach (verified 2026-09-19): `godot_connect` → `ws://127.0.0.1:6550`, project **Evolution Zoo**, Godot **4.6-stable**.

File tools (work without the editor): scenes, scripts, shaders, resources, animation, InputMap, audio, navigation, UI builders, `godot_help`.

Live tools (need Godot open + AI Bridge):

```
godot_connect
godot_connection_status
godot_editor_get_project_info
godot_editor_get_scene_tree
godot_editor_open_scene
godot_editor_save_scene
godot_editor_run_scene
godot_editor_stop_scene
godot_editor_refresh_filesystem
godot_editor_add_node / modify_node / remove_node
godot_editor_get_errors / get_output / get_log_file
godot_editor_execute_gdscript
```

Runtime tools (need a **running** scene, not just the editor):

```
godot_runtime_status
godot_runtime_wait
godot_runtime_press_action / release_action / tap_action
godot_runtime_mouse_move / click
godot_runtime_type_text
godot_runtime_capture_screenshot
```

Default bridge: `127.0.0.1:6550`.

This repo vendors `tools/godot-mcp` and registers it in `.cursor/mcp.json` (and this machine's `~/.cursor/mcp.json`) with `--port 6550`. After `npm install --omit=dev` in that folder, Cursor can launch the server. `godot_connect` then talks to the AI Bridge.

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": [
        "${workspaceFolder}/tools/godot-mcp/dist/index.js",
        "--project",
        "${workspaceFolder}",
        "--port",
        "6550"
      ]
    }
  }
}
```

## Project-specific GUI skill (always on)

`.cursor/skills/godot-gui/SKILL.md` is the local source of truth for HUD work:

1. UI scenes are **Control-rooted**. One `CanvasLayer` on `Main.tscn`.
2. Layout with nested Containers, not hardcoded pixels. Design at **1280×720**. Grid cell **100×100**.
3. Full-rect overlays: `mouse_filter = MOUSE_FILTER_IGNORE`. Only real buttons/panels STOP.
4. Theme on HUD root (`art/ui/zoo_theme.tres`), not per-node StyleBoxes.
5. Drive UI from `Events` signals, not `_process`.

## Fast probes

Use `godot-interactive/references/fast-probe-presets.md` for a temporary Label/Button/LineEdit. Remove before signoff unless the user wants to keep it.
