<p align="right"><b>English</b> · <a href="README.es.md">Español</a></p>

<p align="center"><img src="assets/velador-estudio.jpg" alt="Estudio Velador" width="100%"></p>

# AI panel for REAPER

**REAPER + Claude Code integration.** A chat inside REAPER that sets up your mixing session, organizes your files, measures your tracks and exports stems. Made at [Estudio Velador](https://kiyo.ar), in Patagonia, Argentina.

<sub>Beta, in development: try it on a copy of your sessions. We keep improving it with your feedback.</sub>

> **Velador:** "AI measures, it doesn't listen. The taste is yours. This takes the boring part off your plate."

<p align="center"><img src="assets/sesion-armada.jpg" alt="Mixing session organized in folders and colors" width="320"></p>

## 🚀 Step by step (REAPER, Apple Silicon Mac)

1. 🎚️ **Install REAPER** → [reaper.fm/download.php](https://www.reaper.fm/download.php) and open it once.
2. 🧩 **Install ReaImGui** (in REAPER: *Extensions › ReaPack › Browse packages › ReaImGui*) → [download](https://github.com/cfillion/reaimgui/releases). Restart REAPER.
3. 💳 **Have a Claude plan** (Pro or higher) → [claude.com/pricing](https://claude.com/pricing). You pay for it; usage comes out of your own plan.
4. ⌨️ **Install Claude Code** → [official guide](https://code.claude.com/docs/en/setup). Check `claude --version`; if it is older than 2.1.280, run `claude update`.
5. 🍺 **Install the pieces** → [Homebrew](https://brew.sh), then in Terminal: `brew install ffmpeg` and `pip3 install numpy scipy`.
6. ⬇️ **Download this** → [Download ZIP](../../archive/refs/heads/main.zip).
7. ▶️ **Install**: in Terminal, inside the folder: `sh agent-cable/instalar.sh`.
8. 🪟 **Open the window**: in REAPER, *Actions › Show action list › New action › Load ReaScript…* → `AgentCable/AgentCable.lua` → run.
9. 🔑 **Sign in**: *Iniciar sesión* button. Terminal opens with the **official Anthropic login**; you complete it there.
10. 💬 **Type** (examples below) and press Enter. Every action can be undone with **Cmd+Z**.

> **Velador:** "Start with a folder of test audio, not with a client's session."

The panel speaks Spanish today, but you can write your requests in English.

## ✍️ Try asking

| | |
|---|---|
| 📁 | "set up a session with the audio files in /path/to/folder" |
| 🗣️ | "de-ess the vocals" |
| 📦 | "export stems by instrument family" |
| 🥁 | "find me a short, dry kick in my samples" |

## 🧰 What's inside

- 📁 **`cable ordenar`** — copies your audio files sorted by instrument family (`BAT 01 - Kick.wav`) and gives you a sheet with loudness, balance and phase. Works with **any DAW**.
  > **Velador:** "The ones marked `?` were guessed by measuring: check them yourself."
- 📦 **`cable stems`** — stems by family, summing the files (no effects).
- 📊 **`cable medir`** — measures every file and tells you which ones look like the same take.
- 🗣️ **`cable eses`** — de-esser on a copy. The original is never touched.
- 🥁 **`cable samples`** — search your sample folders (read-only): `cable samples agregar "/your/folder"`.
- 🍎 **`cable logic`** — opens the files in Logic Pro, one track per file. [More info](docs/logic.md).

The commands live in `~/Library/Application Support/REAPER/Scripts/AgentCable/bin/`.

## 📖 Real examples

Real requests with measured timings: [docs/ejemplos.md](docs/ejemplos.md) (in Spanish).

## 💌 Write to me

I want to know what happened, what helped and what's missing.

- 🐞 **Something doesn't work** → [open an issue](../../issues/new/choose)
- 💡 **An idea or a request** → [Discussions](../../discussions)
- 🎚️ **Show me how you used it** → [share your example](../../issues/new?template=ejemplo.yml)
- 📷 **Direct message** → [@kiyo.velador](https://www.instagram.com/kiyo.velador/)

## 🛡️ Safety

- It can only use the `cable` command and read files: it doesn't delete, rename or render unless you ask.
- Your samples are read, **never** written.
- It never stores or sees your Claude username, password or code. [Details](SECURITY.md).
- Tested on **REAPER 7 + Apple Silicon Mac**. Everything else, untested. Logic: sorts and names, no colors.

## ℹ️ Notice

Independent project by Estudio Velador, **not affiliated with Anthropic**. "Claude" and "Claude Code" are trademarks of Anthropic. REAPER is made by Cockos. [MIT](LICENSE) license.

---
<p align="center"><b>Estudio Velador</b> · 🌐 <a href="https://kiyo.ar/en/"><b>kiyo.ar</b></a> · 📷 <a href="https://www.instagram.com/kiyo.velador/">@kiyo.velador</a></p>
