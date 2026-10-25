<p><b>English</b> · <a href="logic.md">Español</a></p>

# Agent Cable with Logic Pro (tested on Logic Pro X 10.7.9, macOS)
Logic doesn't let other programs build tracks for it (no scripting API for that). What it does do: open a new project with one track per audio file you hand it, named after the file and all starting at bar 1. So the route is: sort first, open after.

## Steps (2 commands)
1. `cable ordenar <folder>`: sorted copy by family (`BAT 01 - Kick.wav`, `BAJ 01…`), `?` on the doubtful ones, same length from 0, plus `HOJA.html` with LUFS, balance and phase.
2. `cable logic <folder>_ORDENADA`: opens every file in Logic. Logic asks about the sample rate once: choose "Change project" (48 kHz). Without the command it is the same as dragging the files from the folder into Logic.

## Measured (27 files, 3 minutes each, Mac with Logic already open)
- `cable ordenar`: 87 s. Logic: about 30 s until you see all 27 tracks in order, named and aligned at bar 1 (you answer 1–2 dialogs: close the current project and the sample rate).
- Tested on 2026-10-21.

## What it does NOT do
- No colors, folders (groups) or buses: those go in your own Logic template (drag the tracks into your folders). REAPER and Ableton can do that on their own.
- FCPXML (`cable logic-xml`): tested; Logic 10.7.9 imports it but puts everything in ONE "Dialogue" track, even if each clip has its own role. It doesn't work for building tracks.
- Exporting stems ("File > Export > All Tracks as Audio Files") is not automated: do it by hand in Logic, then `cable medir <folder>` measures what you exported.
- The AI doesn't "listen": classification comes from the file name and, when there isn't one, from measurement.
