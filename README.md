# Kiyo Herramientas

> ## ⚠️ BETA · EN DESARROLLO
> Esto es una versión de prueba que se está armando a la vista de todos. Funciona en las pruebas que hicimos, pero puede fallar, cambiar sin aviso y no está listo para trabajo de clientes sin que lo pruebes antes **sobre una copia**. Si algo no anda, abrí un *issue* y lo miramos.

Herramientas de **Kiyo Velador** ([kiyo.ar](https://kiyo.ar)) para mezclar más rápido con ayuda de una IA: una ventana de chat **dentro de REAPER** que arma sesiones, ordena archivos, mide y exporta, y comandos sueltos que sirven en cualquier programa de audio.

La IA **mide** (nivel, graves/medios/agudos, balance, fase), no «escucha». El criterio final es tuyo: la herramienta hace lo operativo y vos decidís.

## Qué necesitás
| Qué | Dónde | Costo |
|---|---|---|
| Una Mac con chip Apple (M1 o más nuevo). Windows y Mac Intel: sin probar | — | — |
| REAPER 7 | [reaper.fm/download.php](https://www.reaper.fm/download.php) | licencia propia de REAPER (hay prueba) |
| Una cuenta de **Claude** con plan de pago (Pro o superior) | [claude.com/pricing](https://claude.com/pricing) | lo pagás vos a Anthropic; hoy Pro figura en USD 20 por mes |
| **Claude Code** (el programa oficial de Anthropic) | [Instalación oficial](https://code.claude.com/docs/en/setup) | incluido en tu plan |
| ReaImGui (extensión de REAPER) | [github.com/cfillion/reaimgui](https://github.com/cfillion/reaimgui/releases) o ReaPack | gratis |
| `python3` con `numpy` y `scipy`, y `ffmpeg` | [brew.sh](https://brew.sh) → `brew install ffmpeg` y `pip3 install numpy scipy` | gratis |

Importante: **cada persona usa su propia cuenta de Claude**. Estas herramientas no te dan acceso a Claude, no guardan tu usuario ni tu contraseña y no pasan por ningún servidor nuestro. Usan el Claude Code oficial que instalás vos. Los pedidos gastan de la cuota de tu plan.

## Paso a paso para REAPER
1. **Instalá REAPER** desde el link de arriba y abrilo una vez.
2. **Instalá ReaImGui**: en REAPER, `Extensions › ReaPack › Browse packages` → buscá *ReaImGui* → instalar → reiniciá REAPER. (Sin ReaPack: bajá `reaper_imgui-arm64.dylib` de la [página de versiones](https://github.com/cfillion/reaimgui/releases) y ponelo en `~/Library/Application Support/REAPER/UserPlugins/`.)
3. **Instalá Claude Code** siguiendo la [guía oficial](https://code.claude.com/docs/en/setup) y comprobá en la Terminal que anda: `claude --version`. Se necesita la versión 2.1.280 o más nueva para usar los modelos Claude 5.5; actualizá con `claude update`.
4. **Bajá estas herramientas**: botón verde *Code › Download ZIP* de este repositorio, o `git clone https://github.com/MarcosKiyo/kiyo-herramientas.git`.
5. **Instalá**: en la Terminal, dentro de la carpeta descargada: `sh agent-cable/instalar.sh`. Copia todo a `~/Library/Application Support/REAPER/Scripts/AgentCable/`.
6. **Cargá la ventana en REAPER**: `Actions › Show action list › New action › Load ReaScript…` → elegí `AgentCable/AgentCable.lua` → ejecutala. Aparece el chat; podés acoplarlo arrastrándolo.
7. **Iniciá sesión en Claude**: si todavía no la iniciaste, el chat muestra el botón *Iniciar sesión (abre la Terminal)*. Se abre el inicio de sesión **oficial de Anthropic** en la Terminal; lo completás ahí. La ventana no ve tu clave ni ningún código.

## Primer uso (sobre una copia de tu sesión o con audios de prueba)
Escribí en el chat y Enter. Ejemplos:
- «armá una sesión con los audios de /ruta/a/la/carpeta»
- «pasale eses a las voces»
- «exportame los stems por familia» *(solo exporta si lo pedís con esas palabras)*
- «traeme un kick seco y corto de mis samples»
Cada acción en REAPER queda como un **paso de deshacer** (Cmd+Z).

## Qué hace cada herramienta
| Herramienta | Qué hace | Cómo se usa |
|---|---|---|
| **Ventana de chat** (`AgentCable.lua`) | habla con tu Claude Code y actúa sobre la sesión abierta | dentro de REAPER |
| `cable ordenar <carpeta>` | copia los audios a una carpeta ordenada por familia (`BAT 01 - Kick.wav`…), `?` en los dudosos, todos desde 0 y del mismo largo, y crea una hoja con LUFS, pico, balance y fase | cualquier programa |
| `cable stems <carpeta_ORDENADA>` | stems por familia **sumando los archivos, sin efectos** | cualquier programa |
| `cable medir <carpeta>` | tabla de medición de cada audio y qué pistas parecen la misma toma | cualquier programa |
| `cable eses <voz.wav>` | de-esser por automatización: crea una copia «- Orejitas DS», el original no se toca | cualquier programa |
| `cable samples …` | índice de tus carpetas de samples (solo lectura) y búsqueda con medición | `cable samples agregar "/ruta"`, `indexar`, `buscar "kick seco corto"` |
| `cable logic <carpeta_ORDENADA>` | abre los audios en Logic Pro: una pista por archivo, nombrada y desde el compás 1 | Mac con Logic. Ver [docs/logic.md](docs/logic.md) |
Los comandos `cable …` están en `~/Library/Application Support/REAPER/Scripts/AgentCable/bin/`.

## Límites (para no prometer de más)
- Probado en **REAPER 7 sobre Mac con chip Apple**. Otros sistemas, sin probar.
- Logic: ordena y nombra, **no** pone colores ni exporta stems solo. Ableton y otros programas: por ahora solo el camino de archivos (`ordenar`, `stems`).
- Con nombres de archivo genéricos (`Audio_001`), la clasificación por medición acierta poco; los dudosos van marcados con `?`.
- Un pedido tarda lo que tarde la IA (de decenas de segundos a unos minutos). Desde la ventana, REAPER mismo responde en menos de un segundo.
- Es una sola conversación en la ventana. Si trabajás en un proyecto real, **probá primero sobre una copia**.

## Seguridad
- Claude solo puede usar el comando `cable`, leer archivos y listarlos. No puede borrar, renombrar ni ejecutar comandos desde la ventana de REAPER, ni renderizar si no lo pedís.
- Tus carpetas de samples se leen, **nunca** se escriben.
- Detalle y cómo reportar un problema: [SECURITY.md](SECURITY.md).

## Aviso
Proyecto independiente de Kiyo Velador. **No está afiliado ni respaldado por Anthropic.** «Claude» y «Claude Code» son marcas de Anthropic; acá solo se menciona que se usa Claude Code. REAPER es de Cockos. Licencia [MIT](LICENSE): usalo, modificalo y compartilo, sin garantía.

---
Más contenido y novedades: **[kiyo.ar](https://kiyo.ar)** · Instagram [@kiyo.velador](https://www.instagram.com/kiyo.velador/)
