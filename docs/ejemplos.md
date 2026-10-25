<p><a href="examples.md">English</a> · <b>Español</b></p>

# Ejemplos reales

Todo esto se probó el 21 y 22 de octubre de 2026 en una Mac con chip Apple, REAPER 7.14 y Claude Code, **sobre copias** de audios de una sesión real (24 archivos de unos 3 minutos). Los tiempos son de reloj, no estimados. Cada acción en REAPER queda como un paso de deshacer.

## Armar la sesión desde una carpeta
> «armá una sesión con los audios de /ruta/a/la/carpeta»

- Resultado: **30 pistas** (24 audios, 6 carpetas) con color por familia, todos alineados en el compás 1.
- Tiempo: de 70 a 157 segundos. Casi todo es la IA pensando; REAPER tarda menos de un segundo.
- Cuando los nombres no dicen nada (`Audio_001`), clasifica midiendo y **te marca las dudas**. Revisalas vos.

## Armar la sesión dentro de tu template
> «abrí mi plantilla en una pestaña nueva y armá la sesión de esta carpeta dentro de sus carpetas»

- Resultado: 36 pistas (13 de la plantilla + 23 nuevas), los **22 plugins de la plantilla intactos**, colores y carpetas sin cambios, y el archivo de la plantilla sin tocar.
- Tiempo: 107 segundos.

## Eses en las voces
> «pasale eses a las voces»

- Resultado: 3 voces con unas 44 a 47 eses detectadas, reducción de hasta 8 dB. Se crea una copia («- Velador DS»); **el original queda intacto** como toma 1 para comparar.
- Tiempo: 98 segundos.

## Stems por familia
> «exportame los stems por familia»

- Resultado: 5 archivos WAV (batería, bajo, sintes, voces, ambientes), todos del mismo largo y empezando en 0, con los volúmenes de la sesión.
- Tiempo: 111 segundos. Solo exporta cuando se lo pedís con esas palabras.

## Un sample de tu carpeta
> «traeme un kick seco y corto de mis samples»

- Resultado: 3 opciones con duración, cola medida y pico, y un aviso cuando un archivo viene pasado de nivel.
- Tiempo: 16 segundos con 13.000 samples indexados (el índice tardó 37 segundos en armarse).

## Ordenar y medir sin abrir ningún programa
`cable ordenar ./mi-carpeta` copia los audios por familia (`BAT 01 - Kick.wav`), deja la hoja con volumen, pico, balance y fase, y marca con `?` lo que dedujo midiendo.

- 27 audios en 87 segundos.
- Sirve en cualquier programa: Ableton, Logic, Pro Tools, lo que uses.

## Lo que no hace (todavía)
- No escucha: mide. El criterio es tuyo.
- Logic: ordena y nombra las pistas, pero no pone colores ni exporta stems.
- Probado solo en REAPER 7 sobre Mac con chip Apple.

¿Probaste algo distinto? [Contanos tu ejemplo](../../../issues/new?template=ejemplo.yml).
