# Evolution Zoo — current implementation snapshot

Jam theme: **Evolution**. Team of 2. Godot 4.x (docs say 4.7; `project.godot` features array currently says **4.6**), 2D pixel art, Compatibility renderer.

## Pitch and loop (design)

Ticket revenue → cash ($) → buy pens / animals / DNA vials → DNA Lab drop → trait/tag update → visitors react → revenue.

Visitor attraction and skill archetype share **one tag model**. Tags: Cute, Elegant, Majestic, Weird, Scary, Bulky, Gross, Silly. Opposing pairs (Cute/Scary, Cute/Gross, Elegant/Gross, Silly/Scary) are a paddock welfare hit.

Visitors: Children, Parents, Tourists, Goths, Content Creators, Thrill-Seekers, Scientists. Skill archetypes (dominant tag): Nimble, Tanky, Predator, Novelty, Showpiece.

**Now wired (was “later” in DEMO.md):** street + cars, guests walking the grass, interest drain, ticket payout from still-interested visitors. Still missing: day cycle, Showtime payouts, arrival gates (low/high rating), merch/hype/cry side effects, fail state.

## What Play does today

`run/main_scene` = `res://scenes/Main.tscn`.

- Right-drag pan, wheel zoom (`1.0` / `2.0`)
- Bottom dock: Pens / Animals category tabs, catalog ribbon of priced tiles
- Pens ($40 small 4×3, $75 large 6×5) and base animals (Jimothy $30, Horse $45, Spikeback $50, Gloop $40, Chimory $55, Jimmothy $20)
- Ghost preview green/red on 100px grid; cash is spent on a successful place. Pens cannot be built on the parking/road strip.
- Click animal → right exhibit card (thumbnail, archetype, who comes / stays away and why, trait mix). Delete animal on the card.
- Click empty pen (no tool) → paddock card. Delete pen also deletes animals inside. No refund.
- Exhibit → Open DNA Lab → pick a body part → drag a randomiser vial onto the empty ATGC rung
- Vial shop spends cash ($20). Starts with $100 and **2** randomisers.
- Cash no longer idles +$6. `WalletService` ticks every **5s** and sums `Visitor.ticket_value()` for guests still paying (interest above 28% of max).
- Street along the south edge: cars, kerbside bays, families of children/parents, generic patrons. Right-click a waiting patron to hail a pickup (per `Street` / `Visitor` comments).
- No starter exhibit. Buy a pen, then a base animal.

## Scene tree

```
Main (Node2D, main.gd)
├── FloorGrid (Node2D, floor_grid.gd)     # 16×10 grass, z = -1
├── Camera2D
├── BuildMode (Node2D, build_mode.gd)
│   └── Pen instances → Animal instances
├── Street (instance of Street.tscn)      # road, parking, cars, visitors
└── HUDLayer (CanvasLayer, layer 10)
    └── HUD (Control, PRESET_FULL_RECT, mouse_filter IGNORE)
```

Creature rig (`scenes/Creature.tscn`):

```
Creature (Node2D, creature_visuals.gd)
├── Tail
├── BackLegs
├── FrontLegs
├── Body
└── Head          # snout and eyes live here
```

All part sprites sit at the origin on a shared **100×100** canvas (high-res Fresco PNGs are scaled down onto that cell).

## Autoloads

| Name | File | Job |
| --- | --- | --- |
| Events | `scripts/events.gd` | `animal_selected`, `pen_selected`, `money_changed`, `vials_changed`, `creature_mutated`, `build_tool_changed`, `placement_rejected`, `placement_succeeded` |
| GridService | `scripts/grid_service.gd` | `CELL_SIZE = 100`, 16×10 grass, parking 96px + road 148px, occupy / world↔cell, camera limits |
| PlaceholderArt | `scripts/placeholder_art.gd` | procedural grayscale parts + palettes; file overrides |
| WalletService | `scripts/wallet_service.gd` | cash ($) + randomiser vial stock; ticket collect |
| TraitLibrary | `scripts/trait_library.gd` | options, tags, approval, archetype |
| GodotAIBridgeRuntime | `addons/godot_ai_bridge/runtime_bridge.gd` | runtime harness for MCP |

`scripts/mutagen_service.gd` is leftover and **not** autoloaded.

## Collision / picking

- Animals: `CharacterBody2D`, `MOTION_MODE_FLOATING`, layer **2**, mask **4**, `input_pickable`
- Pen fences: runtime `StaticBody2D` walls, layer **4**, mask 0
- Visitors: `Area2D`, group `visitors`, `input_pickable`
- `viewport.physics_object_picking = true` in `main.gd` (off by default in Godot)
- No animal-vs-animal collision

## Art pipeline (live)

1. Shape slots → swap `Sprite2D.texture`
2. Color slot → one shared `ShaderMaterial` (`palette_swap.gdshader`) sampling a 1px-tall palette
3. Real Jimothy PNGs override option 0 (tail often hidden via catalog `hide`). Chimory PNGs override option 3 on all five slots. Jimmothy PNGs override option 4 on all five slots.
4. Floor: flat HSB 71/98/85 fill plus scattered `tuft_1`–`tuft_3` overlays
5. Visitor sprites: `art/visitors/` boy/girl/mum/dad/patron

## HUD rules (do not regress)

- UI scenes are Control-rooted. One `CanvasLayer` lives on Main.
- Nested Containers only. No hardcoded HUD pixels.
- Empty / spacer / full-rect wrappers: `mouse_filter = IGNORE` (value `2` in `.tscn`). HUD root sets this in `_ready`.
- Theme on HUD root (`art/ui/zoo_theme.tres`). Update from Events signals, not `_process`.
- Exhibit thumbnail: `SubViewport` shares `world_2d` with the main tree + a dedicated `Camera2D`. Do not enable physics picking on that SubViewport.
- DNA Lab is a dimmed overlay: strand + vial tray on the left, exhibit card reparented to the right.

## Tests

Headless: `tests/smoke_test.tscn` — grid, pens, animals, mutation, HUD, thumbnail.
