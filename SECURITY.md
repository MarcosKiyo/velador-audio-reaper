# Security

**English** · [Español](#español)

Status: **beta**. This software runs Lua code inside REAPER on behalf of an AI that uses your own Claude account. Try it on copies of your sessions first.

## What it does and doesn't do
- The panel launches the official Claude Code on your Mac with minimal permissions: only the `cable` command, plus reading and listing files. It cannot edit files, delete, rename, or run system commands from Lua.
- Every request to REAPER is a single undo step.
- It blocks renders and exports unless the request says "stems", "export", "render" or "bounce".
- Sample folders you add with `cable samples agregar` are read-only.
- **It never handles credentials:** you complete the sign-in yourself in Anthropic's official flow (Terminal). This tool does not ask for, see, store or forward your username, password, code or token. It sends no data to any server of ours; what Claude receives travels through your own account, under Anthropic's terms.
- It is not a sealed box: the request to the AI may include track and file names from your session.

## How to report a security problem
Use "Security › Report a vulnerability" in this repository's *Security* tab (private report). If it isn't available, open an *issue* **without** sensitive data and we'll answer there.

## What does not belong in this repository
Keys, tokens, personal paths, client names or real sessions. If you find any, tell us the same way.

---

## Español

### Seguridad

Estado: **beta**. Este software ejecuta código Lua dentro de REAPER a pedido de una IA que corre con tu propia cuenta de Claude. Usalo primero sobre copias de tus sesiones.

#### Lo que hace y lo que no
- La ventana lanza el Claude Code oficial de tu Mac con permisos mínimos: solo el comando `cable`, leer y listar archivos. No puede editar archivos, ni borrar, ni renombrar, ni ejecutar comandos del sistema desde Lua.
- Cada pedido a REAPER es un paso de deshacer.
- Bloquea renders y exportaciones salvo que el pedido diga «stems», «exportar», «render» o «bounce».
- Las carpetas de samples que agregues con `cable samples agregar` son de solo lectura.
- **No maneja credenciales:** el inicio de sesión lo completás vos en el flujo oficial de Anthropic (Terminal). Esta herramienta no pide, ve, guarda ni reenvía tu usuario, contraseña, código ni token. No envía datos a ningún servidor propio; lo que Claude recibe viaja por tu cuenta, bajo los términos de Anthropic.
- No es una caja cerrada: el pedido a la IA puede incluir nombres de pistas y de archivos de tu sesión.

#### Cómo reportar un problema de seguridad
Usá «Security › Report a vulnerability» en la pestaña *Security* de este repositorio (reporte privado). Si no está disponible, abrí un *issue* **sin** datos sensibles y te contestamos por ahí.

#### Qué no va en este repositorio
Claves, tokens, rutas personales, nombres de clientes ni sesiones reales. Si encontrás algo así, avisá por el mismo medio.
