# Seguridad

Estado: **beta**. Este software ejecuta código Lua dentro de REAPER a pedido de una IA que corre con tu propia cuenta de Claude. Usalo primero sobre copias de tus sesiones.

## Lo que hace y lo que no
- La ventana lanza el Claude Code oficial de tu Mac con permisos mínimos: solo el comando `cable`, leer y listar archivos. No puede editar archivos, ni borrar, ni renombrar, ni ejecutar comandos del sistema desde Lua.
- Cada pedido a REAPER es un paso de deshacer.
- Bloquea renders y exportaciones salvo que el pedido diga «stems», «exportar», «render» o «bounce».
- Las carpetas de samples que agregues con `cable samples agregar` son de solo lectura.
- **No maneja credenciales:** el inicio de sesión lo completás vos en el flujo oficial de Anthropic (Terminal). Esta herramienta no pide, ve, guarda ni reenvía tu usuario, contraseña, código ni token. No envía datos a ningún servidor propio; lo que Claude recibe viaja por tu cuenta, bajo los términos de Anthropic.
- No es una caja cerrada: el pedido a la IA puede incluir nombres de pistas y de archivos de tu sesión.

## Cómo reportar un problema de seguridad
Usá «Security › Report a vulnerability» en la pestaña *Security* de este repositorio (reporte privado). Si no está disponible, abrí un *issue* **sin** datos sensibles y te contestamos por ahí.

## Qué no va en este repositorio
Claves, tokens, rutas personales, nombres de clientes ni sesiones reales. Si encontrás algo así, avisá por el mismo medio.
