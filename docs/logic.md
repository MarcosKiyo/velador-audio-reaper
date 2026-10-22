# Agent Cable en Logic Pro (probado en Logic Pro X 10.7.9, macOS)
Logic no deja que otro programa le arme pistas (sin API). Lo que sí hace: abre un proyecto nuevo con una pista por cada audio que le pasás, con el nombre del archivo y todos desde el compás 1. Por eso el camino es ordenar primero y abrir después.

## Pasos (2 comandos)
1. `cable ordenar <carpeta>`: copia ordenada por familia (`BAT 01 - Kick.wav`, `BAJ 01…`), «?» en los dudosos, mismo largo desde 0, y `HOJA.html` con LUFS, balance y fase.
2. `cable logic <carpeta>_ORDENADA`: abre todos los audios en Logic. Logic pregunta una vez la frecuencia: elegí «Cambiar proyecto» (48 kHz). Sin comando, es lo mismo que arrastrar los archivos de la carpeta a Logic.

## Medido (27 audios de 3 min, Mac con Logic ya abierto)
- `cable ordenar`: 87 s. Logic: ~30 s hasta ver las 27 pistas en orden, nombradas y alineadas en el compás 1 (hay que contestar 1-2 diálogos: cerrar el proyecto actual y la frecuencia).
- Probado el 21-10-2026.

## Qué NO hace
- No pone colores, carpetas (grupos) ni buses: eso va en tu template de Logic (arrastrar las pistas a tus carpetas). Ableton y REAPER sí lo hacen solos.
- FCPXML (`cable logic-xml`): probado, Logic 10.7.9 lo importa pero junta todo en UNA sola pista «Dialogue», aunque cada clip tenga su rol. No sirve para armar pistas.
- Exportar stems («Archivo > Exportar > Todas las pistas como archivos de audio») no se automatizó: se hace a mano en Logic y después `cable medir <carpeta>` mide lo exportado.
- Claude no «escucha»: la clasificación es por el nombre del archivo y, si no hay, por medición.
