"""cable samples indexar | buscar "<pedido>" [--n 5] | estado
Indice local (SQLite) de tus carpetas de samples + busqueda con medicion. SOLO LECTURA: nunca mueve, renombra ni borra nada.
Carpetas: las de samples.cfg (una ruta por linea; se agregan con `cable samples agregar <carpeta>`)."""
import os, re, sys, sqlite3, subprocess, time, wave, json
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import numpy as np

AQUI = Path(__file__).resolve().parent
DB = AQUI.parent / "samples.db"
CFG = AQUI.parent / "samples.cfg"
DEFAULT = []
EXT = {".wav", ".aif", ".aiff", ".flac", ".mp3", ".m4a", ".ogg"}
SR = 22050


def carpetas():
    return [l.strip() for l in CFG.read_text().splitlines() if l.strip()] if CFG.exists() else DEFAULT


def conectar():
    c = sqlite3.connect(DB)
    c.execute("create table if not exists s(path text primary key, name text, folder text, ext text, size int, dur real, bpm int, key text, mtime real)")
    c.execute("create index if not exists i_name on s(name)")
    return c


def dur_wav(p):
    try:
        with wave.open(str(p)) as w:
            return w.getnframes() / w.getframerate()
    except Exception:
        return None


def dur_ffprobe(p):
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(p)], capture_output=True, text=True).stdout.strip()
    try:
        return float(r)
    except ValueError:
        return None


def bpm_key(nombre):
    m = re.search(r"(\d{2,3})\s?bpm", nombre, re.I) or re.search(r"[_\- ](\d{2,3})[_\- ](?:[A-G][#b]?(?:m|min|maj)?)\b", nombre)
    k = re.search(r"(?:^|[_\- ])([A-G][#b]?(?:m|min|maj|minor|major)?)(?:[_\- .]|$)", nombre)
    return (int(m.group(1)) if m else None), (k.group(1) if k else None)


def indexar():
    if not carpetas():
        sys.exit("Todavia no hay carpetas de samples. Agregalas con: cable samples agregar \"/ruta/a/tus/samples\"")
    c = conectar()
    ya = {r[0]: r[1] for r in c.execute("select path, mtime from s")}
    nuevos, vistos = [], set()
    for raiz in carpetas():
        for dp, dn, fn in os.walk(raiz):
            dn[:] = [d for d in dn if not d.startswith(".")]
            for f in fn:
                if f.startswith(".") or Path(f).suffix.lower() not in EXT:
                    continue
                p = os.path.join(dp, f)
                vistos.add(p)
                try:
                    st = os.stat(p)
                except OSError:
                    continue
                if ya.get(p) != st.st_mtime:
                    nuevos.append((p, st))
    print(f"{len(vistos)} audios en {len(carpetas())} carpetas, {len(nuevos)} nuevos o cambiados", flush=True)

    def info(t):
        p, st = t
        e = Path(p).suffix.lower()
        d = dur_wav(p) if e == ".wav" else None
        if d is None:
            d = dur_ffprobe(p)
        b, k = bpm_key(Path(p).stem)
        return (p, Path(p).stem, str(Path(p).parent), e, st.st_size, d, b, k, st.st_mtime)

    t0 = time.time()
    with ThreadPoolExecutor(8) as ex:
        for i, fila in enumerate(ex.map(info, nuevos), 1):
            c.execute("insert or replace into s values(?,?,?,?,?,?,?,?,?)", fila)
            if i % 500 == 0:
                c.commit()
                print(f"  {i}/{len(nuevos)} ({time.time() - t0:.0f} s)", flush=True)
    for p in set(ya) - vistos:
        c.execute("delete from s where path=?", (p,))
    c.commit()
    print(f"listo: {c.execute('select count(*) from s').fetchone()[0]} en el indice, {time.time() - t0:.0f} s", flush=True)


SIN = {  # sinonimos es/en: cada grupo se busca como alternativas
    "kick": ["kick", "bombo", "bd", "kik"], "bombo": ["kick", "bombo", "bd"], "snare": ["snare", "redoblante", "caja", "sd"],
    "hat": ["hat", "hihat", "hh", "hi-hat"], "clap": ["clap", "palma", "palmas"], "bajo": ["bass", "bajo", "808", "sub"],
    "bass": ["bass", "bajo", "808", "sub"], "tom": ["tom"], "perc": ["perc", "percusion", "shaker", "conga", "bongo"],
    "voz": ["vox", "vocal", "voz"], "guitarra": ["guitar", "gtr", "guitarra"], "piano": ["piano", "keys"], "pad": ["pad"],
    "crash": ["crash"], "ride": ["ride"], "fx": ["fx", "riser", "sweep", "impact"], "loop": ["loop"],
}
NEG_SECO = ["verb", "reverb", "wet", "delay", "echo", "room", "long", "tail"]


