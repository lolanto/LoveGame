# Quickstart: Black Hole Skill

## Features
- Press **'T'** to spawn a Black Hole 3 meters above the player.
- Black Hole lasts 10 seconds.
- Objects within 5 meters are sucked in.

## Testing
1. Run the game (`run.bat`).
2. Move player near some Movable objects (Physics boxes).
3. Press **'T'**.
4. Observe objects flying towards the point above the player.
5. Verify Black Hole disappears after 10s.

## Configuration
- Input and Balancing values are in `Config.lua` (Table: `Config.BlackHole`).
- `GravitationalFieldCMP.lua` defines component data structure.
