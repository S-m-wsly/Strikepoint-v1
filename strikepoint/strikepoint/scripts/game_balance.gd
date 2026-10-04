extends Node
class_name GameBalance
## Every tunable number lives here. Change values here, not in gameplay code.

const MATCH_DURATION := 180.0
const KILL_POINTS := 1
const TARGET_POINTS := 10
const TARGET_HP := 1000.0
const MAIN_TOWER_HP := 2000.0
const RESPAWN_TIME := 8.0
const SPAWN_PROTECTION := 2.0
const POWERUP_RESPAWN := 20.0
const POWERUP_DURATION := 8.0
const ATTACK_COOLDOWN := 0.65

# "reach" = basic attack range in world units.
static func character_stats(id: String) -> Dictionary:
    var stats = {
        "kael": {"health": 850.0, "damage": 75.0, "speed": 7.0, "reach": 14.0, "role": "ARCHER / SCOUT", "color": Color("#45d35c")},
        "nyx": {"health": 780.0, "damage": 62.0, "speed": 8.5, "reach": 9.0, "role": "SHOOTER / SPEEDSTER", "color": Color("#ff7a2e")},
        "jax": {"health": 820.0, "damage": 90.0, "speed": 6.8, "reach": 12.0, "role": "GUNSLINGER / TACTICIAN", "color": Color("#f0b83b")},
        "orion": {"health": 1250.0, "damage": 55.0, "speed": 5.5, "reach": 6.5, "role": "TANK / SUPPORT", "color": Color("#42d5f5")},
        "zuri": {"health": 900.0, "damage": 58.0, "speed": 7.0, "reach": 8.0, "role": "ENGINEER / AREA CONTROL", "color": Color("#c34cff")},
        "kage": {"health": 720.0, "damage": 105.0, "speed": 8.0, "reach": 5.0, "role": "ASSASSIN / DISRUPTOR", "color": Color("#7a1f3a")}
    }
    return stats.get(id, stats["kael"]).duplicate()
