# Chase the Score

Procedural vertical platformer prototype built to the GDD: climb an endless tower toward the music source, loot Sound Cards from enemies, and spend them as guns or discard them for movement skills. All art and audio are **engine-node placeholders** designed to be swapped out.

Godot 4.7 · GL Compatibility. Open the folder in Godot and press F5 (`src/main/main.tscn` is the main scene).

## Controls

| Action | Keys |
| --- | --- |
| Move | A/D |
| Jump | Space |
| Aim | Mouse movement |
| Attack/Fire | Left click |
| Use skill card | Right click |
| Swap skill card | Shift |
| Pause | Esc |
| Restart | R |

The game launches to a title screen (any key or START to play). Pressing R mid-run kills you instantly and shows the score screen; pressing R again restarts. Esc pauses with Master/Music/SFX sliders — saved to `user://settings.cfg`.

All weapons and directional discard skills (Meteor Launch, Grapple Hook) aim from the player toward the crosshair. With no usable card in the active slot you always have the **default melee** — a Neon White-style slash toward the crosshair that also parries enemy projectiles and breaks blocks. Stomp enemies Downwell-style by landing on their heads. Shotgun recoil pushes you opposite your aim — shoot down to boost up.

## Project layout

```
src/
  autoload/    game_state.gd (score/multiplier/high score), audio_director.gd (music layers + beat clock)
  cards/       card_data.gd — the five Sound Card definitions
  player/      player.tscn/.gd — movement, stomp, 2-slot card inventory, fire + discard abilities
  projectiles/ projectile.tscn (all bullets), explosion.tscn
  enemies/     enemy_base.gd + hopper (PITCH), glitch_shell (TEMPO), bass_block (FORTE),
			   hook_weaver (CHORD), metronome (REST) — each guarantees its card drop
  pickups/     card_pickup (magnetic drop), butterfly (softlock fail-safe drop)
  level/       chunk_library.gd (ASCII chunk maps + REQ tags), chunk_generator.gd (stacking, look-ahead,
			   softlock watchdog, cleanup), platform_tile, one_way_platform, breakable_block,
			   music_source.gd (proximity target), kill_line.gd (rising hazard)
  ui/          hud.gd — score, multiplier, HP dots, card slots, Proximity Meter, game over
  main/        main.tscn/.gd — game loop, camera, proximity scoring, multiplier decay
```

## GDD systems implemented

- **Proximity scoring** — baseline score rate scales with closeness to the music source (`main.gd`); multiplier grows while climbing and decays after 1.5 s of stalling. High score persists to `user://highscore.save`.
- **Dynamic soundtrack hooks** — `audio_director.gd` fades drum/lead layers with distance and exposes `play_fill()` stingers per discard; a 120 BPM beat signal drives platform/enemy/UI pulsing.
- **Sound Cards** — PITCH, TEMPO, FORTE, and CHORD each have Standard Fire + Discard Ability per the GDD table; REST drops heal 1 HP instantly on pickup instead of taking a slot. Neon White rule: firing the last round spends the card entirely — burning all your ammo means losing the discard skill (that's what the stomp path and butterfly fail-safes are for).
- **Guaranteed drop economy** — every enemy death spawns its card pickup.
- **Chunk-Based Dependency Grid** — `chunk_library.gd` chunks carry `req` tags; the `!` marker hard-codes the key enemy at the base of every lock (Look-Ahead Rule). Holding the required card in either slot raises that chunk's selection weight (Dual-Card Safeguard).
- **Fail-safes** — REQ chunks include hopper stomp paths, and standing 4 s in a chunk's safe zone without the required card summons the butterfly carrying it (collecting resets the multiplier).

## Replacing the placeholder art

Every entity keeps its look inside a node named `Visual` (ColorRects/Labels) or in a `_draw()` block marked `REPLACE ART`:

- **Scenes** (`player.tscn`, four enemy scenes, `card_pickup.tscn`, `butterfly.tscn`, `platform_tile.tscn`, `one_way_platform.tscn`, `breakable_block.tscn`, `projectile.tscn`): delete the `Visual` children and drop in a `Sprite2D`/`AnimatedSprite2D` named `Visual`. Collision shapes and scripts are untouched by the swap.
- **Drawn placeholders** (`explosion.gd`, `music_source.gd`, `kill_line.gd`, `melee_slash.gd`, `crosshair.gd`): replace the `_draw()` code with sprites/particles.
- **Walls** are plain ColorRect strips built in `chunk_generator.gd::_build_walls()`.
- **HUD** is built in code (`hud.gd`); swap for a themed scene when ready. All glyphs/icons (cards, enemies, menu buttons, ammo markers) are hand-drawn SVGs in `assets/icons/` — font-independent, so they render identically on web. Replace any .svg to reskin them.
- **Palette**: black `0a0a0a`, white `f2f2f2`, accent hot pink `ff2e88` — change the accent by find-replacing `ff2e88`.

## Audio

`assets/audio/` ships with a complete CC0 placeholder soundtrack: four phase-locked 120 BPM stems (bass/drums/pads/lead) mixed live by proximity to the music source, plus 15 one-shot stingers for weapons, discards, and events. All of it was procedurally synthesized for this project (`tools/generate_audio.py`) and dedicated CC0 — see `CREDITS.md`. To replace any file, drop a same-named `.ogg` into `assets/audio/` (stems must share one exact length; looping is set in code, no import settings needed) and update `CREDITS.md`.

## Adding chunks

Append a dictionary to `ChunkLibrary.CHUNKS`: 15-character rows (top first), legend at the top of the file. Standing platforms (`=`) are thin one-way strips you can jump up through; solid `#` blocks are for walls/floors/ceilings only. Keep main-route rises to ~3 rows, keep a platform near the top and bottom of every chunk so seams stay climbable, and place `!` plus `S` safe tiles in any chunk with a `req` tag.
