# STRIKEPOINT

A 3v3 objective-combat prototype built with Godot 4.3.

## Core rule
Destroy both enemy outer targets (A and B) to unlock the enemy Main Tower. Destroying the Main Tower wins immediately. If the 3-minute timer expires first, the higher score wins. Ties go to objective damage, then eliminations, then a draw.

## Controls
- Keyboard: WASD / arrows move, Space attacks (hold to keep attacking), 1 / 2 / 3 abilities, R restarts after a match.
- Touch: floating joystick on the left half of the screen, attack and ability buttons on the right. Multi-touch works, so you can move and attack together.
- Attacks hit the nearest enemy hero in range, otherwise the nearest unlocked objective in range.

## Characters
Kael (Archer), Nyx (Shooter), Jax Ryder (Gunslinger), Orion (Tank), Zuri (Engineer), Kage (Assassin). Each hero has a head in its own color. Stats, including attack range, are in `scripts/game_balance.gd`.

## Project layout
- `scripts/game_balance.gd` all tunable numbers
- `scripts/main.gd` builds the arena, objectives, power-ups and characters
- `scripts/match_manager.gd` score, timer, unlock and win logic
- `scripts/character.gd` movement, AI, attacks, abilities, death and respawn
- `scripts/objective.gd`, `scripts/powerup.gd`, `scripts/ui.gd`, `scripts/touch_controls.gd`

## Run
Open the folder in Godot 4.3 and press Play.

## Android APK
Push to GitHub. The workflow `.github/workflows/android-build.yml` builds a debug APK (signed with a throwaway debug key) and uploads it as the `STRIKEPOINT-Android` artifact on the Actions run. A signed release build needs your own keystore added as repository secrets.

## Known gaps (prototype)
No main menu or character select yet, abilities are generic area attacks, no audio or VFX, AI just targets the nearest enemy or objective.
