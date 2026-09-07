# Chrono Chess MVP

[简体中文](README.zh-CN.md)

An original desktop chess-puzzle prototype built with Godot 4.7.2. It contains
the first two Chapter 1 puzzles, a deterministic rule engine, and an original
geometric placeholder presentation. No third-party game assets, copy, levels,
or UI layouts are included.

## Toolchain

- Godot: `4.7.2.stable`.
- Local executable used for verification:
  `F:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe`

## Start

Open `project.godot` in Godot 4.7.2 and run the project. The main scene is a
1280x720 desktop puzzle screen. It supports mouse selection, highlighted legal
destinations, `R` for rewind, `Z` for undo, and `Escape` to cancel a rewind
preview.

From this project directory, the installed GUI executable can also start the
game directly:

```powershell
& 'F:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe' --path .
```

## Test

```powershell
& 'F:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/TestRunner.gd
```

## Windows Export

`export_presets.cfg` contains a `Windows Desktop` x86_64 preset. Install the
matching Godot 4.7.2 export templates, create the output directory, then run:

```powershell
New-Item -ItemType Directory -Force build\windows
& 'F:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-release 'Windows Desktop' 'build\windows\ChronoChess.exe'
```

The preset is present in source control. The export itself has not been
validated on this machine because its 4.7.2 Windows export templates are not
installed.

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
- A playable Chapter 1 desktop UI: level switcher, custom-drawn board and
  pieces, inspector, undo/retry controls, rewind preview/confirmation, result
  dialog, and fixed-width timeline nodes with fate-lock and archive markers.
- Original geometric placeholder art only, including the chronal mark and
  programmatic piece silhouettes. No external game assets, writing, or levels
  are used.
- UI regression coverage for rewind confirmation, Escape cancellation, reset
  selection clearing, and archived timeline rendering.

## Local Save

Completed levels are stored atomically in Godot's local `user://` storage as
`chrono_chess_profile.json`. The game keeps the best white-action count for
each completed Chapter 1 puzzle.

## Not Yet Implemented

- A verified standalone Windows `.exe` export. This machine has the Godot
  editor but not the matching 4.7.2 export templates yet.
- Additional chapters, authored temporal-rook/overlap puzzle levels, audio,
  accessibility settings beyond keyboard operation, localization, or online
  play.
