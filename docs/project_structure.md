# Project Structure

This project is now grouped by responsibility so runtime code, content sources, and validation scripts do not compete for the same folders.

## Runtime layout

- `scenes/gameplay/`: playable combat scene and entity scene files
- `scenes/ui/screens/`: full-screen flow scenes
- `scenes/ui/components/`: HUD and modal panel scenes
- `scripts/core/`: autoload and shared data providers
- `scripts/gameplay/entities/`: player, enemies, projectiles, pickups, and area effects
- `scripts/gameplay/systems/`: battle orchestration and spawn flow
- `scripts/gameplay/world/`: environment presentation scripts
- `scripts/gameplay/effects/`: combat VFX helpers
- `scripts/ui/screens/`: menu and result controllers
- `scripts/ui/components/`: HUD and modal logic
- `scripts/ui/common/`: shared theme and icon helpers

## Support layout

- `tests/probes/`: Godot smoke and regression probes
- `art/runtime/`: runtime-ready textures and extracted sprites
- `art/drafts/`: source drafts, spritesheets, and direction explorations
- `tools/`: asset processing helpers
- `docs/`: engineering notes such as this structure guide

## Conventions

- Scene folders mirror the responsibility of the scripts that drive them.
- Probe scripts stay under `tests/` so debug tooling never mixes with shipped runtime code.
- Disposable logs and cache-style outputs are ignored by git and should stay out of the repo root.
- New gameplay code should prefer the existing ownership layers instead of adding more flat root-level folders.
