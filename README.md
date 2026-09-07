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

## Not Yet Implemented

- Fate locks and the Level 2 deterministic black reply.
- Temporal rook and overlap handling.
- Board interaction, timeline UI, undo, saves, and the desktop UI.
