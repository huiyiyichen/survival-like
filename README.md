# Cursed Grove Survivor Demo

This repository is organized as a small Godot project instead of a flat prototype dump.
Runtime code, scenes, tests, tools, and source art now live in separate areas so gameplay work can keep growing without turning the repo root into a scratchpad.

## Layout

- `scenes/gameplay/`: playable combat scene and entity scene assets
- `scenes/ui/screens/`: full-screen flows such as menu, character select, and result
- `scenes/ui/components/`: HUD and in-run modal panels
- `scripts/core/`: autoloads and shared runtime data
- `scripts/gameplay/`: gameplay entities, systems, world, effects, and scene controllers
- `scripts/ui/`: screen controllers, HUD logic, and shared UI helpers
- `tests/probes/`: Godot probe scripts for smoke tests and regression checks
- `art/runtime/`: runtime-ready textures and cut sprites
- `art/drafts/`: draft art, spritesheets, and source exploration
- `tools/`: one-off asset preparation utilities

## Run

Open the project in Godot 4.6 and run the main scene from `project.godot`.
The current entry scene is `res://scenes/ui/screens/main_menu.tscn`.

## Verify

Example headless checks:

```powershell
& 'D:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe' --headless --path . --import
& 'D:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe' --headless --path . -s res://tests/probes/load_game_scene_probe.gd
& 'D:\Program Files\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64.exe' --headless --path . -s res://tests/probes/boss_finish_transition_probe.gd
```

Probe logs are treated as disposable artifacts and are ignored by git.
