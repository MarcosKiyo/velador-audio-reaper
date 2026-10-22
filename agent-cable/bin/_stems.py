"""cable stems <carpeta_ORDENADA> [salida]: stems por familia sumando los audios de cada prefijo (BAT, BAJ, SYN, GTR, AMB, VOZ).
Suma simple, SIN efectos, volumenes ni paneos de ningun DAW: sirve para cualquier programa y para medir. Para stems con tu cadena de plugins, exporta desde tu DAW.
La referencia (REF) no entra. Originales intactos."""
import sys, re, time, subprocess
from pathlib import Path
import numpy as np

SR = 48000


def leer(f):
    r = subprocess.run(["ffmpeg", "-v", "error", "-i", str(f), "-ac", "2", "-ar", str(SR), "-f", "f32le", "-"], capture_output=True)
    return np.frombuffer(r.stdout, np.float32).reshape(-1, 2)


def main(carpeta, salida=None):
    t0 = time.time()
    src = Path(carpeta).expanduser()
    dst = Path(salida) if salida else src.parent / (src.name.replace("_ORDENADA", "") + "_STEMS")
    dst.mkdir(exist_ok=True)
    grupos = {}
    for f in sorted(src.iterdir()):
        if f.suffix.lower() not in {".wav", ".aif", ".aiff", ".flac", ".mp3"} or f.name.startswith("."):
            continue
        m = re.match(r"([A-Z]{3})\??\s", f.name)
        fam = m.group(1) if m else "OTROS"
        if fam == "REF":
            continue
        grupos.setdefault(fam, []).append(f)
    for fam, fs in grupos.items():
        mezcla = None
        for f in fs:
            x = leer(f)
            if mezcla is None:
                mezcla = x.astype(np.float64)
            else:
                n = max(len(mezcla), len(x))
                mezcla = np.pad(mezcla, ((0, n - len(mezcla)), (0, 0))) + np.pad(x.astype(np.float64), ((0, n - len(x)), (0, 0)))
        pico = float(np.abs(mezcla).max())
        out = dst / f"{fam}.wav"
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "f32le", "-ar", str(SR), "-ac", "2", "-i", "-", "-c:a", "pcm_s24le", str(out)],
                       input=np.clip(mezcla, -1, 1).astype(np.float32).tobytes(), check=True)
        aviso = "  AVISO: pico sobre 0 dBFS, recortado (baja los niveles antes de sumar)" if pico > 1 else ""
        print(f"{fam}: {len(fs)} pistas, pico {20 * np.log10(pico + 1e-12):.1f} dBFS{aviso}")
    print(f"{len(grupos)} stems en {dst} ({time.time() - t0:.1f} s)")


main(*sys.argv[1:3])
