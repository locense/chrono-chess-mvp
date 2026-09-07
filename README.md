# Chrono Chess MVP

An original desktop chess-puzzle prototype built with Godot 4.7.2. It contains
the first two Chapter 1 puzzles, a deterministic rule engine, and an original
geometric placeholder presentation. No third-party game assets, copy, levels,
or UI layouts are included.

## Toolchain

- Godot: `4.7.2.stable`.
- Local executable used for verification:
  `F:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe`

## Start

Open `project.godot` in Godot 4.7.2 and run the project. The playable scene is
added in the UI checkpoint.

## Test

```powershell
& 'F:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/TestRunner.gd
```

## Implemented

- Project configuration and stable piece/event data contracts.
- JSON definitions for Chapter 1, Levels 1 and 2.
- Deterministic ordinary-event replay and stable absolute-turn snapshots.
- Ordinary king, rook, knight, and bishop movement for puzzle capture rules.
- Single-timeline rewind with persistent energy and archived future events.
- Level 1 load, rewind, win, and direct-failure rule tests.
- Fate locks rebuilt from preplayed captures, including visible fate echoes.
- Synchronous deterministic black script support for Level 2.
- Level 2 solution and alternate-path fate-lock tests.
- Stable SHA-256 world-state hashing for deterministic replay checks.
- One temporal rook rule layer, stored outside ordinary timeline snapshots.
- Reality overlaps that freeze ordinary pieces and reject normal entry.
- Temporal annihilation against an enemy king, allied-king rejection, and
  temporal capture removal tests.
- Temporal projection validation across recorded history, including target-king
  turn windows and JSON-backed temporal capture replay.
- Session-level undo for confirmed moves and rewinds, using deep state copies.
- Atomic local completion profile writes with validated temporary files and a
  backup fallback.

## Not Yet Implemented

- Board interaction, timeline UI, and the desktop UI.
