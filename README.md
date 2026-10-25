<p align="center"><img src="assets/velador-estudio.jpg" alt="Estudio Velador studio" width="100%"></p>

<p align="center">English + Español en la misma página · <a href="README.es.md">versión completa en español</a></p>

# AI panel for REAPER · Panel de IA para REAPER

**REAPER + Claude Code: Claude for REAPER.** A chat panel inside REAPER that builds your mixing session from a folder of audio, sorts files, measures levels and exports stems.<br>
**REAPER + Claude Code: Claude para REAPER.** Un chat dentro de REAPER que arma tu sesión de mezcla desde una carpeta de audios, ordena archivos, mide niveles y exporta stems.

Made at / Hecho en [Estudio Velador](https://kiyo.ar), Patagonia, Argentina.

<sub>Beta: try it on a copy of your sessions · probalo sobre una copia de tus sesiones. We improve it with your feedback · lo mejoramos con lo que nos cuentes.</sub>

> **Velador:** "The AI measures, it doesn't listen. The judgment is yours." · «La IA mide, no escucha. El criterio es tuyo. Esto te saca lo aburrido.»

<p align="center"><img src="assets/sesion-armada.jpg" alt="A session built by the panel: color-coded folders and tracks · sesión armada con carpetas y colores" width="320"></p>

## 🚀 Step by step · Paso a paso (REAPER, Mac with Apple Silicon · Mac con chip Apple)

1. 🎚️ **Install REAPER · Instalá REAPER** → [reaper.fm/download.php](https://www.reaper.fm/download.php). Open it once · abrilo una vez.
2. 🧩 **Install ReaImGui · Instalá ReaImGui** (*Extensions › ReaPack › Browse packages › ReaImGui*) → [download · descarga](https://github.com/cfillion/reaimgui/releases). Restart REAPER · reiniciá REAPER.
3. 💳 **Get a Claude plan · Tené un plan de Claude** (Pro or higher · Pro o más) → [claude.com/pricing](https://claude.com/pricing). You pay it, usage comes from your plan · lo pagás vos y el uso sale de tu plan.
4. ⌨️ **Install Claude Code · Instalá Claude Code** → [official guide · guía oficial](https://code.claude.com/docs/en/setup). `claude --version`; if older than 2.1.280 · si es menor a 2.1.280: `claude update`.
5. 🍺 **Install the pieces · Instalá las piezas** → [Homebrew](https://brew.sh), then in Terminal · y en la Terminal: `brew install ffmpeg` and · y `pip3 install numpy scipy`.
6. ⬇️ **Download this · Bajá esto** → [Download ZIP](../../archive/refs/heads/main.zip).
7. ▶️ **Install · Instalá**: in Terminal, inside the folder · en la Terminal, dentro de la carpeta: `sh agent-cable/instalar.sh`.
8. 🪟 **Open the panel · Abrí la ventana**: *Actions › Show action list › New action › Load ReaScript…* → `AgentCable/AgentCable.lua` → run · ejecutar.
9. 🔑 **Sign in · Iniciá sesión**: button *Iniciar sesión*. Terminal opens Anthropic's **official** login; you finish it there · se abre la Terminal con el login **oficial** de Anthropic y lo completás ahí. The panel never sees your password or code · el panel nunca ve tu contraseña ni tu código.
10. 💬 **Type a request · Escribí un pedido** (examples below · ejemplos abajo) and press Enter. Every action can be undone with **Cmd+Z** · cada acción se deshace con **Cmd+Z**.

> **Velador:** "Start with a folder of test audio, not with a client's session." · «Empezá con una carpeta de audios de prueba, no con la sesión de un cliente.»

> The panel answers in Spanish for now; you can write in English · el panel responde en español por ahora; podés escribirle en inglés.

## ✍️ Try asking · Probá pedirle

| | English | Español |
|---|---|---|
| 📁 | "build a session from the audio files in /path/to/folder" | «armá una sesión con los audios de /ruta/a/la/carpeta» |
| 🗣️ | "de-ess the vocals" | «pasale eses a las voces» |
| 📦 | "export stems by family" | «exportame los stems por familia» |
| 🥁 | "bring me a dry, short kick from my samples" | «traeme un kick seco y corto de mis samples» |

## 🧰 What's inside · Qué trae

- 📁 **`cable ordenar`** — copies your audio sorted by family (`BAT 01 - Kick.wav`) with a sheet of loudness (LUFS), balance and phase; works with **any DAW** · copia tus audios ordenados por familia y te da una hoja con volumen, balance y fase; sirve en **cualquier programa**.
  > **Velador:** "Files marked `?` were guessed from measurements: check them." · «Los que tienen `?` los dedujo midiendo: revisalos vos.»
- 📦 **`cable stems`** — stems by family, summing the files, no effects · stems por familia, sumando los archivos, sin efectos.
- 📊 **`cable medir`** — measures every file and finds what looks like the same take · mide cada audio y te dice cuáles parecen la misma toma.
- 🗣️ **`cable eses`** — de-esser on a copy, the original is never touched · de-esser en una copia, el original no se toca.
- 🥁 **`cable samples`** — sample search in your own folders, read-only · buscador en tus carpetas de samples, solo lectura: `cable samples agregar "/your/folder"`.
- 🍎 **`cable logic`** — opens the audio in Logic Pro, one track per file · abre los audios en Logic, una pista por archivo. [More info](docs/logic.en.md) · [Más info](docs/logic.md).

Commands live in · Los comandos están en `~/Library/Application Support/REAPER/Scripts/AgentCable/bin/`.

## 📖 Real examples · Ejemplos reales

Actual requests with measured timings · pedidos de verdad con tiempos medidos: [English](docs/examples.md) · [Español](docs/ejemplos.md).

## 💌 Get in touch · Escribime

- 🐞 **Something broke · Algo no anda** → [open an issue · abrí un issue](../../issues/new/choose)
- 💡 **An idea or a request · Una idea o un pedido** → [Discussions · Discusiones](../../discussions)
- 🎚️ **Show me how you used it · Mostrame cómo lo usaste** → [share your example · contame tu ejemplo](../../issues/new?template=ejemplo.yml)
- 📷 **Direct message · Mensaje directo** → [@kiyo.velador](https://www.instagram.com/kiyo.velador/)

## 🛡️ Safety · Cuidado

- Only the `cable` command and reading files: no deleting, renaming or rendering unless you ask · solo el comando `cable` y leer archivos: no borra, no renombra y no renderiza si no se lo pedís.
- Your samples are read, **never** written · tus samples se leen, **nunca** se escriben.
- It never stores or sees your Claude username, password or code · no guarda ni ve tu usuario, contraseña ni código de Claude. [Details · Detalle](SECURITY.md).
- Tested on **REAPER 7 + Apple Silicon Mac**; the rest is untested · probado en **REAPER 7 + Mac con chip Apple**; lo demás, sin probar.

## ℹ️ Notice · Aviso

Independent project by Estudio Velador, **not affiliated with Anthropic** · proyecto independiente, **no afiliado a Anthropic**. "Claude" and "Claude Code" are trademarks of Anthropic · son marcas de Anthropic. REAPER is by Cockos · REAPER es de Cockos. [MIT](LICENSE).

---
<p align="center"><b>Estudio Velador</b> · 🌐 <a href="https://kiyo.ar"><b>kiyo.ar</b></a> · 📷 <a href="https://www.instagram.com/kiyo.velador/">@kiyo.velador</a></p>
