<p><b>English</b> · <a href="ejemplos.md">Español</a></p>

# Real examples

All of this was tested on October 21–22, 2026 on a Mac with Apple Silicon, REAPER 7.14 and Claude Code, **on copies** of audio from a real session (24 files, about 3 minutes each). Timings are wall-clock, not estimates. Every action in REAPER is one undo step.

## Build a session from a folder
> "build a session from the audio files in /path/to/folder"

- Result: **30 tracks** (24 audio, 6 folders), color-coded by family, all aligned at bar 1.
- Time: 70 to 157 seconds. Most of it is the AI thinking; REAPER itself takes under a second.
- When the file names say nothing (`Audio_001`), it classifies by measurement and **flags its doubts**. Check those yourself.

## Build the session inside your own template
> "open my template in a new tab and build the session from this folder inside its folders"

- Result: 36 tracks (13 from the template + 23 new), the template's **22 plugins untouched**, colors and folders unchanged, and the template file itself left alone.
- Time: 107 seconds.

## De-ess the vocals
> "de-ess the vocals"

- Result: 3 vocal tracks with roughly 44 to 47 sibilants detected, up to 8 dB of reduction. A copy is created ("- Velador DS"); **the original stays intact** as take 1 so you can A/B.
- Time: 98 seconds.

## Stems by family
> "export stems by family"

- Result: 5 WAV files (drums, bass, synths, vocals, ambience), all the same length and starting at 0, with the session's levels.
- Time: 111 seconds. It only exports when you ask with those words.

## One sample from your own folders
> "bring me a dry, short kick from my samples"

- Result: 3 options with length, measured tail and peak, plus a warning when a file is clipped.
- Time: 16 seconds with 13,000 samples indexed (building the index took 37 seconds).

## Sort and measure without opening any DAW
`cable ordenar ./my-folder` copies the audio by family (`BAT 01 - Kick.wav`), writes a sheet with loudness, peak, balance and phase, and marks with `?` whatever it guessed from measurements.

- 27 files in 87 seconds.
- Works with any program: Ableton, Logic, Pro Tools, whatever you use.

## What it doesn't do (yet)
- It doesn't listen: it measures. The judgment is yours.
- Logic: it sorts and names the tracks, but doesn't add colors or export stems.
- Tested only on REAPER 7 on a Mac with Apple Silicon.

Tried something different? [Tell us your example](../../../issues/new?template=ejemplo.yml).
