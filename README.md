# DayNightDefenseDemo

A Godot 4.x 2D top-down survival building defense demo.

The player gathers resources during the day, builds walls and gates, upgrades weapons, and survives enemy attacks at night. This is a prototype version using simple geometric placeholder art.

## Current Features

- Top-down WASD player movement
- Mouse-aimed shooting with projectile hit feedback
- Player HP and Game Over state
- Automatic resource pickup
- Grid-based wall and gate building
- Build placement preview with valid/invalid colors
- Player-built walls and gates with HP
- Gates allow the player to pass through
- Day/night cycle
- Enemy waves during day and night
- Enemy count increases by day
- Fast enemies unlock from day 2
- Breaker enemies unlock from day 4
- Enemy HP and damage scale over time
- Enemies chase the player, attack the player, and destroy player buildings
- Weapon upgrades with resource cost
- HUD for resources, HP, weapon level, day, phase, and timer
- Start screen and restart after Game Over

## Controls

| Action | Input |
| --- | --- |
| Move | W / A / S / D |
| Shoot | Left Mouse Button or Space |
| Build Wall | 1 |
| Build Gate | 2 |
| Cancel Build | Right Mouse Button |
| Upgrade Weapon | F |
| Start Game | Enter |
| Restart After Game Over | R |

## How To Run

1. Install Godot 4.x.
2. Clone this repository.
3. Open the project folder in Godot.
4. Run the project. The main scene is `res://scenes/Main.tscn`.
5. Press `Enter` to start.

## Project Structure

```text
res://
├── data/
│   ├── building_config.json
│   ├── enemy_config.json
│   ├── game_config.json
│   ├── wave_config.json
│   └── weapon_config.json
├── scenes/
│   ├── BuildGate.tscn
│   ├── BuildWall.tscn
│   ├── Enemy.tscn
│   ├── Main.tscn
│   ├── Player.tscn
│   ├── Projectile.tscn
│   ├── ResourceNode.tscn
│   └── UI.tscn
└── scripts/
    ├── build_manager.gd
    ├── buildable.gd
    ├── day_night_manager.gd
    ├── enemy.gd
    ├── game_manager.gd
    ├── player.gd
    ├── projectile.gd
    ├── resource_node.gd
    ├── ui.gd
    ├── wave_manager.gd
    └── weapon_manager.gd
```

## Gameplay Notes

- The current day/night duration is set to 15 seconds each in `data/game_config.json` for quick testing.
- Resource nodes are blue stars and are collected automatically when the player walks over them.
- Purple blocks are player-built walls.
- Green blocks are player-built gates.
- Black walls are default map walls and cannot be destroyed.
- Red circles are enemies.
- Yellow triangle is the player.

## Known Limitations

- Enemy pathfinding is still simple direct chasing, so enemies can get stuck on default map walls.
- The fixed map is still authored directly inside `Main.tscn`.
- There are no final art assets, animations, sound effects, or particle systems yet.
- Building UI is minimal and does not yet show selected build mode or building HP.

## Suggested Next Steps

- Replace simple enemy chasing with `NavigationAgent2D` or `AStarGrid2D`.
- Split the map out into separate map scenes such as `scenes/maps/TestMap.tscn`.
- Add building HP bars, repair, and demolish tools.
- Spawn night enemies in timed sub-waves instead of all at once.
- Add placeholder sound effects for shooting, hit, pickup, build, and death.
