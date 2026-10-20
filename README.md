# Super Snake

A Snake game for macOS where you earn the customization by playing.

Start with the classic look and unlock more as you go: a Nokia 3310 phone, a 90s CRT monitor with flicker and glow knobs, custom colors, and new CRT color schemes. Every unlock comes from an achievement.

## Game modes

- **Normal**: classic Snake. Field size, speed and the number of apples are under Extra settings.
- **Super Snake**: each apple has a chance to spawn a ★ power-up star:
  - **Nearby apples**: the next 5 apples appear within 7 spaces of your head
  - **Apples in a row**: 2 apples appear in a straight line, 3 spaces apart
  - **+4 apples**: 4 extra apples appear at once
  - **Big apple**: a large apple worth 4 points

  There is also a rare **rainbow star** that gives a one-time shield: pass through yourself once, or warp through a wall to the opposite side.

## Achievements

Open **Achievements** from the main menu to see the achievement trees. The **Classic** tree unlocks in order, and finishing part of it opens the **Super Snake** tree. Each achievement unlocks a new theme or color option.

## Controls

| Action | Keys |
| --- | --- |
| Move | Arrow keys, WASD, or 2 / 4 / 6 / 8 |
| Pause / resume | Space (or 5) |
| Start / play again | Enter |
| Back to menu | Esc |

## Build the Mac app

Requires macOS with the Xcode Command Line Tools (`xcode-select --install`).

```bash
./build.sh
```

This builds **Super Snake.app** and installs it into `/Applications`. You can also open `Snake.html` in any browser to play.