def tokens(q):
    q = q.lower()
    corto = bool(re.search(r"\b(corto|short|punchy|seco|dry|tight)\b", q))
    seco = bool(re.search(r"\b(seco|dry|tight)\b", q))
    largo = bool(re.search(r"\b(largo|long|sostenido|sustain)\b", q))
    palabras = [w for w in re.findall(r"[a-z0-9áéíóúñ#]+", q) if w not in {"un", "una", "el", "la", "de", "mis", "mi", "traeme", "buscame", "dame", "samples", "sample", "muestra", "y", "con", "que", "corto", "short", "punchy", "seco", "dry", "tight", "largo", "long"}]
    grupos = [SIN.get(w, [w]) for w in palabras]
    return grupos, corto, seco, largo


def medir(p):
    r = subprocess.run(["ffmpeg", "-v", "error", "-t", "3", "-i", p, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"], capture_output=True)
    x = np.frombuffer(r.stdout, np.float32)
    if len(x) < 256:
        return None
    pico = np.abs(x).max() + 1e-9
    env = np.sqrt(np.convolve(x ** 2, np.ones(220) / 220, "same")) + 1e-9
    i0 = int(np.argmax(env))
    umbral = env[i0] * 10 ** (-40 / 20)
    despues = np.where(env[i0:] < umbral)[0]
    decay = (despues[0] if len(despues) else len(env) - i0) / SR
    seg = x[max(i0 - 100, 0):i0 + int(SR * .15)]
    S = np.abs(np.fft.rfft(seg * np.hanning(len(seg)))) ** 2
    fq = np.fft.rfftfreq(len(seg), 1 / SR)
    tot = S.sum() + 1e-12
    return dict(graves=float(S[fq < 150].sum() / tot), agudos=float(S[fq > 2500].sum() / tot), decay=float(decay),
                pico_db=float(20 * np.log10(pico)), ataque_ms=float(max(i0 - np.argmax(env > env[i0] * .1), 0) / SR * 1000))


def buscar(q, n=5):
    c = conectar()
    grupos, corto, seco, largo = tokens(q)
    filas = c.execute("select path, name, folder, dur, bpm, key from s").fetchall()
    cand = []
    for p, nombre, carpeta, d, bpm, key in filas:
        txt = (nombre + " " + carpeta).lower()
        txt_nombre = nombre.lower()
        pts = 0
        ok = True
        for g in grupos:
            en_nombre = any(re.search(rf"(?<![a-z]){re.escape(a)}(?![a-z])", txt_nombre) for a in g)
            en_ruta = any(re.search(rf"(?<![a-z]){re.escape(a)}(?![a-z])", txt) for a in g)
            if not en_ruta:
                ok = False
                break
            pts += 3 if en_nombre else 1
        if not ok:
            continue
        if d is None:
            continue
        if corto and d > 1.5:
            continue
        if largo and d < 2:
            continue
        if seco and any(t in txt for t in NEG_SECO):
            pts -= 2
        if "loop" in txt_nombre and not any("loop" in a for g in grupos for a in g):
            pts -= 3
        cand.append((pts, p, nombre, d, bpm, key))
    cand.sort(key=lambda t: (-t[0], t[3]))
    total = len(cand)
    top = cand[:60]
    res = []
    with ThreadPoolExecutor(8) as ex:
        ms = list(ex.map(lambda t: medir(t[1]), top))
    for t, m in zip(top, ms):
        if m is None:
            continue
        sc = t[0]
        es_kick = any(a in ("kick", "bombo") for g in grupos for a in g)
        if es_kick:
            sc += 4 * m["graves"] - 3 * m["agudos"]
        if seco or corto:
            sc += 2 * max(0, 1 - m["decay"] / 0.5)
        res.append((sc, t, m))
    res.sort(key=lambda r: -r[0])
    print(f"{total} coinciden con «{q}»; midiendo los {len(top)} mejores por nombre. Los {min(n, len(res))} primeros:")
    for sc, t, m in res[:n]:
        print(f"- {t[1]}\n    {t[3]:.2f} s · graves {m['graves']:.0%} · agudos {m['agudos']:.0%} · cola a -40 dB {m['decay']*1000:.0f} ms · pico {m['pico_db']:.1f} dBFS"
              + (f" · {t[4]} bpm" if t[4] else "") + (f" · {t[5]}" if t[5] else ""))
    if not res:
        print("sin resultados: probá otras palabras (kick, snare, hat, bass, vox, loop…)")


def estado():
    c = conectar()
    n, d = c.execute("select count(*), sum(dur)/3600 from s").fetchone()
    print(f"indice: {n} audios, {d or 0:.0f} h de audio; carpetas: {', '.join(carpetas())}; db: {DB}")


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a or a[0] == "estado":
        estado()
    elif a[0] == "agregar":
        p = str(Path(" ".join(a[1:])).expanduser().resolve())
        if not Path(p).is_dir():
            sys.exit("no existe la carpeta: " + p)
        lista = carpetas()
        if p not in lista:
            CFG.write_text("\n".join(lista + [p]) + "\n")
        print("carpetas de samples:", *carpetas(), sep="\n  ")
    elif a[0] == "indexar":
        indexar()
    elif a[0] == "buscar":
        n = 5
        if "--n" in a:
            n = int(a[a.index("--n") + 1])
            a = a[:a.index("--n")] + a[a.index("--n") + 2:]
        buscar(" ".join(a[1:]), n)
    else:
        sys.exit(__doc__)
