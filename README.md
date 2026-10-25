<p align="center"><img src="assets/velador-estudio.jpg" alt="Estudio Velador studio" width="100%"></p>

<p align="center"><b>English</b> · <a href="README.es.md">Español</a></p>

# AI panel for REAPER

**REAPER + Claude Code integration.** A chat panel inside REAPER that builds your mixing session from a folder of audio, sorts files, measures levels and exports stems. Made at [Estudio Velador](https://kiyo.ar), in Patagonia, Argentina.

<sub>Beta, in development: try it on a copy of your sessions. We improve it with what you tell us.</sub>

> **Velador:** "The AI measures, it doesn't listen. The judgment is yours. This just takes the boring part off your plate."

<p align="center"><img src="assets/sesion-armada.jpg" alt="A session built by the panel: color-coded folders and tracks" width="320"></p>

## 🚀 Step by step (REAPER, Mac with Apple Silicon)

1. 🎚️ **Install REAPER** → [reaper.fm/download.php](https://www.reaper.fm/download.php) and open it once.
2. 🧩 **Install ReaImGui** (in REAPER: *Extensions › ReaPack › Browse packages › ReaImGui*) → [download](https://github.com/cfillion/reaimgui/releases). Restart REAPER.
3. 💳 **Get a Claude plan** (Pro or higher) → [claude.com/pricing](https://claude.com/pricing). You pay for it yourself; usage comes out of your plan.
4. ⌨️ **Install Claude Code** → [official guide](https://code.claude.com/docs/en/setup). Check with `claude --version`; if it is older than 2.1.280, run `claude update`.
5. 🍺 **Install the pieces** → [Homebrew](https://brew.sh), then in Terminal: `brew install ffmpeg` and `pip3 install numpy scipy`.
6. ⬇️ **Download this** → [Download ZIP](../../archive/refs/heads/main.zip).
7. ▶️ **Install**: in Terminal, inside the folder: `sh agent-cable/instalar.sh`.
8. 🪟 **Open the panel**: in REAPER, *Actions › Show action list › New action › Load ReaScript…* → `AgentCable/AgentCable.lua` → run.
9. 🔑 **Sign in**: click *Iniciar sesión* (sign in). Terminal opens with Anthropic's **official** login; you finish it there. The panel never sees your password or code.
10. 💬 **Type** a request (examples below) and press Enter. Every action in REAPER can be undone with **Cmd+Z**.

> **Velador:** "Start with a folder of test audio, not with a client's session."

> Heads up: the panel and the assistant's replies are in Spanish for now. An English version is planned.

## ✍️ Try asking

| | |
|---|---|
| 📁 | "build a session from the audio files in /path/to/folder" |
| 🗣️ | "de-ess the vocals" |
| 📦 | "export stems by family" |
| 🥁 | "bring me a dry, short kick from my samples" |

## 🧰 What's inside

- 📁 **`cable ordenar`** (sort): copies your audio sorted by family (`BAT 01 - Kick.wav`) and gives you a sheet with loudness (LUFS), balance and phase. Works with **any DAW**.
  > **Velador:** "The ones marked `?` were guessed from measurements: double-check them yourself."
- 📦 **`cable stems`**: stems by family, summing the files (no effects).
- 📊 **`cable medir`** (measure): measures every file and tells you which tracks look like the same take.
- 🗣️ **`cable eses`** (de-esser): a de-esser that works on a copy. The original is never touched.
- 🥁 **`cable samples`**: sample search across your own folders (read-only): `cable samples agregar "/your/folder"`.
- 🍎 **`cable logic`**: opens the audio in Logic Pro, one track per file. [More info](docs/logic.en.md).

The commands live in `~/Library/Application Support/REAPER/Scripts/AgentCable/bin/`.

## 📖 Real examples

Actual requests with measured timings: [docs/examples.md](docs/examples.md).

## 💌 Get in touch

I want to hear what happened, what helped, and what's missing.

- 🐞 **Something broke** → [open an issue](../../issues/new/choose)
- 💡 **An idea or a request** → [Discussions](../../discussions)
- 🎚️ **Show me how you used it** → [share your example](../../issues/new?template=ejemplo.yml)
- 📷 **Direct message** → [@kiyo.velador](https://www.instagram.com/kiyo.velador/)

## 🛡️ Safety

- It can only use the `cable` command and read files: it does not delete, rename, or render unless you ask.
- Your samples are read, **never** written.
- It does not store or see your Claude username, password, or login code. [Details](SECURITY.md).
- Tested on **REAPER 7 + Mac with Apple Silicon**. Anything else is untested. Logic: sorts and names tracks, no colors.

## ℹ️ Notice

An independent project by Estudio Velador, **not affiliated with Anthropic**. "Claude" and "Claude Code" are trademarks of Anthropic. REAPER is by Cockos. [MIT license](LICENSE).

---
<p align="center"><b>Estudio Velador</b> · 🌐 <a href="https://kiyo.ar"><b>kiyo.ar</b></a> · 📷 <a href="https://www.instagram.com/kiyo.velador/">@kiyo.velador</a></p>
