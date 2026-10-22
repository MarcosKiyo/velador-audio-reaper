"""cable logic <carpeta_ORDENADA> [salida.fcpxml]: genera un FCPXML (una pista de audio por archivo, nombrada, desde 0) para
Logic Pro: File > Import > Final Cut Pro XML. Orden = orden alfabetico de la carpeta (BAT, BAJ, SYN... gracias a `cable ordenar`)."""
import sys, subprocess
from pathlib import Path
from urllib.parse import quote
from xml.sax.saxutils import quoteattr

RATE = 48000


def muestras(f):
    r = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries", "stream=duration,sample_rate", "-of", "csv=p=0", str(f)],
                       capture_output=True, text=True).stdout.strip().split(",")
    return round(float(r[1]) * float(r[0]))  # segundos * sample_rate de ESE archivo (la carpeta ordenada ya viene a 48 kHz)


def main(carpeta, salida=None):
    src = Path(carpeta).expanduser().resolve()
    fs = sorted(f for f in src.iterdir() if f.suffix.lower() in {".wav", ".aif", ".aiff", ".flac", ".mp3", ".m4a"} and not f.name.startswith("."))
    if not fs:
        sys.exit("no hay audios en " + str(src))
    dst = Path(salida) if salida else src.parent / (src.name + ".fcpxml")
    n = [muestras(f) for f in fs]
    total = max(n)
    res, lanes = [], []
    for i, (f, m) in enumerate(zip(fs, n), 1):
        nombre = f.stem
        rol = nombre.replace('.', ' ')
        res.append(f'    <asset id="a{i}" name={quoteattr(nombre)} src="file://{quote(str(f))}" start="0s" duration="{m}/{RATE}s" hasAudio="1" audioSources="1" audioChannels="2" audioRate="{RATE}"/>')
        lanes.append(f'            <asset-clip ref="a{i}" lane="{i}" offset="0s" name={quoteattr(nombre)} duration="{m}/{RATE}s" start="0s" audioRole="dialogue.{rol}"/>')
    xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>
<fcpxml version="1.8">
  <resources>
    <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
{chr(10).join(res)}
  </resources>
  <library>
    <event name={quoteattr(src.name)}>
      <project name={quoteattr(src.name)}>
        <sequence format="r1" duration="{total}/{RATE}s" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
          <spine>
            <gap name="Gap" offset="0s" duration="{total}/{RATE}s" start="0s">
{chr(10).join(lanes)}
            </gap>
          </spine>
        </sequence>
      </project>
    </event>
  </library>
</fcpxml>
'''
    dst.write_text(xml)
    print(f"{len(fs)} pistas -> {dst}")


main(*sys.argv[1:3])
